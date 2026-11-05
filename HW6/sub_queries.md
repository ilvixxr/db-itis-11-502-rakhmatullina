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
<img width="430" height="162" alt="image" src="https://github.com/user-attachments/assets/a2dbf2a5-4f2f-447e-9db3-21985f24f726" />

### 1.2. SELECT (выборка с подзапросом в SELECT)
**Что хотим получить:** Вывести имя клиента и количество его абонементов (подзапрос в SELECT).

```sql
SELECT 
    first_name, 
    last_name,
    (SELECT COUNT(*) FROM membership m WHERE m.client_id = c.client_id) AS membership_count
FROM client c;
```
<img width="476" height="166" alt="image" src="https://github.com/user-attachments/assets/7dca1468-7b70-4e7e-952b-fc270e425648" />

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
<img width="288" height="118" alt="image" src="https://github.com/user-attachments/assets/b5f544eb-8e77-456f-a02a-6237beab9380" />

### 2.2. FROM (выборка из подзапроса с JOIN)
**Что хотим получить:** Вывести имена тренеров, у которых есть хотя бы одна тренировка, используя подзапрос в FROM.

```sql
SELECT DISTINCT tr.first_name, tr.last_name
FROM (
    SELECT trainer_id FROM training
) AS t
JOIN trainer tr ON t.trainer_id = tr.trainer_id;
```
<img width="347" height="152" alt="image" src="https://github.com/user-attachments/assets/48c7fd1d-473a-449f-ba90-f4b4ef7c1a9f" />

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
<img width="340" height="123" alt="image" src="https://github.com/user-attachments/assets/bb1f58c6-1e47-4d20-8c96-4bb03c7c764c" />

### 3.2. WHERE (фильтрация по дате)
**Что хотим получить:** Найти тренировки, которые прошли после самой ранней тренировки тренера с ID = 1.

```sql
SELECT name, training_date
FROM training
WHERE training_date > (
    SELECT MIN(training_date) FROM training WHERE trainer_id = 1
);
```
<img width="394" height="148" alt="image" src="https://github.com/user-attachments/assets/3c6145d1-bc50-49ac-9271-666221187b56" />

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
<img width="288" height="128" alt="image" src="https://github.com/user-attachments/assets/224314a7-10af-47d9-907d-76a144f09045" />

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
<img width="273" height="98" alt="image" src="https://github.com/user-attachments/assets/cad14f62-31f1-4c15-8e11-7897a6c7c569" />

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
<img width="421" height="122" alt="image" src="https://github.com/user-attachments/assets/f008e250-1dcc-4795-a1f3-1b79fb5a0e6b" />


### 5.2. ALL (сравнение со всеми)
**Что хотим получить:** Найти платежи, сумма которых больше или равна сумме *всех* платежей, сделанных через онлайн (то есть самый крупный онлайн-платеж).

```sql
SELECT payment_id, amount, method
FROM payment
WHERE amount >= ALL (
    SELECT amount FROM payment WHERE method = 'online'
);
```
<img width="396" height="97" alt="image" src="https://github.com/user-attachments/assets/ed1839c6-6bd2-427b-be03-6a77c4994b4c" />

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
<img width="496" height="165" alt="image" src="https://github.com/user-attachments/assets/35b85fee-8350-4f56-a242-82df76fd243a" />

### 6.2. IN (проверка на вхождение в список)
**Что хотим получить:** Найти все тренировки, которые ведут тренеры со специализацией 'Йога' или 'Бокс'.

```sql
SELECT name, training_date
FROM training
WHERE trainer_id IN (
    SELECT trainer_id FROM trainer WHERE specialization IN ('Йога', 'Бокс')
);
```
<img width="394" height="125" alt="image" src="https://github.com/user-attachments/assets/c4861579-e643-4768-b467-9c504859d45d" />

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
<img width="426" height="73" alt="image" src="https://github.com/user-attachments/assets/51d35dc1-49b5-4648-9e54-28f04dfb60ab" />


### 7.2. ANY (сравнение с любым)
**Что хотим получить:** Найти тренировки, которые длятся больше, чем *хотя бы одна* тренировка по 'Кроссфиту'.

```sql
SELECT name, duration_min
FROM training
WHERE duration_min > ANY (
    SELECT duration_min FROM training WHERE name LIKE '%Кроссфит%'
);
```
<img width="312" height="201" alt="image" src="https://github.com/user-attachments/assets/44bb943e-20b2-4f5c-a5fc-61766dacac30" />

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
<img width="347" height="71" alt="image" src="https://github.com/user-attachments/assets/52e29d8f-f3e1-4af9-938a-0ebd97287d7d" />

### 8.2. EXISTS (проверка существования)
**Что хотим получить:** Вывести список тренеров, у которых есть тренировки в расписании.

```sql
SELECT tr.first_name, tr.last_name
FROM trainer tr
WHERE EXISTS (
    SELECT 1 FROM training t WHERE t.trainer_id = tr.trainer_id
);
```
<img width="344" height="147" alt="image" src="https://github.com/user-attachments/assets/07fa15e0-421c-4543-ab70-368e2d5eb22e" />

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
<img width="350" height="146" alt="image" src="https://github.com/user-attachments/assets/aceb1af7-d326-48b9-9550-fa45977d279f" />


### 9.2. Сравнение по нескольким столбцам (Строковое сравнение)
**Что хотим получить:** Найти клиентов, у которых пара (имя, фамилия) в алфавитном порядке идёт после пары самого первого клиента в базе.

```sql
SELECT first_name, last_name
FROM client
WHERE (first_name, last_name) > (
    SELECT first_name, last_name FROM client ORDER BY client_id ASC LIMIT 1
);
```
<img width="354" height="95" alt="image" src="https://github.com/user-attachments/assets/9510aefb-6f81-4988-bb4c-5d26f0be95b2" />

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
<img width="349" height="172" alt="image" src="https://github.com/user-attachments/assets/146a9529-cbac-4535-84fb-6b467f637131" />


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
<img width="355" height="96" alt="image" src="https://github.com/user-attachments/assets/ffb62280-2ab3-4e1f-8bb3-53bf617cae8c" />


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
<img width="346" height="99" alt="image" src="https://github.com/user-attachments/assets/f65d5f71-1ab0-4abd-81c7-ce605c39c379" />


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
<img width="352" height="173" alt="image" src="https://github.com/user-attachments/assets/5a0d3615-32b5-4f71-8429-91164bdae6ab" />


### 2.5. Тренировки с максимальной загрузкой (аншлаг)
**Что хотим получить:** Вывести тренировки, на которые записалось столько же людей, сколько указано в поле max_participants.

```sql
SELECT t.name, t.training_date
FROM training t
WHERE t.max_participants = (
    SELECT COUNT(*) FROM visit v WHERE v.training_id = t.training_id
);
```
<img width="396" height="70" alt="image" src="https://github.com/user-attachments/assets/b7460781-c061-4641-a3af-858d247fe53d" />
