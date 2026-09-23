## Запрос 1

**Формулировка:** Найти имя, фамилию и специализацию всех тренеров, 
нанятых после 1 января 2023 года.

**Реляционная алгебра:**
π first_name, last_name, specialization ( σ hire_date > '2023-01-01' (Trainer) )

## Запрос 2

**Формулировка:** Получить имена и фамилии клиентов и названия тренировок, 
которые они посетили (attended = true).

**Реляционная алгебра:**
π Client.first_name, Client.last_name, Training.name (
    σ Visit.attended = true (Visit)
    ⋈ Client
    ⋈ Training
)
