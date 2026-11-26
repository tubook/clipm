#pragma once

#include <windows.h>

class FocusAndPasteManager {
 public:
  explicit FocusAndPasteManager(HWND flutter_hwnd) : flutter_hwnd_(flutter_hwnd) {}

  void CapturePreviousWindow();
  void RestoreFocusAndPaste(bool simulate_paste);

 private:
  void SendCtrlV();

  HWND flutter_hwnd_ = nullptr;
  HWND previous_hwnd_ = nullptr;
};
