<?php

namespace App\Services;

use App\Models\Classroom;
use App\Models\User;
use App\Models\StudentAttempt;

class GradeCalculationService
{
    public function calculateWeightedAverage(Classroom $classroom, User $student)
    {
        $assessments = $classroom->assessments()->where('is_published', true)->get();

        if ($assessments->isEmpty()) {
            return 0;
        }

        $totalWeightedScore = 0;
        $totalWeight = 0;

        foreach ($assessments as $assessment) {
            $attempt = StudentAttempt::where('assessment_id', $assessment->id)
                ->where('student_attempts.student_id', $student->id)
                ->where('status', 'submitted')
                ->first();

            $score = $attempt ? $attempt->score : 0;
            // Assuming score is a percentage or needs to be normalized
            // For now, let's assume assessment max score is 100 or handle accordingly

            $totalWeightedScore += ($score * ($assessment->weight / 100));
            $totalWeight += $assessment->weight;
        }

        return $totalWeight > 0 ? ($totalWeightedScore / ($totalWeight / 100)) : 0;
    }
}
