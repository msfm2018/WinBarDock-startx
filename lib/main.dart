import 'dart:ffi';
import 'dart:convert'; // for JSON decoding
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart' as path;
import 'package:win32/win32.dart';

import 'dwm_ffi.dart';

typedef GetStartMenuAppsC = Pointer<Utf16> Function();
typedef GetStartMenuAppsDart = Pointer<Utf16> Function();

typedef TakeAppIcoC = Pointer<Utf16> Function();
typedef TakeAppIcoDart = Pointer<Utf16> Function();

late DynamicLibrary _dylib;

int getFlutterWindowHandle() {
  final hwnd = FindWindowEx(0, 0, TEXT('TForm1'), TEXT('startx'));
  if (hwnd == 0) {
    throw Exception('Unable to find Flutter window handle.');
  }
  return hwnd;
}

class FileListPage extends StatefulWidget {
  @override
  _FileListPageState createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  Map<String, String> _iconCache = {};
  List<Map<String, String>> apps = [];
  List<bool> _hovered = List.generate(100, (_) => false);
  DateTime? _lastTapTime; // 用于记录上一次点击时间

  void fetchStartMenuApps() async {
    try {
      final getStartMenuApps = _dylib.lookupFunction<GetStartMenuAppsC, GetStartMenuAppsDart>('GetStartMenuApps');
      final Pointer<Utf16> resultPointer = getStartMenuApps();
      String result = resultPointer.toDartString();
      List<dynamic> jsonList = jsonDecode(result);

      setState(() {
        apps = jsonList
            .where((json) {
              final filePath = json['path'] as String;
              return filePath.isNotEmpty && // 确保路径非空
                  filePath.endsWith('.exe') && // 只保留可执行文件
                  !filePath.toLowerCase().contains('explorer.exe'); // 排除 File Explorer
            })
            .map((json) => {
                  'name': json['name'] as String,
                  'path': json['path'] as String,
                })
            .toList();

        // apps = jsonList
        //     .map((json) => {
        //           'name': json['name'] as String,
        //           'path': json['path'] as String,
        //         })
        //     .toList();
      });
    } catch (e) {
      print('Error fetching Start Menu Apps: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    _dylib = Platform.isWindows
        ? DynamicLibrary.open('assets/startMenuApps.dll') // Replace with your DLL path
        : DynamicLibrary.process();
    fetchStartMenuApps();
  }

  void _handleDoubleClick(String filePath) async {
    try {
      Process process = await Process.start(filePath, []);
       exit(0);
  
    } catch (e) {
   
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('1111'),
        actions: [
          IconButton(
            icon: Icon(Icons.connect_without_contact),
            tooltip: '远程连接',
            onPressed: () {
              Process.start('mstsc.exe', ['/v:'], runInShell: true);
            },
          ),
          IconButton(
            icon: Icon(Icons.note),
            tooltip: '记事本',
            onPressed: () {
              Process.start('notepad.exe', []);
            },
          ),
          IconButton(
            icon: Icon(Icons.code),
            tooltip: '命令窗口',
            onPressed: () {
              Process.run('cmd', ['/c', 'start cmd'], runInShell: true);
            },
          ),
          IconButton(
            icon: Icon(Icons.calculate),
            tooltip: '计算器',
            onPressed: () {
              Process.start('calc.exe', []);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主体内容
          ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final fileName = apps[index]['name']!;
              final filePath = apps[index]['path']!;

              String imagePath = '';

              // Directory directory = Directory('D:\\V01\\bin\\img\\app');
              Directory directory = Directory(args1[0]);
              List<FileSystemEntity> filesInFolder = directory.listSync();

              for (var file in filesInFolder) {
                if (file is File && file.uri.pathSegments.last == '$fileName.png') {
                  imagePath = file.path;
                  break;
                }
              }

              return MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _hovered[index] = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _hovered[index] = false;
                  });
                },
                child: GestureDetector(
                  onTap: () {
                    _handleDoubleClick(filePath);
                  },
                  child: Container(
                    color: _hovered[index] ? Colors.grey[300] : Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 18.0),
                      tileColor: Colors.transparent,
                      leading: imagePath.isNotEmpty
                          ? Image.file(
                              File(imagePath),
                              width: 25,
                              height: 25,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.account_circle),
                      title: Text(fileName),
                    ),
                  ),
                ),
              );
            },
          ),
          // 底部按钮
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.grey[200], // 背景颜色
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 关闭按钮
                  IconButton(
                    icon: Image.asset(
                      'assets/icons/close.png', // 替换为关闭按钮图片路径
                      width: 30,
                      height: 30,
                    ),
                    onPressed: () {
                      Process.run('shutdown', ['/s', '/t', '0']);
                    },
                  ),
                  // 重启按钮
                  IconButton(
                    icon: Image.asset(
                      'assets/icons/reset.png', // 替换为注销按钮图片路径
                      width: 30,
                      height: 30,
                    ),
                    onPressed: () {
                      Process.run('shutdown', ['/r', '/t', '0']).then((result) {}).catchError((e) {});
                    },
                  ),
                  IconButton(
                    icon: Image.asset(
                      'assets/icons/logout.png', // 替换为注销按钮图片路径
                      width: 30,
                      height: 30,
                    ),
                    onPressed: () {
                      Process.run('shutdown', ['/l']); // 注销用户
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> args1 = [];
const borderColor = Color(0xFF805306);
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

// 如果参数为空，直接退出应用
  if (args.isEmpty) {
    exit(0); // 使用 exit(0) 退出应用
  }
  args1 = args; // 保存参数
  // 确保设置窗口圆角
  Future.delayed(Duration.zero, () {
    try {
      final hwnd = getFlutterWindowHandle();
      DwmAPI.setWindowCornerPreference(hwnd, DwmAPI.DWMWCP_ROUND);
    } catch (e) {
      print('Error setting window corner preference: $e');
    }
  });

  runApp(MaterialApp(
    home: FileListPage(),
  ));
}
