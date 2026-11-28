#pragma once

#include <windows.h>

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

struct NativeClipboardEvent {
  std::string type;  // "text" | "richText" | "image" | "file"
  std::string plain_text;
  std::string rich_content;
  std::vector<uint8_t> image_bytes;
  int image_width = 0;
  int image_height = 0;
  std::vector<std::string> file_paths;
  std::string source_app;
};

class ClipboardMonitor {
 public:
  using Callback = std::function<void(const NativeClipboardEvent&)>;

  explicit ClipboardMonitor(Callback callback);
  ~ClipboardMonitor();

  bool Start();
  void Stop();

  bool WriteToClipboard(const std::string& type,
                        const std::string& plain_text,
                        const std::string& rich_content,
                        const std::vector<uint8_t>& image_bytes,
                        const std::vector<std::string>& file_paths = {});

 private:
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam);
  void HandleClipboardUpdate();
  bool ShouldIgnoreClipboard() const;
  std::string GetSourceAppName() const;
  bool TryExtractImage(NativeClipboardEvent& out_event) const;

  Callback callback_;
  HWND msg_hwnd_ = nullptr;
  ULONG_PTR gdiplus_token_ = 0;
  bool suppress_next_update_ = false;

  UINT fmt_exclude_monitor_ = 0;
  UINT fmt_can_include_history_ = 0;
  UINT fmt_viewer_ignore_ = 0;
  UINT fmt_internal_marker_ = 0;
  UINT fmt_png_ = 0;
  UINT fmt_html_ = 0;
};
