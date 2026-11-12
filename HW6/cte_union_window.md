## 1. CTE

### 1.1. Выборка через CTE
**Что хотим получить:** Создать временную таблицу (CTE) с именами клиентов и вывести её.

```sql
WITH ClientNames AS (
    SELECT first_name, last_name 
    FROM client
)
SELECT * FROM ClientNames;
```

### 1.2. Агрегация через CTE
**Что хотим получить:** Посчитать количество тренировок у каждого тренера, используя CTE.

```sql
WITH TrainingCount AS (
    SELECT trainer_id, COUNT(*) AS total_trainings
    FROM training
    GROUP BY trainer_id
)
SELECT tr.first_name, tr.last_name, tc.total_trainings
FROM trainer tr
JOIN TrainingCount tc ON tr.trainer_id = tc.trainer_id;
```

### 1.3. Фильтрация через CTE
**Что хотим получить:** Вывести клиентов, у которых есть абонементы, используя CTE.

```sql
WITH ActiveClients AS (
    SELECT DISTINCT client_id 
    FROM membership
)
SELECT c.first_name, c.last_name
FROM client c
JOIN ActiveClients ac ON c.client_id = ac.client_id;
```

---

## 2. UNION, INTERSECT, EXCEPT — по 1 запросу

### 2.1. UNION (Объединение)
**Что хотим получить:** Получить единый список имен и фамилий клиентов и тренеров.

```sql
SELECT first_name, last_name, 'Клиент' AS role FROM client
UNION
SELECT first_name, last_name, 'Тренер' AS role FROM trainer;
```

### 2.2. INTERSECT (Пересечение)
**Что хотим получить:** Найти клиентов и тренеров с одинаковыми именами.

```sql
SELECT first_name, last_name FROM client
INTERSECT
SELECT first_name, last_name FROM trainer;
```

### 2.3. EXCEPT (Разность)
**Что хотим получить:** Найти клиентов, которые ни разу не совершали платежей.

```sql
SELECT client_id, first_name, last_name FROM client
EXCEPT
SELECT c.client_id, c.first_name, c.last_name 
FROM client c
JOIN payment p ON c.client_id = p.client_id;
```

---

## 3. Оконные функции

### 3.1. PARTITION BY (2 запроса)
**Что хотим получить 3.1.1:** Показать среднюю длительность тренировок для каждого тренера рядом с каждой тренировкой.

```sql
SELECT 
    trainer_id, 
    name, 
    duration_min,
    AVG(duration_min) OVER (PARTITION BY trainer_id) AS avg_duration
FROM training;
```

**Что хотим получить 3.1.2:** Показать максимальную длительность тренировки для каждого тренера.

```sql
SELECT 
    trainer_id, 
    name, 
    duration_min,
    MAX(duration_min) OVER (PARTITION BY trainer_id) AS max_duration
FROM training;
```

### 3.2. PARTITION BY + ORDER BY (2 запроса)
**Что хотим получить 3.2.1:** Накопительная сумма длительности тренировок каждого тренера (по дате).

```sql
SELECT 
    trainer_id, 
    training_date, 
    duration_min,
    SUM(duration_min) OVER (PARTITION BY trainer_id ORDER BY training_date) AS running_total
FROM training;
```

**Что хотим получить 3.2.2:** Накопительная сумма платежей каждого клиента (по дате).

```sql
SELECT 
    client_id, 
    payment_date, 
    amount,
    SUM(amount) OVER (PARTITION BY client_id ORDER BY payment_date) AS cumulative_paid
FROM payment;
```

### 3.3. ROWS и RANGE (2 запроса)
**Что хотим получить 3.3.1 (ROWS):** Скользящее среднее платежей (берем текущую строку и одну предыдущую).

```sql
SELECT 
    client_id,
    payment_date,
    amount,
    AVG(amount) OVER (
        PARTITION BY client_id 
        ORDER BY payment_date 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS moving_avg
FROM payment;
```

**Что хотим получить 3.3.2 (RANGE):** Сумма платежей клиента, учитывая только текущую и предыдущую строки (в данном примере работает так же, как ROWS, но по логике RANGE сравнивает значения).

```sql
SELECT 
    client_id,
    payment_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY client_id 
        ORDER BY payment_date 
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS range_sum
FROM payment;
```

### 3.4. Ранжирующие функции (ROW_NUMBER, RANK, DENSE_RANK, NTILE)
**Что хотим получить 3.4.1 (ROW_NUMBER):** Дать уникальный номер каждой тренировке внутри одного тренера.

```sql
SELECT 
    trainer_id, 
    name,
    ROW_NUMBER() OVER (PARTITION BY trainer_id ORDER BY training_date) AS row_num
FROM training;
```

**Что хотим получить 3.4.2 (RANK):** Ранжировать тренировки по длительности (при равенстве пропускает номер).

```sql
SELECT 
    trainer_id, 
    name,
    duration_min,
    RANK() OVER (PARTITION BY trainer_id ORDER BY duration_min DESC) AS rank_num
FROM training;
```

**Что хотим получить 3.4.3 (DENSE_RANK):** То же самое, но без пропуска номеров.

```sql
SELECT 
    trainer_id, 
    name,
    duration_min,
    DENSE_RANK() OVER (PARTITION BY trainer_id ORDER BY duration_min DESC) AS dense_rank_num
FROM training;
```

**Что хотим получить 3.4.4 (NTILE):** Разбить все тренировки на 2 группы по длительности (1 - самые долгие, 2 - остальные).

```sql
SELECT 
    name,
    duration_min,
    NTILE(2) OVER (ORDER BY duration_min DESC) AS group_num
FROM training;
```

### 3.5. Функции смещения (LAG, LEAD, FIRST_VALUE, LAST_VALUE)
**Что хотим получить 3.5.1 (LAG):** Показать длительность предыдущей тренировки этого же тренера.

```sql
SELECT 
    trainer_id, 
    name, 
    duration_min,
    LAG(duration_min) OVER (PARTITION BY trainer_id ORDER BY training_date) AS prev_duration
FROM training;
```

**Что хотим получить 3.5.2 (LEAD):** Показать длительность следующей тренировки этого же тренера.

```sql
SELECT 
    trainer_id, 
    name, 
    duration_min,
    LEAD(duration_min) OVER (PARTITION BY trainer_id ORDER BY training_date) AS next_duration
FROM training;
```

**Что хотим получить 3.5.3 (FIRST_VALUE):** Вывести длительность самой первой тренировки тренера в каждой строке.

```sql
SELECT 
    trainer_id, 
    name, 
    FIRST_VALUE(duration_min) OVER (PARTITION BY trainer_id ORDER BY training_date) AS first_duration
FROM training;
```

**Что хотим получить 3.5.4 (LAST_VALUE):** Вывести длительность самой последней тренировки тренера в каждой строке (добавили рамку, чтобы функция увидела весь раздел).

```sql
SELECT
    trainer_id,
    name,
    LAST_VALUE(duration_min) OVER (
        PARTITION BY trainer_id 
        ORDER BY training_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_duration
FROM training;
```
