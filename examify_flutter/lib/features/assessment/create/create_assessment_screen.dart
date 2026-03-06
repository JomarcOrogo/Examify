import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../teacher_essentials/data/teacher_essentials_service.dart';
import '../../teacher_essentials/models/assessment_template.dart';
import '../../../core/api/api_client.dart';

class CreateAssessmentScreen extends ConsumerStatefulWidget {
  final String classroomId;
  const CreateAssessmentScreen({super.key, required this.classroomId});

  @override
  ConsumerState<CreateAssessmentScreen> createState() =>
      _CreateAssessmentScreenState();
}

class _CreateAssessmentScreenState
    extends ConsumerState<CreateAssessmentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '60');
  String _type = 'exam';
  AssessmentTemplate? _selectedTemplate;
  bool _isSaving = false;

  void _applyTemplate(AssessmentTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _type = template.type;
      _timeLimitController.text = template.timeLimitMinutes.toString();
    });
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(apiClientProvider);
      final questions =
          _selectedTemplate?.questions
              .map(
                (q) => {
                  'body': q.body,
                  'type': q.type,
                  'points': q.points,
                  'options': q.options
                      .map((o) => {'body': o.body, 'is_correct': o.isCorrect})
                      .toList(),
                },
              )
              .toList() ??
          [];

      await dio.post(
        '/classrooms/${widget.classroomId}/assessments',
        data: {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'type': _type,
          'time_limit_minutes': int.tryParse(_timeLimitController.text) ?? 60,
          'is_published': true,
          'questions': questions,
        },
      );

      if (mounted) {
        ref.invalidate(assessmentsProvider(int.parse(widget.classroomId)));
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assessment created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create assessment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(assessmentTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Assessment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            templatesAsync.when(
              data: (templates) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Load from Template',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AssessmentTemplate>(
                    value: _selectedTemplate,
                    hint: const Text('Select a template to pre-fill'),
                    isExpanded: true,
                    items: templates
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.title)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _applyTemplate(val);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('Error loading templates: $e'),
            ),
            AppTextField(
              controller: _titleController,
              label: 'Assessment Title',
              hint: 'e.g. Midterm Physics',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hint: 'Enter instructions or details',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'exam', child: Text('Exam')),
                DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                DropdownMenuItem(value: 'activity', child: Text('Activity')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _timeLimitController,
              label: 'Time Limit (Minutes)',
              keyboardType: TextInputType.number,
            ),
            if (_selectedTemplate != null) ...[
              const SizedBox(height: 24),
              Text(
                'Template Questions (${_selectedTemplate!.questions.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: _selectedTemplate!.questions
                      .map(
                        (q) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.help_outline, size: 16),
                          title: Text(q.body),
                          subtitle: Text('${q.options.length} options'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
              text: 'Save Assessment',
              onPressed: _isSaving ? null : () => _save(),
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
