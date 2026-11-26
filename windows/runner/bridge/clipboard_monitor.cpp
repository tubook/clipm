#include "clipboard_monitor.h"

#include <gdiplus.h>
#include <shlwapi.h>

#include <chrono>
#include <memory>
#include <thread>

#pragma comment(lib, "gdiplus.lib")

namespace {

constexpr wchar_t kMonitorWindowClass[] = L"ClipmClipboardMonitorHiddenWindow";

std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return {};
  int size = WideCharToMultiByte(CP_UTF8, 0, wide.data(),
                                 static_cast<int>(wide.size()), nullptr, 0,
                                 nullptr, nullptr);
  std::string utf8(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()),
                      utf8.data(), size, nullptr, nullptr);
  return utf8;
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return {};
  int size = MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                 static_cast<int>(utf8.size()), nullptr, 0);
  std::wstring wide(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                      wide.data(), size);
  return wide;
}

bool OpenClipboardWithRetry(HWND owner, int max_retries = 5) {
  for (int i = 0; i < max_retries; ++i) {
    if (OpenClipboard(owner)) return true;
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  return false;
}

bool GetPngEncoderClsid(CLSID* out_clsid) {
  UINT num = 0, size = 0;
  Gdiplus::GetImageEncodersSize(&num, &size);
  if (size == 0) return false;
  std::vector<uint8_t> buf(size);
  auto* info = reinterpret_cast<Gdiplus::ImageCodecInfo*>(buf.data());
  Gdiplus::GetImageEncoders(num, size, info);
  for (UINT i = 0; i < num; ++i) {
    if (wcscmp(info[i].MimeType, L"image/png") == 0) {
      *out_clsid = info[i].Clsid;
      return true;
    }
  }
  return false;
}

bool ParsePngDimensions(const std::vector<uint8_t>& bytes, int& width,
                        int& height) {
  if (bytes.size() < 24) return false;
  static const uint8_t kSig[8] = {0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A};
  if (memcmp(bytes.data(), kSig, 8) != 0) return false;
  width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
  height =
      (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
  return width > 0 && height > 0;
}

}  // namespace

ClipboardMonitor::ClipboardMonitor(Callback callback)
    : callback_(std::move(callback)) {
  Gdiplus::GdiplusStartupInput input;
  Gdiplus::GdiplusStartup(&gdiplus_token_, &input, nullptr);

  fmt_exclude_monitor_ =
      RegisterClipboardFormatW(L"ExcludeClipboardContentFromMonitorProcessing");
  fmt_can_include_history_ =
      RegisterClipboardFormatW(L"CanIncludeInClipboardHistory");
  fmt_viewer_ignore_ = RegisterClipboardFormatW(L"Clipboard Viewer Ignore");
  fmt_internal_marker_ = RegisterClipboardFormatW(L"ClipmInternalWrite");
  fmt_png_ = RegisterClipboardFormatW(L"PNG");
  fmt_html_ = RegisterClipboardFormatW(L"HTML Format");
}

ClipboardMonitor::~ClipboardMonitor() {
  Stop();
  if (gdiplus_token_ != 0) {
    Gdiplus::GdiplusShutdown(gdiplus_token_);
  }
}

bool ClipboardMonitor::Start() {
  if (msg_hwnd_ != nullptr) return true;

  WNDCLASSW wc{};
  wc.lpfnWndProc = &ClipboardMonitor::WndProc;
  wc.hInstance = GetModuleHandleW(nullptr);
  wc.lpszClassName = kMonitorWindowClass;
  RegisterClassW(&wc);

  msg_hwnd_ = CreateWindowExW(0, kMonitorWindowClass, L"", 0, 0, 0, 0, 0,
                              HWND_MESSAGE, nullptr, wc.hInstance, this);
  if (!msg_hwnd_) return false;
  return AddClipboardFormatListener(msg_hwnd_) == TRUE;
}

void ClipboardMonitor::Stop() {
  if (msg_hwnd_) {
    RemoveClipboardFormatListener(msg_hwnd_);
    DestroyWindow(msg_hwnd_);
    msg_hwnd_ = nullptr;
  }
}

LRESULT CALLBACK ClipboardMonitor::WndProc(HWND hwnd, UINT msg, WPARAM wparam,
                                           LPARAM lparam) {
  if (msg == WM_NCCREATE) {
    auto* cs = reinterpret_cast<CREATESTRUCTW*>(lparam);
    SetWindowLongPtrW(hwnd, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    return TRUE;
  }

  auto* self =
      reinterpret_cast<ClipboardMonitor*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
  if (self && msg == WM_CLIPBOARDUPDATE) {
    self->HandleClipboardUpdate();
    return 0;
  }
  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

bool ClipboardMonitor::ShouldIgnoreClipboard() const {
  if (IsClipboardFormatAvailable(fmt_internal_marker_) ||
      IsClipboardFormatAvailable(fmt_exclude_monitor_) ||
      IsClipboardFormatAvailable(fmt_viewer_ignore_)) {
    return true;
  }

  if (IsClipboardFormatAvailable(fmt_can_include_history_)) {
    HANDLE h = GetClipboardData(fmt_can_include_history_);
    if (h) {
      auto* val = static_cast<DWORD*>(GlobalLock(h));
      bool disallowed = (val != nullptr && *val == 0);
      GlobalUnlock(h);
      if (disallowed) return true;
    }
  }
  return false;
}

std::string ClipboardMonitor::GetSourceAppName() const {
  HWND owner = GetClipboardOwner();
  if (!owner) owner = GetForegroundWindow();
  if (!owner) return {};

  DWORD pid = 0;
  GetWindowThreadProcessId(owner, &pid);
  if (pid == 0) return {};

  HANDLE proc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (!proc) return {};

  wchar_t path[MAX_PATH] = {0};
  DWORD size = MAX_PATH;
  std::string name;
  if (QueryFullProcessImageNameW(proc, 0, path, &size)) {
    std::wstring full(path);
    auto pos = full.find_last_of(L"\\/");
    name = WideToUtf8(pos == std::wstring::npos ? full : full.substr(pos + 1));
  }
  CloseHandle(proc);
  return name;
}

bool ClipboardMonitor::TryExtractImage(NativeClipboardEvent& out_event) const {
  if (IsClipboardFormatAvailable(fmt_png_)) {
    HANDLE h = GetClipboardData(fmt_png_);
    if (h) {
      SIZE_T sz = GlobalSize(h);
      auto* ptr = static_cast<const uint8_t*>(GlobalLock(h));
      if (ptr && sz > 24) {
        out_event.image_bytes.assign(ptr, ptr + sz);
        GlobalUnlock(h);
        if (ParsePngDimensions(out_event.image_bytes, out_event.image_width,
                               out_event.image_height)) {
          out_event.type = "image";
          return true;
        }
      } else if (ptr) {
        GlobalUnlock(h);
      }
    }
  }

  if (IsClipboardFormatAvailable(CF_DIB)) {
    HANDLE h = GetClipboardData(CF_DIB);
    if (!h) return false;
    auto* bmi = static_cast<BITMAPINFO*>(GlobalLock(h));
    if (!bmi) return false;

    const BYTE* bits =
        reinterpret_cast<const BYTE*>(bmi) + bmi->bmiHeader.biSize;
    if (bmi->bmiHeader.biBitCount <= 8) {
      DWORD colors = bmi->bmiHeader.biClrUsed
                         ? bmi->bmiHeader.biClrUsed
                         : (1u << bmi->bmiHeader.biBitCount);
      bits += colors * sizeof(RGBQUAD);
    } else if (bmi->bmiHeader.biCompression == BI_BITFIELDS) {
      bits += 3 * sizeof(DWORD);
    }

    std::unique_ptr<Gdiplus::Bitmap> bmp(
        Gdiplus::Bitmap::FromBITMAPINFO(bmi, const_cast<BYTE*>(bits)));
    GlobalUnlock(h);
    if (!bmp || bmp->GetLastStatus() != Gdiplus::Ok) return false;

    CLSID png_clsid;
    if (!GetPngEncoderClsid(&png_clsid)) return false;

    IStream* stream = nullptr;
    if (FAILED(CreateStreamOnHGlobal(nullptr, TRUE, &stream))) return false;

    bool ok = false;
    if (bmp->Save(stream, &png_clsid, nullptr) == Gdiplus::Ok) {
      HGLOBAL mem = nullptr;
      if (SUCCEEDED(GetHGlobalFromStream(stream, &mem))) {
        SIZE_T sz = GlobalSize(mem);
        auto* data = static_cast<const uint8_t*>(GlobalLock(mem));
        if (data && sz > 0) {
          out_event.type = "image";
          out_event.image_bytes.assign(data, data + sz);
          out_event.image_width = static_cast<int>(bmp->GetWidth());
          out_event.image_height = static_cast<int>(bmp->GetHeight());
          ok = true;
        }
        if (data) GlobalUnlock(mem);
      }
    }
    stream->Release();
    return ok;
  }
  return false;
}

void ClipboardMonitor::HandleClipboardUpdate() {
  if (suppress_next_update_) {
    suppress_next_update_ = false;
    return;
  }

  if (!OpenClipboardWithRetry(msg_hwnd_)) return;

  if (ShouldIgnoreClipboard()) {
    CloseClipboard();
    return;
  }

  NativeClipboardEvent event;
  event.source_app = GetSourceAppName();
  bool has_payload = false;

  if (!IsClipboardFormatAvailable(CF_HDROP) && TryExtractImage(event)) {
    has_payload = true;
  }

  if (!has_payload && IsClipboardFormatAvailable(CF_UNICODETEXT)) {
    HANDLE h_text = GetClipboardData(CF_UNICODETEXT);
    if (h_text) {
      auto* wstr = static_cast<const wchar_t*>(GlobalLock(h_text));
      if (wstr) {
        event.plain_text = WideToUtf8(std::wstring(wstr));
        GlobalUnlock(h_text);
      }
    }

    if (!event.plain_text.empty()) {
      has_payload = true;
      event.type = "text";

      if (IsClipboardFormatAvailable(fmt_html_)) {
        HANDLE h_html = GetClipboardData(fmt_html_);
        if (h_html) {
          auto* html_str = static_cast<const char*>(GlobalLock(h_html));
          if (html_str && html_str[0] != '\0') {
            event.rich_content = std::string(html_str);
            event.type = "richText";
          }
          if (html_str) GlobalUnlock(h_html);
        }
      }
    }
  }

  CloseClipboard();

  if (has_payload && callback_) {
    callback_(event);
  }
}

bool ClipboardMonitor::WriteToClipboard(
    const std::string& type, const std::string& plain_text,
    const std::string& rich_content, const std::vector<uint8_t>& image_bytes) {
  if (!OpenClipboardWithRetry(msg_hwnd_)) return false;

  suppress_next_update_ = true;
  EmptyClipboard();

  if (HGLOBAL h_mark = GlobalAlloc(GMEM_MOVEABLE, 1)) {
    if (auto* p = GlobalLock(h_mark)) {
      *static_cast<uint8_t*>(p) = 1;
      GlobalUnlock(h_mark);
      SetClipboardData(fmt_internal_marker_, h_mark);
    }
  }

  if (type == "image" && !image_bytes.empty()) {
    if (HGLOBAL h_png = GlobalAlloc(GMEM_MOVEABLE, image_bytes.size())) {
      if (auto* p = GlobalLock(h_png)) {
        memcpy(p, image_bytes.data(), image_bytes.size());
        GlobalUnlock(h_png);
        SetClipboardData(fmt_png_, h_png);
      }
    }
  } else {
    if (type == "richText" && !rich_content.empty()) {
      if (HGLOBAL h_html =
              GlobalAlloc(GMEM_MOVEABLE, rich_content.size() + 1)) {
        if (auto* p = GlobalLock(h_html)) {
          memcpy(p, rich_content.c_str(), rich_content.size() + 1);
          GlobalUnlock(h_html);
          SetClipboardData(fmt_html_, h_html);
        }
      }
    }
    if (!plain_text.empty()) {
      std::wstring wide = Utf8ToWide(plain_text);
      SIZE_T bytes = (wide.size() + 1) * sizeof(wchar_t);
      if (HGLOBAL h_text = GlobalAlloc(GMEM_MOVEABLE, bytes)) {
        if (auto* p = GlobalLock(h_text)) {
          memcpy(p, wide.c_str(), bytes);
          GlobalUnlock(h_text);
          SetClipboardData(CF_UNICODETEXT, h_text);
        }
      }
    }
  }

  CloseClipboard();
  return true;
}
