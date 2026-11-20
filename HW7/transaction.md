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
<img width="1447" height="1080" alt="Снимок экрана — 2026-11-17 в 13 01 35" src="https://github.com/user-attachments/assets/d104c7db-4740-4de0-90da-ac2995df1a04" />

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
<img width="1447" height="1080" alt="Снимок экрана — 2026-11-17 в 13 04 16" src="https://github.com/user-attachments/assets/f97fa1fc-1520-41e7-be95-7e348a6f9c9c" />

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
<img width="1447" height="1080" alt="Снимок экрана — 2026-11-17 в 13 05 01" src="https://github.com/user-attachments/assets/4b61ccef-b042-4090-861c-28eb0aad9946" />

**Проверка:**
```sql
SELECT * FROM client WHERE last_name = 'Отмененный';
```
<img width="1447" height="1080" alt="Снимок экрана — 2026-11-17 в 13 05 48" src="https://github.com/user-attachments/assets/834401fd-1199-4e0e-9c41-c66ab36af2e7" />

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
<img width="1447" height="1080" alt="Снимок экрана — 2026-11-17 в 13 06 04" src="https://github.com/user-attachments/assets/c6041033-84eb-4bcf-97b0-4c0d8167e168" />

**Проверка:**
```sql
SELECT payment_id, amount FROM payment WHERE payment_id = 1;
```
<img width="1447" height="1080" alt="Снимок экрана — 2026-11-17 в 13 06 16" src="https://github.com/user-attachments/assets/a3ca24ec-2f1e-42fe-9716-05c7e7f6b341" />

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
<img width="1447" height="1080" alt="Снимок экрана — 2026-11-17 в 13 06 30" src="https://github.com/user-attachments/assets/aa62bb44-6d55-48b8-85e6-5827a1552f94" />

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
<img width="1447" height="1080" alt="Снимок экрана — 2026-11-17 в 13 07 08" src="https://github.com/user-attachments/assets/c38f04c5-7950-44c1-9217-86598beb1488" />

**Проверка:**
```sql
SELECT * FROM membership WHERE client_id = 9999;
```
<img width="778" height="521" alt="Снимок экрана — 2026-11-18 в 10 44 56" src="https://github.com/user-attachments/assets/2f95614b-9dfc-4890-825e-1b19e9dbee4f" />

*Вывод:* Ошибка `violates foreign key constraint`. Транзакция прервана, «битая» запись не добавлена.

---

## 2. Уровни изоляции

### 2.1. READ UNCOMMITTED (Попытка грязного чтения)
**Цель:** Проверить, можно ли увидеть незакоммиченные данные.

**Т1:** 
```sql
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
UPDATE membership SET price = 9999.00 WHERE membership_id = 9;
```
<img width="720" height="544" alt="Снимок экрана — 2026-11-17 в 13 17 06" src="https://github.com/user-attachments/assets/17633af4-84d9-4ab6-8ed8-2abff7a4c3c6" />

**Т2:** 
```sql
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SELECT price FROM membership WHERE membership_id = 9;
```
<img width="519" height="585" alt="Снимок экрана — 2026-11-17 в 13 17 27" src="https://github.com/user-attachments/assets/b8a16df2-a9c2-4074-8954-0940208a1180" />

*Вывод:* В PostgreSQL уровень изоляции READ UNCOMMITTED фактически работает как READ COMMITTED. Это означает, что СУБД на уровне архитектуры запрещает «грязное чтение». Транзакция Т2 не увидела измененную цену (9999.00), потому что Т1 не выполнила COMMIT. База данных защищает пользователей от чтения незафиксированных данных.

### 2.2. READ COMMITTED (Грязное чтение)
**Цель:** Убедиться, что после COMMIT данные сразу видны всем.

**Т1:**
```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE membership SET price = 8888.00 WHERE membership_id = 1;
COMMIT;
```
<img width="804" height="494" alt="Снимок экрана — 2026-11-18 в 12 24 03" src="https://github.com/user-attachments/assets/fdb4f6cb-a0a4-4eb6-8d6b-fd9c95102dec" />

**Т2:**
```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT price FROM membership WHERE membership_id = 1;
```
<img width="736" height="637" alt="Снимок экрана — 2026-11-18 в 12 24 15" src="https://github.com/user-attachments/assets/03b792c8-105c-4679-bc77-907a686d1b29" />

*Вывод:* Вывод: На уровне READ COMMITTED транзакция Т2 видит только те изменения, которые были успешно зафиксированы (COMMIT) в Т1. Как только Т1 завершила транзакцию, новые данные (цена 8888.00) сразу стали доступны для чтения в Т2.

---

### 2.3. READ COMMITTED: Неповторяющееся чтение
**Цель:** Показать, что один и тот же SELECT в транзакции может дать разные результаты.

**Т1:**
```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT price FROM membership WHERE membership_id = 1;
```
<img width="743" height="613" alt="Снимок экрана — 2026-11-18 в 12 26 29" src="https://github.com/user-attachments/assets/1a673c96-7a77-4f07-8c8e-ab70a67f151a" />

**Т2:**
```sql
BEGIN;
UPDATE membership SET price = 7777.00 WHERE membership_id = 1;
COMMIT;
```
<img width="601" height="491" alt="Снимок экрана — 2026-11-18 в 12 26 51" src="https://github.com/user-attachments/assets/56488e89-57ec-4c75-9c3f-c115a5b51a64" />

**Т1:**
```sql
SELECT price FROM membership WHERE membership_id = 1;
```
<img width="794" height="665" alt="Снимок экрана — 2026-11-18 в 12 27 01" src="https://github.com/user-attachments/assets/82172e1f-746d-4577-a3a0-00e26488981b" />

*Вывод:* Уровень READ COMMITTED допускает аномалию «неповторяющееся чтение». В рамках одной и той же транзакции Т1 мы выполнили два одинаковых SELECT. Первый показал исходную цену, а второй — новую цену (7777.00), так как между запросами транзакция Т2 успела изменить данные и сделать COMMIT.

---

### 2.4. REPEATABLE READ: Изоляция от изменений
**Цель:** Доказать, что Т1 не видит изменений Т2.

**Т1:**
```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT price FROM membership WHERE membership_id = 1;
```
<img width="688" height="543" alt="Снимок экрана — 2026-11-18 в 12 36 20" src="https://github.com/user-attachments/assets/7de8156b-c15e-4b0c-97ea-67ba4320f052" />

**Т2:**
```sql
BEGIN;
UPDATE membership SET price = 6666.00 WHERE membership_id = 1;
COMMIT;
```
<img width="599" height="467" alt="Снимок экрана — 2026-11-18 в 12 37 19" src="https://github.com/user-attachments/assets/71a3b5c2-7caa-4b4f-8a48-3a55f272be4f" />

**Т1:**
```sql
SELECT price FROM membership WHERE membership_id = 1;
```
<img width="685" height="570" alt="Снимок экрана — 2026-11-18 в 12 37 39" src="https://github.com/user-attachments/assets/c13f36d8-cb69-4e60-9ca3-0cce5372a58f" />

*Вывод:* Уровень REPEATABLE READ защищает от неповторяющегося чтения. В рамках транзакции Т1 мы дважды выполнили SELECT. Оба раза база вернула одинаковое исходное значение цены, несмотря на то, что Т2 успела обновить строку и сделать COMMIT. Т1 видит «снимок» базы данных на момент своего старта.

---

### 2.5. REPEATABLE READ: Фантомное чтение
**Цель:** Проверить, появляются ли новые строки (фантомы) при повторном SELECT.

**Т1:**
```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM membership WHERE client_id = 1;
```
<img width="599" height="550" alt="Снимок экрана — 2026-11-18 в 12 38 40" src="https://github.com/user-attachments/assets/55ba0b01-4b8f-4495-856e-9e24850e2c8b" />

**Т2:**
```sql
BEGIN;
INSERT INTO membership (client_id, type, start_date, end_date, price) 
VALUES (1, 'Разовый', '2024-06-01', '2024-06-02', 500.00);
COMMIT;
```
<img width="590" height="499" alt="Снимок экрана — 2026-11-18 в 12 39 03" src="https://github.com/user-attachments/assets/8f6ef618-850c-4b69-a683-27604b4b1edc" />

**Т1:**
```sql
SELECT COUNT(*) FROM membership WHERE client_id = 1;
```
<img width="592" height="548" alt="Снимок экрана — 2026-11-18 в 12 39 52" src="https://github.com/user-attachments/assets/4de7541b-104f-4bab-b106-65efe07e04e4" />

*Вывод:* Уровень REPEATABLE READ полностью защищает от фантомного чтения. Транзакция Т2 добавила новую запись (INSERT) в таблицу и зафиксировала изменения. Однако при повторном выполнении SELECT COUNT(*) транзакция Т1 увидела то же самое количество строк, что и в первый раз. Новые «фантомные» строки для Т1 невидимы.

---

### 2.6. SERIALIZABLE: Конфликт при вставке
**Цель:** Смоделировать ошибку сериализации при одновременной вставке.

**Т1:**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM membership WHERE type = 'Безлимит';
```
<img width="604" height="556" alt="Снимок экрана — 2026-11-18 в 12 41 00" src="https://github.com/user-attachments/assets/50ef5d65-a659-414f-adc4-17462d1232d7" />

**Т2:**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM membership WHERE type = 'Безлимит';
```
<img width="591" height="557" alt="Снимок экрана — 2026-11-18 в 12 41 47" src="https://github.com/user-attachments/assets/9299c8ce-e619-42d9-8e35-759437b782f4" />

**Т1:**
```sql
INSERT INTO membership (client_id, type, start_date, end_date, price) 
VALUES (2, 'Безлимит', '2024-06-01', '2024-07-01', 10000.00);
COMMIT;
```
<img width="675" height="476" alt="Снимок экрана — 2026-11-18 в 12 42 05" src="https://github.com/user-attachments/assets/6bee5429-0a9c-4b32-8d30-d7da19d05770" />

**Т2:**
```sql
INSERT INTO membership (client_id, type, start_date, end_date, price) 
VALUES (3, 'Безлимит', '2024-06-01', '2024-07-01', 10000.00);
COMMIT; -- Здесь выпадет ошибка could not serialize access
```
<img width="626" height="554" alt="Снимок экрана — 2026-11-18 в 12 42 44" src="https://github.com/user-attachments/assets/8021b457-3131-4732-8363-79328285aaec" />

*Вывод:* На уровне SERIALIZABLE СУБД отслеживает не только обновление одних и тех же строк, но и логические зависимости чтения. Если Т2 вставляет данные на основе SELECT, который стал неактуален из-за действий Т1, возникает ошибка could not serialize access due to read/write dependencies. Это заставляет приложение повторить всю транзакцию целиком, гарантируя целостность данных.

### 2.7. SERIALIZABLE: Конфликт при обновлении
**Цель:** Показать, что параллельное обновление на уровне SERIALIZABLE приведет к откату одной из транзакций.

**Т1:**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
UPDATE membership SET price = 5000 WHERE membership_id = 2;
```
<img width="655" height="516" alt="Снимок экрана — 2026-11-18 в 13 03 00" src="https://github.com/user-attachments/assets/109c5027-114b-4de5-9872-0270451712bb" />

**Т2:**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
UPDATE membership SET price = 6000 WHERE membership_id = 2;
-- Пытается обновить ту же строку, будет ждать Т1
```
<img width="585" height="858" alt="Снимок экрана — 2026-11-18 в 13 03 24" src="https://github.com/user-attachments/assets/570250ba-3640-496c-88c0-726e2d2ae98c" />

**Т1:**
```sql
COMMIT;
```
**Т2:**
```sql
Ошибка сериализации
```
<img width="585" height="466" alt="Снимок экрана — 2026-11-18 в 13 06 13" src="https://github.com/user-attachments/assets/4a401043-3a72-47ee-86d6-1e85b14c1c8f" />

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
ROLLBACK TO my_sp; -- откат только второго изменения
COMMIT;
```
**Проверка:**
```sql
SELECT client_id, phone FROM client WHERE client_id IN (1, 2);
```
<img width="601" height="529" alt="Снимок экрана — 2026-11-18 в 13 31 35" src="https://github.com/user-attachments/assets/79389a95-0a7f-4da4-9c63-921fa058f6ed" />

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
ROLLBACK TO sp1; -- откатываем всё после первой точки
COMMIT;
```
**Проверка:**
```sql
SELECT membership_id, price FROM membership WHERE membership_id IN (1, 2, 3);
```
<img width="274" height="114" alt="Снимок экрана — 2026-11-18 в 13 32 41" src="https://github.com/user-attachments/assets/e81450f8-ac4d-433b-b592-276eedca4f67" />

*Вывод:* Цена 1-го абонемента изменилась. Цены 2-го и 3-го остались прежними, так как откат к `sp1` отменил вторую точку и все изменения после неё.

---

## 4. Общий вывод по работе
В ходе работы я научилась управлять транзакциями. 
Транзакции (`BEGIN`/`COMMIT`) позволяют объединять операции. Ошибки вызывают автоматический откат. 
Уровни изоляции (`READ COMMITTED`, `REPEATABLE READ`, `SERIALIZABLE`) защищают от аномалий (грязное чтение, неповторяющееся чтение, фантомы). Чем выше уровень, тем строже изоляция, но тем больше вероятность конфликтов.
`SAVEPOINT` позволяет делать частичный откат внутри транзакции.
