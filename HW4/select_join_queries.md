# HW4 — Запросы SELECT и JOIN

### 1. Абонементы в диапазоне цен (BETWEEN)

**Формулировка:** найти абонементы с ценой от 3000 до 20000 рублей.

```sql
SELECT membership_id, type, price, яstart_date, end_date
FROM membership
WHERE price BETWEEN 3000 AND 20000
ORDER BY price;
```

### 1.2. Клиенты с определёнными id (IN)

**Формулировка:** найти клиентов с id 1, 3 или 5.

```sql
SELECT client_id, first_name, last_name, email FROM client
WHERE client_id IN (1, 3, 5)
ORDER BY client_id;
```
### 1.3. Категория абонемента по цене

**Формулировка:** для каждого абонемента вывести тип, цену и категорию 
(«Дешёвый», «Средний», «Дорогой») в зависимости от цены.

```sql
SELECT 
    membership_id, type, price,
    CASE
        WHEN price < 5000 THEN 'Дешёвый'
        WHEN price BETWEEN 5000 AND 20000 THEN 'Средний'
        ELSE 'Дорогой'
    END AS price_category 
FROM membership ORDER BY price;
```

### 1.4. Статус тренера по стажу

**Формулировка:** для каждого тренера вывести имя, дату найма и стаж-категорию
(«Новичок», «Опытный», «Ветеран»).

```sql
SELECT first_name, last_name, hire_date,
    CASE
        WHEN hire_date > '2023-01-01' THEN 'Новичок'
        WHEN hire_date BETWEEN '2020-01-01' AND '2023-01-01' THEN 'Опытный'
        ELSE 'Ветеран'
    END AS experience_level 
FROM trainer ORDER BY hire_date;
```
## 2. Выборка данных, оператор LIKE

### 2.1. Клиенты с mail.ru

**Формулировка:** найти всех клиентов, чей email заканчивается на `@mail.ru`.

```sql
SELECT client_id, first_name, last_name, email FROM client
WHERE email LIKE '%@mail.ru'
ORDER BY last_name;
```

### 2.2. Тренеры, чья фамилия начинается на «М»

**Формулировка:** найти тренеров с фамилией на букву «М».

```sql
SELECT trainer_id, first_name, last_name, specialization FROM trainer
WHERE last_name LIKE 'М%'
ORDER BY last_name;
```

## 3. DISTINCT

### 3.1. Уникальные типы абонементов

**Формулировка:** вывести все уникальные типы абонементов.

```sql
SELECT DISTINCT type FROM membership ORDER BY type;
```

### 3.2. Уникальные специализации тренеров

**Формулировка:** вывести все уникальные специализации тренеров.

```sql
SELECT DISTINCT specialization FROM trainer
ORDER BY specialization;
```

## 4. JOIN

### 4.1. Клиенты и их платежи

**Формулировка:** вывести ФИО клиента и сумму его платежа.

```sql
SELECT c.first_name,c.last_name, p.payment_date, p.amount, p.method FROM client c
JOIN payment p ON c.client_id = p.client_id
ORDER BY p.payment_date;
```

### 4.2. Посещения с именами клиентов и тренировок

**Формулировка:** вывести имя клиента, название тренировки и дату посещения.

```sql
SELECT 
    c.first_name c.last_name AS client_name, t.name AS training_name, v.visit_date, v.attended
FROM visit v
JOIN client c ON v.client_id = c.client_id
JOIN training t ON v.training_id = t.training_id;
```

## 5. Соединение INNER JOIN

### 5.1. Абонементы с именами клиентов

**Формулировка:** вывести тип абонемента, цену и ФИО клиента.

```sql
SELECT m.membership_id, m.type, m.price, c.first_name, c.last_name
FROM membership m
INNER JOIN client c ON m.client_id = c.client_id
ORDER BY m.membership_id;
```

### 5.2. Тренировки с тренерами

**Формулировка:** вывести название тренировки, дату и имя тренера.

```sql
SELECT t.training_id, t.name AS training_name, t.training_date, tr.first_name
FROM training t
INNER JOIN trainer tr ON t.trainer_id = tr.trainer_id
ORDER BY t.training_date;
```

---

## 6. Внешнее соединение LEFT и RIGHT OUTER JOIN

### 6.1. LEFT OUTER JOIN — все клиенты и их абонементы

**Формулировка:** вывести всех клиентов и их абонементы. Если абонемента нет — NULL.

```sql
SELECT c.client_id, c.first_name, c.last_name, m.type, m.price
FROM client c
LEFT OUTER JOIN membership m ON c.client_id = m.client_id
ORDER BY c.client_id;
```

### 6.2. RIGHT OUTER JOIN — все абонементы и их клиенты

**Формулировка:** вывести все абонементы и клиентов. Если у абонемента нет клиента — NULL.

```sql
SELECT c.first_name, c.last_name, m.membership_id, m.type, m.price
FROM client c
RIGHT OUTER JOIN membership m ON c.client_id = m.client_id
ORDER BY m.membership_id;
```

## 7. Перекрестное соединение CROSS JOIN

### 7.1. Все пары «клиент — тренировка»

**Формулировка:** показать все возможные комбинации клиентов и тренировок.

```sql
SELECT c.first_name, c.last_name, t.name AS training_name, t.training_date
FROM client c
CROSS JOIN training t
ORDER BY c.last_name, t.training_date;
```

### 7.2. Все пары «тренер — тип абонемента»

**Формулировка:** показать все возможные комбинации тренеров и типов абонементов.

```sql
SELECT tr.first_name tr.last_name AS trainer_name, m.type AS membership_type, m.price
FROM trainer tr
CROSS JOIN membership m
ORDER BY tr.last_name, m.type;
```
