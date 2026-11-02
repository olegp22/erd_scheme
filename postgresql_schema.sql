-- Скрипт для PostgreSQL
-- Все внешние ключи объявлены непосредственно в CREATE TABLE.
-- Команды ALTER TABLE отсутствуют.

CREATE TYPE "role_user" AS ENUM (
    'admin',
    'teacher',
    'student'
);

CREATE TYPE "type_questions" AS ENUM (
    'single_choice',
    'multiple_choice',
    'text_input',
    'matching',
    'ordering',
    'parameterized_task'
);

CREATE TYPE "matching_side" AS ENUM (
    'left',
    'right'
);

CREATE TYPE "grading_mode" AS ENUM (
    'all_or_nothing',
    'partial_credit'
);

CREATE TYPE "status_testing" AS ENUM (
    'draft',
    'published',
    'archived'
);

CREATE TYPE "StatusImplementation" AS ENUM (
    'assigned',
    'started',
    'completed'
);

CREATE TYPE "ReasonAppointment" AS ENUM (
    'automatically',
    'manually'
);

CREATE TABLE "Users" (
    "id" uuid PRIMARY KEY,
    "email" text UNIQUE NOT NULL,
    "role" role_user DEFAULT 'student',
    "name" text NOT NULL,
    "surname" text NOT NULL,
    "patronymic" text,
    "password" text NOT NULL
);

CREATE TABLE "Questions" (
    "id" serial PRIMARY KEY,
    "text" text,
    "type" type_questions NOT NULL
);

CREATE TABLE "MatchingItem" (
    "id" serial PRIMARY KEY,
    "id_questions" integer NOT NULL
        REFERENCES "Questions" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "value" text NOT NULL,
    "side" matching_side NOT NULL
);

CREATE TABLE "Tests" (
    "id" serial PRIMARY KEY,
    "title" text UNIQUE NOT NULL,
    "description" text,
    "instruction" text,
    "specialty" text
);

CREATE TABLE "Testings" (
    "id" serial PRIMARY KEY,
    "name" text UNIQUE NOT NULL,
    "description" text,
    "status" status_testing DEFAULT 'draft'
);

CREATE TABLE "ParameterizedTask" (
    "id" serial PRIMARY KEY,
    "id_questions" integer NOT NULL
        REFERENCES "Questions" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "template" text NOT NULL,
    "answer_formula" text NOT NULL
);

CREATE TABLE "AnswerOptions" (
    "id" serial PRIMARY KEY,
    "id_questions" integer NOT NULL
        REFERENCES "Questions" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "value" text NOT NULL,
    "is_correct" boolean NOT NULL DEFAULT false
);

CREATE TABLE "MatchingPair" (
    "id" serial PRIMARY KEY,
    "left_item_id" integer NOT NULL
        REFERENCES "MatchingItem" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "right_item_id" integer NOT NULL
        REFERENCES "MatchingItem" ("id") DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE "OrderingItem" (
    "id" serial PRIMARY KEY,
    "id_questions" integer NOT NULL
        REFERENCES "Questions" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "value" text NOT NULL,
    "correct_position" integer NOT NULL
);

CREATE TABLE "TaskParameter" (
    "id" serial PRIMARY KEY,
    "task_id" integer NOT NULL
        REFERENCES "ParameterizedTask" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "name" text NOT NULL,
    "min_value" integer,
    "max_value" integer
);

CREATE TABLE "TestQuestions" (
    "test_id" integer REFERENCES "Tests" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "question_id" integer REFERENCES "Questions" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "is_required" boolean DEFAULT false,
    "mode" grading_mode DEFAULT 'all_or_nothing',
    "max_score_question" numeric(10,2) NOT NULL
        CHECK ("max_score_question" >= 0),
    "penalty_per_error" numeric(10,2) DEFAULT 0
        CHECK ("penalty_per_error" >= 0),
    PRIMARY KEY ("test_id", "question_id")
);

CREATE TABLE "TestingTest" (
    "testing_id" integer REFERENCES "Testings" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "test_id" integer REFERENCES "Tests" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "order_index" integer DEFAULT 1 CHECK ("order_index" > 0),
    "time_limit_test" int DEFAULT 0 CHECK ("time_limit_test" >= 0),
    "passing_score" int NOT NULL,
    "time_start" timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("test_id", "testing_id")
);

CREATE TABLE "ResultTest" (
    "id" uuid PRIMARY KEY,
    "testing_id" integer NOT NULL
        REFERENCES "Testings" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "test_id" integer NOT NULL
        REFERENCES "Tests" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "user_id" uuid NOT NULL
        REFERENCES "Users" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "total_score" numeric(10,2) CHECK ("total_score" >= 0),
    "max_score" numeric(10,2) NOT NULL CHECK ("max_score" >= 0),
    "percent" numeric(10,2) CHECK ("percent" >= 0),
    "passed" boolean NOT NULL,
    "started_at" timestamp,
    "completed_at" timestamp,
    "attempt_number" integer NOT NULL DEFAULT 1
);

CREATE TABLE "UserAnswers" (
    "id" serial PRIMARY KEY,
    "result_test_id" uuid NOT NULL
        REFERENCES "ResultTest" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "question_id" integer NOT NULL
        REFERENCES "Questions" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "score" numeric(10,2) NOT NULL,
    "is_correct" boolean NOT NULL
);

CREATE TABLE "StudentTextAnswer" (
    "id_user_answer" integer PRIMARY KEY
        REFERENCES "UserAnswers" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "content" text
);

CREATE TABLE "StudentSelectedOption" (
    "id" serial PRIMARY KEY,
    "id_user_answer" integer NOT NULL
        REFERENCES "UserAnswers" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "answer_option_id" integer
        REFERENCES "AnswerOptions" ("id") DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE "StudentOrderingAnswer" (
    "id" serial PRIMARY KEY,
    "is_user_answer" integer NOT NULL
        REFERENCES "UserAnswers" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "id_item" integer NOT NULL
        REFERENCES "OrderingItem" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "position" integer
);

CREATE TABLE "StudentParameterizedAnswer" (
    "student_answer_id" integer PRIMARY KEY
        REFERENCES "UserAnswers" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "generated_parameters" jsonb NOT NULL,
    "answer" numeric(10,2)
);

CREATE TABLE "StudentMatchingAnswer" (
    "id" serial PRIMARY KEY,
    "student_answer_id" integer NOT NULL
        REFERENCES "UserAnswers" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "left_item_id" integer NOT NULL
        REFERENCES "MatchingItem" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "right_item_id" integer NOT NULL
        REFERENCES "MatchingItem" ("id") DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE "TestAssigments" (
    "id" serial PRIMARY KEY,
    "test_id" integer REFERENCES "Tests" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "testing_id" integer REFERENCES "Testings" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "user_id" uuid NOT NULL REFERENCES "Users" ("id") DEFERRABLE INITIALLY IMMEDIATE,
    "source" "ReasonAppointment" DEFAULT 'automatically',
    "status" "StatusImplementation" DEFAULT 'assigned',
    "create_at" timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX ON "OrderingItem" ("id_questions", "correct_position");
CREATE UNIQUE INDEX ON "TaskParameter" ("task_id", "name");
CREATE UNIQUE INDEX ON "UserAnswers" ("result_test_id", "question_id");
CREATE UNIQUE INDEX ON "StudentSelectedOption" ("id_user_answer", "answer_option_id");
