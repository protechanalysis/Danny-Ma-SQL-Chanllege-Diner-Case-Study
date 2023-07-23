CREATE TABLE runner_ratings AS 
SELECT *, FLOOR(1 + RAND() * 5) AS rating
FROM runner_orders
WHERE cancellation = 'Not cancelled';
