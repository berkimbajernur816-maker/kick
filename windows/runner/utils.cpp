#include "utils.h"

#include <flutter_windows.h>
#include <cstring>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

const wchar_t kKickWindowTitle[] = L"KiCk";
const wchar_t kKickSingleInstanceMutexName[] =
    L"Local\\KiCk.SingleInstanceMutex";

namespace {

constexpr wchar_t kKickActivateWindowMessageName[] =
    L"KiCk.ActivateWindow";
constexpr int kExistingWindowLookupAttempts = 20;
constexpr DWORD kExistingWindowLookupDelayMs = 100;

UINT kKickActivateWindowMessage =
    ::RegisterWindowMessage(kKickActivateWindowMessageName);

HWND FindKickWindow() {
  return ::FindWindow(nullptr, kKickWindowTitle);
}

void ShowAndFocusWindow(HWND window) {
  if (window == nullptr) {
    return;
  }

  auto style = static_cast<DWORD>(::GetWindowLongPtr(window, GWL_STYLE));
  if ((style & WS_VISIBLE) == 0) {
    ::SetWindowLongPtr(window, GWL_STYLE, style | WS_VISIBLE);
  }

  const int show_command = ::IsIconic(window) ? SW_RESTORE : SW_SHOW;
  ::ShowWindowAsync(window, show_command);
  ::SetWindowPos(window, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
  ::SetForegroundWindow(window);
}

}  // namespace

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}

std::wstring Utf16FromUtf8(const char* utf8_string) {
  if (utf8_string == nullptr) {
    return std::wstring();
  }

  const int input_length = static_cast<int>(strlen(utf8_string));
  const int target_length = ::MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string, input_length, nullptr, 0);
  std::wstring utf16_string;
  if (target_length <= 0 ||
      static_cast<size_t>(target_length) > utf16_string.max_size()) {
    return utf16_string;
  }

  utf16_string.resize(target_length);
  const int converted_length = ::MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string, input_length,
      utf16_string.data(), target_length);
  if (converted_length == 0) {
    return std::wstring();
  }

  return utf16_string;
}

UINT GetKickActivateWindowMessage() {
  return kKickActivateWindowMessage;
}

bool NotifyExistingKickInstance() {
  HWND existing_window = nullptr;
  for (int attempt = 0; attempt < kExistingWindowLookupAttempts; ++attempt) {
    existing_window = FindKickWindow();
    if (existing_window != nullptr) {
      break;
    }

    ::Sleep(kExistingWindowLookupDelayMs);
  }

  if (existing_window == nullptr) {
    return false;
  }

  DWORD process_id = 0;
  ::GetWindowThreadProcessId(existing_window, &process_id);
  if (process_id != 0) {
    ::AllowSetForegroundWindow(process_id);
  }

  ::PostMessage(existing_window, GetKickActivateWindowMessage(), 0, 0);
  ShowAndFocusWindow(existing_window);
  return true;
}
