 monday_cofee_data_analysis
 select* from city;
 select* from products;
 select* from customers; 
 select* from sales;

--Reports and data analysis 
--How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name,round((population*0.25)/1000000,2) as coffee_consumers_in_millions,city_rank
from city

order by 2 desc



--What is the total revenue generated from coffee sales across all the cities in the last quarter of 2023?

select 
sum(total) as total_revenue
from sales
where 
extract (year from sale_date) = 2023
and
extract (quarter from sale_date)= 4
 

select
ci.city_name,
sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
where 
extract (year from s.sale_date) = 2023
and
extract (quarter from s.sale_date)= 4
group by 1 
order by 2 desc 

--salescount for each year
--how many unit of coffee product have been sold?

select
p.product_name,
count(s.sale_id) as total_orders
from products as p
left join
sales as s
on s.product_id = p.product_id
group by 1
order by 2 desc


--Average Sales Amount per City
--What is the average sales amount per customer in each city?


 select
ci.city_name,
sum(s.total) as total_revenue,
count(distinct s.customer_id) as total_customers,
round(
sum(s.total)::numeric/count(distinct s.customer_id)::numeric,2) as avg_sales_per_cust
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1 
order by 2 desc 


--City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.



with city_table as
(
SELECT
city_name,
ROUND ((population * 0.25)/1000000, 2) as coffee_consumers
FROM city
),

customers_table
as
(
SELECT 
ci.city_name,
COUNT (DISTINCT c.customer_id) as unique_cx
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
)

SELECT
customers_table.city_name,
city_table.coffee_consumers as coffee_consumer_in_million,
customers_table.unique_cx
FROM city_table 
JOIN
customers_table 
ON city_table.city_name = customers_table.city_name


--Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?


SELECT * 
FROM -- table
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
	-- ORDER BY 1, 3 DESC
) as t1
WHERE rank <= 3



--Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?


SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1



-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer


with city_table
as
(
SELECT 
    ci.city_name, 
    COUNT(DISTINCT s.customer_id) AS total_customers, 
    ROUND(SUM(s.total)::NUMERIC / COUNT(DISTINCT s.customer_id)::NUMERIC, 2) AS avg_sales_per_cust 
FROM city AS ci 
JOIN customers AS c ON c.city_id = ci.city_id 
JOIN sales AS s ON s.customer_id = c.customer_id 
GROUP BY ci.city_name 
ORDER BY total_customers DESC
),

city_rent
as
(select city_name,
       estimated_rent
from city	   
)	

select cr.city_name,
       cr.estimated_rent,
	   ct.total_customers,
	   ct.avg_sales_per_cust,
	   round
	   (cr.estimated_rent:: numeric/ ct.total_customers::numeric,2) as avg_rent_per_customer
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 4 desc



--Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).


WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	



-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.