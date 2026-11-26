#include "focus_and_paste_manager.h"

#include <chrono>
#include <thread>
#include <vector>

void FocusAndPasteManager::CapturePreviousWindow() {
  HWND fg = GetForegroundWindow();
  if (fg != nullptr && fg != flutter_hwnd_) {
    previous_hwnd_ = fg;
  }
}

void FocusAndPasteManager::RestoreFocusAndPaste(bool simulate_paste) {
  if (flutter_hwnd_) {
    ShowWindow(flutter_hwnd_, SW_HIDE);
  }

  if (previous_hwnd_ && IsWindow(previous_hwnd_)) {
    DWORD current_thread = GetCurrentThreadId();
    DWORD target_thread = GetWindowThreadProcessId(previous_hwnd_, nullptr);

    bool attached = false;
    if (current_thread != target_thread) {
      attached = AttachThreadInput(current_thread, target_thread, TRUE) != 0;
    }

    SetForegroundWindow(previous_hwnd_);
    BringWindowToTop(previous_hwnd_);
    SetFocus(previous_hwnd_);

    if (attached) {
      AttachThreadInput(current_thread, target_thread, FALSE);
    }
  }

  if (!simulate_paste) return;

  std::thread([this]() {
    std::this_thread::sleep_for(std::chrono::milliseconds(60));
    SendCtrlV();
  }).detach();
}

void FocusAndPasteManager::SendCtrlV() {
  std::vector<INPUT> inputs;

  auto release_if_down = [&](WORD vk) {
    if (GetAsyncKeyState(vk) & 0x8000) {
      INPUT in{};
      in.type = INPUT_KEYBOARD;
      in.ki.wVk = vk;
      in.ki.dwFlags = KEYEVENTF_KEYUP;
      inputs.push_back(in);
    }
  };
  release_if_down(VK_SHIFT);
  release_if_down(VK_LSHIFT);
  release_if_down(VK_RSHIFT);
  release_if_down(VK_MENU);
  release_if_down(VK_LWIN);
  release_if_down(VK_RWIN);

  auto push_key = [&](WORD vk, DWORD flags) {
    INPUT in{};
    in.type = INPUT_KEYBOARD;
    in.ki.wVk = vk;
    in.ki.dwFlags = flags;
    inputs.push_back(in);
  };

  push_key(VK_CONTROL, 0);
  push_key('V', 0);
  push_key('V', KEYEVENTF_KEYUP);
  push_key(VK_CONTROL, KEYEVENTF_KEYUP);

  SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
}
