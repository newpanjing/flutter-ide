import 'package:flutter/material.dart';

class SyntaxTreeNode {
  final String name;
  final String type; // class, method, variable, constant
  final List<SyntaxTreeNode> children;
  final int lineNumber;
  bool isExpanded;

  SyntaxTreeNode({
    required this.name,
    required this.type,
    required this.lineNumber,
    this.children = const [],
    this.isExpanded = true,
  });
}

class SyntaxTree extends StatefulWidget {
  final String? code;
  final Function(int)? onLineSelected;

  const SyntaxTree({super.key, this.code, this.onLineSelected});

  @override
  State<SyntaxTree> createState() => _SyntaxTreeState();
}

class _SyntaxTreeState extends State<SyntaxTree> {
  List<SyntaxTreeNode> _nodes = [];

  @override
  void initState() {
    super.initState();
    _parseCode();
  }

  @override
  void didUpdateWidget(SyntaxTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != oldWidget.code) {
      _parseCode();
    }
  }

  void _parseCode() {
    if (widget.code == null) {
      setState(() {
        _nodes = [];
      });
      return;
    }

    // 简单的解析逻辑，后续可以使用更复杂的解析器
    final lines = widget.code!.split('\n');
    final nodes = <SyntaxTreeNode>[];
    SyntaxTreeNode? currentClass;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('class ')) {
        final className = trimmed.split(' ')[1].split('{')[0].trim();
        currentClass = SyntaxTreeNode(
          name: className,
          type: 'class',
          lineNumber: lines.indexOf(line),
          children: [],
        );
        nodes.add(currentClass);
      } else if (trimmed.startsWith('void ') ||
          trimmed.startsWith('Future<void> ')) {
        if (currentClass != null && trimmed.contains('(')) {
          final methodName = trimmed.split('(')[0].split(' ').last.trim();
          currentClass.children.add(
            SyntaxTreeNode(
              name: methodName,
              type: 'method',
              lineNumber: lines.indexOf(line),
            ),
          );
        }
      }
    }

    setState(() {
      _nodes = nodes;
    });
  }

  Widget _buildNode(SyntaxTreeNode node, {double indent = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (widget.onLineSelected != null) {
              widget.onLineSelected!(node.lineNumber);
            }
            setState(() {
              node.isExpanded = !node.isExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(left: indent),
            child: Row(
              children: [
                if (node.children.isNotEmpty)
                  Icon(
                    node.isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: Colors.white54,
                  ),
                if (node.children.isEmpty) const SizedBox(width: 16),
                const SizedBox(width: 4),
                Icon(
                  node.type == 'class' ? Icons.class_ : Icons.functions,
                  size: 16,
                  color: node.type == 'class' ? Colors.yellow : Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(node.name, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        if (node.isExpanded)
          ...node.children.map(
            (child) => _buildNode(child, indent: indent + 24),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '大纲',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _nodes.map((node) => _buildNode(node)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
