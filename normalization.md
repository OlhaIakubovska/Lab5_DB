# Звіт з Лабораторної робота №5
**Тема:** Нормалізація бази даних онлайн-курсів

**Студентка:** Якубовська О.В.

**Група:** ІО-45
---

## 1. Огляд вихідної схеми

Схема з ЛР №2 містить 7 таблиць:

| Таблиця    | Стовпці |
|------------|---------|
| User       | UserID, FirstName, LastName, Email, Password, RegistrationDate |
| Student    | UserID, AcademicLevel, TotalPoints |
| Instructor | UserID, Bio, Expertise, Rating |
| Course     | CourseID, Title, Description, Price, InstructorID |
| Module     | ModuleID, CourseID, Title, OrderNumber, ContentURL |
| Enrollment | EnrollmentID, StudentID, CourseID, EnrollDate, Progress, Status |
| Review     | ReviewID, CourseID, StudentID, Rating, CommentText, ReviewDate |

---

## 2. Функціональні залежності (ФЗ)

### 2.1 Таблиця `User`
```
UserID → FirstName, LastName, Email, Password, RegistrationDate
Email  → UserID, FirstName, LastName, Password, RegistrationDate
```
Первинний ключ: `UserID`. Альтернативний ключ: `Email`.

### 2.2 Таблиця `Student`
```
UserID → AcademicLevel, TotalPoints
```
Первинний ключ: `UserID` (FK → User).

### 2.3 Таблиця `Instructor`
```
UserID → Bio, Expertise, Rating
```
Первинний ключ: `UserID` (FK → User).

### 2.4 Таблиця `Course`
```
CourseID    → Title, Description, Price, InstructorID
InstructorID → (атрибути Instructor — зовнішній ключ)
```
Первинний ключ: `CourseID`.

> **Потенційна проблема**: поле `Expertise` (спеціалізація) зберігається як вільний рядок у таблиці `Instructor`. Якщо один предмет експертизи використовується кількома викладачами, його назва дублюється — ознака можливої денормалізації.

### 2.5 Таблиця `Module`
```
ModuleID          → CourseID, Title, OrderNumber, ContentURL
(CourseID, OrderNumber) → ModuleID, Title, ContentURL
```
Первинний ключ: `ModuleID`. Альтернативний ключ: `(CourseID, OrderNumber)`.

### 2.6 Таблиця `Enrollment`
```
EnrollmentID        → StudentID, CourseID, EnrollDate, Progress, Status
(StudentID, CourseID) → EnrollmentID, EnrollDate, Progress, Status
```
Первинний ключ: `EnrollmentID`. Альтернативний унікальний ключ: `(StudentID, CourseID)`.

> **Потенційна проблема**: поле `Status` ('Active'/'Completed') є **похідним** від `Progress`: якщо Progress = 100 → Status = 'Completed'. Це транзитивна залежність:  
> `EnrollmentID → Progress → Status`

### 2.7 Таблиця `Review`
```
ReviewID            → CourseID, StudentID, Rating, CommentText, ReviewDate
(StudentID, CourseID) → ReviewID, Rating, CommentText, ReviewDate
```
Первинний ключ: `ReviewID`. Альтернативний унікальний ключ: `(StudentID, CourseID)`.

---

## 3. Перевірка нормальних форм

### 3.1 Перша нормальна форма (1NF)

**Вимоги 1NF:** усі атрибути атомарні, немає повторюваних груп.

| Таблиця    | 1NF? | Коментар |
|------------|------|----------|
| User       | ✅   | Усі атрибути атомарні |
| Student    | ✅   | Усі атрибути атомарні |
| Instructor | ✅   | `Expertise` — один рядок (атомарний) |
| Course     | ✅   | Усі атрибути атомарні |
| Module     | ✅   | Усі атрибути атомарні |
| Enrollment | ✅   | Усі атрибути атомарні |
| Review     | ✅   | Усі атрибути атомарні |

**Висновок:** усі таблиці відповідають 1NF.

---

### 3.2 Друга нормальна форма (2NF)

**Вимоги 2NF:** таблиця у 1NF + жоден неключовий атрибут не залежить від *частини* складеного ключа.

Таблиці з простим (одностовпцевим) ключем автоматично задовольняють 2NF.  
Таблиці з альтернативним складеним ключем перевіряємо окремо:

| Таблиця    | Складений ключ | 2NF? | Коментар |
|------------|----------------|------|----------|
| Enrollment | (StudentID, CourseID) | ✅ | EnrollDate, Progress, Status залежать від обох стовпців |
| Review     | (StudentID, CourseID) | ✅ | Rating, CommentText, ReviewDate залежать від обох стовпців |
| Module     | (CourseID, OrderNumber) | ✅ | Title, ContentURL залежать від обох стовпців |

**Висновок:** усі таблиці відповідають 2NF.

---

### 3.3 Третя нормальна форма (3NF)

**Вимоги 3NF:** таблиця у 2NF + жоден неключовий атрибут не залежить від іншого неключового атрибута (без транзитивних залежностей).

#### Проблема 1 — Таблиця `Enrollment`: транзитивна залежність `Progress → Status`

```
EnrollmentID → Progress → Status
```

`Status` ('Active' або 'Completed') логічно визначається значенням `Progress` (100 = Completed, <100 = Active). Це **транзитивна залежність**, що порушує 3NF:

- **Аномалія оновлення**: якщо Progress оновлюється до 100, але Status залишається 'Active' — дані суперечливі.
- **Надлишковість**: один факт (завершеність) зберігається двічі.

**Виправлення:** видалити поле `Status` і обчислювати його через View або генерований стовпець.

#### Проблема 2 — Таблиця `Instructor`: поле `Expertise` як вільний рядок

```
UserID → Expertise (текстовий рядок)
```

Наприклад, якщо 10 викладачів мають спеціалізацію 'Web Development', рядок дублюється. При перейменуванні спеціалізації потрібно оновлювати багато рядків.

**Виправлення:** винести `Expertise` в окрему довідникову таблицю `ExpertiseArea`.

---

## 4. Застосування нормалізації

### 4.1 Виправлення таблиці `Enrollment` (усунення транзитивної залежності)

**До (порушення 3NF):**
```
Enrollment(EnrollmentID PK, StudentID FK, CourseID FK, EnrollDate, Progress, Status)
```

**Транзитивна залежність:**
```
Progress → Status  (якщо Progress = 100 → Status = 'Completed', інакше 'Active')
```

**Після (3NF):**  
Видаляємо `Status` із таблиці. Статус визначається через обчислюваний вираз або View:

```
Enrollment(EnrollmentID PK, StudentID FK, CourseID FK, EnrollDate, Progress)
```

Статус курсу обчислюється: `CASE WHEN Progress = 100 THEN 'Completed' ELSE 'Active' END`.
<img width="1348" height="611" alt="image" src="https://github.com/user-attachments/assets/fb7d6780-1765-4b01-8239-d42d3ef94ead" />

**Чому це усуває аномалію:**  
Тепер неможлива ситуація, де `Progress = 100` але `Status = 'Active'`. Єдине джерело правди — поле `Progress`.

---

### 4.2 Виправлення таблиці `Instructor` (винесення `Expertise`)

**До (потенційна надлишковість):**
```
Instructor(UserID PK, Bio, Expertise VARCHAR(100), Rating)
```

**Після (3NF):**  
Створюємо таблицю-довідник:

```
ExpertiseArea(ExpertiseID PK, ExpertiseName UNIQUE)
Instructor(UserID PK, Bio, ExpertiseID FK → ExpertiseArea, Rating)
```
<img width="2111" height="398" alt="image" src="https://github.com/user-attachments/assets/400d80b6-9c87-4fba-bcc0-cab8977c9b89" />

**Чому це усуває аномалію:**  
- Аномалія оновлення: при зміні назви спеціалізації оновлюється лише один рядок в `ExpertiseArea`.
- Аномалія вставки: можна додати нову спеціалізацію без прив'язки до конкретного викладача.
- Аномалія видалення: видалення останнього викладача зі спеціалізацією не знищує саму спеціалізацію.

---

## 5. Підсумкова схема (3NF)
<img width="1100" height="225" alt="image" src="https://github.com/user-attachments/assets/1dd8ace5-2300-4218-b2d8-d713fc99f7dd" />

### Таблиці без змін (вже у 3NF):
- `User` — без змін
- `Student` — без змін
- `Course` — без змін
- `Module` — без змін
- `Review` — без змін

### Змінені таблиці:
- `Instructor` — поле `Expertise VARCHAR(100)` замінено на `ExpertiseID INTEGER FK`
- `Enrollment` — видалено поле `Status`

### Нові таблиці:
- `ExpertiseArea(ExpertiseID, ExpertiseName)`
<img width="828" height="335" alt="image" src="https://github.com/user-attachments/assets/197c60a2-2e6d-4d68-a618-66cccc867909" />

---

## 6. Нові CREATE TABLE для фінальної схеми (3NF)

Повні визначення таблиць наведено у файлі `lab5_normalization.sql`.

---

## 8. Висновки

| Таблиця    | Вихідна НФ | Проблема | Результат |
|------------|------------|----------|-----------|
| User       | 3NF | — | Без змін |
| Student    | 3NF | — | Без змін |
| Instructor | 2NF* | `Expertise` — вільний рядок, дублювання | Додано `ExpertiseArea`, FK |
| Course     | 3NF | — | Без змін |
| Module     | 3NF | — | Без змін |
| Enrollment | 2NF* | `Progress → Status` (транзитивна залежність) | Видалено `Status`, замінено View |
| Review     | 3NF | — | Без змін |

\* *Формально таблиці були у 2NF, але порушували 3NF через зазначені залежності.*

Після нормалізації схема повністю відповідає **3NF**: кожен неключовий атрибут залежить лише від первинного ключа, цілісно і без транзитивних залежностей.
