import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/api/api_client.dart';

class ConsentModal extends ConsumerStatefulWidget {
  final String assessmentId;
  const ConsentModal({super.key, required this.assessmentId});

  @override
  ConsumerState<ConsentModal> createState() => _ConsentModalState();
}

class _ConsentModalState extends ConsumerState<ConsentModal> {
  bool _agreed = false;
  bool _isLoading = false;

  void _startExam() async {
    setState(() => _isLoading = true);

    try {
      final dio = ref.read(apiClientProvider);

      // 1. Record Consent
      await dio.post('/assessments/${widget.assessmentId}/consent');

      // 2. Start Attempt
      final response = await dio.post(
        '/assessments/${widget.assessmentId}/start',
      );
      final attemptId = response.data['attempt_id'];

      if (!mounted) return;
      context.pushReplacement(
        '/assessment/${widget.assessmentId}/take?attemptId=$attemptId',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start exam: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('📋 Exam Monitoring Notice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please read carefully before starting.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This assessment is proctored. The following data will be monitored and recorded:\n\n'
              '• Device focus and application tabbing\n'
              '• Unauthorized access to other tabs or windows\n'
              '• Multiple violations will result in auto-submission\n'
              '• Your IP address and device information',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const Spacer(),
            CheckboxListTile(
              value: _agreed,
              onChanged: (val) => setState(() => _agreed = val ?? false),
              title: const Text('I understand and agree to be monitored'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    onPressed: () => context.pop(),
                    isSecondary: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    text: 'Start Exam \u2192',
                    onPressed: _agreed ? _startExam : () {},
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
