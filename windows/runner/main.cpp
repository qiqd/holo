#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// 添加窗口居中函数
void CenterWindow(HWND hwnd) {
  if (!hwnd) return;

  // 获取窗口大小
  RECT rect;
  GetWindowRect(hwnd, &rect);
  int window_width = rect.right - rect.left;
  int window_height = rect.bottom - rect.top;

  // 获取屏幕工作区（排除任务栏）
  MONITORINFO monitor_info = { sizeof(MONITORINFO) };
  HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  GetMonitorInfo(monitor, &monitor_info);
  
  int screen_width = monitor_info.rcWork.right - monitor_info.rcWork.left;
  int screen_height = monitor_info.rcWork.bottom - monitor_info.rcWork.top;

  // 计算居中位置
  int x = monitor_info.rcWork.left + (screen_width - window_width) / 2;
  int y = monitor_info.rcWork.top + (screen_height - window_height) / 2;

  // 移动窗口
  SetWindowPos(hwnd, nullptr, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnSeparateThread);


  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1000, 800);
  if (!window.Create(L"Holo", origin, size)) {
    return EXIT_FAILURE;
  }

  CenterWindow(window.GetHandle());

  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
