-- =============================================
-- Лабораторна робота №5
-- Нормалізація бази даних — Платформа для онлайн-курсів
-- Студентка: Якубовська О.В., група ІО-45
-- =============================================

-- ========================
-- КРОК 1: ЗНЕСЕННЯ СТАРИХ ТАБЛИЦЬ
-- (виконувати лише при повному перестворенні)
-- ========================

DROP VIEW IF EXISTS EnrollmentView;
DROP TABLE IF EXISTS Review      CASCADE;
DROP TABLE IF EXISTS Enrollment  CASCADE;
DROP TABLE IF EXISTS Module      CASCADE;
DROP TABLE IF EXISTS Course      CASCADE;
DROP TABLE IF EXISTS Instructor  CASCADE;
DROP TABLE IF EXISTS Student     CASCADE;
DROP TABLE IF EXISTS "User"      CASCADE;
DROP TABLE IF EXISTS ExpertiseArea CASCADE;

-- ========================
-- КРОК 2: СТВОРЕННЯ ТАБЛИЦЬ (3NF)
-- ========================

-- 1. Користувач (User) — супертип
--    Без змін відносно ЛР №2
CREATE TABLE "User" (
    UserID           SERIAL PRIMARY KEY,
    FirstName        VARCHAR(50)  NOT NULL,
    LastName         VARCHAR(50)  NOT NULL,
    Email            VARCHAR(100) NOT NULL UNIQUE,
    Password         VARCHAR(255) NOT NULL,
    RegistrationDate DATE         NOT NULL DEFAULT CURRENT_DATE
);

-- 2. Студент (Student) — підтип User
--    Без змін відносно ЛР №2
CREATE TABLE Student (
    UserID        INTEGER PRIMARY KEY REFERENCES "User"(UserID) ON DELETE CASCADE,
    AcademicLevel VARCHAR(50) NOT NULL
        CHECK (AcademicLevel IN ('бакалавр', 'магістр', 'аспірант')),
    TotalPoints   INTEGER     NOT NULL DEFAULT 0 CHECK (TotalPoints >= 0)
);

-- 3. Довідник спеціалізацій (ExpertiseArea) — НОВА ТАБЛИЦЯ
--    Виділена з Instructor для усунення транзитивної залежності:
--    раніше: Instructor.Expertise VARCHAR(100) — вільний рядок, що дублювався
--    тепер:  нормалізований довідник зі зв'язком FK
CREATE TABLE ExpertiseArea (
    ExpertiseID   SERIAL PRIMARY KEY,
    ExpertiseName VARCHAR(100) NOT NULL UNIQUE
);

-- 4. Викладач (Instructor) — підтип User
--    ЗМІНА: поле Expertise VARCHAR(100) замінено на ExpertiseID FK → ExpertiseArea
--    Це усуває дублювання назви спеціалізації та аномалії оновлення
CREATE TABLE Instructor (
    UserID      INTEGER PRIMARY KEY REFERENCES "User"(UserID) ON DELETE CASCADE,
    Bio         TEXT,
    ExpertiseID INTEGER      NOT NULL REFERENCES ExpertiseArea(ExpertiseID),
    Rating      NUMERIC(3,2) CHECK (Rating >= 0 AND Rating <= 5)
);

-- 5. Курс (Course)
--    Без змін відносно ЛР №2
CREATE TABLE Course (
    CourseID     SERIAL PRIMARY KEY,
    Title        VARCHAR(150) NOT NULL,
    Description  TEXT,
    Price        NUMERIC(8,2) NOT NULL DEFAULT 0 CHECK (Price >= 0),
    InstructorID INTEGER      NOT NULL REFERENCES Instructor(UserID) ON DELETE RESTRICT
);

-- 6. Модуль (Module)
--    Без змін відносно ЛР №2
CREATE TABLE Module (
    ModuleID    SERIAL PRIMARY KEY,
    CourseID    INTEGER      NOT NULL REFERENCES Course(CourseID) ON DELETE CASCADE,
    Title       VARCHAR(150) NOT NULL,
    OrderNumber INTEGER      NOT NULL CHECK (OrderNumber > 0),
    ContentURL  VARCHAR(255),
    UNIQUE (CourseID, OrderNumber)
);

-- 7. Зарахування (Enrollment)
--    ЗМІНА: видалено поле Status VARCHAR(20)
--    Обґрунтування: Status є транзитивно залежним від Progress
--    (Progress = 100 → Status = 'Completed', інакше 'Active')
--    Це порушувало 3NF: EnrollmentID → Progress → Status
--    Тепер Status обчислюється через View EnrollmentView
CREATE TABLE Enrollment (
    EnrollmentID SERIAL PRIMARY KEY,
    StudentID    INTEGER      NOT NULL REFERENCES Student(UserID)  ON DELETE CASCADE,
    CourseID     INTEGER      NOT NULL REFERENCES Course(CourseID) ON DELETE CASCADE,
    EnrollDate   DATE         NOT NULL DEFAULT CURRENT_DATE,
    Progress     NUMERIC(5,2) NOT NULL DEFAULT 0
        CHECK (Progress >= 0 AND Progress <= 100),
    UNIQUE (StudentID, CourseID)
);

-- 8. Відгук (Review)
--    Без змін відносно ЛР №2
CREATE TABLE Review (
    ReviewID    SERIAL PRIMARY KEY,
    CourseID    INTEGER  NOT NULL REFERENCES Course(CourseID)  ON DELETE CASCADE,
    StudentID   INTEGER  NOT NULL REFERENCES Student(UserID)   ON DELETE CASCADE,
    Rating      INTEGER  NOT NULL CHECK (Rating >= 1 AND Rating <= 5),
    CommentText TEXT,
    ReviewDate  DATE     NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE (StudentID, CourseID)
);

-- ========================
-- КРОК 3: VIEW ДЛЯ ОБЧИСЛЕННЯ STATUS
-- Status визначається автоматично на основі Progress
-- ========================

CREATE OR REPLACE VIEW EnrollmentView AS
SELECT
    EnrollmentID,
    StudentID,
    CourseID,
    EnrollDate,
    Progress,
    CASE WHEN Progress = 100 THEN 'Completed' ELSE 'Active' END AS Status
FROM Enrollment;


-- ========================
-- КРОК 4: ВСТАВКА ДАНИХ
-- ========================

-- 1. Користувачі
INSERT INTO "User" (FirstName, LastName, Email, Password, RegistrationDate) VALUES
    ('Олена',   'Коваль',     'o.koval@gmail.com',      'hashed_pass_1', '2024-01-10'),
    ('Михайло', 'Бондаренко', 'm.bondarenko@gmail.com', 'hashed_pass_2', '2024-02-15'),
    ('Аліна',   'Шевченко',   'a.shevchenko@gmail.com', 'hashed_pass_3', '2024-03-01'),
    ('Ігор',    'Мельник',    'i.melnyk@gmail.com',     'hashed_pass_4', '2024-03-20'),
    ('Наталія', 'Лисенко',    'n.lysenko@gmail.com',    'hashed_pass_5', '2024-04-05'),
    ('Дмитро',  'Савченко',   'd.savchenko@gmail.com',  'hashed_pass_6', '2024-04-10');

-- 2. Студенти (UserID 1, 2, 3)
INSERT INTO Student (UserID, AcademicLevel, TotalPoints) VALUES
    (1, 'бакалавр', 150),
    (2, 'магістр',  320),
    (3, 'бакалавр', 75);

-- 3. Довідник спеціалізацій
INSERT INTO ExpertiseArea (ExpertiseName) VALUES
    ('Web Development'),
    ('Machine Learning'),
    ('UI/UX та JavaScript');

-- 4. Викладачі (UserID 4, 5, 6)
INSERT INTO Instructor (UserID, Bio, ExpertiseID, Rating) VALUES
    (4, 'Досвідчений розробник з 10 роками у веб-розробці.', 1, 4.80),
    (5, 'PhD з машинного навчання, автор 3 книг.',           2, 4.95),
    (6, 'Фронтенд-розробник та UX-дизайнер.',               3, 4.60);

-- 5. Курси
INSERT INTO Course (Title, Description, Price, InstructorID) VALUES
    ('Python для початківців',   'Базовий курс мови програмування Python.',            499.00, 4),
    ('Machine Learning з нуля',  'Практичний курс з ML з використанням sklearn.',      899.00, 5),
    ('JavaScript та React',      'Сучасний фронтенд-розробка на React.',               699.00, 6),
    ('PostgreSQL та бази даних', 'Проектування та робота з реляційними базами даних.', 599.00, 4),
    ('UX Design основи',         'Принципи проектування зручних інтерфейсів.',         399.00, 6);

-- 6. Модулі
INSERT INTO Module (CourseID, Title, OrderNumber, ContentURL) VALUES
    (1, 'Вступ до Python',        1, 'https://courses.example.com/python/module1'),
    (1, 'Змінні та типи даних',   2, 'https://courses.example.com/python/module2'),
    (1, 'Умови та цикли',         3, 'https://courses.example.com/python/module3'),
    (2, 'Вступ до ML',            1, 'https://courses.example.com/ml/module1'),
    (2, 'Лінійна регресія',       2, 'https://courses.example.com/ml/module2'),
    (2, 'Класифікація',           3, 'https://courses.example.com/ml/module3'),
    (3, 'Основи JavaScript',      1, 'https://courses.example.com/js/module1'),
    (3, 'Вступ до React',         2, 'https://courses.example.com/js/module2'),
    (4, 'Реляційна модель даних', 1, 'https://courses.example.com/db/module1'),
    (4, 'SQL запити',             2, 'https://courses.example.com/db/module2'),
    (5, 'Основи UX',              1, 'https://courses.example.com/ux/module1'),
    (5, 'Wireframing',            2, 'https://courses.example.com/ux/module2');

-- 7. Зарахування (без поля Status — тепер обчислюється)
INSERT INTO Enrollment (StudentID, CourseID, EnrollDate, Progress) VALUES
    (1, 1, '2024-05-01', 100.00),
    (1, 3, '2024-06-10',  60.00),
    (1, 4, '2024-07-01',  30.00),
    (2, 2, '2024-05-15', 100.00),
    (2, 1, '2024-06-01',  80.00),
    (3, 3, '2024-06-20',  45.00),
    (3, 5, '2024-07-05',  20.00);

-- 8. Відгуки
INSERT INTO Review (CourseID, StudentID, Rating, CommentText, ReviewDate) VALUES
    (1, 1, 5, 'Чудовий курс! Все пояснено дуже зрозуміло.',       '2024-06-01'),
    (2, 2, 5, 'Найкращий курс з ML який я бачив. Рекомендую!',    '2024-07-10'),
    (3, 3, 4, 'Гарний курс, але хотілося б більше практики.',      '2024-07-20'),
    (1, 2, 4, 'Добре підходить для початківців.',                  '2024-07-15'),
    (4, 1, 5, 'Дуже корисно для розуміння баз даних.',             '2024-08-01');


-- ========================
-- КРОК 5: ПЕРЕВІРКА ДАНИХ
-- ========================

-- Перевірка через View (статус обчислюється автоматично)
SELECT * FROM EnrollmentView;

-- Перевірка зв'язку Instructor ↔ ExpertiseArea
SELECT u.FirstName, u.LastName, ea.ExpertiseName, i.Rating
FROM Instructor i
JOIN "User" u ON i.UserID = u.UserID
JOIN ExpertiseArea ea ON i.ExpertiseID = ea.ExpertiseID;

-- Загальна перевірка
SELECT * FROM "User";
SELECT * FROM Student;
SELECT * FROM ExpertiseArea;
SELECT * FROM Instructor;
SELECT * FROM Course;
SELECT * FROM Module;
SELECT * FROM Enrollment;
SELECT * FROM Review;
