import 'dart:ffi';
import 'dart:convert'; // for JSON decoding
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart' as path;

typedef GetStartMenuAppsC = Pointer<Utf16> Function();
typedef GetStartMenuAppsDart = Pointer<Utf16> Function();

typedef TakeAppIcoC = Pointer<Utf16> Function();
typedef TakeAppIcoDart = Pointer<Utf16> Function();

late DynamicLibrary _dylib;

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
            .map((json) => {
                  'name': json['name'] as String,
                  'path': json['path'] as String,
                })
            .toList();
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
      print('Program launched successfully: $filePath');
    } catch (e) {
      print('Failed to launch program: $e');
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

              Directory directory = Directory('C:\\Users\\Administrator\\Desktop\\111\\WinBarDock-7.4\\bin\\img\\app');
              // Directory directory = Directory(args1[0]);
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text('')),
  //     body:
  //         // WindowBorder(
  //         //   color: borderColor,
  //         //   width: 1,
  //         //   child:

  //         ListView.builder(
  //       itemCount: apps.length,
  //       itemBuilder: (context, index) {
  //         final fileName = apps[index]['name']!;
  //         final filePath = apps[index]['path']!;

  //         String imagePath = '';

  //         Directory directory = Directory('C:\\Users\\Administrator\\Desktop\\111\\WinBarDock-7.4\\bin\\img\\app');
  //         // Directory directory = Directory(args1[0]);
  //         List<FileSystemEntity> filesInFolder = directory.listSync();

  //         for (var file in filesInFolder) {
  //           if (file is File && file.uri.pathSegments.last == '$fileName.png') {
  //             imagePath = file.path;
  //             break;
  //           }
  //         }

  //         return MouseRegion(
  //           onEnter: (_) {
  //             setState(() {
  //               _hovered[index] = true;
  //             });
  //           },
  //           onExit: (_) {
  //             setState(() {
  //               _hovered[index] = false;
  //             });
  //           },
  //           child: GestureDetector(
  //             onTap: () {
  //               // DateTime now = DateTime.now();
  //               // if (_lastTapTime != null && now.difference(_lastTapTime!) <= Duration(milliseconds: 500)) {
  //               // 检测到双击事件
  //               _handleDoubleClick(filePath);
  //               // }
  //               // _lastTapTime = now;
  //             },
  //             child: Container(
  //               color: _hovered[index] ? Colors.grey[300] : Colors.transparent,
  //               child: ListTile(
  //                 contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 18.0),
  //                 tileColor: Colors.transparent,
  //                 leading: imagePath.isNotEmpty
  //                     ? Image.file(
  //                         File(imagePath),
  //                         width: 25,
  //                         height: 25,
  //                         fit: BoxFit.cover,
  //                       )
  //                     : Icon(Icons.account_circle),
  //                 title: Text(fileName),
  //                 // if (args.isNotEmpty) {
  //                 //   fileName = args[0];
  //                 // } Text(fileName),
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
}

List<String> args1 = [];
const borderColor = Color(0xFF805306);
Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    args1 = args;

    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FileListPage(),
    ));
  } else {
    runApp(MaterialApp(
      home: FileListPage(),
    ));
  }

  // 在窗口构建完成后，设置无边框窗口
}
