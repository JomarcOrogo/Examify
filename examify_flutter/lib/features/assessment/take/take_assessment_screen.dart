import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/proctoring/proctoring_service.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/violation_banner.dart';
import '../../teacher_essentials/data/teacher_essentials_service.dart';
import '../../../shared/models/assessment.dart';
import '../../../shared/models/question.dart';

class TakeAssessmentScreen extends ConsumerStatefulWidget {
  final String assessmentId;
  final int attemptId;
  const TakeAssessmentScreen({
    super.key,
    required this.assessmentId,
    required this.attemptId,
  });

  @override
  ConsumerState<TakeAssessmentScreen> createState() =>
      _TakeAssessmentScreenState();
}

class _TakeAssessmentScreenState extends ConsumerState<TakeAssessmentScreen> {
  late ProctoringService _proctoringService;
  int _violationCount = 0;
  int _currentQuestionIndex = 0;
  final Map<int, int?> _selectedAnswers =
      {}; // Map of question index -> selected option index

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initProctoring();
  }

  void _initTimer(int minutes) {
    if (_isInitialized) return;
    _secondsRemaining = minutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _submit(autoSubmit: true);
      }
    });
    _isInitialized = true;
  }

  void _initProctoring() {
    _proctoringService = ProctoringService(
      attemptId: widget.attemptId,
      apiClient: ref.read(apiClientProvider),
      onViolation: (action) {
        if (!mounted) return;
        setState(() {
          _violationCount = _proctoringService.violationCount;
        });

        if (action == ProctoringAction.warn ||
            action == ProctoringAction.finalWarn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Warning: Focus loss detected. Please stay on the exam screen.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (action == ProctoringAction.autoSubmitted) {
          _submit(autoSubmit: true);
        }
      },
    );
    _proctoringService.start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _proctoringService.stop();
    super.dispose();
  }

  void _submit({bool autoSubmit = false, List<Question>? questions}) async {
    _timer?.cancel();
    await _proctoringService.stop();

    if (questions != null) {
      final answers = <Map<String, dynamic>>[];
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final selectedIdx = _selectedAnswers[i];
        answers.add({
          'question_id': q.id,
          'option_id': selectedIdx != null ? q.options[selectedIdx].id : null,
        });
      }

      try {
        final service = ref.read(teacherEssentialsServiceProvider);
        final result = await service.submitAssessment(
          widget.attemptId,
          answers,
        );

        if (!mounted) return;
        context.pushReplacement(
          '/assessment/${widget.assessmentId}/result',
          extra: result,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit assessment: $e')),
        );
      }
    } else {
      if (!mounted) return;
      context.pushReplacement('/assessment/${widget.assessmentId}/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessmentAsync = ref.watch(
      assessmentDetailProvider(int.parse(widget.assessmentId)),
    );

    return PopScope(
      canPop: false,
      child: assessmentAsync.when(
        data: (assessment) {
          _initTimer(assessment.timeLimitMinutes);
          return _buildExamUI(context, assessment);
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Error loading assessment: $err')),
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildExamUI(BuildContext context, Assessment assessment) {
    final questions = assessment.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment')),
        body: const Center(
          child: Text('No questions found in this assessment.'),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('${assessment.title} - Proctored'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Time Left: ${_formatTime(_secondsRemaining)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _secondsRemaining < 60 ? Colors.red : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_violationCount > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ViolationBanner(violationCount: _violationCount),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentQuestion.body,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: currentQuestion.options.length,
                        itemBuilder: (context, index) {
                          final option = currentQuestion.options[index];
                          return RadioListTile<int>(
                            title: Text(option.body),
                            value: index,
                            groupValue: _selectedAnswers[_currentQuestionIndex],
                            onChanged: (val) {
                              setState(() {
                                _selectedAnswers[_currentQuestionIndex] = val;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppButton(
                          text: 'Previous',
                          onPressed: _currentQuestionIndex > 0
                              ? () => setState(() => _currentQuestionIndex--)
                              : null,
                          isSecondary: true,
                        ),
                        if (_currentQuestionIndex < questions.length - 1)
                          AppButton(
                            text: 'Next Question',
                            onPressed: () => setState(() {
                              _currentQuestionIndex++;
                            }),
                          )
                        else
                          AppButton(
                            text: 'Submit Assessment',
                            onPressed: () => _submit(questions: questions),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
