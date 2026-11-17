DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
--PART 1

CREATE TABLE departments (
 dept_id INT PRIMARY KEY,
 dept_name VARCHAR(50),
 location VARCHAR(50)
);
CREATE TABLE employees (
 emp_id INT PRIMARY KEY,
 emp_name VARCHAR(100),
 dept_id INT,
 salary DECIMAL(10,2),
 FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
CREATE TABLE projects (
 proj_id INT PRIMARY KEY,
 proj_name VARCHAR(100),
 budget DECIMAL(12,2),
 dept_id INT,
 FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
-- Insert sample data
INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');
INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);
INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);


--PART 2

-- 2.1

CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

-- Ans: 2 indexes -> emp_salary_idx and emp_id as it's a PRIMARY KEY

-- 2.2

CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;

--Ans: we use JOINs with foreign keys therefore it would be easier if we could find
-- matching rows with indexes instead os scanning and it is faster

-- 2.3

SELECT
 tablename,
 indexname,
 indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

--departments,departments_pkey
-- employees,emp_dept_idx
-- employees,emp_salary_idx
-- employees,employees_pkey
-- projects,projects_pkey

-- _pkey keys were created automatically bc they are PRIMARY KEYs


-- PART 3

-- 3.1

CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

-- ANS: no, as the data is sorted inside each dept_id therefore it can be efficient only if you
--search for specific salary in specific department, otherwise a lot of time would be spent on
-- searching for the right department

-- 3.2

CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
--360 ms
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
-- 345 ms

-- yes, the order matters as the data is being sorted inside the salary therefore
-- search for a specific dept_id inside a known salary bracket would be quicker

-- PART 4

-- 4.1

ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

--ERROR:  duplicate key value violates unique constraint "emp_email_unique_idx"
--DETAIL:  Key (email)=(john.smith@company.com) already exists.


-- 4.2

ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';

-- yes, an index was automatically created. it is a unique b-tree index on phone


-- PART 5

-- 5.1

CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

-- this index stores already sorted salaries therefore sorting can be skipped -> faster

-- 5.2

CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;


-- PART 6

-- 6.1

CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';

-- without this index postgresql would read every row, calculate lower() and compare with 'john smith'


-- 6.2

ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- PART 7

-- 7.1

ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- 7.2

DROP INDEX emp_salary_dept_idx;

-- every index has a cost -> it slows down updates, deletes, inserts as it updates its own data
-- it takes up disk memory

-- 7.3

REINDEX INDEX employees_salary_index;

-- Part 8

-- 8.1

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

-- optimized:

-- Index for the WHERE clause
CREATE INDEX emp_salary_filter_idx ON employees(salary)
WHERE salary > 50000;

-- Index for the JOIN
CREATE INDEX emp_dept_idx ON employees(dept_id);

-- Index for ORDER BY
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

-- 8.2

CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

-- partial index stored values that match its WHERE condition -> its smaller in taken space
-- cheaper and faster

-- 8.3

EXPLAIN SELECT * FROM employees WHERE salary > 52000;

-- output shows s seq scan even though several indexes on salary exist -> postgresql
-- cost-based planner decided that reading directly is cheaper


-- PART 9

-- 9.1

CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';

-- hash is used for determining whether some string is equal to smth stored in the table
-- it cannot be used to sort the data

-- 9.2

CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

SELECT * FROM projects WHERE proj_name = 'Website Redesign';

SELECT * FROM projects WHERE proj_name > 'Database';



-- pART 10

-- 10.1

SELECT
 schemaname,
 tablename,
 indexname,
 pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- the largest indexes are the two hash indexes 32kb each, every b-tree is 16kb
-- hash indexes take up more space due to storage conditions - buckets, bitmap page, metapages


-- 10.2

DROP INDEX IF EXISTS proj_name_hash_idx;

-- 10.3

CREATE VIEW index_documentation AS
SELECT
 tablename,
 indexname,
 indexdef,
 'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
 AND indexname LIKE '%salary%';
SELECT * FROM index_documentation;


-- SUMMARY QUESTIONS

-- 1. b-tree
-- 2. columns that are frequently used, foreign keys columns and other columns used in JOIN conditions, order by columns
-- 3. small tables, very frequently used update,insert,delete -> will be slow
-- 4. update is done automatically
-- 5. using EXPLAIN


