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
<img width="343" height="197" alt="Снимок экрана — 2026-11-12 в 12 56 36" src="https://github.com/user-attachments/assets/ea371815-5c16-48da-80b7-eb06f4acc686" />

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
<img width="451" height="146" alt="Снимок экрана — 2026-11-12 в 12 57 07" src="https://github.com/user-attachments/assets/55ac024a-1226-4d23-a038-0b19393ec0cf" />

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
<img width="346" height="172" alt="Снимок экрана — 2026-11-12 в 12 57 42" src="https://github.com/user-attachments/assets/0d588384-0487-4e81-9fb5-6e56dcf80665" />


## 2. UNION, INTERSECT, EXCEPT — по 1 запросу

### 2.1. UNION (Объединение)
**Что хотим получить:** Получить единый список имен и фамилий клиентов и тренеров.

```sql
SELECT first_name, last_name, 'Клиент' AS role FROM client
UNION
SELECT first_name, last_name, 'Тренер' AS role FROM trainer;
```
<img width="402" height="296" alt="Снимок экрана — 2026-11-12 в 12 58 02" src="https://github.com/user-attachments/assets/2050168a-bf0a-4591-a6ff-437d979c288a" />

### 2.2. INTERSECT (Пересечение)
**Что хотим получить:** Найти клиентов и тренеров с одинаковыми именами.

```sql
SELECT first_name, last_name FROM client
INTERSECT
SELECT first_name, last_name FROM trainer;
```
<img width="446" height="71" alt="Снимок экрана — 2026-11-12 в 12 59 01" src="https://github.com/user-attachments/assets/6106652f-036a-4dd4-8c59-e7004c284d48" />

### 2.3. EXCEPT (Разность)
**Что хотим получить:** Найти клиентов, которые ни разу не совершали платежей.

```sql
SELECT client_id, first_name, last_name FROM client
EXCEPT
SELECT c.client_id, c.first_name, c.last_name 
FROM client c
JOIN payment p ON c.client_id = p.client_id;
```
<img width="520" height="98" alt="Снимок экрана — 2026-11-12 в 12 59 19" src="https://github.com/user-attachments/assets/2ad5a7a5-f96e-4405-8107-6afaa1eba1a1" />


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
<img width="525" height="295" alt="Снимок экрана — 2026-11-12 в 12 59 43" src="https://github.com/user-attachments/assets/f754b137-0a50-4866-a264-b72a3d2d36f9" />

**Что хотим получить 3.1.2:** Показать максимальную длительность тренировки для каждого тренера.

```sql
SELECT 
    trainer_id, 
    name, 
    duration_min,
    MAX(duration_min) OVER (PARTITION BY trainer_id) AS max_duration
FROM training;
```
<img width="490" height="295" alt="Снимок экрана — 2026-11-12 в 13 00 15" src="https://github.com/user-attachments/assets/cd047e6e-fa81-455a-9087-b5970706d82c" />


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
<img width="514" height="294" alt="Снимок экрана — 2026-11-12 в 13 00 34" src="https://github.com/user-attachments/assets/6f3ec2ab-cbb3-4d31-ab5a-4ac9d1854baf" />

**Что хотим получить 3.2.2:** Накопительная сумма платежей каждого клиента (по дате).

```sql
SELECT 
    client_id, 
    payment_date, 
    amount,
    SUM(amount) OVER (PARTITION BY client_id ORDER BY payment_date) AS cumulative_paid
FROM payment;
```
<img width="457" height="223" alt="Снимок экрана — 2026-11-12 в 13 00 53" src="https://github.com/user-attachments/assets/bd3a8c30-1cb0-4504-b5f5-3423a787da7b" />

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
<img width="498" height="221" alt="Снимок экрана — 2026-11-12 в 13 01 12" src="https://github.com/user-attachments/assets/4bf5fcc8-d662-4394-843e-72baf6edc715" />

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
<img width="429" height="221" alt="Снимок экрана — 2026-11-12 в 13 01 44" src="https://github.com/user-attachments/assets/b107f9a0-4197-48ed-9140-8c891d737b32" />

### 3.4. Ранжирующие функции (ROW_NUMBER, RANK, DENSE_RANK, NTILE)
**Что хотим получить 3.4.1 (ROW_NUMBER):** Дать уникальный номер каждой тренировке внутри одного тренера.

```sql
SELECT 
    trainer_id, 
    name,
    ROW_NUMBER() OVER (PARTITION BY trainer_id ORDER BY training_date) AS row_num
FROM training;
```
<img width="367" height="298" alt="Снимок экрана — 2026-11-12 в 13 02 05" src="https://github.com/user-attachments/assets/0d0c3090-9d23-47c3-b135-9895cbeadc0b" />

**Что хотим получить 3.4.2 (RANK):** Ранжировать тренировки по длительности (при равенстве пропускает номер).

```sql
SELECT 
    trainer_id, 
    name,
    duration_min,
    RANK() OVER (PARTITION BY trainer_id ORDER BY duration_min DESC) AS rank_num
FROM training;
```
<img width="470" height="296" alt="Снимок экрана — 2026-11-12 в 13 02 22" src="https://github.com/user-attachments/assets/1c2675c1-9b5c-420f-9399-73c9f69b0ec8" />

**Что хотим получить 3.4.3 (DENSE_RANK):** То же самое, но без пропуска номеров.

```sql
SELECT 
    trainer_id, 
    name,
    duration_min,
    DENSE_RANK() OVER (PARTITION BY trainer_id ORDER BY duration_min DESC) AS dense_rank_num
FROM training;
```
<img width="505" height="296" alt="Снимок экрана — 2026-11-12 в 13 02 44" src="https://github.com/user-attachments/assets/59b10050-cfd9-4fc4-8906-6076037da006" />

**Что хотим получить 3.4.4 (NTILE):** Разбить все тренировки на 2 группы по длительности (1 - самые долгие, 2 - остальные).

```sql
SELECT 
    name,
    duration_min,
    NTILE(2) OVER (ORDER BY duration_min DESC) AS group_num
FROM training;
```
<img width="395" height="293" alt="Снимок экрана — 2026-11-12 в 13 15 40" src="https://github.com/user-attachments/assets/8153d8cb-aa22-4dca-baf5-273fc3f0049e" />

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
<img width="489" height="302" alt="Снимок экрана — 2026-11-12 в 13 03 36" src="https://github.com/user-attachments/assets/07a9039f-9b9a-418e-8ccb-0effc3493aab" />

**Что хотим получить 3.5.2 (LEAD):** Показать длительность следующей тренировки этого же тренера.

```sql
SELECT 
    trainer_id, 
    name, 
    duration_min,
    LEAD(duration_min) OVER (PARTITION BY trainer_id ORDER BY training_date) AS next_duration
FROM training;
```
<img width="486" height="301" alt="Снимок экрана — 2026-11-12 в 13 03 57" src="https://github.com/user-attachments/assets/e1c37d0f-f51b-47a2-b9d7-f0422ee1e313" />

**Что хотим получить 3.5.3 (FIRST_VALUE):** Вывести длительность самой первой тренировки тренера в каждой строке.

```sql
SELECT 
    trainer_id, 
    name, 
    FIRST_VALUE(duration_min) OVER (PARTITION BY trainer_id ORDER BY training_date) AS first_duration
FROM training;
```
<img width="399" height="298" alt="Снимок экрана — 2026-11-12 в 13 04 12" src="https://github.com/user-attachments/assets/d41c8d87-9757-45b1-bac8-19cbcd42acd0" />

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
<img width="394" height="301" alt="Снимок экрана — 2026-11-12 в 13 04 33" src="https://github.com/user-attachments/assets/589464a2-1b8e-4fc1-8f4f-328815ebccc8" />
