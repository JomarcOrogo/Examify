import 'package:flutter/material.dart';
// Triggering hot reload for seeded data verification
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/teacher_essentials_service.dart';
import '../models/gradebook_entry.dart';

class GradebookScreen extends ConsumerWidget {
  final int classroomId;

  const GradebookScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradebookAsync = ref.watch(gradebookProvider(classroomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Classroom Gradebook')),
      body: gradebookAsync.when(
        data: (entries) => _buildTable(context, entries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<GradebookEntry> entries) {
    if (entries.isEmpty) {
      return const Center(child: Text('No students enrolled in this class.'));
    }

    // Get all unique assessment titles from the entries
    final assessmentTitles = entries
        .expand((e) => e.scores.keys)
        .toSet()
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Student ID')),
            const DataColumn(label: Text('Name')),
            const DataColumn(label: Text('Section')),
            ...assessmentTitles.map((title) => DataColumn(label: Text(title))),
            const DataColumn(label: Text('Calculated Grade')),
          ],
          rows: entries
              .map((entry) => _buildDataRow(entry, assessmentTitles))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(GradebookEntry entry, List<String> assessmentTitles) {
    return DataRow(
      cells: [
        DataCell(Text(entry.studentId ?? 'N/A')),
        DataCell(Text(entry.name)),
        DataCell(Text(entry.section ?? 'N/A')),
        ...assessmentTitles.map((title) {
          final score = entry.scores[title];
          return DataCell(Text(score?.toString() ?? '0.0'));
        }),
        DataCell(
          Text(
            entry.calculatedGrade.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
