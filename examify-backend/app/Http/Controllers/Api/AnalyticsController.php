<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Assessment;
use App\Models\StudentAttempt;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    public function getExamAnalytics($id)
    {
        $assessment = Assessment::findOrFail($id);

        $attempts = StudentAttempt::where('assessment_id', $id)
            ->where('status', 'submitted')
            ->get();

        if ($attempts->isEmpty()) {
            return response()->json([
                'average_score' => 0,
                'highest_score' => 0,
                'lowest_score' => 0,
                'distribution' => [],
            ]);
        }

        $average = $attempts->avg('score');
        $highest = $attempts->max('score');
        $lowest = $attempts->min('score');

        // Frequency distribution (histogram data)
        $distribution = $attempts->groupBy(function ($item) {
            return floor($item->score / 10) * 10;
        })->map->count();

        // Specific requirements: distribution of correct/incorrect answers per question
        // This requires joining with student_answers and questions
        $questionPerformance = DB::table('questions')
            ->where('assessment_id', $id)
            ->leftJoin('student_answers', 'questions.id', '=', 'student_answers.question_id')
            ->select(
                'questions.id',
                'questions.text',
                DB::raw('SUM(CASE WHEN student_answers.is_correct = 1 THEN 1 ELSE 0 END) as correct_count'),
                DB::raw('SUM(CASE WHEN student_answers.is_correct = 0 THEN 1 ELSE 0 END) as incorrect_count')
            )
            ->groupBy('questions.id', 'questions.text')
            ->get();

        return response()->json([
            'average_score' => round($average, 2),
            'highest_score' => $highest,
            'lowest_score' => $lowest,
            'score_distribution' => $distribution,
            'question_performance' => $questionPerformance,
        ]);
    }
}
