CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  -- 1. What is the total amount each customer spent at the restaurant?

  SELECT sales.customer_id, SUM(menu.price) AS Total_Amount
  FROM menu 
  JOIN sales 
  ON menu.product_id= sales.product_id
  GROUP BY sales.customer_id

  -- 2. How many days has each customer visited the restaurant?
  
  SELECT customer_id, COUNT(DISTINCT order_date) AS Number_Of_Days
  FROM sales 
  GROUP BY customer_id

  -- 3. What was the first item from the menu purchased by each customer?

  WITH final AS(
				SELECT s.*, m.product_name,
				RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rank
				FROM menu as m
				JOIN sales as s
				ON m.product_id = s.product_id
				)
SELECT * FROM final
WHERE rank = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(*) AS mostpurchaseditems
FROM menu as m
JOIN sales as s
ON m.product_id = s.product_id
GROUP BY product_name

-- 5. Which item was the most popular for each customer?

WITH final AS (
			SELECT s.customer_id, product_name, COUNT(*) as mostpopular
			FROM menu as m
			JOIN sales as s
			ON m.product_id = s.product_id
			GROUP BY product_name, s.customer_id
)
SELECT *, 
RANK() OVER (PARTITION BY customer_id ORDER BY mostpopular desc) AS rank
FROM final 

--6. Which item was purchased first by the customer after they became a member?

WITH final AS(
SELECT s.customer_id, me.product_name,
RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS Ranking
FROM [Danny's Dinner Database].[dbo].[sales] AS s
LEFT JOIN [Danny's Dinner Database].[dbo].[members] AS m
ON s.customer_id = m.customer_id
JOIN [Danny's Dinner Database].[dbo].[menu] AS me
ON s.product_id = me.product_id
WHERE order_date >= join_date
)
SELECT *
FROM final
WHERE Ranking= 1

--7. Which item was purchased just before the customer became a member?

SELECT s.*, m.*, me.product_name,
RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS Ranking
FROM [Danny's Dinner Database].[dbo].[sales] AS s
LEFT JOIN [Danny's Dinner Database].[dbo].[members] AS m
ON s.customer_id = m.customer_id
JOIN [Danny's Dinner Database].[dbo].[menu] AS me
ON s.product_id = me.product_id
WHERE join_date >= order_date

--8. What is the total items and amount spent for each member before they became a member?

WITH final AS(
SELECT s.customer_id, s.order_date, m.join_date, me.product_name, me.price
FROM [Danny's Dinner Database].[dbo].[sales] AS s
JOIN [Danny's Dinner Database].[dbo].[menu] AS me
ON me.product_id = s.product_id
LEFT JOIN [Danny's Dinner Database].[dbo].[members] AS m
ON m.customer_id = s.customer_id
WHERE order_date < join_date
)
SELECT customer_id, SUM(price) AS Amount_spent, COUNT(DISTINCT product_name) AS Total_items
FROM final
GROUP BY customer_id

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH final AS(
SELECT s.customer_id, s.order_date, me.product_name, me.price,
CASE 
	WHEN product_name = 'sushi' THEN 2*me.price
	ELSE me.price 
	END AS Newprice
FROM [Danny's Dinner Database].[dbo].[sales] AS s
JOIN [Danny's Dinner Database].[dbo].[menu] AS me
ON me.product_id = s.product_id
)
SELECT customer_id, SUM(Newprice)*10 AS Points
FROM final
GROUP BY customer_id


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
--how many points do customer A and B have at the end of January?

WITH final AS(
				SELECT s.customer_id, s.order_date, m.join_date, me.product_name, me.price,
				CASE 
					WHEN product_name = 'sushi' THEN 2*me.price
					WHEN s.order_date BETWEEN m.join_date THEN 2*price
					ELSE me.price 
					END AS Newprice
				FROM [Danny's Dinner Database].[dbo].[sales] AS s
				JOIN [Danny's Dinner Database].[dbo].[menu] AS me
				ON me.product_id = s.product_id
				JOIN [Danny's Dinner Database].[dbo].[members] AS m
				ON m.customer_id = s.customer_id
				WHERE order_date = '2021-01-31'
)
SELECT customer_id, SUM(Newprice)*10 AS Final_Points
FROM final
GROUP BY customer_id


