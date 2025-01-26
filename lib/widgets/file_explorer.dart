import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

class FileExplorer extends StatefulWidget {
  final Function(String) onFileSelected;
  final String? initialPath;
  final String? filePath;

  const FileExplorer({
    super.key,
    required this.onFileSelected,
    this.initialPath,
    this.filePath,
  });

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  String? currentPath;
  List<FileSystemEntity> files = [];
  bool isCreatingNewFile = false;
  final TextEditingController _newFileController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    currentPath = widget.initialPath;
    if (currentPath != null) {
      _loadFiles();
    }
  }

  @override
  void dispose() {
    _newFileController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadFiles() {
    if (currentPath == null) return;
    setState(() {
      files =
          Directory(currentPath!)
              .listSync()
              .where((entity) => !path.basename(entity.path).startsWith('.'))
              .toList()
            ..sort((a, b) {
              if (a is Directory && b is File) return -1;
              if (a is File && b is Directory) return 1;
              return path.basename(a.path).compareTo(path.basename(b.path));
            });
    });
  }

  void _selectFolder() async {
    String? directory = await FilePicker.platform.getDirectoryPath();

    if (directory != null) {
      setState(() {
        currentPath = directory;
        _loadFiles();
      });
    }
  }

  void _createNewFile() {
    if (currentPath == null) return;
    setState(() {
      isCreatingNewFile = true;
    });
  }

  void _handleNewFileSubmit() {
    if (currentPath == null) return;

    String fileName = _newFileController.text.trim();
    if (fileName.isEmpty) return;

    if (!fileName.contains('.')) {
      fileName = '$fileName.dart';
    }

    final newFilePath = path.join(currentPath!, fileName);
    File(newFilePath).createSync();

    setState(() {
      isCreatingNewFile = false;
      _newFileController.clear();
      _loadFiles();
    });

    widget.onFileSelected(newFilePath);
  }

  void _cancelNewFile() {
    setState(() {
      isCreatingNewFile = false;
      _newFileController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_open, color: Colors.white),
                  onPressed:
                      currentPath == null
                          ? _selectFolder
                          : () {
                            setState(() {
                              currentPath = path.dirname(currentPath!);
                              _loadFiles();
                            });
                          },
                  tooltip: currentPath == null ? '选择文件夹' : '返回上级目录',
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: currentPath == null ? null : _createNewFile,
                  tooltip: '新建文件',
                ),
              ],
            ),
          ),
          Expanded(
            child:
                currentPath == null
                    ? Center(
                      child: Text(
                        '请选择一个文件夹',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    )
                    : Column(
                      children: [
                        if (isCreatingNewFile)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Focus(
                              focusNode: _focusNode,
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.escape) {
                                  _cancelNewFile();
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: TextField(
                                controller: _newFileController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: '输入文件名',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white24,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                autofocus: true,
                                onSubmitted: (_) => _handleNewFileSubmit(),
                                onEditingComplete: _handleNewFileSubmit,
                              ),
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: files.length,
                            itemBuilder: (context, index) {
                              final file = files[index];
                              final isDirectory = file is Directory;
                              return ListTile(
                                leading: Icon(
                                  isDirectory
                                      ? Icons.folder
                                      : Icons.insert_drive_file,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                title: Text(
                                  path.basename(file.path),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                selected:
                                    !isDirectory &&
                                    widget.filePath == file.path,
                                selectedTileColor: Colors.blue.withOpacity(0.2),
                                selectedColor: Colors.white,
                                hoverColor: Colors.white.withOpacity(0.1),
                                onTap: () {
                                  if (isDirectory) {
                                    setState(() {
                                      currentPath = file.path;
                                      _loadFiles();
                                    });
                                  } else {
                                    widget.onFileSelected(file.path);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
