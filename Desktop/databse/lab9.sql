-- PART 2

-- 2.1

CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date INTO v_days
      FROM rentals
     WHERE rental_id = p_rental_id;
    RETURN v_days;
END; $$
LANGUAGE plpgsql;

SELECT rental_days(2);
SELECT rental_days(11);
SELECT rental_days(19);
SELECT rental_days(999);

-- Q: both can return NULL but reasons are different.
-- rental 19 exists but its end_date is NULL -> start_date = NULL
-- rental 999 doesnt exist so initial value is NULL

-- 2.2

CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT) RETURNS INT AS $$
DECLARE
    v_cnt INT;
BEGIN
    SELECT COUNT(*) INTO v_cnt
      FROM rentals
     WHERE member_id = p_member_id;
    RETURN v_cnt;
END; $$
LANGUAGE plpgsql;

SELECT member_rental_count(1) AS m1,
       member_rental_count(5) AS m5,
       member_rental_count(6) AS m6,
       member_rental_count(99) AS m99;

-- Q: COUNT * counts the rows it receives and the count of xero is 0
-- so member 6 and member 99 both give 0

-- 2.3

CREATE OR REPLACE FUNCTION station_city(p_station_id INT) RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city INTO v_city
      FROM stations
     WHERE station_id = p_station_id;
    RETURN v_city;
END; $$
LANGUAGE plpgsql;

SELECT station_city(30);
SELECT station_city(77);

-- 2.4

SELECT rental_id, member_id, rental_days(rental_id) AS days
  FROM rentals
 WHERE rental_days(rental_id) > 4
 ORDER BY days DESC, rental_id;


-- PART 3

-- 3.1

CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (100 - p_percent) / 100, 2);
END; $$
LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);

-- 3.2

CREATE OR REPLACE FUNCTION member_stats(
    p_member_id    INT,
    OUT rental_cnt INT,
    OUT total_fee  NUMERIC,
    OUT last_start DATE)
AS $$
BEGIN
    SELECT COUNT(*), COALESCE(SUM(fee), 0), MAX(start_date)
      INTO rental_cnt, total_fee, last_start
      FROM rentals
     WHERE member_id = p_member_id;
END; $$
LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);

-- q: SELECT member_stats(3) return one cilumn holding a single composite value
-- SELECT * FROM uses the function as a row source so the three
-- OUT parameters become three named columns

-- 3.3

CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC) AS $$
BEGIN
    p_fee := p_fee + 5.00;
END; $$
LANGUAGE plpgsql;

SELECT rental_id, fee, apply_late_fee(fee) AS fee_with_late_charge
  FROM rentals
 WHERE rental_id = 1;

-- Q: INOUT is also an output parameter. when a function has output parameters
-- the return type is taken from them so no RETURNS clause is needed

-- 3.4

CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total   NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC)
AS $$
BEGIN
    SELECT SUM(p_fees[i]), ROUND(AVG(p_fees[i]), 2), MAX(p_fees[i])
      INTO total, average, largest
      FROM generate_subscripts(p_fees, 1) g(i);
END; $$
LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
SELECT * FROM fee_summary(VARIADIC ARRAY[13.50, 35.00, 18.50, 31.50]);
SELECT * FROM fee_summary();

-- Q: a call with no arguments fails: a VARIADIC parameter needs at least one actual argument to collect

-- 3.5

-- A - IN
-- B - INOUT
-- C - VARIADIC
-- D - two OUT parameters


-- part 4

-- 4.1

CREATE OR REPLACE FUNCTION total_fees(p_member_id INT) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO v_total
      FROM rentals
     WHERE member_id = p_member_id;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1) AS member_1, total_fees(6) AS member_6;

-- 4.2

CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO v_total
      FROM rentals
     WHERE member_id = p_member_id
       AND start_date >= p_from_date;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');
SELECT total_fees(1, DATE '2025-01-01');

\df total_fees

SELECT oid, proname, pg_get_function_identity_arguments(oid) AS arguments,
       pg_get_function_result(oid) AS returns
  FROM pg_proc
 WHERE proname = 'total_fees'
 ORDER BY oid;

-- 4.3

CREATE OR REPLACE FUNCTION total_fees(p_member_id INT,
                                      p_from_date DATE DEFAULT DATE '2025-01-01')
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO v_total
      FROM rentals
     WHERE member_id = p_member_id
       AND start_date >= p_from_date;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1);

-- Q: CREATE OR REPLACE kept the signature (integer, date) and only added a default, so there are still two functions.


-- 4.4

DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1);
SELECT total_fees(1, DATE '-infinity') AS all_time_total;

-- Q: Now only total_fees(integer, date) is left, so total_fees(1) fills p_from_date with the default 2025-01-01 and returns 50.00 (rentals 3 and 4; rental 19 has no fee).
-- Dropping the other version instead would leave total_fees(integer), which sums all of member 1's fees and returns 98.50 (the second query shows that all-time total).
-- So the answer depends on which version is dropped: same call, different number.


-- 4.5

CREATE OR REPLACE FUNCTION total_fees(p_full_name VARCHAR) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0) INTO v_total
      FROM members m
      JOIN rentals r ON r.member_id = m.member_id
     WHERE m.full_name = p_full_name;
    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');
SELECT total_fees(1);

\df total_fees

-- q: the new function differs in argument type so total_fees(1) still has exactly one candidate.


-- PART 5

--5.1

CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (found_id INT, found_model VARCHAR, found_rate NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT b.bike_id, b.model, b.daily_rate
          FROM bikes b
         WHERE b.model ILIKE p_pattern
         ORDER BY b.bike_id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');

-- Q: without FROM the function sits in the select list. it ctill returns two rows
-- but each row is one column named find_bikes
-- so the three fields are glued into (105, "Road Sprint", 9.25)

-- 5.2
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (h_rental_id INT, h_model VARCHAR, h_station VARCHAR,
               h_days INT, h_fee NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT r.rental_id, b.model, s.station_name,
               r.end_date - r.start_date, r.fee
          FROM rentals r
          JOIN bikes b         ON b.bike_id    = r.bike_id
          LEFT JOIN stations s ON s.station_id = b.station_id
         WHERE r.member_id = p_member_id
         ORDER BY r.start_date;
END; $$
LANGUAGE plpgsql;

SELECT * FROM member_history(3);

-- 5.3

CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- q: the sql statement inside the CREATE are parsed and planned the first time they run.

-- fix 1
DROP FUNCTION bike_list(INT);
CREATE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id
                 ORDER BY bike_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

--fix 2
DROP FUNCTION bike_list(INT);
CREATE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT b.bike_id, b.model FROM bikes b WHERE b.station_id = p_station_id
                 ORDER BY b.bike_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- 5.4

CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
        SELECT st.station_name, COUNT(b.bike_id), st.capacity - COUNT(b.bike_id)
          FROM stations st
          LEFT JOIN bikes b ON b.station_id = st.station_id
         WHERE st.city = p_city
         GROUP BY st.station_id, st.station_name, st.capacity
         ORDER BY st.station_id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');

--fixed

CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
        SELECT st.station_name,
               COUNT(b.bike_id)::INT,
               (st.capacity - COUNT(b.bike_id))::INT
          FROM stations st
          LEFT JOIN bikes b ON b.station_id = st.station_id
         WHERE st.city = p_city
         GROUP BY st.station_id, st.station_name, st.capacity
         ORDER BY st.station_id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');


--RETURN QUERY does not convert types: the query's columns must match the declared ones exactly. COUNT returns bigint, so the call fails at run time with the message above.


-- PART 6

--6.1
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report $$;

-- the label after END does not match the label at the top
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_rep $$;

--A mismatched end label is a compile-time error. The block is rejected before it runs, so nothing is executed and no notice is printed.


-- 6.2
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
    fee_total     NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;

    SELECT SUM(fee) INTO fee_total FROM rentals;
    RAISE NOTICE '1) outer fee_total before the subblock: %', fee_total;

    <<recent>>
    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT SUM(fee) INTO fee_total FROM rentals WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE '2) subblock fee_total (2025 onwards): %', fee_total;
        RAISE NOTICE '3) outer fee_total seen from the subblock: %', rental_report.fee_total;
    END recent;

    RAISE NOTICE '4) outer fee_total after the subblock: %', fee_total;
END rental_report $$;

--The four numbers are 621.50, 369.00, 621.50, 621.50. The assignment inside the subblock did not change the outer variable: the subblock declared its own fee_total, and inside the subblock the plain name refers to that inner variable, which hides the outer one.



-- 6.3

DO $$
<<rental_report>>
DECLARE
    fee_total NUMERIC;
BEGIN
    SELECT SUM(fee) INTO fee_total FROM rentals;

    <<first_sub>>
    DECLARE
        open_cnt INT;
    BEGIN
        SELECT COUNT(*) INTO open_cnt FROM rentals WHERE end_date IS NULL;
        RAISE NOTICE 'first subblock: open rentals = %', open_cnt;
    END first_sub;

    <<second_sub>>
    BEGIN
        RAISE NOTICE 'second subblock: open rentals = %', open_cnt;
    END second_sub;
END rental_report $$;



DO $$
<<rental_report>>
DECLARE
    fee_total NUMERIC;
    open_cnt  INT;
BEGIN
    SELECT SUM(fee) INTO fee_total FROM rentals;

    <<first_sub>>
    BEGIN
        SELECT COUNT(*) INTO open_cnt FROM rentals WHERE end_date IS NULL;
        RAISE NOTICE 'first subblock: open rentals = %', open_cnt;
    END first_sub;

    <<second_sub>>
    BEGIN
        RAISE NOTICE 'second subblock: open rentals = %', open_cnt;
    END second_sub;
END rental_report $$;


-- 6.4

CREATE OR REPLACE FUNCTION fee_split(p_from_date DATE,
                                     OUT before_total NUMERIC,
                                     OUT after_total  NUMERIC)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee) FILTER (WHERE start_date <  p_from_date), 0),
           COALESCE(SUM(fee) FILTER (WHERE start_date >= p_from_date), 0)
      INTO before_total, after_total
      FROM rentals;
END; $$
LANGUAGE plpgsql;

SELECT * FROM fee_split(DATE '2025-01-01');

SELECT f.before_total, f.after_total,
       f.before_total + f.after_total        AS split_sum,
       (SELECT SUM(fee) FROM rentals)        AS table_total,
       f.before_total + f.after_total = (SELECT SUM(fee) FROM rentals) AS adds_up
  FROM fee_split(DATE '2025-01-01') f;


-- PART 7

-- 7.1

CREATE OR REPLACE FUNCTION station_load(p_station_id INT,
                                        OUT bikes_parked INT,
                                        OUT capacity_pct NUMERIC)
AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT capacity INTO v_capacity FROM stations WHERE station_id = p_station_id;

    SELECT COUNT(*) INTO bikes_parked FROM bikes WHERE station_id = p_station_id;

    capacity_pct := ROUND(100.0 * bikes_parked / NULLIF(v_capacity, 0), 1);
END; $$
LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
  FROM stations s, LATERAL station_load(s.station_id) l;


-- 7.2

CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (t_member VARCHAR, t_rentals INT, t_spent NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT m.full_name,
               COUNT(r.rental_id)::INT,
               COALESCE(SUM(r.fee), 0)
          FROM members m
          LEFT JOIN rentals r ON r.member_id = m.member_id
         GROUP BY m.member_id, m.full_name
         ORDER BY 3 DESC, m.member_id
         LIMIT p_limit;
END; $$
LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);



--Aisha Nurlanova has 5 rentals, more than Daniyar Serik and Chen Wei (4 each), but she is ranked 4th, below them. This is not a bug: the ranking is by amount spent, not by number of rentals. Her rentals were short and on cheaper bikes, and rental 19 is still open with a NULL fee, which SUM ignores, so it adds a rental to her count but nothing to her total.


-- 7.3

CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (i_member VARCHAR, i_model VARCHAR, i_days INT,
               i_amount NUMERIC, i_status VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT m.full_name,
               b.model,
               COALESCE(r.end_date, CURRENT_DATE) - r.start_date,
               ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date) * b.daily_rate, 2),
               (CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END)::VARCHAR
          FROM rentals r
          JOIN members m ON m.member_id = r.member_id
          JOIN bikes   b ON b.bike_id   = r.bike_id
         WHERE r.rental_id = p_rental_id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);
SELECT i.i_amount, r.fee, i.i_amount = r.fee AS matches
  FROM rental_invoice(11) i, rentals r
 WHERE r.rental_id = 11;
SELECT CURRENT_DATE AS run_date;

--Yes: for rental 11 the calculated amount (8 days × 9.25 = 74.00) equals the stored fee 74.00. For rental 19 the number of days is CURRENT_DATE - 2025-10-10, so it grows by one each day and the amount grows by 4.50 per day; on 2026-11-24 it is 410 days and 1845.00.


-- 7.4

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (c_members INT, c_rentals INT, c_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT COUNT(DISTINCT m.member_id)::INT,
               COUNT(r.rental_id)::INT,
               COALESCE(SUM(r.fee), 0)
          FROM members m
          LEFT JOIN rentals r ON r.member_id = m.member_id
         WHERE m.city = p_city;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (c_members INT, c_rentals INT, c_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
        SELECT COUNT(DISTINCT m.member_id)::INT,
               COUNT(r.rental_id)::INT,
               COALESCE(SUM(r.fee), 0)
          FROM members m
          LEFT JOIN rentals r ON r.member_id = m.member_id
                             AND r.start_date >= p_from_date
         WHERE m.city = p_city;
END; $$
LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');
SELECT * FROM city_report('Astana');
SELECT * FROM city_report('Astana', DATE '2025-01-01');

-- the date condition moved into WHERE, for comparison
SELECT COUNT(DISTINCT m.member_id) AS c_members,
       COUNT(r.rental_id)          AS c_rentals,
       COALESCE(SUM(r.fee), 0)     AS c_revenue
  FROM members m
  LEFT JOIN rentals r ON r.member_id = m.member_id
 WHERE m.city = 'Almaty'
   AND r.start_date >= DATE '2025-01-01';


-- LAB Q

-- 1 The name is just the identifier, for example total_fees. The signature is the name together with the list of input argument types, for example total_fees(integer, date); return type and parameter names are not part of it. With overloading several functions share one name, so the name alone does not say which one to drop.

-- 2 $$ ... $$ delimits the function body as a string in which single quotes need no escaping. Without it the whole body is an ordinary string literal, and every quote inside must be doubled

-- 3 Several OUT parameters fit when the function returns exactly one row of a few values, such as member_stats or fee_split: one query fills them and the function can be used like a single record. RETURNS TABLE fits when the function returns any number of rows, such as find_bikes or member_history

-- 4 The VARIADIC parameter takes all remaining positional arguments.

-- 5 RETURN expression ends the function and returns one value. RETURN QUERY select does not end the function: it appends all rows of the query to the result set of a set-returning function

-- 6  A default lets a function be called with fewer arguments, so its set of possible calls grows.

-- 7 A variable declared in a subblock exists only while that subblock runs. When the subblock ends, the variable is gone: the outer block cannot read it, and a later subblock cannot either

-- 8 Advantage: the rule is defined once inside the database, so every application, report and script uses the same logic and the work costs one round trip.

-- 9 A trusted language such as PL/pgSQL cannot reach outside the database server: no file system, no network, no operating-system calls.

-- 10  It does not replace anything. The signature includes the argument types, so a different list is a different function, and PostgreSQL creates a new, second function with the same name. The old one stays in the database.



