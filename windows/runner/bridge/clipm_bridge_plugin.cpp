#include "clipm_bridge_plugin.h"

namespace {
std::unique_ptr<ClipmBridgePlugin> g_clipm_bridge_instance;
}

void ClipmBridgePlugin::RegisterWithRegistrar(flutter::FlutterEngine* engine,
                                              HWND flutter_hwnd) {
  g_clipm_bridge_instance =
      std::make_unique<ClipmBridgePlugin>(engine->messenger(), flutter_hwnd);
}

ClipmBridgePlugin::ClipmBridgePlugin(flutter::BinaryMessenger* messenger,
                                     HWND flutter_hwnd)
    : flutter_hwnd_(flutter_hwnd),
      focus_manager_(std::make_unique<FocusAndPasteManager>(flutter_hwnd)) {
  method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "com.clipm/native_bridge/methods",
          &flutter::StandardMethodCodec::GetInstance());

  method_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });

  event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, "com.clipm/native_bridge/events",
          &flutter::StandardMethodCodec::GetInstance());

  auto handler = std::make_unique<
      flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue*,
             std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
                 sink) {
        std::lock_guard<std::mutex> lock(sink_mutex_);
        event_sink_ = std::move(sink);
        return nullptr;
      },
      [this](const flutter::EncodableValue*) {
        std::lock_guard<std::mutex> lock(sink_mutex_);
        event_sink_.reset();
        return nullptr;
      });
  event_channel_->SetStreamHandler(std::move(handler));
}

ClipmBridgePlugin::~ClipmBridgePlugin() {
  if (monitor_) monitor_->Stop();
}

void ClipmBridgePlugin::EmitClipboardEvent(const NativeClipboardEvent& event) {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  if (!event_sink_) return;

  flutter::EncodableMap map;
  map[flutter::EncodableValue("type")] = flutter::EncodableValue(event.type);
  if (!event.plain_text.empty()) {
    map[flutter::EncodableValue("plainText")] =
        flutter::EncodableValue(event.plain_text);
  }
  if (!event.rich_content.empty()) {
    map[flutter::EncodableValue("richContent")] =
        flutter::EncodableValue(event.rich_content);
  }
  if (!event.image_bytes.empty()) {
    map[flutter::EncodableValue("imageBytes")] =
        flutter::EncodableValue(event.image_bytes);
    map[flutter::EncodableValue("imageWidth")] =
        flutter::EncodableValue(event.image_width);
    map[flutter::EncodableValue("imageHeight")] =
        flutter::EncodableValue(event.image_height);
  }
  if (!event.source_app.empty()) {
    map[flutter::EncodableValue("sourceApp")] =
        flutter::EncodableValue(event.source_app);
  }
  event_sink_->Success(flutter::EncodableValue(map));
}

void ClipmBridgePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();

  if (method == "startMonitoring") {
    if (!monitor_) {
      monitor_ = std::make_unique<ClipboardMonitor>(
          [this](const NativeClipboardEvent& ev) { EmitClipboardEvent(ev); });
    }
    monitor_->Start();
    result->Success();
  } else if (method == "stopMonitoring") {
    if (monitor_) monitor_->Stop();
    result->Success();
  } else if (method == "capturePreviousApp") {
    focus_manager_->CapturePreviousWindow();
    result->Success();
  } else if (method == "writeClipboard") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Expected map arguments");
      return;
    }
    auto get_str = [&](const char* key) -> std::string {
      auto it = args->find(flutter::EncodableValue(key));
      if (it != args->end()) {
        if (const auto* s = std::get_if<std::string>(&it->second)) return *s;
      }
      return {};
    };
    std::vector<uint8_t> img;
    auto it_img = args->find(flutter::EncodableValue("imageBytes"));
    if (it_img != args->end()) {
      if (const auto* v = std::get_if<std::vector<uint8_t>>(&it_img->second)) {
        img = *v;
      }
    }

    if (monitor_) {
      monitor_->WriteToClipboard(get_str("type"), get_str("plainText"),
                                 get_str("richContent"), img);
    }
    result->Success();
  } else if (method == "restoreFocusAndPaste") {
    bool simulate_paste = true;
    if (const auto* args =
            std::get_if<flutter::EncodableMap>(call.arguments())) {
      auto it = args->find(flutter::EncodableValue("simulatePaste"));
      if (it != args->end()) {
        if (const auto* b = std::get_if<bool>(&it->second)) simulate_paste = *b;
      }
    }
    focus_manager_->RestoreFocusAndPaste(simulate_paste);
    result->Success();
  } else if (method == "checkAccessibilityPermission") {
    result->Success(flutter::EncodableValue(true));
  } else if (method == "getActiveScreenWorkArea") {
    POINT pt{};
    if (!GetCursorPos(&pt)) {
      result->Success();
      return;
    }
    HMONITOR monitor = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
    MONITORINFO mi{};
    mi.cbSize = sizeof(MONITORINFO);
    if (!GetMonitorInfoW(monitor, &mi)) {
      result->Success();
      return;
    }
    UINT dpi = flutter_hwnd_ ? GetDpiForWindow(flutter_hwnd_) : 96;
    double scale = dpi > 0 ? static_cast<double>(dpi) / 96.0 : 1.0;

    flutter::EncodableMap rect;
    rect[flutter::EncodableValue("x")] =
        flutter::EncodableValue(static_cast<double>(mi.rcWork.left) / scale);
    rect[flutter::EncodableValue("y")] =
        flutter::EncodableValue(static_cast<double>(mi.rcWork.top) / scale);
    rect[flutter::EncodableValue("width")] = flutter::EncodableValue(
        static_cast<double>(mi.rcWork.right - mi.rcWork.left) / scale);
    rect[flutter::EncodableValue("height")] = flutter::EncodableValue(
        static_cast<double>(mi.rcWork.bottom - mi.rcWork.top) / scale);
    result->Success(flutter::EncodableValue(rect));
  } else if (method == "setLaunchAtLogin") {
    bool enabled = false;
    if (const auto* args =
            std::get_if<flutter::EncodableMap>(call.arguments())) {
      auto it = args->find(flutter::EncodableValue("enabled"));
      if (it != args->end()) {
        if (const auto* b = std::get_if<bool>(&it->second)) enabled = *b;
      }
    }
    HKEY key = nullptr;
    const wchar_t* run_path = L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
    const wchar_t* value_name = L"clipm";
    bool ok = false;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, run_path, 0, KEY_SET_VALUE, &key) ==
        ERROR_SUCCESS) {
      if (enabled) {
        wchar_t exe_path[MAX_PATH];
        DWORD len = GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
        if (len > 0 && len < MAX_PATH) {
          std::wstring quoted = L"\"";
          quoted += exe_path;
          quoted += L"\"";
          ok = RegSetValueExW(
                   key, value_name, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(quoted.c_str()),
                   static_cast<DWORD>((quoted.size() + 1) * sizeof(wchar_t))) ==
               ERROR_SUCCESS;
        }
      } else {
        LSTATUS status = RegDeleteValueW(key, value_name);
        ok = (status == ERROR_SUCCESS || status == ERROR_FILE_NOT_FOUND);
      }
      RegCloseKey(key);
    }
    result->Success(flutter::EncodableValue(ok));
  } else if (method == "getLaunchAtLogin") {
    HKEY key = nullptr;
    const wchar_t* run_path = L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
    const wchar_t* value_name = L"clipm";
    bool enabled = false;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, run_path, 0, KEY_QUERY_VALUE, &key) ==
        ERROR_SUCCESS) {
      DWORD type = 0;
      DWORD size = 0;
      if (RegQueryValueExW(key, value_name, nullptr, &type, nullptr, &size) ==
              ERROR_SUCCESS &&
          type == REG_SZ && size > 0) {
        enabled = true;
      }
      RegCloseKey(key);
    }
    result->Success(flutter::EncodableValue(enabled));
  } else {
    result->NotImplemented();
  }
}
