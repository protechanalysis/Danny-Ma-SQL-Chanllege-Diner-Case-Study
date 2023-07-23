-- creating a table that contains ingridients name, exclusions, extras name
-- Step 1: Run the entire SQL query to create the table and populate it with data
CREATE TABLE tab_order_delivered AS
WITH RECURSIVE top AS (
    -- Initial part: Extract the first topping and remaining toppings for each pizza
    SELECT
        pizza_id,
        SUBSTRING_INDEX(toppings, ',', 1) AS toppings,
        SUBSTRING(toppings, LENGTH(SUBSTRING_INDEX(toppings, ',', 1)) + 2) AS remaining_toppings
    FROM
        pizza_recipes
    -- Recursive part: Continue extracting remaining toppings until none are left
    UNION ALL
    SELECT
        pizza_id,
        SUBSTRING_INDEX(remaining_toppings, ',', 1) AS toppings,
        SUBSTRING(remaining_toppings, LENGTH(SUBSTRING_INDEX(remaining_toppings, ',', 1)) + 2) AS remaining_toppings
    FROM
        top
    WHERE
        remaining_toppings <> ''
),
-- Step 2: Join pizza names, toppings, and pizza toppings to get the final ingredients of each pizza
ing AS (
    SELECT
        pizza_name,
        pizza_id,
        topping_name
    FROM
        pizza_names
    INNER JOIN top USING (pizza_id)
    INNER JOIN pizza_toppings ON toppings = topping_id
),
-- Step 3: Get the most commonly added extra topping from customer orders
fg AS (
    SELECT
        pizza_name,
        pizza_id,
        GROUP_CONCAT(topping_name) AS ingredients
    FROM
        ing
    GROUP BY
        pizza_name,
        pizza_id
),
new_customer_order AS (
    SELECT
        order_id,
        customer_id,
        pizza_id,
        exclusions,
        extras,
        order_time,
        ROW_NUMBER() OVER () AS sef
    FROM
        customer_orders
),
add_exclusion AS (
    SELECT
        order_id,
        customer_id,
        pizza_id,
        SUBSTRING_INDEX(SUBSTRING_INDEX(exclusions, ',', numbers.n), ',', -1) AS exclusions,
        extras,
        sef
    FROM
        new_customer_order
    CROSS JOIN (
        SELECT 1 AS n UNION ALL
        SELECT 2 AS n
    ) AS numbers
    ON CHAR_LENGTH(exclusions) - CHAR_LENGTH(REPLACE(exclusions, ',', '')) >= numbers.n - 1
    ORDER BY
        order_id
),
add_extra AS (
    SELECT
        order_id,
        customer_id,
        pizza_id,
        SUBSTRING_INDEX(SUBSTRING_INDEX(extras, ',', numbers.n), ',', -1) AS extras,
        exclusions,
        sef
    FROM
        add_exclusion
    CROSS JOIN (
        SELECT 1 AS n UNION ALL
        SELECT 2 AS n
    ) AS numbers
    ON CHAR_LENGTH(extras) - CHAR_LENGTH(REPLACE(extras, ',', '')) >= numbers.n - 1
    ORDER BY
        order_id
),
top_name AS (
    SELECT
        order_id,
        customer_id,
        pizza_id,
        extras,
        exclusions,
        c.topping_name AS extra,
        b.topping_name AS exclusion,
        sef
    FROM
        add_extra
    LEFT JOIN pizza_toppings AS c ON extras = c.topping_id
    LEFT JOIN pizza_toppings AS b ON exclusions = b.topping_id
),
top_name_row AS (
    SELECT
        sef,
        GROUP_CONCAT(DISTINCT exclusion) AS exclusions_name,
        GROUP_CONCAT(DISTINCT extra) AS extras_name
    FROM
        top_name
    GROUP BY
        sef
)
SELECT
    order_id,
    customer_id,
    pizza_id,
    exclusions,
    extras,
    exclusions_name,
    extras_name,
    order_time,
    ingredients
FROM
    new_customer_order
INNER JOIN top_name_row USING (sef)
INNER JOIN fg USING (pizza_id)
INNER JOIN runner_orders USING(order_id)
where cancellation = 'Not cancelled';

-- Step 2: After the query has been executed successfully, the new table "new_table" will be created with the results.
