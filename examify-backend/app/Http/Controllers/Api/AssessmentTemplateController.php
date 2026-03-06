<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AssessmentTemplateController extends Controller
{
    public function index()
    {
        $templates = [
            [
                'id' => 'gen_knowledge',
                'title' => 'General Knowledge Quiz',
                'description' => 'A basic quiz covering general topics like geography and science.',
                'type' => 'quiz',
                'time_limit_minutes' => 15,
                'weight' => 20,
                'questions' => [
                    [
                        'body' => 'What is the capital of France?',
                        'type' => 'multiple_choice',
                        'points' => 10,
                        'options' => [
                            ['body' => 'Paris', 'is_correct' => true],
                            ['body' => 'London', 'is_correct' => false],
                            ['body' => 'Berlin', 'is_correct' => false],
                        ]
                    ],
                    [
                        'body' => 'Which planet is known as the Red Planet?',
                        'type' => 'multiple_choice',
                        'points' => 10,
                        'options' => [
                            ['body' => 'Mars', 'is_correct' => true],
                            ['body' => 'Venus', 'is_correct' => false],
                            ['body' => 'Jupiter', 'is_correct' => false],
                        ]
                    ]
                ]
            ],
            [
                'id' => 'science_midterm',
                'title' => 'Science Midterm Exam',
                'description' => 'Comprehensive midterm covering introductory biological concepts.',
                'type' => 'exam',
                'time_limit_minutes' => 60,
                'weight' => 40,
                'questions' => [
                    [
                        'body' => 'What is the powerhouse of the cell?',
                        'type' => 'multiple_choice',
                        'points' => 5,
                        'options' => [
                            ['body' => 'Mitochondria', 'is_correct' => true],
                            ['body' => 'Nucleus', 'is_correct' => false],
                            ['body' => 'Ribosome', 'is_correct' => false],
                        ]
                    ],
                    [
                        'body' => 'What is the chemical symbol for Water?',
                        'type' => 'multiple_choice',
                        'points' => 5,
                        'options' => [
                            ['body' => 'H2O', 'is_correct' => true],
                            ['body' => 'CO2', 'is_correct' => false],
                            ['body' => 'O2', 'is_correct' => false],
                        ]
                    ]
                ]
            ]
        ];

        return response()->json($templates);
    }
}
