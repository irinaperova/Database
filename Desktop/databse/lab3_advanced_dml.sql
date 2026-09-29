CREATE DATABASE advanced_lab;
\c advanced_lab

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name varchar(50),
    last_name varchar(50),
    department varchar(50) DEFAULT 'Unassigned',
    salary integer default 40000,
    hire_date DATE,
    status varchar(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name varchar(50),
    budget integer,
    manager_id integer
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name varchar(100),
    dept_id integer,
    start_date date,
    end_date date,
    budget integer
);

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES
    ('CRM System',       1, '2022-01-10', '2022-12-31', 120000),
    ('Website Redesign', 2, '2022-03-01', '2022-11-30',  35000),
    ('Sales Automation', 1, '2023-02-15', '2024-06-30',  80000),
    ('Payroll Upgrade',  3, '2023-05-01', '2024-12-31',  95000);

--Insert data into employees table specifying only certain columns (emp_id, first_name,
--last_name, department)--

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (100, 'Irina', 'Perova', 'IT');

--Insert a row into employees where salary uses DEFAULT value and status uses DEFAULT
--value.

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Anastasia', 'Volkova', 'HR', DEFAULT, '2026-09-01', DEFAULT);

--Insert 3 departments using one INSERT statement with multiple VALUES clauses.

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('IT', 100000, 1),
    ('HR', 40000, 2),
    ('Logistics', 2000, 3);

--Insert an employee where hire_date is calculated as current date and salary is calculated as
--50000 * 1.1.

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Ruslan', 'Koshkin', 'IT', 50000 * 1.1, CURRENT_DATE);

--Create a temporary table ‘temp_employees’ and insert data from employees table where
--department equals ‘IT’.

CREATE TEMP TABLE temp_employees (
    emp_id      INTEGER,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    department  VARCHAR(50),
    salary      INTEGER,
    hire_date   DATE,
    status      VARCHAR(20)
);

INSERT INTO temp_employees
SELECT * FROM employees
WHERE department = 'IT';

--Increase all employee salaries by 10% using UPDATE with multiplication.

UPDATE employees
SET salary = salary * 1.1;

--Update employee status to ‘Senior’ where salary is greater than 60000 AND hire_date is
--before ‘2020-01-01’.

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
    AND hire_date < '2020-01-01';

--Update employee department using CASE: - If salary > 80000 then department =
--‘Management’ - If salary between 50000 and 80000 then department = ‘Senior’ - Else
--department = ‘Junior’

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 and 80000 THEN 'Senior'
    ELSE 'Junior'
END;

--Set department to DEFAULT value for employees where status equals ‘Inactive’.

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

--Update department budget to be 20% higher than the average salary of employees in that
--department

UPDATE departments
SET budget = (
    SELECT AVG(employees.salary) *1.2
    FROM employees
    WHERE employees.department = departments.dept_name
    )
WHERE dept_name IN (SELECT DISTINCT department FROM employees);

--Update employees set salary = salary * 1.15 and status = ‘Promoted’ where department =
--‘Sales’ in single statement.

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

--Delete all employees where status equals ‘Terminated’.

DELETE FROM employees
WHERE status = 'Terminated';

--Delete employees where salary < 40000 AND hire_date > ‘2023-01-01’ AND department IS
--NULL.

DELETE FROM employees
WHERE salary < 40000
    AND hire_date > '2023-01-01'
    AND department IS NULL;

--Delete departments where dept_id NOT IN (SELECT DISTINCT department FROM
--employees WHERE department IS NOT NULL).

DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT employees.department
    FROM employees
    WHERE department IS NOT NULL
    );

--Delete all projects where end_date < ‘2023-01-01’ and return all deleted data.

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

--Insert employee with NULL salary and NULL department.

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Karina', 'Petrova', NULL, NULL, '2023-01-01');

--Update all employees set department = ‘Unassigned’ where department IS NULL.

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

--Delete all employees where salary IS NULL OR department IS NULL.

DELETE FROM employees
WHERE salary IS NULL
    OR department IS NULL;

--Insert new employee and return the auto-generated emp_id and full name (concatenated).

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Elena', 'Ivanova', 'IT', 65000, '2024-01-01')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

--Update salary for employees in ‘IT’ department (increase by 5000) and return emp_id, old
--salary, and new salary.

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id,
    salary - 5000 AS old_salary,
    salary AS new_salary;

--Delete employees where hire_date < ‘2020-01-01’ and return all columns of deleted rows.

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

--Write INSERT that only adds employee if no employee with same first_name and last_name
--already exists (use WHERE NOT EXISTS).

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
SELECT 'Karina', 'Petrova', 'IT', 35000, '2024-09-01'
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'Karina'
    AND last_name = 'Petrova'
);

--Update employee salaries based on department budget: if department budget > 100000,
--increase salary by 10%, otherwise by 5%.

UPDATE employees
SET salary = CASE
    WHEN  (SELECT departments.budget
           FROM departments
           WHERE departments.dept_name = employees.department) > 100000
    THEN salary * 1.10
    ELSE salary * 1.05
END
WHERE department IN (SELECT departments.dept_name FROM departments);

--Insert 5 employees in single statement, then update all their salaries to be 10% higher in
--single UPDATE.

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('Zhanar', 'Iskakova', 'Logistics', 42000, '2024-08-02', 'New'),
    ('Yulia', 'Vlasova', 'HR', 50000, '2023-05-02', 'New'),
    ('Dahlia', 'Smith', 'HR', 70000, '2024-07-20', 'New'),
    ('Maksim', 'Kuchkin', 'IT', 40000, '2025-03-04', 'New'),
    ('Arseniy', 'Kovalev', 'IT', 40000, '2023-06-17', 'New');

UPDATE employees
SET salary = salary * 1.1
WHERE status = 'New';

--Create new table ‘employee_archive’, move all employees with status ‘Inactive’ from
--employees to employee_archive, then delete them from original table.

CREATE TABLE employee_archive (
    emp_id      INTEGER,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    department  VARCHAR(50),
    salary      INTEGER,
    hire_date   DATE,
    status      VARCHAR(20),
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO employee_archive (emp_id, first_name, last_name, department, salary, hire_date, status)
SELECT employees.emp_id, employees.first_name, employees.last_name, employees.department,employees.salary, employees.hire_date, employees.status
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

--Update project end_date to be 30 days later for projects where budget > 50000 AND
--associated department has more than 3 employees.

UPDATE projects
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
    AND dept_id IN (
        SELECT d.dept_id
        FROM departments d
        WHERE (SELECT COUNT(*)
               FROM employees e
               WHERE e.department = d.dept_name) > 3
    );

