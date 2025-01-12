import 'dart:ffi';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class DwmAPI {
  static const DWMWA_WINDOW_CORNER_PREFERENCE = 33;

  // 窗口圆角偏好选项
  static const DWMWCP_DEFAULT = 0; // 默认
  static const DWMWCP_DONOTROUND = 1; // 不圆角
  static const DWMWCP_ROUND = 2; // 圆角
  static const DWMWCP_ROUNDSMALL = 3; // 小圆角

  static final _dwmapi = DynamicLibrary.open('dwmapi.dll');

  // 定义 DwmSetWindowAttribute 函数
  static final _DwmSetWindowAttribute = _dwmapi.lookupFunction<Int32 Function(IntPtr hwnd, Uint32 dwAttribute, Pointer pvAttribute, Uint32 cbAttribute),
      int Function(int hwnd, int dwAttribute, Pointer pvAttribute, int cbAttribute)>('DwmSetWindowAttribute');

  static void setWindowCornerPreference(int hwnd, int preference) {
    final cornerPreference = calloc<Int32>();
    cornerPreference.value = preference;

    final result = _DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, cornerPreference, sizeOf<Int32>());
    if (result != S_OK) {
      throw WindowsException(result);
    }

    calloc.free(cornerPreference);
  }
}
