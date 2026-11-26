#pragma once

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <mutex>

#include "clipboard_monitor.h"
#include "focus_and_paste_manager.h"

class ClipmBridgePlugin {
 public:
  static void RegisterWithRegistrar(flutter::FlutterEngine* engine,
                                    HWND flutter_hwnd);

  ClipmBridgePlugin(flutter::BinaryMessenger* messenger, HWND flutter_hwnd);
  ~ClipmBridgePlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void EmitClipboardEvent(const NativeClipboardEvent& event);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
  std::mutex sink_mutex_;

  std::unique_ptr<ClipboardMonitor> monitor_;
  std::unique_ptr<FocusAndPasteManager> focus_manager_;
};
