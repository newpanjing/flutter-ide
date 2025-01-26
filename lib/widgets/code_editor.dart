import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/androidstudio.dart';
import 'package:flutter_highlight/themes/dark.dart';
import 'package:flutter_highlight/themes/idea.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:myapp/widgets/syntax_tree.dart';

class CodeEditor extends StatefulWidget {
  final String? filePath;

  const CodeEditor({super.key, this.filePath});

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  String _content = '';
  late CodeController _controller;
  String _output = '';
  bool _isRunning = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = CodeController(text: '', language: null, patternMap: {});
    _loadFile();
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filePath != oldWidget.filePath) {
      _loadFile();
    }
  }

  void _loadFile() {
    if (widget.filePath == null) {
      setState(() {
        _content = '';
        _controller.text = '';
      });
      return;
    }

    try {
      final file = File(widget.filePath!);
      if (file.existsSync()) {
        setState(() {
          _content = file.readAsStringSync();
          _controller.text = _content;
          _controller.language = _getLanguageMode(widget.filePath!);
        });
      }
    } catch (e) {
      debugPrint('Error loading file: $e');
    }
  }

  _saveFile() async {
    if (widget.filePath == null) return;

    try {
      final file = File(widget.filePath!);
      file.writeAsStringSync(_controller.text);
      setState(() {
        _content = _controller.text;
      });
    } catch (e) {
      debugPrint('Error saving file: $e');
    }
  }

  Process? _process;

  Future<void> _runCode() async {
    if (widget.filePath == null) return;
    await _saveFile();

    setState(() {
      _isRunning = true;
      _output = '运行中...';
    });

    try {
      _process = await Process.start('dart', [widget.filePath!]);
      _process!.stdout.transform(const SystemEncoding().decoder).listen((data) {
        setState(() {
          _output += data;
        });
      });
      _process!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        setState(() {
          _output += 'data:\n${data}\n';
        });
      });
      await _process!.exitCode;
    } catch (e) {
      setState(() {
        _output += '错误: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _stopCode() {
    _process?.kill();
    setState(() {
      _isRunning = false;
      _output += '已停止运行';
    });
  }

  @override
  void dispose() {
    _process?.kill();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filePath == null) {
      return const Center(
        child: Text('请选择一个文件', style: TextStyle(color: Colors.white)),
      );
    }

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        widget.filePath!.split('/').last,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.save, color: Colors.white),
                        onPressed: _saveFile,
                        tooltip: '保存文件',
                      ),
                      IconButton(
                        icon: Icon(
                          _isRunning ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: _isRunning ? _stopCode : _runCode,
                        tooltip: _isRunning ? '停止运行' : '运行代码',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: CodeTheme(
                            data: CodeThemeData(styles: androidstudioTheme),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: CodeField(
                                controller: _controller,
                                textStyle: const TextStyle(fontSize: 14),
                                onChanged: (text) {
                                  setState(() {
                                    _content = text;
                                  });
                                },
                                gutterStyle: GutterStyle(
                                  textStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  width: 80,
                                  margin: 0,
                                  showLineNumbers: true,
                                  showErrors: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 150,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade800),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _output,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 250,
            child: SyntaxTree(
              code: _content,
              onLineSelected: (line) {
                final text = _controller.text;
                final lines = text.split('\n');
                int offset = 0;
                for (int i = 0; i < line && i < lines.length; i++) {
                  offset += lines[i].length + 1; // +1 for newline character
                }
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: offset),
                );
                final lineHeight = 20.0; // 估算每行高度
                _scrollController.animateTo(
                  line * lineHeight,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _getLanguageMode(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        return dart;
      case 'js':
        return javascript;
      case 'css':
        return css;
      case 'json':
        return json;
      case 'yaml':
      case 'yml':
        return yaml;
      case 'md':
        return markdown;
      default:
        return null;
    }
  }
}
