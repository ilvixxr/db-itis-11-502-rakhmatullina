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
<img width="606" height="66" alt="" src="https://github.com/user-attachments/assets/a22d78bd-3da2-4925-ae91-249011378f70" />


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
<img width="768" height="93" alt="" src="https://github.com/user-attachments/assets/621c1613-bf30-4e8c-b34a-3186cba4d0fc" />

## 2. STRING_AGG()

### 2.1. Список всех клиентов одной строкой

**Формулировка:** вывести всех клиентов в одну строку через запятую.

```sql
SELECT 
    STRING_AGG(first_name || ' ' || last_name, ', ' ORDER BY last_name) AS all_clients
FROM client;
```
<img width="548" height="70" alt="" src="https://github.com/user-attachments/assets/aef166e2-f5ab-47ba-8cb0-9cf44c9f5a1e" />

### 2.2. Уникальные специализации тренеров

**Формулировка:** вывести все уникальные специализации тренеров в одну строку.

```sql
SELECT 
    STRING_AGG(DISTINCT specialization, ', ' ORDER BY specialization) AS all_specializations
FROM trainer;
```
<img width="344" height="67" alt="" src="https://github.com/user-attachments/assets/6c373528-92fc-4502-a7bc-497d569bc966" />


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
<img width="420" height="119" alt="" src="https://github.com/user-attachments/assets/495e532d-a3a0-416b-8d4d-29ed3e18d846" />


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
<img width="567" height="100" alt="" src="https://github.com/user-attachments/assets/9c7e79f8-35f1-4df2-8cd0-9d5a2ca41d4b" />


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
<img width="423" height="124" alt="" src="https://github.com/user-attachments/assets/fed733be-bd62-4cbe-8c3e-e958d14a1723" />


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
<img width="570" height="95" alt="" src="https://github.com/user-attachments/assets/e4661582-383e-4416-bc11-db8d47f3cf90" />


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
<img width="376" height="222" alt="" src="https://github.com/user-attachments/assets/b14646f2-3c57-4cd3-a41d-2f207bd4fd14" />


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
<img width="307" height="191" alt="" src="https://github.com/user-attachments/assets/1249840b-98cd-40b6-a7c9-c314a1404c65" />

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
<img width="391" height="121" alt="" src="https://github.com/user-attachments/assets/c3a46952-34b0-4807-b0d7-97b37baa4e55" />

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
<img width="351" height="175" alt="" src="https://github.com/user-attachments/assets/ca219985-6ac4-4413-b3cd-db4d73d709e7" />

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
<img width="372" height="374" alt="" src="https://github.com/user-attachments/assets/6dfc1ac9-2bac-4142-9d5f-78eb8726ca67" />

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
<img width="332" height="341" alt="" src="https://github.com/user-attachments/assets/1aaa20c7-20da-459a-a984-475af31d5d94" />

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
<img width="413" height="94" alt="" src="https://github.com/user-attachments/assets/8f1f4906-2ab4-40b0-83ea-797f6a243d9f" />

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
