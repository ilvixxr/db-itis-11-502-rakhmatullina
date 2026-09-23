UPDATE client
SET phone = '+7-900-999-99-99'
WHERE client_id = 1;

UPDATE visit
SET attended = TRUE,
    comment = 'Опоздал на 10 минут'
WHERE visit_id = 4;

UPDATE payment
SET method = 'card'
WHERE method = 'cash';

UPDATE trainer
SET specialization = 'Пилатес и стретчинг'
WHERE trainer_id = 4;