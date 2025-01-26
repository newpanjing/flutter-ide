import 'package:flutter/material.dart';
import 'widgets/file_explorer.dart';
import 'widgets/code_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Editor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  String? selectedFilePath;

  void _handleFileSelected(String filePath) {
    setState(() {
      selectedFilePath = filePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: FileExplorer(
              onFileSelected: _handleFileSelected,
              initialPath: null,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: CodeEditor(filePath: selectedFilePath)),
        ],
      ),
    );
  }
}
