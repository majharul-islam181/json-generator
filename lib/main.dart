import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

void main() {
  runApp(const FreezedModelGeneratorApp());
}

class FreezedModelGeneratorApp extends StatelessWidget {
  const FreezedModelGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freezed Model Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _classNameController =
      TextEditingController(text: "UserModel");

  String generatedCode = "";
  Map<String, String> _downloadFiles = {};

  void generateModel() {
    try {
      final json = jsonDecode(_jsonController.text);
      final className = _classNameController.text.trim();

      if (json is Map<String, dynamic>) {
        final dartFileName = className.toLowerCase();

        final modelCode =
            generateFreezedModel(className: className, json: json);
        final freezedStub = '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
            '// This would be generated by `freezed`.\n';
        final jsonStub = '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
            '// This would be generated by `json_serializable`.\n';

        setState(() {
          generatedCode = modelCode;
          _downloadFiles = {
            '$dartFileName.dart': modelCode,
            '$dartFileName.freezed.dart': freezedStub,
            '$dartFileName.g.dart': jsonStub,
          };
        });
      } else {
        showError("Invalid JSON format. Must be a JSON object.");
      }
    } catch (e) {
      showError("Error parsing JSON: $e");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void copyToClipboard() {
    html.window.navigator.clipboard?.writeText(generatedCode);
    showError("Copied to clipboard");
  }

  void downloadFile() {
    _downloadFiles.forEach((fileName, content) {
      final blob = html.Blob([content]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    });

    showError("Files downloaded successfully");
  }

  String generateFreezedModel({
    required String className,
    required Map<String, dynamic> json,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        "import 'package:freezed_annotation/freezed_annotation.dart';");
    buffer.writeln();
    buffer.writeln("part '${className.toLowerCase()}.freezed.dart';");
    buffer.writeln("part '${className.toLowerCase()}.g.dart';");
    buffer.writeln();
    buffer.writeln("@freezed");
    buffer.writeln("class $className with _\$$className {");
    buffer.writeln("  const factory $className({");

    json.forEach((key, value) {
      final type = _getDartType(value);
      buffer.writeln("    required $type $key,");
    });

    buffer.writeln("  }) = _$className;");
    buffer.writeln();
    buffer.writeln(
        "  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);");
    buffer.writeln("}");

    return buffer.toString();
  }

  String _getDartType(dynamic value) {
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'List<dynamic>';
    if (value is Map) return 'Map<String, dynamic>';
    return 'String';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Freezed Model Generator')),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _classNameController,
                        decoration: const InputDecoration(
                          labelText: 'Model Class Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: TextField(
                          controller: _jsonController,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            labelText: 'Paste JSON here',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                              onPressed: generateModel,
                              child: const Text("Generate")),
                          const SizedBox(width: 12),
                          if (generatedCode.isNotEmpty) ...[
                            ElevatedButton(
                                onPressed: copyToClipboard,
                                child: const Text("Copy")),
                            const SizedBox(width: 12),
                            ElevatedButton(
                                onPressed: downloadFile,
                                child: const Text("Download")),
                          ]
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (generatedCode.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            generatedCode,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
