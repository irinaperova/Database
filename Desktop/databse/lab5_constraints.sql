--Irina Perova 25B032334


CREATE DATABASE constraints_lab;
\c constraints_lab

--task 1.1
--table employees with info about staff
CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    first_name  TEXT,
    last_name   TEXT,
    age         INTEGER CHECK (age BETWEEN 18 AND 65),
    --age must be between 18 and 65 both included
    salary      NUMERIC CHECK (salary > 0)
    --greater than zero
);

--task 1.2
--table with catalog of products
CREATE TABLE products_catalog (
    product_id     INTEGER PRIMARY KEY,
    product_name   TEXT,
    regular_price  NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
    --regular price cant be free, discount is also greater than 0
    --and discount cant be same or more than regular price
);


--task 1.3
--table with info about booking (id, dates, num of guests
CREATE TABLE bookings (
    booking_id     INTEGER PRIMARY KEY,
    check_in_date  DATE,
    check_out_date DATE,
    num_guests     INTEGER,
    CONSTRAINT valid_guests CHECK (num_guests BETWEEN 1 AND 10),
    --a booking is for 1 to 10 guests, 0 is not included bc it doesnt make any sense
    CONSTRAINT valid_dates CHECK (check_out_date > check_in_date)
    --guest must leave after the arrival, > is strict -> check out on the same day is prohibited
);

--task 1.4
--VALID DATA
INSERT INTO employees VALUES (1, 'Irina', 'Perova', 19, 85000);
INSERT INTO employees VALUES (2, 'Arseniy', 'Kassymov', 25, 12000);
-- Result: INSERT successful for both statements, every CHECK is true

INSERT INTO products_catalog VALUES (1, 'Laptop', 450000, 399000);
INSERT INTO products_catalog VALUES (2, 'Mouse', 12000, 9500);
--successful insert

INSERT INTO bookings VALUES (1, '2026-11-01', '2026-11-05', 2);
INSERT INTO bookings VALUES (2, '2026-12-20', '2026-12-27', 4);
--successful insert

--INVALID DATA
--violates age and salary constraints
-- ERROR: new row for relation "employees" violates check constraint "employees_age_check"
-- insert into employees VALUES (3, 'Ruslan', 'Tsoy', 16, -100);

--VIOLATES regular price and discount constraint as they are both zero
-- ERROR: new row for relation "products_catalog" violates check constraint "valid_discount"
-- INSERT INTO products_catalog VALUES (3, 'Cable', 0, 0);

--violates check-in and check-out constraints as check out is earlier than check in
--also violates number of guests constraint as there are 11 of them
-- ERROR: new row for relation "bookings" violates check constraint "valid_dates"
-- INSERT INTO bookings VALUES (3, '2026-09-10', '2026-09-01', 11);

-- a CHECK constraint is tested on every INSERT and UPDATE, and the whole row is rejected when the condition is false, so nothing gets saved at all.
-- when one row breaks more than one constraint postgres stops at the first failed check and reports only that one, so the error for Ruslan names employees_age_check and says nothing about the negative salary.
-- the same happens with the booking above, the error only names valid_dates even though num_guests is invalid too.
-- every error message contains the constraint name, this is why naming them manually like valid_discount and valid_dates is better than letting postgres generate names like employees_age_check.
-- valid_discount joins three rules in one constraint so the error does not tell which of them failed, and for Cable all three are broken at once as both prices are zero.
-- BETWEEN includes both limits, so age 18 and age 65 are accepted and so are 1 and 10 guests.
-- a CHECK only rejects a row when the condition is FALSE, and comparing anything to NULL gives UNKNOWN instead, so a row with a NULL age would pass the age check without any error, which means CHECK cannot protect a column from missing values and that is what NOT NULL does in part 2.



--PART 2

-- task 2.1
-- customers table, three columns are required and one is optional
CREATE TABLE customers (
    -- NOT NULL means the column must always have a value, an INSERT without it fails
    customer_id       INTEGER NOT NULL PRIMARY KEY,
    -- email is required as we cannot contact a customer without it
    email             TEXT    NOT NULL,
    -- phone is the only nullable column here, a customer may simply not have one
    phone             TEXT,
    -- registration_date is required so every customer has a known start date
    registration_date DATE    NOT NULL
);


-- task 2.2
-- inventory table combines NOT NULL and CHECK on the same columns
CREATE TABLE inventory (
    item_id      INTEGER   NOT NULL PRIMARY KEY,
    item_name    TEXT      NOT NULL,
    -- NOT NULL stops an empty value and CHECK stops a negative one, zero is allowed as the item can be out of stock
    quantity     INTEGER   NOT NULL CHECK (quantity >= 0),
    -- unit_price uses > 0 and not >= 0 because a product cannot be free
    unit_price   NUMERIC   NOT NULL CHECK (unit_price > 0),
    -- last_updated is required so we always know when the record was changed
    last_updated TIMESTAMP NOT NULL
);

-- task 2.3
-- VALID DATA, every required column has a value
INSERT INTO customers VALUES (1, 'irina@kbtu.kz', '+77011112233', '2026-01-15');
INSERT INTO customers VALUES (2, 'arseniy@kbtu.kz', '+77052223344', '2026-03-02');
INSERT INTO inventory VALUES (1, 'Laptop', 12, 450000, '2026-10-01 09:00:00');
INSERT INTO inventory VALUES (2, 'Mouse', 0, 9500, CURRENT_TIMESTAMP);
-- successful insert, quantity 0 passes as the CHECK allows zero

-- NULL IN A NULLABLE COLUMN, both work as phone has no NOT NULL
INSERT INTO customers VALUES (3, 'dana@kbtu.kz', NULL, '2026-05-20');
-- successful insert, NULL is written into phone
INSERT INTO customers (customer_id, email, registration_date) VALUES (4, 'timur@kbtu.kz', '2026-06-01');
-- successful insert too, a column that is left out of the list also becomes NULL

-- INVALID DATA, NULL in a NOT NULL column
-- ERROR: null value in column "email" of relation "customers" violates not-null constraint
-- INSERT INTO customers VALUES (5, NULL, '+77077778899', '2026-07-01');

-- ERROR: null value in column "email" of relation "customers" violates not-null constraint
-- INSERT INTO customers (customer_id, phone, registration_date) VALUES (6, '+77011110000', '2026-07-05');

-- ERROR: null value in column "registration_date" of relation "customers" violates not-null constraint
-- INSERT INTO customers VALUES (7, 'saule@kbtu.kz', '+77012223344', NULL);

-- ERROR: null value in column "customer_id" of relation "customers" violates not-null constraint
-- INSERT INTO customers VALUES (NULL, 'marat@kbtu.kz', '+77013334455', '2026-08-01');

-- ERROR: null value in column "quantity" of relation "inventory" violates not-null constraint
-- INSERT INTO inventory VALUES (3, 'Keyboard', NULL, 25000, CURRENT_TIMESTAMP);

-- ERROR: null value in column "last_updated" of relation "inventory" violates not-null constraint
-- INSERT INTO inventory VALUES (6, 'Lamp', 3, 12000, NULL);

-- INVALID DATA, CHECK constraints on inventory
-- ERROR: new row for relation "inventory" violates check constraint "inventory_quantity_check"
-- INSERT INTO inventory VALUES (4, 'Monitor', -5, 85000, CURRENT_TIMESTAMP);

-- ERROR: new row for relation "inventory" violates check constraint "inventory_unit_price_check"
-- INSERT INTO inventory VALUES (5, 'Cable', 10, 0, CURRENT_TIMESTAMP);


--PART 3

-- task 3.1
-- users table, UNIQUE stops two accounts from sharing a login or an email
CREATE TABLE users (
    user_id    INTEGER PRIMARY KEY,
    -- UNIQUE checks the whole table
    username   TEXT UNIQUE,
    -- the same rule for email as one address belongs to one account only
    email      TEXT UNIQUE,
    created_at TIMESTAMP
);

-- task 3.2
-- one student cannot enroll in the same course twice in the same semester
CREATE TABLE course_enrollments (
    enrollment_id INTEGER PRIMARY KEY,
    student_id    INTEGER,
    course_code   TEXT,
    semester      TEXT,
    -- UNIQUE works on the COMBINATION of three columns, each column separately can repeat
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);

-- task 3.3
-- task 3.1 already created UNIQUE constraints but with generated names, so first we drop those
ALTER TABLE users DROP CONSTRAINT users_username_key;
ALTER TABLE users DROP CONSTRAINT users_email_key;

-- and add them back with our own names, a named constraint can be dropped by its name and it appears in the error
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

-- VALID DATA
INSERT INTO users VALUES (1, 'irina_p', 'irina@kbtu.kz', '2026-01-15 10:00:00');
INSERT INTO users VALUES (2, 'arseniy_k', 'arseniy@kbtu.kz', '2026-02-20 14:30:00');
-- successful insert, both usernames and both emails are different

INSERT INTO course_enrollments VALUES (1, 101, 'CS201', 'Fall 2026');
INSERT INTO course_enrollments VALUES (2, 101, 'CS202', 'Fall 2026');
INSERT INTO course_enrollments VALUES (3, 102, 'CS201', 'Fall 2026');
INSERT INTO course_enrollments VALUES (4, 101, 'CS201', 'Spring 2027');
-- all four pass, student 101 repeats three times and CS201 repeats three times, but no full combination is repeated

-- INVALID DATA
-- ERROR: duplicate key value violates unique constraint "unique_username"
-- DETAIL: Key (username)=(irina_p) already exists.
-- INSERT INTO users VALUES (3, 'irina_p', 'dana@kbtu.kz', CURRENT_TIMESTAMP);

-- ERROR: duplicate key value violates unique constraint "unique_email"
-- DETAIL: Key (email)=(irina@kbtu.kz) already exists.
-- INSERT INTO users VALUES (4, 'dana_s', 'irina@kbtu.kz', CURRENT_TIMESTAMP);

-- ERROR: duplicate key value violates unique constraint "unique_enrollment"
-- DETAIL: Key (student_id, course_code, semester)=(101, CS201, Fall 2026) already exists.
-- INSERT INTO course_enrollments VALUES (5, 101, 'CS201', 'Fall 2026');

-- EXTRA TESTS, both of these are saved without any error
INSERT INTO users VALUES (5, NULL, NULL, CURRENT_TIMESTAMP);
INSERT INTO users VALUES (6, NULL, NULL, CURRENT_TIMESTAMP);
-- UNIQUE allows many NULLs as two unknown values are not considered equal

INSERT INTO users VALUES (7, 'IRINA_P', 'other@kbtu.kz', CURRENT_TIMESTAMP);
-- UNIQUE compares text exactly, so IRINA_P and irina_p count as different logins



--part 4

-- task 4.1
-- departments is the main table for part 5, employees_dept will reference it
CREATE TABLE departments (
    -- PRIMARY KEY is UNIQUE and NOT NULL together, it identifies every row and other tables can point to it
    dept_id   INTEGER PRIMARY KEY,
    -- a department always needs a name, but it does not have to be unique
    dept_name TEXT NOT NULL,
    -- location is optional and can stay empty
    location  TEXT
);

-- task 4.2
-- it connects students and courses
CREATE TABLE student_courses (
    student_id      INTEGER,
    course_id       INTEGER,
    enrollment_date DATE,
    grade           TEXT,
    -- the key is the PAIR of columns, the same student cannot be enrolled in the same course twice
    -- a composite key is always written as a table level constraint
    CONSTRAINT pk_student_courses PRIMARY KEY (student_id, course_id)
);

-- VALID DATA
INSERT INTO departments VALUES (1, 'IT', 'Almaty');
INSERT INTO departments VALUES (2, 'Finance', 'Astana');
INSERT INTO departments VALUES (3, 'HR', 'Almaty');
-- successful insert, all three ids are different

INSERT INTO departments VALUES (4, 'Marketing', NULL);
-- successful too, location has no NOT NULL so it can stay empty

INSERT INTO student_courses VALUES (101, 201, '2026-09-01', 'A');
INSERT INTO student_courses VALUES (101, 202, '2026-09-01', 'B+');
INSERT INTO student_courses VALUES (102, 201, '2026-09-02', 'A-');
-- all three pass, student 101 appears twice and course 201 appears twice, but no pair is repeated

-- INVALID DATA
-- the error says UNIQUE even though we declared PRIMARY KEY, because a primary key contains a unique constraint inside it
-- ERROR: duplicate key value violates unique constraint "departments_pkey"
-- DETAIL: Key (dept_id)=(1) already exists.
-- INSERT INTO departments VALUES (1, 'Marketing', 'Shymkent');

-- this time the error says NOT NULL, the second half of a primary key
-- ERROR: null value in column "dept_id" of relation "departments" violates not-null constraint
-- INSERT INTO departments VALUES (NULL, 'Logistics', 'Almaty');

-- ERROR: null value in column "dept_name" of relation "departments" violates not-null constraint
-- INSERT INTO departments VALUES (5, NULL, 'Almaty');

-- ERROR: duplicate key value violates unique constraint "pk_student_courses"
-- DETAIL: Key (student_id, course_id)=(101, 201) already exists.
-- INSERT INTO student_courses VALUES (101, 201, '2027-01-15', 'A');

-- course_id has no explicit NOT NULL but a primary key adds it automatically to every column it covers
-- ERROR: null value in column "course_id" of relation "student_courses" violates not-null constraint
-- INSERT INTO student_courses VALUES (103, NULL, '2026-09-05', 'B');

-- a table cannot have a second primary key, postgres refuses the statement itself
-- ERROR: multiple primary keys for table "departments" are not allowed
-- ALTER TABLE departments ADD CONSTRAINT pk_two PRIMARY KEY (dept_name);

-- task 4.3
-- 1. THE DIFFERENCE BETWEEN UNIQUE AND PRIMARY KEY
-- a PRIMARY KEY is UNIQUE and NOT NULL joined together plus the meaning of being the identifier of the row.
-- UNIQUE only stops repeated values, it still allows NULL and even many NULLs at once as we saw in part 3.
-- both create an index automatically, and the two errors above show the two halves, a duplicate dept_id gives "violates unique constraint" and a NULL dept_id gives "violates not-null constraint".
-- other tables can reference a primary key, which is why departments.dept_id is the target in part 5.

-- 2. WHEN TO USE A SINGLE COLUMN VS A COMPOSITE PRIMARY KEY
-- a single column key is used when one value identifies the object, like dept_id for a department.
-- a composite key is used in junction tables like student_courses where a row means "this student takes this course" and the pair already identifies it.
-- a composite key also writes the rule into the schema, here the same student cannot be enrolled in the same course twice.

-- 3. WHY ONLY ONE PRIMARY KEY BUT MANY UNIQUE CONSTRAINTS
-- a primary key answers what identifies a row and that question has only one answer, otherwise other tables would not know what to reference.
-- postgres enforces it, a second primary key fails with "multiple primary keys for table departments are not allowed".
-- uniqueness is a different rule that just says a value cannot repeat, so a table can have as many as it needs.
-- the users table in part 3 shows it, username and email are both unique but user_id is what identifies the row.



--PART 5

-- task 5.1
-- employees_dept is a child table of departments from task 4.1
CREATE TABLE employees_dept (
    emp_id    INTEGER PRIMARY KEY,
    emp_name  TEXT NOT NULL,
    -- REFERENCES makes a FOREIGN KEY, the value here must already exist in departments.dept_id
    -- the target column must be a PRIMARY KEY or UNIQUE, which is why part 4 had to come first
    dept_id   INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

-- VALID DATA, departments 1 and 2 already exist from task 4.1
INSERT INTO employees_dept VALUES (1, 'Irina Perova', 1, '2026-02-01');
INSERT INTO employees_dept VALUES (2, 'Arseniy Kassymov', 2, '2026-03-15');
INSERT INTO employees_dept VALUES (3, 'Dana Omarova', 1, '2026-04-10');
-- successful insert, two employees share department 1 as a foreign key does not require the value to be unique in the child table

INSERT INTO employees_dept VALUES (5, 'Saule Abenova', NULL, '2026-06-01');
-- successful too, a foreign key allows NULL and it means "no department yet"

-- INVALID DATA
-- ERROR: insert or update on table "employees_dept" violates foreign key constraint "employees_dept_dept_id_fkey"
-- DETAIL: Key (dept_id)=(99) is not present in table "departments".
-- INSERT INTO employees_dept VALUES (4, 'Timur Ospanov', 99, '2026-05-01');

-- a foreign key also protects the parent table, department 1 cannot be deleted while employees point to it
-- ERROR: update or delete on table "departments" violates foreign key constraint "employees_dept_dept_id_fkey" on table "employees_dept"
-- DETAIL: Key (dept_id)=(1) is still referenced from table "employees_dept".
-- DELETE FROM departments WHERE dept_id = 1;

-- task 5.2
-- parent tables first, a child cannot reference a table that does not exist yet
CREATE TABLE authors (
    author_id   INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country     TEXT
);

CREATE TABLE publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);

-- books is a child of two tables at once
CREATE TABLE books (
    book_id          INTEGER PRIMARY KEY,
    title            TEXT NOT NULL,
    -- one author writes many books, so author_id repeats here freely
    author_id        INTEGER REFERENCES authors(author_id),
    -- the same publisher prints many books
    publisher_id     INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    -- isbn is UNIQUE and not a primary key, book_id identifies the row while isbn is just a value that cannot repeat
    isbn             TEXT UNIQUE
);

INSERT INTO authors VALUES (1, 'Abai Kunanbaev', 'Kazakhstan');
INSERT INTO authors VALUES (2, 'Mukhtar Auezov', 'Kazakhstan');
INSERT INTO authors VALUES (3, 'George Orwell', 'United Kingdom');

INSERT INTO publishers VALUES (1, 'Atamura', 'Almaty');
INSERT INTO publishers VALUES (2, 'Foliant', 'Astana');
INSERT INTO publishers VALUES (3, 'Penguin Books', 'London');

-- books go last, every author_id and publisher_id already exists
INSERT INTO books VALUES (1, 'Book of Words', 1, 1, 1995, '9789965123456');
INSERT INTO books VALUES (2, 'Abai Zholy', 2, 1, 2003, '9789965654321');
INSERT INTO books VALUES (3, '1984', 3, 3, 1949, '9780451524935');
INSERT INTO books VALUES (4, 'Animal Farm', 3, 3, 1945, '9780452284241');
-- author 3 and publisher 3 are used twice, a foreign key allows that

-- INVALID DATA
-- ERROR: insert or update on table "books" violates foreign key constraint "books_author_id_fkey"
-- DETAIL: Key (author_id)=(99) is not present in table "authors".
-- INSERT INTO books VALUES (5, 'Unknown Book', 99, 1, 2020, '9780000000001');

-- ERROR: duplicate key value violates unique constraint "books_isbn_key"
-- DETAIL: Key (isbn)=(9780451524935) already exists.
-- INSERT INTO books VALUES (6, 'Copy of 1984', 3, 3, 1949, '9780451524935');



-- task 5.3
CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    -- ON DELETE RESTRICT protects the parent, a category that still has products cannot be deleted
    category_id  INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id    INTEGER PRIMARY KEY,
    -- ON DELETE CASCADE works the opposite way, deleting an order also deletes all its items
    order_id   INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    -- no ON DELETE here, so the default NO ACTION applies and a product cannot be deleted while it appears in an order
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity   INTEGER CHECK (quantity > 0)
);


-- sample data, parents first
INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO categories VALUES (2, 'Furniture');
INSERT INTO categories VALUES (3, 'Stationery');

INSERT INTO products_fk VALUES (1, 'Laptop', 1);
INSERT INTO products_fk VALUES (2, 'Mouse', 1);
INSERT INTO products_fk VALUES (3, 'Office Chair', 2);

INSERT INTO orders VALUES (1, '2026-09-01');
INSERT INTO orders VALUES (2, '2026-09-15');

INSERT INTO order_items VALUES (1, 1, 1, 2);
INSERT INTO order_items VALUES (2, 1, 2, 5);
INSERT INTO order_items VALUES (3, 2, 3, 1);
-- successful insert, items 1 and 2 belong to order 1, item 3 to order 2

-- TEST 1: RESTRICT
-- category 1 is used by Laptop and Mouse so the delete is refused, nothing changes
-- ERROR: update or delete on table "categories" violates foreign key constraint "products_fk_category_id_fkey" on table "products_fk"
-- DETAIL: Key (category_id)=(1) is still referenced from table "products_fk".
-- DELETE FROM categories WHERE category_id = 1;

DELETE FROM categories WHERE category_id = 3;
-- DELETE 1, category 3 has no products so RESTRICT does not block it

-- TEST 2: CASCADE
SELECT * FROM order_items ORDER BY item_id;
-- 3 rows before the delete

DELETE FROM orders WHERE order_id = 1;
-- DELETE 1, items 1 and 2 are removed automatically with no error

SELECT * FROM order_items ORDER BY item_id;
-- only item 3 is left as order 2 was not touched

-- TEST 3: what happens in each case
-- RESTRICT refuses the delete and keeps both tables unchanged, used when child rows matter on their own as a product still exists without its category.
-- CASCADE deletes the children together with the parent, used when a child is meaningless alone as an order item belongs to one order only.
-- without ON DELETE the default is NO ACTION which behaves like RESTRICT here, so product_id in order_items also blocks deleting an ordered product.
-- CASCADE is risky as one DELETE silently removes rows from several tables.


-- part 6, task 6.1
-- a separate schema is used because customers and orders already exist in public from parts 2 and 5
CREATE SCHEMA ecommerce;
SET search_path TO ecommerce, public;

CREATE TABLE customers (
    customer_id       INTEGER PRIMARY KEY,
    name              TEXT NOT NULL,
    -- email is required and unique, two accounts cannot share an address
    email             TEXT NOT NULL UNIQUE,
    -- phone is optional as a customer may not leave one
    phone             TEXT,
    -- DEFAULT fills the date automatically when it is not given
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE products (
    product_id     INTEGER PRIMARY KEY,
    name           TEXT NOT NULL,
    description    TEXT,
    -- price uses >= 0 and not > 0 so a free promo item is still allowed
    price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    -- stock can be zero when the item is sold out but never negative
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    -- RESTRICT because order history must survive, a customer cannot be deleted while their orders exist
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    order_date   DATE NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    -- IN works as a list of allowed values, anything else is rejected
    status       TEXT NOT NULL
                 CONSTRAINT valid_status CHECK (status IN
                 ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    -- CASCADE because a line has no meaning without its order
    order_id        INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    -- RESTRICT because deleting a product must not erase past sales
    product_id      INTEGER NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    -- quantity uses > 0, ordering zero items makes no sense
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    -- unit_price is stored separately so the order keeps the price at the moment of purchase
    unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

INSERT INTO customers VALUES (1,'Irina Perova','irina@kbtu.kz','+77011112233','2026-01-15');
INSERT INTO customers VALUES (2,'Arseniy Kassymov','arseniy@kbtu.kz','+77052223344','2026-02-20');
INSERT INTO customers VALUES (3,'Dana Omarova','dana@kbtu.kz',NULL,'2026-03-05');
INSERT INTO customers VALUES (4,'Timur Ospanov','timur@kbtu.kz','+77773334455','2026-04-12');
INSERT INTO customers VALUES (5,'Saule Abenova','saule@kbtu.kz','+77014445566','2026-05-30');
-- customer 3 has no phone which is allowed as phone has no NOT NULL

INSERT INTO products VALUES (1,'Laptop','14 inch business laptop',450000.00,12);
INSERT INTO products VALUES (2,'Wireless Mouse','Bluetooth mouse',9500.00,120);
INSERT INTO products VALUES (3,'Office Chair','Ergonomic chair',75000.00,0);
INSERT INTO products VALUES (4,'USB-C Cable',NULL,2500.00,340);
INSERT INTO products VALUES (5,'Monitor','27 inch 4K monitor',185000.00,7);
-- product 3 has stock 0 which passes as the CHECK allows zero

INSERT INTO orders VALUES (1,1,'2026-06-01',459500.00,'delivered');
INSERT INTO orders VALUES (2,2,'2026-06-15',75000.00,'shipped');
INSERT INTO orders VALUES (3,1,'2026-07-02',187500.00,'processing');
INSERT INTO orders VALUES (4,3,'2026-07-20',9500.00,'pending');
INSERT INTO orders VALUES (5,4,'2026-08-11',2500.00,'cancelled');
-- all five status values from the list are used, customer 1 has two orders

INSERT INTO order_details VALUES (1,1,1,1,450000.00);
INSERT INTO order_details VALUES (2,1,2,1,9500.00);
INSERT INTO order_details VALUES (3,2,3,1,75000.00);
INSERT INTO order_details VALUES (4,3,5,1,185000.00);
INSERT INTO order_details VALUES (5,3,4,1,2500.00);
-- orders 1 and 3 have two lines each

-- UNIQUE on email
-- ERROR: duplicate key value violates unique constraint "customers_email_key"
-- DETAIL: Key (email)=(irina@kbtu.kz) already exists.
-- INSERT INTO customers VALUES (6,'Fake Irina','irina@kbtu.kz','+77010000000','2026-09-01');

-- NOT NULL on email
-- ERROR: null value in column "email" of relation "customers" violates not-null constraint
-- INSERT INTO customers VALUES (7,'No Email',NULL,'+77010000001','2026-09-02');

-- CHECK price >= 0
-- ERROR: new row for relation "products" violates check constraint "products_price_check"
-- INSERT INTO products VALUES (6,'Broken Item','negative price',-100.00,5);

-- CHECK stock_quantity >= 0
-- ERROR: new row for relation "products" violates check constraint "products_stock_quantity_check"
-- INSERT INTO products VALUES (7,'Ghost Item','negative stock',1000.00,-3);

INSERT INTO products VALUES (8,'Free Sample','promo item',0.00,50);
-- successful insert, price 0 passes as the rule is >= 0 and not > 0

-- CHECK valid_status, 'completed' is not in the allowed list
-- ERROR: new row for relation "orders" violates check constraint "valid_status"
-- INSERT INTO orders VALUES (6,1,'2026-09-05',1000.00,'completed');

-- the list is case sensitive so 'Pending' is rejected too
-- ERROR: new row for relation "orders" violates check constraint "valid_status"
-- INSERT INTO orders VALUES (7,1,'2026-09-06',1000.00,'Pending');

-- FOREIGN KEY on customer_id
-- ERROR: insert or update on table "orders" violates foreign key constraint "orders_customer_id_fkey"
-- DETAIL: Key (customer_id)=(99) is not present in table "customers".
-- INSERT INTO orders VALUES (8,99,'2026-09-07',1000.00,'pending');

-- CHECK quantity > 0, zero and negative both fail
-- ERROR: new row for relation "order_details" violates check constraint "order_details_quantity_check"
-- INSERT INTO order_details VALUES (6,1,1,0,450000.00);
-- INSERT INTO order_details VALUES (7,1,1,-2,450000.00);

-- ON DELETE RESTRICT on orders.customer_id
-- ERROR: update or delete on table "customers" violates foreign key constraint "orders_customer_id_fkey" on table "orders"
-- DETAIL: Key (customer_id)=(1) is still referenced from table "orders".
-- DELETE FROM customers WHERE customer_id = 1;

-- ON DELETE RESTRICT on order_details.product_id
-- ERROR: update or delete on table "products" violates foreign key constraint "order_details_product_id_fkey" on table "order_details"
-- DELETE FROM products WHERE product_id = 1;

-- ON DELETE CASCADE on order_details.order_id
SELECT order_detail_id, order_id FROM order_details ORDER BY order_detail_id;
-- 5 rows before the delete

DELETE FROM orders WHERE order_id = 1;
-- DELETE 1, lines 1 and 2 are removed automatically, 3 rows are left

SELECT order_detail_id, order_id FROM order_details ORDER BY order_detail_id;

DELETE FROM customers WHERE customer_id = 5;
-- DELETE 1, customer 5 has no orders so RESTRICT does not block it

SET search_path TO public;
-- restore the default schema at the end of the file