----- What are the standard ingredients for each pizza?
----- the above cte is to split the pizza recipes toppings e.g(1,5) row into two rows retaining their id the 'recursive' is to looping
-- Step 1: Recursive CTE to extract individual toppings from the 'toppings' column in pizza recipes
with recursive top as (
-- Initial part: Extract the first topping and remaining toppings for each pizza
	select pizza_id, substring_index(toppings, ',',1) as toppings,
    substring(toppings, length(substring_index(toppings, ',',1)) +2) as remaining_toppings
    from pizza_recipes
    -- Recursive part: Continue extracting remaining toppings until none are left
    union all
    select pizza_id, substring_index(remaining_toppings, ',',1) as toppings,
    substring(remaining_toppings, length(substring_index(remaining_toppings, ',',1)) +2) as remaining_toppings
    from top
    where remaining_toppings <> ''
    ),
    -- Step 2: Join pizza names, toppings, and pizza toppings to get the final ingredients of each pizza
 ing as (
select pizza_name, topping_name
from pizza_names
inner join top
using(pizza_id)
inner join pizza_toppings
on toppings = topping_id
)
-- Step 3: Get the most commonly added extra topping from customer orders
select pizza_name, group_concat(topping_name) as ingridients 
from ing
group by pizza_name;
----- group_concat is to convert multiple rows in a single rows having the same id


----- What was the most commonly added extra?
----- the above cte is to split the extras e.g(1,5) row into two rows retaining their id the 'recursive' is to looping
with recursive extra as (
	select order_id, substring_index(extras, ',',1) as extras,
    substring(extras, length(substring_index(extras, ',',1)) +2) as remaining_extras
    from customer_orders
    union all
    select order_id, substring_index(remaining_extras, ',',1) as extras,
    substring(remaining_extras, length(substring_index(remaining_extras, ',',1)) +2) as remaining_extras
    from extra
    where remaining_extras <> ''
    )
    
select topping_name, count(extras) as num_times_extra
from extra
inner join pizza_toppings
on extras = topping_id
group by topping_name
limit 1;

----- What was the most common exclusion?
-- Step 1: Recursive CTE to extract individual exclusions from the 'exclusions' column
WITH RECURSIVE exclusion AS (
    -- Initial part: Extract the first exclusion and remaining exclusions for each order
    SELECT
        order_id,
        SUBSTRING_INDEX(exclusions, ',', 1) AS exclusions,
        SUBSTRING(exclusions, LENGTH(SUBSTRING_INDEX(exclusions, ',', 1)) + 2) AS remaining_exclusion
    FROM
        customer_orders
    UNION ALL
    -- Recursive part: Continue extracting remaining exclusions until none are left
    SELECT
        order_id,
        SUBSTRING_INDEX(remaining_exclusion, ',', 1) AS exclusions,
        SUBSTRING(remaining_exclusion, LENGTH(SUBSTRING_INDEX(remaining_exclusion, ',', 1)) + 2) AS remaining_exclusion
    FROM
        exclusion
    WHERE
        remaining_exclusion <> ''
)

-- Step 2: Find the topping that is most frequently excluded from customer orders
SELECT
    topping_name,
    COUNT(exclusions) AS num_times_excluded
FROM
    exclusion
INNER JOIN
    pizza_toppings
ON
    exclusions = topping_id
GROUP BY
    topping_name
ORDER BY
    num_times_excluded DESC
LIMIT 1;


----- Generate an order item for each record in the customers_orders table in the format of one of the following: Meat Lovers, Meat Lovers - Exclude Beef, Meat Lovers - Extra Bacon, Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- Step 1: Retrieve order details and assign sequential numbers to each row
WITH new_customer_order AS (
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

-- Step 2: Extract individual exclusion toppings from the 'exclusions' column
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
    ORDER BY order_id
),

-- Step 3: Extract individual extra toppings from the 'extras' column
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
    ORDER BY order_id
),

-- Step 4: Map the extracted toppings to their respective names
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
    LEFT JOIN pizza_toppings AS c
    ON extras = c.topping_id
    LEFT JOIN pizza_toppings AS b
    ON exclusions = b.topping_id
),

-- Step 5: Group the results to concatenate exclusion and extra names
top_name_row AS (
    SELECT
        sef,
        GROUP_CONCAT(DISTINCT exclusion) AS exclusions_name,
        GROUP_CONCAT(DISTINCT extra) AS extras_name
    FROM
        top_name
    GROUP BY sef
)

-- Step 6: Generate a summary of the order items based on pizza type, exclusions, and extras
SELECT
    order_id,
    customer_id,
    pizza_id,
    exclusions,
    extras,
    exclusions_name,
    extras_name,
    CASE
        WHEN exclusions IS NULL AND extras_name IS NULL AND pizza_id = 1 THEN 'Meat lovers'
        WHEN exclusions IS NOT NULL AND extras_name IS NULL AND pizza_id = 1 THEN CONCAT('Meat lovers - Exclude ', exclusions_name)
        WHEN exclusions IS NULL AND extras_name IS NOT NULL AND pizza_id = 1 THEN CONCAT('Meat lovers - Extra ', extras_name)
        WHEN exclusions IS NOT NULL AND extras_name IS NOT NULL AND pizza_id = 1 THEN CONCAT('Meat lovers - Exclude ', exclusions_name, ' Extra ', extras_name)
        WHEN exclusions IS NULL AND extras_name IS NULL AND pizza_id = 2 THEN 'Vegetarian'
        WHEN exclusions IS NOT NULL AND extras_name IS NULL AND pizza_id = 2 THEN CONCAT('Vegetarian - Exclude ', exclusions_name)
        WHEN exclusions IS NULL AND extras_name IS NOT NULL AND pizza_id = 2 THEN CONCAT('Vegetarian - Extra ', extras_name)
        ELSE CONCAT('Vegeterian - Exclude ', exclusions_name, 'Extra ', extras_name)
    END AS order_item,
    order_time
FROM
    new_customer_order
INNER JOIN top_name_row
USING (sef);

