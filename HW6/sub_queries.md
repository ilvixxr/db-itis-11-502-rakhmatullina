# HW6 — Подзапросы и выборки

---

### 1.1. SELECT (выборка с подзапросом в SELECT)
**Что хотим получить:** Вывести ID и название тренировки, а также максимальную длительность среди всех тренировок в виде отдельного столбца.

```sql
SELECT 
    training_id, 
    name,
    (SELECT MAX(duration_min) FROM training) AS max_duration_overall
FROM training;
```

### 1.2. SELECT (выборка с подзапросом в SELECT)
**Что хотим получить:** Вывести имя клиента и количество его абонементов (подзапрос в SELECT).

```sql
SELECT 
    first_name, 
    last_name,
    (SELECT COUNT(*) FROM membership m WHERE m.client_id = c.client_id) AS membership_count
FROM client c;
```

---

### 2.1. FROM (выборка из подзапроса)
**Что хотим получить:** Вывести клиентов, чей средний чек за абонемент выше 5000. Используем подзапрос в блоке FROM (создаем временную таблицу).

```sql
SELECT 
    avg_data.client_id, 
    avg_data.avg_price
FROM (
    SELECT client_id, AVG(price) AS avg_price
    FROM membership
    GROUP BY client_id
) AS avg_data
WHERE avg_data.avg_price > 5000;
```

### 2.2. FROM (выборка из подзапроса с JOIN)
**Что хотим получить:** Вывести имена тренеров, у которых есть хотя бы одна тренировка, используя подзапрос в FROM.

```sql
SELECT DISTINCT tr.first_name, tr.last_name
FROM (
    SELECT trainer_id FROM training
) AS t
JOIN trainer tr ON t.trainer_id = tr.trainer_id;
```

---

### 3.1. WHERE (фильтрация с подзапросом)
**Что хотим получить:** Найти клиентов, которые потратили на абонементы больше, чем средняя цена всех абонементов в клубе.

```sql
SELECT first_name, last_name
FROM client
WHERE client_id IN (
    SELECT client_id FROM membership WHERE price > (SELECT AVG(price) FROM membership)
);
```

### 3.2. WHERE (фильтрация по дате)
**Что хотим получить:** Найти тренировки, которые прошли после самой ранней тренировки тренера с ID = 1.

```sql
SELECT name, training_date
FROM training
WHERE training_date > (
    SELECT MIN(training_date) FROM training WHERE trainer_id = 1
);
```

---

### 4.1. HAVING (фильтрация групп с подзапросом)
**Что хотим получить:** Вывести типы абонементов, сумма продаж которых превышает общую среднюю цену одного абонемента.

```sql
SELECT 
    type, 
    SUM(price) AS total_sales
FROM membership
GROUP BY type
HAVING SUM(price) > (
    SELECT AVG(price) FROM membership
);
```

### 4.2. HAVING (фильтрация групп с подзапросом)
**Что хотим получить:** Вывести ID клиентов, у которых больше одного абонемента, и общая сумма их абонементов больше минимальной цены в базе.

```sql
SELECT 
    client_id, 
    COUNT(*) AS memberships_count
FROM membership
GROUP BY client_id
HAVING COUNT(*) > 1 
AND SUM(price) > (
    SELECT MIN(price) FROM membership
);
```

---

### 5.1. ALL (сравнение со всеми)
**Что хотим получить:** Найти абонементы, цена которых больше, чем цена *любого* (то есть самого дорогого) месячного абонемента.

```sql
SELECT membership_id, type, price
FROM membership
WHERE price > ALL (
    SELECT price FROM membership WHERE type = 'Месячный'
);
```

### 5.2. ALL (сравнение со всеми)
**Что хотим получить:** Найти платежи, сумма которых больше или равна сумме *всех* платежей, сделанных через онлайн (то есть самый крупный онлайн-платеж).

```sql
SELECT payment_id, amount, method
FROM payment
WHERE amount >= ALL (
    SELECT amount FROM payment WHERE method = 'online'
);
```

---

### 6.1. IN (проверка на вхождение в список)
**Что хотим получить:** Вывести имена и email клиентов, которые совершали платежи (то есть их ID есть в таблице платежей).

```sql
SELECT first_name, last_name, email
FROM client
WHERE client_id IN (
    SELECT client_id FROM payment
);
```

### 6.2. IN (проверка на вхождение в список)
**Что хотим получить:** Найти все тренировки, которые ведут тренеры со специализацией 'Йога' или 'Бокс'.

```sql
SELECT name, training_date
FROM training
WHERE trainer_id IN (
    SELECT trainer_id FROM trainer WHERE specialization IN ('Йога', 'Бокс')
);
```

---

### 7.1. ANY (сравнение с любым)
**Что хотим получить:** Найти абонементы, цена которых больше, чем цена *хотя бы одного* полугодового абонемента.

```sql
SELECT membership_id, type, price
FROM membership
WHERE price > ANY (
    SELECT price FROM membership WHERE type = 'Полугодовой'
);
```

### 7.2. ANY (сравнение с любым)
**Что хотим получить:** Найти тренировки, которые длятся больше, чем *хотя бы одна* тренировка по 'Кроссфиту'.

```sql
SELECT name, duration_min
FROM training
WHERE duration_min > ANY (
    SELECT duration_min FROM training WHERE name LIKE '%Кроссфит%'
);
```

---

### 8.1. EXISTS (проверка существования)
**Что хотим получить:** Вывести список клиентов, которые ни разу не покупали абонемент.

```sql
SELECT c.first_name, c.last_name
FROM client c
WHERE NOT EXISTS (
    SELECT 1 FROM membership m WHERE m.client_id = c.client_id
);
```

### 8.2. EXISTS (проверка существования)
**Что хотим получить:** Вывести список тренеров, у которых есть тренировки в расписании.

```sql
SELECT tr.first_name, tr.last_name
FROM trainer tr
WHERE EXISTS (
    SELECT 1 FROM training t WHERE t.trainer_id = tr.trainer_id
);
```

---

### 9.1. Сравнение по нескольким столбцам (IN)
**Что хотим получить:** Найти клиентов, которые покупали абонементы с самой дорогой и самой дешевой ценой, используя сравнение по паре.

```sql
SELECT first_name, last_name
FROM client
WHERE client_id IN (
    SELECT client_id 
    FROM membership 
    WHERE (type, price) IN (
        ('Месячный', 3000.00),
        ('Годовой', 25000.00)
    )
);
```

### 9.2. Сравнение по нескольким столбцам (Строковое сравнение)
**Что хотим получить:** Найти клиентов, у которых пара (имя, фамилия) в алфавитном порядке идёт после пары самого первого клиента в базе.

```sql
SELECT first_name, last_name
FROM client
WHERE (first_name, last_name) > (
    SELECT first_name, last_name FROM client ORDER BY client_id ASC LIMIT 1
);
```

---

## 2. Коррелированные подзапросы

### 2.1. Клиенты с наибольшим ID абонемента
**Что хотим получить:** Вывести клиентов, у которых есть абонемент с самым большим ID среди всех абонементов этого конкретного клиента (то есть последний купленный).

```sql
SELECT c.first_name, c.last_name
FROM client c
WHERE c.client_id = (
    SELECT m.client_id 
    FROM membership m 
    WHERE m.client_id = c.client_id 
    ORDER BY m.membership_id DESC 
    LIMIT 1
);
```

### 2.2. Клиенты, покупавшие абонемент дороже своей средней цены
**Что хотим получить:** Для каждого клиента посчитать его траты и вывести тех, кто покупал абонементы дороже своей же средней цены.

```sql
SELECT c.first_name, c.last_name
FROM client c
WHERE EXISTS (
    SELECT 1 FROM membership m
    WHERE m.client_id = c.client_id
    AND m.price > (
        SELECT AVG(price) FROM membership WHERE client_id = c.client_id
    )
);
```

### 2.3. Тренеры, ведущие тренировки в первой половине дня
**Что хотим получить:** Вывести имена тренеров, у которых есть тренировки, начинающиеся до 12:00.

```sql
SELECT tr.first_name, tr.last_name
FROM trainer tr
WHERE EXISTS (
    SELECT 1 FROM training t
    WHERE t.trainer_id = tr.trainer_id
    AND EXTRACT(HOUR FROM t.training_date) < 12
);
```

### 2.4. Клиенты, которые посетили все свои тренировки
**Что хотим получить:** Вывести клиентов, у которых нет ни одной записи на тренировку со статусом attended = false.

```sql
SELECT c.first_name, c.last_name
FROM client c
WHERE NOT EXISTS (
    SELECT 1 FROM visit v
    WHERE v.client_id = c.client_id
    AND v.attended = false
);
```

### 2.5. Тренировки с максимальной загрузкой (аншлаг)
**Что хотим получить:** Вывести тренировки, на которые записалось столько же людей, сколько указано в поле max_participants.

```sql
SELECT t.name, t.training_date
FROM training t
WHERE t.max_participants = (
    SELECT COUNT(*) FROM visit v WHERE v.training_id = t.training_id
);
```