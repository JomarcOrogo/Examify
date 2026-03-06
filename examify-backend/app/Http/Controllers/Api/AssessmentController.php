<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Classroom;
use App\Models\Assessment;
use App\Models\ExamConsent;
use App\Models\StudentAttempt;
use Illuminate\Support\Facades\DB;

class AssessmentController extends Controller
{
    public function index(Request $request, $id)
    {
        $classroom = Classroom::findOrFail($id);
        $user = $request->user();

        $query = $classroom->assessments();
        if ($user->role === 'student') {
            if (!$classroom->students()->where('users.id', $user->id)->exists())
                abort(403);
            $query->where('is_published', true);
        } else {
            if ($classroom->teacher_id !== $user->id)
                abort(403);
        }

        return response()->json($query->get(), 200);
    }

    public function store(Request $request, $id)
    {
        $classroom = Classroom::where('id', $id)->where('teacher_id', $request->user()->id)->firstOrFail();

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:exam,quiz,activity',
            'time_limit_minutes' => 'nullable|integer',
            'is_published' => 'required|boolean',
            'max_violations' => 'sometimes|integer',
            'warn_at_violations' => 'sometimes|integer',
            'questions' => 'required|array',
            'questions.*.body' => 'required|string',
            'questions.*.type' => 'sometimes|string',
            'questions.*.points' => 'sometimes|integer',
            'questions.*.options' => 'required|array|min:2',
            'questions.*.options.*.body' => 'required|string',
            'questions.*.options.*.is_correct' => 'required|boolean',
        ]);

        $assessment = null;
        DB::transaction(function () use ($validated, $classroom, &$assessment) {
            $assessment = $classroom->assessments()->create([
                'title' => $validated['title'],
                'description' => $validated['description'] ?? null,
                'type' => $validated['type'],
                'time_limit_minutes' => $validated['time_limit_minutes'] ?? null,
                'is_published' => $validated['is_published'],
                'max_violations' => $validated['max_violations'] ?? 5,
                'warn_at_violations' => $validated['warn_at_violations'] ?? 3,
            ]);

            foreach ($validated['questions'] as $qIndex => $qData) {
                $question = $assessment->questions()->create([
                    'body' => $qData['body'],
                    'type' => $qData['type'] ?? 'multiple_choice',
                    'points' => $qData['points'] ?? 1,
                    'order' => $qIndex,
                ]);

                foreach ($qData['options'] as $oData) {
                    $question->options()->create([
                        'body' => $oData['body'],
                        'is_correct' => $oData['is_correct'],
                    ]);
                }
            }
        });

        return response()->json($assessment->load('questions.options'), 201);
    }

    public function show(Request $request, $id)
    {
        $assessment = Assessment::with('questions.options')->findOrFail($id);
        $user = $request->user();

        if ($user->role === 'student') {
            if (!$assessment->is_published)
                abort(403, 'Assessment not published');
            // Hide is_correct for students
            $assessment->questions->each(function ($question) {
                $question->options->makeHidden('is_correct');
            });
            // Shuffle questions for students
            $assessment->setRelation('questions', $assessment->questions->shuffle());
        }

        return response()->json($assessment, 200);
    }

    public function consent(Request $request, $id)
    {
        $assessment = Assessment::findOrFail($id);

        ExamConsent::updateOrCreate(
            ['assessment_id' => $assessment->id, 'student_id' => $request->user()->id],
            ['ip_address' => $request->ip(), 'consented_at' => now()]
        );

        return response()->json(['message' => 'Consent recorded'], 201);
    }

    public function start(Request $request, $id)
    {
        $assessment = Assessment::findOrFail($id);
        $user = $request->user();

        $consent = ExamConsent::where('assessment_id', $assessment->id)
            ->where('exam_consents.student_id', $user->id)
            ->first();

        if (!$consent) {
            return response()->json(['message' => 'Consent required'], 403);
        }

        $existingAttempt = StudentAttempt::where('assessment_id', $assessment->id)
            ->where('student_attempts.student_id', $user->id)
            ->where('status', 'in_progress')
            ->first();

        if ($existingAttempt) {
            return response()->json(['message' => 'Attempt already in progress'], 409);
        }

        $attempt = StudentAttempt::create([
            'assessment_id' => $assessment->id,
            'student_id' => $user->id,
            'status' => 'in_progress',
            'started_at' => now(),
        ]);

        return response()->json([
            'attempt_id' => $attempt->id,
            'started_at' => $attempt->started_at->toIso8601String()
        ], 201);
    }

    public function destroy(Request $request, $id)
    {
        $assessment = Assessment::findOrFail($id);

        if ($assessment->classroom->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $assessment->delete();

        return response()->json(['message' => 'Assessment deleted successfully'], 200);
    }
}
