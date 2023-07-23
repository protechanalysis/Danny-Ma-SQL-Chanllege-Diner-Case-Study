-- Step 1: Create a temporary table to store intermediate results
CREATE TEMPORARY TABLE temp_pizza_ingredients AS
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
        topping_id,
        topping_name
    FROM
        pizza_names
    INNER JOIN
        top USING (pizza_id)
    INNER JOIN
        pizza_toppings ON toppings = topping_id
)
SELECT * FROM ing;

-- Step 3: Insert data from the temporary table into the pizza_ingredients table
INSERT INTO pizza_ingredients (pizza_name, pizza_id, topping_id, topping_name)
SELECT pizza_name, pizza_id, topping_id, topping_name FROM temp_pizza_ingredients;

-- Step 4: Drop the temporary table
DROP TEMPORARY TABLE temp_pizza_ingredients;
