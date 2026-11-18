# HW7 — Транзакции и уровни изоляции

## 1. Базовые операции с транзакциями

### Сценарий 1.1. Успешная транзакция: Клиент + Абонемент
**Задача:** Добавить нового клиента и сразу же оформить ему абонемент. Если одна операция упадёт, вторая не должна выполниться.

```sql
BEGIN;

INSERT INTO client (first_name, last_name, phone, email) 
VALUES ('Иван', 'Транзакционный', '+7-999-111-11-11', 'trans1@mail.ru');

INSERT INTO membership (client_id, type, start_date, end_date, price) 
VALUES (
    (SELECT MAX(client_id) FROM client), 
    'Месячный', '2024-05-01', '2024-06-01', 3000.00
);

COMMIT;
```
*Вывод:* Обе операции выполнились успешно и зафиксировались (COMMIT). В базе появился новый клиент и его абонемент.

### Сценарий 1.2. Успешная транзакция: Платеж + Скидка
**Задача:** Зафиксировать оплату абонемента и обновить статус/скидку клиента.

**Запрос:**
```sql
BEGIN;

INSERT INTO payment (membership_id, client_id, payment_date, amount, method) 
VALUES (1, 1, CURRENT_DATE, 3000.00, 'card');

UPDATE membership SET discount = 5 WHERE membership_id = 1;

COMMIT;
```
*Вывод:* Транзакция зафиксирована. Платеж добавлен, скидка обновлена.

---

### Сценарий 2.1. Откат транзакции (ROLLBACK): Отмена клиента
**Задача:** Начать добавлять клиента, но передумать и отменить действие.

**Запрос:**
```sql
BEGIN;

INSERT INTO client (first_name, last_name, phone) 
VALUES ('Петр', 'Отмененный', '+7-999-222-22-22');

ROLLBACK;
```

**Проверка:**
```sql
SELECT * FROM client WHERE last_name = 'Отмененный';
```
*Вывод:* Команда `ROLLBACK` отменила вставку. Записи в таблице нет.

---

### Сценарий 2.2. Откат транзакции (ROLLBACK): Отмена платежа
**Задача:** Случайно внесли неверную сумму платежа и откатили транзакцию.

**Запрос:**
```sql
BEGIN;

UPDATE payment SET amount = 99999.00 WHERE payment_id = 1;

ROLLBACK;
```

**Проверка:**
```sql
SELECT payment_id, amount FROM payment WHERE payment_id = 1;
```
*Вывод:* Изменения суммы отменены, вернулось исходное значение.

---

### Сценарий 3.1. Ошибка в транзакции: Деление на ноль
**Задача:** Начать транзакцию, сделать полезное действие, а затем вызвать ошибку.

**Запрос:**
```sql
BEGIN;

INSERT INTO client (first_name, last_name, phone) 
VALUES ('Сергей', 'Ошибочный', '+7-999-333-33-33');

SELECT 1 / 0;

COMMIT;
```

*Вывод:* Возникла ошибка `division by zero`. PostgreSQL автоматически прервал транзакцию, вставка клиента не сохранилась.

---

### Сценарий 3.2. Ошибка в транзакции: Нарушение внешнего ключа (Foreign Key)
**Задача:** Попытаться добавить абонемент для клиента, которого не существует.

**Запрос:**
```sql
BEGIN;

INSERT INTO membership (client_id, type, start_date, end_date, price) 
VALUES (9999, 'Годовой', '2024-05-01', '2025-05-01', 25000.00);

COMMIT;
```

**Проверка:**
```sql
SELECT * FROM membership WHERE client_id = 9999;
```
*Вывод:* Ошибка `violates foreign key constraint`. Транзакция прервана, «битая» запись не добавлена.

---

## 2. Уровни изоляции

### 2.1. READ UNCOMMITTED (Попытка грязного чтения)
**Цель:** Проверить, можно ли увидеть незакоммиченные данные.

**Т1:** 
```sql
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
UPDATE membership SET price = 9999.00 WHERE membership_id = 1;
```
**Т2:** 
```sql
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SELECT price FROM membership WHERE membership_id = 1;
```
*Вывод:* В PostgreSQL уровень изоляции READ UNCOMMITTED фактически работает как READ COMMITTED. Это означает, что СУБД на уровне архитектуры запрещает «грязное чтение». Транзакция Т2 не увидела измененную цену (9999.00), потому что Т1 не выполнила COMMIT. База данных защищает пользователей от чтения незафиксированных данных.

### 2.2. READ COMMITTED (Грязное чтение)
**Цель:** Убедиться, что после COMMIT данные сразу видны всем.

**Т1:**
```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE membership SET price = 8888.00 WHERE membership_id = 1;
COMMIT; -- Фиксируем
```
**Т2:**
```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT price FROM membership WHERE membership_id = 1; -- Увидит 8888
COMMIT;
```
*Вывод:* Вывод: На уровне READ COMMITTED транзакция Т2 видит только те изменения, которые были успешно зафиксированы (COMMIT) в Т1. Как только Т1 завершила транзакцию, новые данные (цена 8888.00) сразу стали доступны для чтения в Т2.

---

### 2.3. READ COMMITTED: Неповторяющееся чтение
**Цель:** Показать, что один и тот же SELECT в транзакции может дать разные результаты.

**Т1:**
```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT price FROM membership WHERE membership_id = 1; -- (1-е чтение)
```
**Т2:**
```sql
BEGIN;
UPDATE membership SET price = 7777.00 WHERE membership_id = 1;
COMMIT;
```
**Т1:**
```sql
SELECT price FROM membership WHERE membership_id = 1; -- (2-е чтение, увидит 7777)
COMMIT;
```
*Вывод:* Уровень READ COMMITTED допускает аномалию «неповторяющееся чтение». В рамках одной и той же транзакции Т1 мы выполнили два одинаковых SELECT. Первый показал исходную цену, а второй — новую цену (7777.00), так как между запросами транзакция Т2 успела изменить данные и сделать COMMIT.

---

### 2.4. REPEATABLE READ: Изоляция от изменений
**Цель:** Доказать, что Т1 не видит изменений Т2.

**Т1:**
```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT price FROM membership WHERE membership_id = 1; -- (1-е чтение)
```
**Т2:**
```sql
BEGIN;
UPDATE membership SET price = 6666.00 WHERE membership_id = 1;
COMMIT;
```
**Т1:**
```sql
SELECT price FROM membership WHERE membership_id = 1; -- (2-е чтение, цена останется прежней!)
COMMIT;
```
*Вывод:* Уровень REPEATABLE READ защищает от неповторяющегося чтения. В рамках транзакции Т1 мы дважды выполнили SELECT. Оба раза база вернула одинаковое исходное значение цены, несмотря на то, что Т2 успела обновить строку и сделать COMMIT. Т1 видит «снимок» базы данных на момент своего старта.

---

### 2.5. REPEATABLE READ: Фантомное чтение
**Цель:** Проверить, появляются ли новые строки (фантомы) при повторном SELECT.

**Т1:**
```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM membership WHERE client_id = 1; -- Допустим, было 2
```
**Т2:**
```sql
BEGIN;
INSERT INTO membership (client_id, type, start_date, end_date, price) 
VALUES (1, 'Разовый', '2024-06-01', '2024-06-02', 500.00);
COMMIT;
```
**Т1:**
```sql
SELECT COUNT(*) FROM membership WHERE client_id = 1; -- Все равно покажет 2 (фантом не пришел)
COMMIT;
```
*Вывод:* Уровень REPEATABLE READ полностью защищает от фантомного чтения. Транзакция Т2 добавила новую запись (INSERT) в таблицу и зафиксировала изменения. Однако при повторном выполнении SELECT COUNT(*) транзакция Т1 увидела то же самое количество строк, что и в первый раз. Новые «фантомные» строки для Т1 невидимы.

---

### 2.6. SERIALIZABLE: Конфликт при вставке
**Цель:** Смоделировать ошибку сериализации при одновременной вставке.

**Т1:**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM membership WHERE type = 'Безлимит';
```
**Т2:**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM membership WHERE type = 'Безлимит';
```
**Т1:**
```sql
INSERT INTO membership (client_id, type, start_date, end_date, price) 
VALUES (2, 'Безлимит', '2024-06-01', '2024-07-01', 10000.00);
COMMIT;
```
**Т2:**
```sql
INSERT INTO membership (client_id, type, start_date, end_date, price) 
VALUES (3, 'Безлимит', '2024-06-01', '2024-07-01', 10000.00);
COMMIT; -- Здесь выпадет ошибка could not serialize access
```
*Вывод:* На уровне SERIALIZABLE СУБД отслеживает не только обновление одних и тех же строк, но и логические зависимости чтения. Если Т2 вставляет данные на основе SELECT, который стал неактуален из-за действий Т1, возникает ошибка could not serialize access due to read/write dependencies. Это заставляет приложение повторить всю транзакцию целиком, гарантируя целостность данных.

### 2.7. SERIALIZABLE: Конфликт при обновлении
**Цель:** Показать, что параллельное обновление на уровне SERIALIZABLE приведет к откату одной из транзакций.

**Т1:**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
UPDATE membership SET price = 5000 WHERE membership_id = 2;
```
**Т2:**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
UPDATE membership SET price = 6000 WHERE membership_id = 2;
-- Пытается обновить ту же строку, будет ждать Т1
```
**Т1:**
```sql
COMMIT;
```
**Т2:**
```sql
Ошибка сериализации
```
*Вывод:* При параллельном выполнении двух транзакций, пытающихся изменить одну и ту же строку, СУБД блокирует вторую транзакцию. После фиксации первой транзакции (COMMIT), вторая получает ошибку could not serialize access due to concurrent update, так как данные, на которые она опиралась, были изменены. Транзакция переходит в состояние aborted, поэтому для успешного завершения необходимо выполнить ROLLBACK и повторить транзакцию заново.

---

## 3. SAVEPOINT (Точки сохранения)

### Сценарий 3.1. Один SAVEPOINT
**Задача:** Сделать несколько изменений, сохранить точку и откатиться к ней.

**Запрос:**
```sql
BEGIN;
UPDATE client SET phone = '+7-111-111-11-11' WHERE client_id = 1;
SAVEPOINT my_sp;
UPDATE client SET phone = '+7-222-222-22-22' WHERE client_id = 2;
ROLLBACK TO my_sp; -- Откат только второго изменения
COMMIT;
```
**Проверка:**
```sql
SELECT client_id, phone FROM client WHERE client_id IN (1, 2);
```
*Вывод:* Изменения до `SAVEPOINT` сохранились (телефон клиента 1), а после — откатились (телефон клиента 2 остался старым).

---

### Сценарий 3.2. Два SAVEPOINT
**Задача:** Создать две точки и вернуться к первой.

**Запрос:**
```sql
BEGIN;
UPDATE membership SET price = 4000.00 WHERE membership_id = 1;
SAVEPOINT sp1;
UPDATE membership SET price = 5000.00 WHERE membership_id = 2;
SAVEPOINT sp2;
UPDATE membership SET price = 6000.00 WHERE membership_id = 3;
ROLLBACK TO sp1; -- Откатываем всё после первой точки
COMMIT;
```
**Проверка:**
```sql
SELECT membership_id, price FROM membership WHERE membership_id IN (1, 2, 3);
```
*Вывод:* Цена 1-го абонемента изменилась. Цены 2-го и 3-го остались прежними, так как откат к `sp1` отменил вторую точку и все изменения после неё.

---

## 4. Общий вывод по работе
В ходе работы я научилась управлять транзакциями. 
Транзакции (`BEGIN`/`COMMIT`) позволяют объединять операции. Ошибки вызывают автоматический откат. 
Уровни изоляции (`READ COMMITTED`, `REPEATABLE READ`, `SERIALIZABLE`) защищают от аномалий (грязное чтение, неповторяющееся чтение, фантомы). Чем выше уровень, тем строже изоляция, но тем больше вероятность конфликтов.
`SAVEPOINT` позволяет делать частичный откат внутри транзакции.
