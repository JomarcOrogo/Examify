import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/teacher_essentials_service.dart';

class BulkUploadScreen extends ConsumerStatefulWidget {
  final int classroomId;
  const BulkUploadScreen({super.key, required this.classroomId});

  @override
  ConsumerState<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends ConsumerState<BulkUploadScreen> {
  bool _isUploading = false;
  double _progress = 0;
  String? _statusMessage;

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _isUploading = true;
        _progress =
            0.5; // Default progress since Dio upload progress is more complex to stream here
        _statusMessage = 'Uploading ${result.files.single.name}...';
      });

      try {
        await ref
            .read(teacherEssentialsServiceProvider)
            .uploadStudents(file, widget.classroomId);
        setState(() {
          _progress = 1.0;
          _statusMessage = 'Import successful!';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Students imported successfully!')),
          );
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
          _statusMessage = 'Error: $e';
        });
      } finally {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isUploading = false;
              _progress = 0;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Student Upload')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_file, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                'Upload Student CSV',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Format: name, email, student_id, section',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              if (_isUploading) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 16),
                Text(_statusMessage ?? ''),
              ] else
                ElevatedButton.icon(
                  onPressed: _pickAndUploadFile,
                  icon: const Icon(Icons.add),
                  label: const Text('Select File'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
