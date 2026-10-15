# HW5 — Агрегатные функции и группировка

## 1. Агрегатные функции: COUNT(), SUM(), AVG(), MIN(), MAX()

### 1.1. Общая статистика по абонементам

**Формулировка:** вывести количество абонементов, общую сумму, среднюю, минимальную и максимальную цену.

```sql
SELECT 
    COUNT(*) AS total_memberships,
    SUM(price) AS total_revenue,
    AVG(price) AS avg_price,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM membership;
```

### 1.2. Агрегаты с группировкой по способу оплаты

**Формулировка:** для каждого способа оплаты вывести количество, сумму, среднее, минимум и максимум платежа.

```sql
SELECT 
    method,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM payment
GROUP BY method
ORDER BY total_amount DESC;
```

## 2. STRING_AGG()

### 2.1. Список всех клиентов одной строкой

**Формулировка:** вывести всех клиентов в одну строку через запятую.

```sql
SELECT 
    STRING_AGG(first_name || ' ' || last_name, ', ' ORDER BY last_name) AS all_clients
FROM client;
```

### 2.2. Уникальные специализации тренеров

**Формулировка:** вывести все уникальные специализации тренеров в одну строку.

```sql
SELECT 
    STRING_AGG(DISTINCT specialization, ', ' ORDER BY specialization) AS all_specializations
FROM trainer;
```

## 3. GROUP BY

### 3.1. Количество абонементов по типам

**Формулировка:** для каждого типа абонемента посчитать количество и сумму.

```sql
SELECT 
    type,
    COUNT(*) AS count_memberships,
    SUM(price) AS total_price
FROM membership
GROUP BY type
ORDER BY count_memberships DESC;
```

### 3.2. Платежи по способам оплаты

**Формулировка:** для каждого способа оплаты посчитать количество, сумму и среднее.

```sql
SELECT 
    method,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount
FROM payment
GROUP BY method
ORDER BY total_amount DESC;
```

## 4. HAVING

### 4.1. Типы абонементов с суммой больше 10000

**Формулировка:** типы абонементов, сумма продаж которых больше 10000.

```sql
SELECT 
    type,
    COUNT(*) AS count_memberships,
    SUM(price) AS total_price
FROM membership
GROUP BY type
HAVING SUM(price) > 10000
ORDER BY total_price DESC;
```

### 4.2. Клиенты с 2 и более абонементами

**Формулировка:** клиенты, у которых 2 и более абонементов.

```sql
SELECT 
    c.client_id,
    c.first_name,
    c.last_name,
    COUNT(m.membership_id) AS membership_count
FROM client c
JOIN membership m ON c.client_id = m.client_id
GROUP BY c.client_id, c.first_name, c.last_name
HAVING COUNT(m.membership_id) >= 2
ORDER BY membership_count DESC;
```

## 5. GROUPING SETS

### 5.1. Платежи по способу оплаты и по клиенту отдельно

**Формулировка:** посчитать сумму платежей отдельно по способу оплаты и отдельно по клиентам.

```sql
SELECT 
    method,
    client_id,
    SUM(amount) AS total_amount
FROM payment
GROUP BY GROUPING SETS ((method), (client_id))
ORDER BY method NULLS LAST, client_id NULLS LAST;
```

### 5.2. Посещения по тренировке и по статусу отдельно

**Формулировка:** посчитать посещения отдельно по тренировкам и отдельно по статусу attended.

```sql
SELECT 
    training_id,
    attended,
    COUNT(*) AS visit_count
FROM visit
GROUP BY GROUPING SETS ((training_id), (attended))
ORDER BY training_id NULLS LAST, attended NULLS LAST;
```

## 6. ROLLUP

### 6.1. Платежи по способам оплаты с общим итогом

**Формулировка:** сумма платежей по способам оплаты с общим итогом.

```sql
SELECT 
    COALESCE(method, 'ИТОГО') AS method,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_amount
FROM payment
GROUP BY ROLLUP(method)
ORDER BY method NULLS LAST;
```

### 6.2. Платежи по способам и годам с промежуточными итогами

**Формулировка:** сумма платежей по способам оплаты и годам с промежуточными итогами по способу и общим итогом.

```sql
SELECT 
    COALESCE(method, 'ИТОГО') AS method,
    COALESCE(EXTRACT(YEAR FROM payment_date)::text, 'ВСЕ ГОДЫ') AS year,
    SUM(amount) AS total_amount
FROM payment
GROUP BY ROLLUP(method, EXTRACT(YEAR FROM payment_date))
ORDER BY method NULLS LAST, year NULLS LAST;
```

## 7. CUBE

### 7.1. Платежи: способ × клиент

**Формулировка:** сумма платежей по всем комбинациям способа оплаты и клиента.

```sql
SELECT 
    COALESCE(method, 'ВСЕ СПОСОБЫ') AS method,
    COALESCE(client_id::text, 'ВСЕ КЛИЕНТЫ') AS client_id,
    SUM(amount) AS total_amount
FROM payment
GROUP BY CUBE(method, client_id)
ORDER BY method NULLS LAST, client_id NULLS LAST;
```

### 7.2. Посещения: тренировка × статус

**Формулировка:** посещения по всем комбинациям тренировки и статуса attended.

```sql
SELECT 
    COALESCE(training_id::text, 'ВСЕ ТРЕНИРОВКИ') AS training_id,
    COALESCE(attended::text, 'ВСЕ') AS attended,
    COUNT(*) AS visit_count
FROM visit
GROUP BY CUBE(training_id, attended)
ORDER BY training_id NULLS LAST, attended NULLS LAST;
```

## 8. Полный порядок: SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY

### 8.1. Платежи по способам оплаты за 2024 год

**Формулировка:** для каждого способа оплаты посчитать количество и сумму платежей за 2024 год, оставить способы с суммой больше 5000, отсортировать по сумме.

```sql
SELECT 
    method,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_amount
FROM payment
WHERE payment_date >= '2024-01-01'
GROUP BY method
HAVING SUM(amount) > 5000
ORDER BY total_amount DESC;
```

### 8.2. Посещения по тренировкам

**Формулировка:** для каждой тренировки посчитать количество посещений, оставить тренировки с 1 и более посещениями, отсортировать по количеству и названию.

```sql
SELECT
    t.name AS training_name,
    COUNT(*) AS visit_count
FROM visit v
         JOIN training t ON v.training_id = t.training_id
WHERE v.visit_date >= '2024-04-01'
GROUP BY t.training_id, t.name
HAVING COUNT(*) >= 1
ORDER BY visit_count DESC, training_name;
```