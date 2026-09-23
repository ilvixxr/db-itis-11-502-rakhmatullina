-- 1. CLIENT
CREATE TABLE client (
    client_id      SERIAL PRIMARY KEY,
    first_name     VARCHAR(50) NOT NULL,
    last_name      VARCHAR(50) NOT NULL,
    phone          VARCHAR(20),
    email          VARCHAR(100) UNIQUE,
    birth_date     DATE
);

-- 2. TRAINER
CREATE TABLE trainer (
    trainer_id      SERIAL PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    specialization  VARCHAR(100),
    hire_date       DATE NOT NULL
);

-- 3. MEMBERSHIP
CREATE TABLE membership (
    membership_id  SERIAL PRIMARY KEY,
    client_id      INT NOT NULL REFERENCES client(client_id),
    type           VARCHAR(50) NOT NULL,
    start_date     DATE NOT NULL,
    end_date       DATE NOT NULL,
    price          NUMERIC(10, 2) NOT NULL
);

-- 4. TRAINING
CREATE TABLE training (
    training_id       SERIAL PRIMARY KEY,
    trainer_id        INT NOT NULL REFERENCES trainer(trainer_id),
    name              VARCHAR(100) NOT NULL,
    training_date     TIMESTAMP NOT NULL,
    duration_min      INT NOT NULL,
    max_participants  INT NOT NULL
);

-- 5. VISIT
CREATE TABLE visit (
    visit_id      SERIAL PRIMARY KEY,
    training_id   INT NOT NULL REFERENCES training(training_id),
    client_id     INT NOT NULL REFERENCES client(client_id),
    visit_date    TIMESTAMP NOT NULL,
    attended      BOOLEAN DEFAULT TRUE
);

-- 6. PAYMENT
CREATE TABLE payment (
    payment_id     SERIAL PRIMARY KEY,
    membership_id  INT NOT NULL REFERENCES membership(membership_id),
    client_id      INT NOT NULL REFERENCES client(client_id),
    payment_date   DATE NOT NULL,
    amount         NUMERIC(10, 2) NOT NULL,
    method         VARCHAR(30) NOT NULL
);