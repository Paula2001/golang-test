-- PostgreSQL schema. Primary keys are UUIDs; if an insert omits the id,
-- gen_random_uuid() (built in since PostgreSQL 13) generates a random v4 UUID.

CREATE TABLE employees (
    employee_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(100) NOT NULL,
    manager_id   UUID REFERENCES employees(employee_id),  -- self-reference
    hire_date    DATE
);

CREATE TABLE customers (
    customer_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(100) NOT NULL,
    country      VARCHAR(50),
    signup_date  DATE,
    phone        VARCHAR(30)            -- nullable on purpose
);

CREATE TABLE products (
    product_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(100) NOT NULL,
    category     VARCHAR(50),
    price        DECIMAL(10,2) NOT NULL
);

CREATE TABLE orders (
    order_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id  UUID NOT NULL REFERENCES customers(customer_id),
    employee_id  UUID REFERENCES employees(employee_id),  -- sales rep
    order_date   DATE NOT NULL,
    status       VARCHAR(20) NOT NULL   -- 'completed', 'cancelled', 'pending'
);

CREATE TABLE order_items (
    order_id     UUID REFERENCES orders(order_id),
    product_id   UUID REFERENCES products(product_id),
    quantity     INT NOT NULL,
    unit_price   DECIMAL(10,2) NOT NULL,  -- price at time of sale
    PRIMARY KEY (order_id, product_id)
);
