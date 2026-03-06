<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\StudentAttempt;
use App\Models\ProctoringLog;
use Illuminate\Support\Facades\DB;

class StudentAttemptController extends Controller
{
    public function submit(Request $request, $id)
    {
        $attempt = StudentAttempt::findOrFail($id);

        if ($attempt->student_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($attempt->status !== 'in_progress') {
            return response()->json(['message' => 'Attempt is already submitted'], 400);
        }

        $validated = $request->validate([
            'answers' => 'required|array',
            'answers.*.question_id' => 'required|exists:questions,id',
            'answers.*.option_id' => 'nullable|exists:options,id',
        ]);

        $score = 0;
        $total = $attempt->assessment->questions()->count();

        DB::transaction(function () use ($validated, $attempt, &$score) {
            foreach ($validated['answers'] as $answerData) {
                $isCorrect = false;
                if (!empty($answerData['option_id'])) {
                    $option = \App\Models\Option::find($answerData['option_id']);
                    if ($option && $option->is_correct) {
                        $isCorrect = true;
                        $score++;
                    }
                }

                $attempt->answers()->create([
                    'question_id' => $answerData['question_id'],
                    'option_id' => $answerData['option_id'] ?? null,
                ]);
            }

            $attempt->update([
                'status' => 'submitted',
                'score' => $score,
                'submitted_at' => now(),
            ]);
        });

        return response()->json([
            'score' => $score,
            'total' => $total,
        ], 200);
    }

    public function proctorEvent(Request $request, $id)
    {
        $attempt = StudentAttempt::findOrFail($id);

        if ($attempt->student_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($attempt->status !== 'in_progress') {
            return response()->json(['message' => 'Attempt no longer active'], 400);
        }

        $validated = $request->validate([
            'event_type' => 'required|in:alt_tab,app_background,window_blur,fullscreen_exit,window_resize,window_maximize,window_unmaximize,window_close_attempt',
            'platform' => 'required|string',
            'device_info' => 'required|string',
            'timestamp' => 'required|date',
        ]);

        $attempt->increment('violation_count');
        $count = $attempt->violation_count;

        ProctoringLog::create([
            'attempt_id' => $attempt->id,
            'event_type' => $validated['event_type'],
            'platform' => $validated['platform'],
            'device_info' => $validated['device_info'],
            'ip_address' => $request->ip(),
            'violation_number' => $count,
            'timestamp' => \Carbon\Carbon::parse($validated['timestamp']),
        ]);

        $assessment = $attempt->assessment;

        if ($count >= $assessment->max_violations) {
            $attempt->update(['status' => 'auto_submitted', 'submitted_at' => now()]);
            return response()->json(['action' => 'auto_submitted']);
        }

        if ($count >= $assessment->warn_at_violations) {
            return response()->json(['action' => 'warn', 'violation_count' => $count]);
        }

        return response()->json(['action' => 'log', 'violation_count' => $count]);
    }
}
