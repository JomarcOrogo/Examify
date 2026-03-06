import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../teacher_essentials/data/teacher_essentials_service.dart';
import '../../shared/models/assessment.dart';

class AssessmentsTab extends ConsumerWidget {
  final String classroomId;
  const AssessmentsTab({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.role.name == 'teacher';
    final assessmentsAsync = ref.watch(
      assessmentsProvider(int.parse(classroomId)),
    );

    return Scaffold(
      body: assessmentsAsync.when(
        data: (assessments) {
          if (assessments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No assessments yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final exams = assessments.where((a) => a.type == 'exam').toList();
          final quizzes = assessments.where((a) => a.type == 'quiz').toList();
          final activities = assessments
              .where((a) => a.type == 'activity')
              .toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(assessmentsProvider(int.parse(classroomId)).future),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (exams.isNotEmpty) ...[
                  _buildAssignmentSection(context, 'Assessments'),
                  ...exams.map(
                    (a) => _buildAssessmentItem(context, ref, a, isTeacher),
                  ),
                  const SizedBox(height: 32),
                ],
                if (quizzes.isNotEmpty) ...[
                  _buildAssignmentSection(context, 'Quizzes'),
                  ...quizzes.map(
                    (a) => _buildAssessmentItem(context, ref, a, isTeacher),
                  ),
                  const SizedBox(height: 32),
                ],
                if (activities.isNotEmpty) ...[
                  _buildAssignmentSection(context, 'Activities'),
                  ...activities.map(
                    (a) => _buildAssessmentItem(context, ref, a, isTeacher),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/classroom/$classroomId/create-assessment'),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
    );
  }

  Widget _buildAssessmentItem(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
    bool isTeacher,
  ) {
    final dateStr = assessment.createdAt != null
        ? DateFormat('MMM d').format(assessment.createdAt!)
        : 'Recently';

    return _buildAssignmentItem(
      context,
      assessment.title,
      'Posted $dateStr',
      assessment.type == 'exam' ? Icons.assignment : Icons.assignment_turned_in,
      isTeacher: isTeacher,
      status: isTeacher ? 'Manage' : 'Available',
      onTap: () => context.push(
        isTeacher
            ? '/assessment/${assessment.id}/reports'
            : '/assessment/${assessment.id}/consent',
      ),
      onDelete: () => _confirmDelete(context, ref, assessment),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: Text('Are you sure you want to delete "${assessment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(teacherEssentialsServiceProvider)
            .deleteAssessment(assessment.id);
        ref.invalidate(assessmentsProvider(int.parse(classroomId)));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Assessment deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  Widget _buildAssignmentSection(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Divider(thickness: 1, height: 24),
      ],
    );
  }

  Widget _buildAssignmentItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    required bool isTeacher,
    String? status,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (isTeacher)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            )
          else
            const Icon(Icons.more_vert, size: 20),
        ],
      ),
    );
  }
}
