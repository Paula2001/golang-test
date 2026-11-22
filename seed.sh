#!/usr/bin/env bash
# Seeds the supermarket database with sample data.
#
# Usage:
#   ./seed.sh           create the tables from schema.sql if they are missing,
#                       then wipe and re-seed all tables
#   ./seed.sh --fresh   drop the tables, recreate them from schema.sql, then seed
#
# Connection settings come from the standard libpq environment variables:
#   PGHOST (localhost)  PGPORT (5433)  PGUSER (postgres)
#   PGPASSWORD (postgres)  PGDATABASE (supermarket)
#
# Everything runs in one transaction: if any seeder fails, nothing is changed.
set -euo pipefail

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5433}"
export PGUSER="${PGUSER:-postgres}"
export PGPASSWORD="${PGPASSWORD:-postgres}"
export PGDATABASE="${PGDATABASE:-supermarket}"

SCHEMA_FILE="$(dirname "$0")/schema.sql"
TABLES="order_items, orders, products, customers, employees"

# Run in this order: later seeders look up rows created by earlier ones.
SEEDERS=(seed_employees seed_customers seed_products seed_orders seed_order_items)

# Each seeder prints SQL; main() pipes all of it into a single psql session.
# Primary keys are generated UUIDs, so seeders reference other rows by name.

seed_employees() {
    cat <<'SQL'
INSERT INTO employees (name, hire_date) VALUES
    ('Margaret Chen',   '2018-03-12'),  -- store manager, reports to no one
    ('David Okafor',    '2019-06-01'),  -- grocery lead
    ('Sofia Ramirez',   '2019-09-15'),  -- fresh food lead
    ('James Whitfield', '2021-02-08'),
    ('Priya Nair',      '2021-11-20'),
    ('Lucas Martin',    '2022-05-03'),
    ('Hannah Becker',   '2023-01-16'),
    ('Omar Haddad',     '2024-07-22'),
    ('Emily Turner',    '2025-03-10');  -- newest hire, no sales yet

-- Managers are set once every employee exists (self-reference).
UPDATE employees e
SET    manager_id = m.employee_id
FROM   (VALUES
           ('David Okafor',    'Margaret Chen'),
           ('Sofia Ramirez',   'Margaret Chen'),
           ('James Whitfield', 'David Okafor'),
           ('Priya Nair',      'David Okafor'),
           ('Omar Haddad',     'David Okafor'),
           ('Lucas Martin',    'Sofia Ramirez'),
           ('Hannah Becker',   'Sofia Ramirez'),
           ('Emily Turner',    'Sofia Ramirez')
       ) AS v(employee, manager)
JOIN   employees m ON m.name = v.manager
WHERE  e.name = v.employee;
SQL
}

seed_customers() {
    cat <<'SQL'
INSERT INTO customers (name, country, signup_date, phone) VALUES
    ('Alice Johnson',  'USA',     '2023-02-14', '+1-555-0101'),
    ('Bruno Silva',    'Brazil',  '2023-05-30', '+55-11-5550-0102'),
    ('Chloe Dubois',   'France',  '2023-08-09', NULL),
    ('Daniel Schmidt', 'Germany', '2023-11-21', '+49-30-5550-0104'),
    ('Elena Petrova',  'Canada',  '2024-01-05', '+1-555-0105'),
    ('Farah Ali',      'UK',      '2024-03-18', NULL),
    ('George Miller',  'USA',     '2024-06-02', '+1-555-0107'),
    ('Hiro Tanaka',    'Japan',   '2024-08-27', '+81-3-5550-0108'),
    ('Isabel Moreno',  'Mexico',  '2024-10-11', '+52-55-5550-0109'),
    ('Jack O''Brien',  'Ireland', '2025-01-19', NULL),        -- only a cancelled order
    ('Karin Larsson',  'Sweden',  '2025-04-07', '+46-8-5550-0111'),
    ('Liam Walker',    'USA',     '2025-07-23', NULL),
    ('Mei Wong',       'Canada',  '2025-09-14', '+1-555-0113'),
    ('Noah Fischer',   'Germany', '2026-02-02', '+49-30-5550-0114'), -- no orders
    ('Olivia Brown',   'UK',      '2026-05-28', NULL);        -- no orders
SQL
}

seed_products() {
    cat <<'SQL'
INSERT INTO products (name, category, price) VALUES
    ('Bananas (1 kg)',                 'Produce',         1.29),
    ('Gala Apples (1 kg)',             'Produce',         3.49),
    ('Baby Spinach (200 g)',           'Produce',         2.99),
    ('Avocados (4 pack)',              'Produce',         4.99),
    ('Whole Milk (1 L)',               'Dairy',           1.19),
    ('Greek Yogurt (500 g)',           'Dairy',           3.79),
    ('Cheddar Cheese (400 g)',         'Dairy',           5.49),
    ('Free-Range Eggs (12)',           'Dairy',           4.29),
    ('Sourdough Loaf',                 'Bakery',          4.50),
    ('Croissants (4 pack)',            'Bakery',          3.99),
    ('Chicken Breast (1 kg)',          'Meat & Seafood',  9.99),
    ('Atlantic Salmon Fillet (500 g)', 'Meat & Seafood', 12.49),
    ('Spaghetti (500 g)',              'Pantry',          1.49),
    ('Extra Virgin Olive Oil (1 L)',   'Pantry',         11.99),
    ('Basmati Rice (2 kg)',            'Pantry',          5.99),
    ('Saffron Threads (1 g)',          'Pantry',          7.99),  -- never ordered
    ('Ground Coffee (500 g)',          'Beverages',       8.99),
    ('Orange Juice (1.5 L)',           'Beverages',       3.29),
    ('Frozen Peas (1 kg)',             'Frozen',          2.49),
    ('Dish Soap (750 ml)',             'Household',       2.79),
    ('Dark Chocolate Bar (100 g)',     'Snacks',          2.19),
    ('Reusable Shopping Bag',          NULL,              0.99);  -- no category
SQL
}

seed_orders() {
    cat <<'SQL'
-- Orders have no natural key, so each seed order gets a ref number that
-- seed_order_items uses to attach line items. The table is dropped at commit.
-- A NULL rep is an online order with no sales rep.
CREATE TEMP TABLE seed_orders ON COMMIT DROP AS
SELECT v.ref, gen_random_uuid() AS order_id, v.customer, v.rep,
       v.order_date::date AS order_date, v.status
FROM (VALUES
    ( 1, 'Alice Johnson',  'James Whitfield', '2025-01-08', 'completed'),
    ( 2, 'Bruno Silva',    'Priya Nair',      '2025-01-15', 'completed'),
    ( 3, 'Chloe Dubois',   'Lucas Martin',    '2025-02-03', 'completed'),
    ( 4, 'Alice Johnson',  NULL,              '2025-02-20', 'completed'),
    ( 5, 'Daniel Schmidt', 'James Whitfield', '2025-03-11', 'cancelled'),
    ( 6, 'Elena Petrova',  'Hannah Becker',   '2025-03-28', 'completed'),
    ( 7, 'Farah Ali',      'Priya Nair',      '2025-04-15', 'completed'),
    ( 8, 'George Miller',  NULL,              '2025-05-02', 'completed'),
    ( 9, 'Hiro Tanaka',    'Lucas Martin',    '2025-05-19', 'completed'),
    (10, 'Isabel Moreno',  'Omar Haddad',     '2025-06-07', 'completed'),
    (11, 'Jack O''Brien',  'James Whitfield', '2025-06-25', 'cancelled'),
    (12, 'Alice Johnson',  'Hannah Becker',   '2025-07-14', 'completed'),
    (13, 'Karin Larsson',  'Priya Nair',      '2025-08-01', 'completed'),
    (14, 'Bruno Silva',    NULL,              '2025-08-22', 'completed'),
    (15, 'Daniel Schmidt', 'Omar Haddad',     '2025-09-09', 'completed'),
    (16, 'Liam Walker',    'Lucas Martin',    '2025-10-03', 'completed'),
    (17, 'Elena Petrova',  'James Whitfield', '2025-11-18', 'completed'),
    (18, 'Mei Wong',       'Hannah Becker',   '2025-12-12', 'completed'),
    (19, 'George Miller',  'Priya Nair',      '2026-01-20', 'cancelled'),
    (20, 'Alice Johnson',  'Omar Haddad',     '2026-03-05', 'completed'),
    (21, 'Hiro Tanaka',    NULL,              '2026-05-16', 'completed'),
    (22, 'Isabel Moreno',  'Lucas Martin',    '2026-08-29', 'completed'),
    (23, 'Karin Larsson',  'James Whitfield', '2026-11-10', 'pending'),
    (24, 'Liam Walker',    NULL,              '2026-11-20', 'pending')
) AS v(ref, customer, rep, order_date, status);

INSERT INTO orders (order_id, customer_id, employee_id, order_date, status)
SELECT s.order_id,
       (SELECT customer_id FROM customers WHERE name = s.customer),
       (SELECT employee_id FROM employees WHERE name = s.rep),
       s.order_date,
       s.status
FROM   seed_orders s
ORDER  BY s.ref;
SQL
}

seed_order_items() {
    cat <<'SQL'
-- Coffee, olive oil, eggs and bananas went up in price in 2026, so their
-- 2025 line items carry the old unit_price (lower than products.price).
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT (SELECT order_id   FROM seed_orders WHERE ref  = v.ref),
       (SELECT product_id FROM products    WHERE name = v.product),
       v.quantity,
       v.unit_price
FROM (VALUES
    ( 1, 'Bananas (1 kg)',                 2,  1.19),
    ( 1, 'Whole Milk (1 L)',               2,  1.19),
    ( 1, 'Free-Range Eggs (12)',           1,  3.89),
    ( 1, 'Sourdough Loaf',                 1,  4.50),
    ( 2, 'Ground Coffee (500 g)',          1,  7.99),
    ( 2, 'Croissants (4 pack)',            2,  3.99),
    ( 3, 'Avocados (4 pack)',              1,  4.99),
    ( 3, 'Greek Yogurt (500 g)',           2,  3.79),
    ( 3, 'Baby Spinach (200 g)',           1,  2.99),
    ( 4, 'Extra Virgin Olive Oil (1 L)',   1, 10.49),
    ( 4, 'Spaghetti (500 g)',              3,  1.49),
    ( 4, 'Cheddar Cheese (400 g)',         1,  5.49),
    ( 5, 'Chicken Breast (1 kg)',          2,  9.99),
    ( 5, 'Basmati Rice (2 kg)',            1,  5.99),
    ( 6, 'Atlantic Salmon Fillet (500 g)', 1, 12.49),
    ( 6, 'Baby Spinach (200 g)',           1,  2.99),
    ( 6, 'Orange Juice (1.5 L)',           1,  3.29),
    ( 7, 'Gala Apples (1 kg)',             1,  3.49),
    ( 7, 'Dark Chocolate Bar (100 g)',     3,  2.19),
    ( 8, 'Frozen Peas (1 kg)',             2,  2.49),
    ( 8, 'Chicken Breast (1 kg)',          1,  9.99),
    ( 8, 'Dish Soap (750 ml)',             1,  2.79),
    ( 8, 'Reusable Shopping Bag',          2,  0.99),
    ( 9, 'Basmati Rice (2 kg)',            1,  5.99),
    ( 9, 'Free-Range Eggs (12)',           1,  3.89),
    ( 9, 'Ground Coffee (500 g)',          1,  7.99),
    (10, 'Avocados (4 pack)',              2,  4.99),
    (10, 'Bananas (1 kg)',                 1,  1.19),
    (10, 'Orange Juice (1.5 L)',           2,  3.29),
    (11, 'Atlantic Salmon Fillet (500 g)', 2, 12.49),
    (12, 'Whole Milk (1 L)',               3,  1.19),
    (12, 'Croissants (4 pack)',            1,  3.99),
    (12, 'Cheddar Cheese (400 g)',         1,  5.49),
    (12, 'Ground Coffee (500 g)',          1,  7.99),
    (13, 'Extra Virgin Olive Oil (1 L)',   1, 10.49),
    (13, 'Spaghetti (500 g)',              2,  1.49),
    (14, 'Greek Yogurt (500 g)',           1,  3.79),
    (14, 'Gala Apples (1 kg)',             2,  3.49),
    (15, 'Chicken Breast (1 kg)',          1,  9.99),
    (15, 'Frozen Peas (1 kg)',             1,  2.49),
    (15, 'Sourdough Loaf',                 1,  4.50),
    (16, 'Dark Chocolate Bar (100 g)',     2,  2.19),
    (16, 'Orange Juice (1.5 L)',           1,  3.29),
    (17, 'Atlantic Salmon Fillet (500 g)', 1, 12.49),
    (17, 'Basmati Rice (2 kg)',            1,  5.99),
    (17, 'Baby Spinach (200 g)',           2,  2.99),
    (18, 'Free-Range Eggs (12)',           2,  3.89),
    (18, 'Bananas (1 kg)',                 2,  1.19),
    (18, 'Dish Soap (750 ml)',             1,  2.79),
    (19, 'Ground Coffee (500 g)',          2,  8.99),
    (20, 'Extra Virgin Olive Oil (1 L)',   1, 11.99),
    (20, 'Cheddar Cheese (400 g)',         1,  5.49),
    (20, 'Sourdough Loaf',                 1,  4.50),
    (20, 'Free-Range Eggs (12)',           1,  4.29),
    (21, 'Bananas (1 kg)',                 3,  1.29),
    (21, 'Greek Yogurt (500 g)',           2,  3.79),
    (22, 'Ground Coffee (500 g)',          1,  8.99),
    (22, 'Croissants (4 pack)',            1,  3.99),
    (22, 'Avocados (4 pack)',              1,  4.99),
    (23, 'Chicken Breast (1 kg)',          1,  9.99),
    (23, 'Spaghetti (500 g)',              2,  1.49),
    (23, 'Whole Milk (1 L)',               2,  1.19),
    (24, 'Dark Chocolate Bar (100 g)',     4,  2.19),
    (24, 'Reusable Shopping Bag',          1,  0.99)
) AS v(ref, product, quantity, unit_price);
SQL
}

usage() {
    sed -n '2,13s/^# \{0,1\}//p' "$0"
}

main() {
    local fresh=false
    case "${1:-}" in
        "")        ;;
        --fresh)   fresh=true ;;
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; exit 1 ;;
    esac

    echo "Seeding database '$PGDATABASE' on $PGHOST:$PGPORT as $PGUSER"

    local has_tables
    has_tables=$(psql -X -At -c "SELECT to_regclass('public.employees') IS NOT NULL")

    {
        echo "BEGIN;"
        if $fresh; then
            echo "DROP TABLE IF EXISTS $TABLES;"
        fi
        if $fresh || [ "$has_tables" = "f" ]; then
            cat "$SCHEMA_FILE"
        fi
        echo "TRUNCATE $TABLES;"
        for seeder in "${SEEDERS[@]}"; do
            "$seeder"
        done
        echo "COMMIT;"
    } | psql -X -q -v ON_ERROR_STOP=1

    psql -X -c "
        SELECT 'employees' AS table_name, count(*) AS rows FROM employees
        UNION ALL SELECT 'customers',   count(*) FROM customers
        UNION ALL SELECT 'products',    count(*) FROM products
        UNION ALL SELECT 'orders',      count(*) FROM orders
        UNION ALL SELECT 'order_items', count(*) FROM order_items"
}

main "$@"
