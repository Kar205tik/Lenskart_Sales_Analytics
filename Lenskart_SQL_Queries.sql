CREATE TABLE lenskart_sales (
    order_id VARCHAR(20),
    order_date DATE,
    city VARCHAR(100),
    states VARCHAR(100),
    sales_channel VARCHAR(50),
    store_type VARCHAR(50),
    product_category VARCHAR(100),
    quantity INT,
    unit_price NUMERIC(10,2),
    discount_percent NUMERIC(5,2),
    net_sales_amount NUMERIC(10,2),
    payment_mode VARCHAR(50),
    customer_gender VARCHAR(20),
    customer_age INT
);

SELECT * FROM lenskart_sales



-- Query 1
--Find the Top 10 cities by total revenue.
SELECT city , SUM(net_sales_amount) as total_revenue
FROM lenskart_sales
WHERE city IS NOT NULL
Group by city
order by kk DESC
LIMIT 10



-- Query 2
--Find product categories with the highest Average Order Value (AOV).


SELECT
    product_category,
    ROUND(SUM(net_sales_amount),2) AS revenue,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(net_sales_amount)/COUNT(order_id),2) AS avg_order_value
FROM lenskart_sales
GROUP BY product_category
ORDER BY avg_order_value DESC;






-- Query 3
--Find states where revenue is above the overall average state revenue.


WITH state_revenue AS (
SELECT
    states,
    SUM(net_sales_amount) AS revenue
FROM lenskart_sales
GROUP BY states
)
SELECT
    states,
    revenue
FROM state_revenue
WHERE revenue >
(
SELECT AVG(revenue)
FROM state_revenue
)
ORDER BY revenue DESC;




-- Query 4
--Find the monthly revenue trend.

SELECT 
	EXTRACT(YEAR FROM order_date) AS y,
	EXTRACT(MONTH FROM order_date)AS m,
	SUM(net_sales_amount)
FROM lenskart_sales
GROUP BY y,m
ORDER BY Y,M 





-- Query 5
--Identify product categories giving high discounts but generating below-average revenue.

WITH category_cte AS
(
SELECT
    product_category,
    AVG(discount_percent) avg_discount,
    SUM(net_sales_amount) revenue
FROM lenskart_sales
GROUP BY product_category
)

SELECT *
FROM category_cte
WHERE
avg_discount >
(
SELECT AVG(avg_discount)
FROM category_cte
)
AND revenue <
(
SELECT AVG(revenue)
FROM category_cte
);



--


-- Query 6
--Find top 5 customers (represented by order frequency) who generated the highest revenue.

SELECT
    city,
    COUNT(order_id) total_orders,
    SUM(net_sales_amount) revenue,
    ROUND(AVG(net_sales_amount),2) avg_order_value
FROM lenskart_sales
GROUP BY city
ORDER BY revenue DESC
LIMIT 5;



-- Query 7
--Har state me sabse zyada revenue kis product category ne generate kiya?

SELECT * 
FROM (
		SELECT
		    states,
		    product_category,
		    SUM(net_sales_amount) AS revenu,
			ROW_NUMBER() OVER(
			PARTITION BY STATES ORDER BY SUM(net_sales_amount) DESC
			) AS rk
		FROM lenskart_sales
		GROUP BY states, product_category
) lenskart_sales
where rk=1;
		
		
-- Query 8
--Find the Top 3 cities by revenue within each state.

SELECT * 
FROM(
SELECT city,
		states, 
		SUM(net_sales_amount) AS revenue,
		ROW_NUMBER() OVER(
		PARTITION BY states ORDER BY SUM(net_sales_amount) DESC
		) AS rk
		FROM lenskart_sales
		GROUP BY city,states
) t
where rk<=3





-- Query 9
--Find the 2nd highest revenue city in each state.


SELECT *
FROM (
       SELECT states,
	   				city,
				   SUM(net_sales_amount) AS revenue,
				   ROW_number() OVER(
				   PARTITION BY states ORDER BY SUM(net_sales_amount) DESC
				   ) AS rk
				   FROM lenskart_sales
				   GROUP BY states,city
) lenskart_sales
where rk=2;


-- Query 10
--Find each state's contribution (%) to the total company revenue.

WITH  revenue_cte AS	(
	SELECT states,
		SUM(net_sales_amount) AS revenue
			FROM lenskart_sales
			GROUP BY states
)
SELECT 
	states,
	 	revenue,
		 Round((revenue*100.0)/ SUM(revenue) OVER(),2) AS contribution_percentage
FROM revenue_cte;







-- Query 11
--Calculate Month-over-Month (MoM) Revenue Growth (%)





WITH monthly_revenue AS (
    SELECT
        EXTRACT(YEAR FROM order_date) AS year,
        EXTRACT(MONTH FROM order_date) AS month,
        SUM(net_sales_amount) AS revenue
    FROM lenskart_sales
    GROUP BY year, month
),

lag_cte AS (
    SELECT
        year,
        month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY year, month
        ) AS previous_month_revenue
    FROM monthly_revenue
)

SELECT
    year,
    month,
    revenue,
    previous_month_revenue,
    ROUND(
        ((revenue - previous_month_revenue) * 100.0)
        / previous_month_revenue,
        2
    ) AS growth_percentage
FROM lag_cte
ORDER BY year, month;







-- Query 12
--Which product categories contribute to the first 80% of total company revenue?



WITH category_wise AS(
		SELECT product_category,
			SUM(net_sales_amount) AS revenue
			FROM lenskart_sales
			GROUP BY product_category
),

running_total AS(
    SELECT product_category,
			revenue,
		SUM( revenue)
		OVER( ORDER BY revenue DESC) AS running
		FROM category_wise
),	
cumulative_percentage AS(
		SELECT product_category,
			running,revenue,
        ROUND(
    (running * 100.0) / SUM(revenue) OVER (),
    2
) AS cumulative_percentage
From running_total
)

SELECT
    product_category,
    revenue,
    running AS cumulative_revenue,
    cumulative_percentage
FROM cumulative_percentage
WHERE cumulative_percentage <= 80
ORDER BY revenue DESC;






-- Query 13
--For each month, show the current month's revenue, 
--next month's revenue, and calculate the expected change (%) compared to the next month.




WITH current_month_revenue AS(
	SELECT
		EXTRACT(MONTH FROM order_date) AS month,
		SUM(net_sales_amount) AS current_month
		FROM lenskart_sales
		GROUP BY month
),
revenue_with_next_month AS(
		SELECT month,current_month,
		LEAD(current_month) OVER(ORDER BY month) AS next_month
		FROM current_month_revenue
)
SELECT month,current_month,
			next_month, 
				next_month-current_month AS differnce
FROM revenue_with_next_month





-- Query 14
--Identify all months where revenue increased compared to the previous month.



WITH monthly_revenue AS(
		SELECT
		EXTRACT(MONTH FROM order_date) AS month,
		SUM(net_sales_amount) AS current_revenue
        FROM lenskart_sales
		GROUP BY month
),
previous_month AS(
	SELECT month,current_revenue,
	LAG(current_revenue) OVER(
	ORDER BY month
	) AS prev_month
	FROM monthly_revenue
)
SELECT month,
		current_revenue,
			prev_month
FROM previous_month
WHERE current_revenue>prev_month




-- Query 15
--Find all product categories where:
--1.Total Quantity Sold is above the company average quantity sold per category
--2.But Total Revenue is below the company average revenue per category


SELECT
    product_category,
    SUM(quantity) AS total_quantity,
    SUM(net_sales_amount) AS total_revenue
FROM lenskart_sales
GROUP BY product_category
HAVING
    
    SUM(quantity) >
    (
        SELECT AVG(total_quantity)
        FROM
        (
            SELECT
                product_category,
                SUM(quantity) AS total_quantity
            FROM lenskart_sales
            GROUP BY product_category
        ) T1
    )
AND
    SUM(net_sales_amount) <
    (
        SELECT AVG(total_revenue)
        FROM
        (
            SELECT
                product_category,
                SUM(net_sales_amount) AS total_revenue
            FROM lenskart_sales
            GROUP BY product_category
        ) T2
    )







-- Query 16
--Find the most preferred payment mode for each customer gender.


WITH payment_summary AS
(
    SELECT customer_gender,
				payment_mode,
				COUNT(order_id) AS total_order
		FROM lenskart_sales		
		GROUP BY customer_gender,payment_mode
),

ranking_cte AS
(
SELECT customer_gender,
			payment_mode,
			       total_order,
				ROW_NUMBER() OVER(
				PARTITION BY customer_gender ORDER BY total_order DESC
				) AS rk
FROM payment_summary	
)

SELECT *
FROM ranking_cte
WHERE rk=1;








-- Query 17
--Find all cities where:
--.Total Revenue is above the company average city revenue
--.AND Average Discount is below the company average discount



SELECT
    city,
    SUM(net_sales_amount) AS total_revenue,
    AVG(discount_percent) AS avg_discount
FROM lenskart_sales
GROUP BY city
HAVING

    SUM(net_sales_amount) >
    (
        SELECT AVG(total_revenue)
        FROM
        (
         SELECT
   				 city,
					SUM(net_sales_amount) AS total_revenue
		FROM lenskart_sales
		GROUP BY city  
        ) T1
    )

AND

    AVG(discount_percent) <
    (
        SELECT AVG(discount_percent)
        FROM lenskart_sales
    );





-- Query 18
--Find the Top 2 product categories (by revenue) in each state.


WITH category_wise AS(
SELECT states,
		product_category,
			SUM(net_sales_amount) AS revenue
FROM lenskart_sales
GROUP BY states,product_category
) ,
ranking_cte AS (
SELECT states,
		product_category,
		  			revenue,
				  ROW_NUMBER() OVER(
					PARTITION BY states ORDER BY revenue DESC
				  ) AS rk
FROM category_wise

)
SELECT *
FROM ranking_cte
where rk<=2;






-- Query 19
--For each sales channel (Online/Offline), 
--find the month in which it generated the highest total revenue.



WITH abc AS (
    SELECT
        sales_channel,
        EXTRACT(MONTH FROM order_date) AS month,
        SUM(net_sales_amount) AS revenue
    FROM lenskart_sales
    GROUP BY sales_channel, month
),

ranking_cte AS (
    SELECT
        sales_channel,
        month,
        revenue,
        ROW_NUMBER() OVER(
            PARTITION BY sales_channel
            ORDER BY revenue DESC
        ) AS rk
    FROM abc
)

SELECT *
FROM ranking_cte
WHERE rk = 1;





-- Query 20
--Find the percentage contribution of each payment mode to the total company revenue.




SELECT
    payment_mode,
    SUM(net_sales_amount) AS revenue,
    ROUND(
        (
            SUM(net_sales_amount) * 100.0
        ) /
        SUM(SUM(net_sales_amount)) OVER(),
        2
    ) AS contribution_percentage

FROM lenskart_sales
GROUP BY payment_mode;






-- Query 21
--The management wants to identify product categories with consistent month-over-month growth.


WITH current_revenue AS(
SELECT product_category,
		EXTRACT(MONTH FROM order_date) AS month,
		SUM(net_sales_amount) AS revenue
FROM lenskart_sales
GROUP BY product_category,month
),

lag_cte AS(
SELECT month,
			revenue,
				product_category,
		    	 LAG(revenue) OVER(
				 PARTITION BY product_category ORDER BY month
				 ) AS prev_rev
FROM current_revenue		 	
)

SELECT product_category,
					month,
					 revenue,
					 	prev_rev,
						 revenue-prev_rev AS revenue_diff,
						 ROUND(
                           (revenue-prev_rev)*100.0/
						   NULLIF(prev_rev,0)  ,2
						 ) AS growth_percent
FROM lag_cte
					   






-- Query 22
--Management wants to identify future sales trends.



WITH current_month AS(
SELECT product_category,
			EXTRACT(MONTH FROM order_date) AS month,
			  SUM(net_sales_amount) AS current_month_revenue
FROM lenskart_sales
GROUP BY product_category,month
),
lead_cte AS(
SELECT  month,
			product_category,
					current_month_revenue,
			 LEAD(current_month_revenue) OVER(
              PARTITION BY product_category ORDER BY month
			 ) AS next_month_revenue
FROM current_month	 
)
SELECT product_category,
            		month,
				 	current_month_revenue,
			  		next_month_revenue,
					next_month_revenue-current_month_revenue AS revenue_differnce,
					ROUND(
                           (next_month_revenue-current_month_revenue)*100.0/
						   NULLIF(current_month_revenue,0)  ,2
						 ) AS expect_growth_percent
FROM lead_cte
					
							  






-- Query 23
-- Customer Age Group Performance Analysis
-- Find Total Orders, Revenue, Avg Discount & Preferred Payment Mode for each Age Group (Youth, Adult, Senior)



WITH age_group AS (
SELECT
    CASE
        WHEN customer_age BETWEEN 18 AND 25 THEN 'Youth'
        WHEN customer_age BETWEEN 26 AND 40 THEN 'Adult'
        ELSE 'Senior'
    END AS age_category,
    payment_mode,
    SUM(net_sales_amount) AS revenue,
    COUNT(order_id) AS total_order,
    AVG(discount_percent) AS avg_discount
FROM lenskart_sales
GROUP BY
    CASE
        WHEN customer_age BETWEEN 18 AND 25 THEN 'Youth'
        WHEN customer_age BETWEEN 26 AND 40 THEN 'Adult'
        ELSE 'Senior'
    END,
    payment_mode
),

ranking AS (
SELECT
    revenue,
    payment_mode,
    age_category,
    total_order,
    avg_discount,
    ROW_NUMBER() OVER (
        PARTITION BY age_category
        ORDER BY total_order DESC
    ) AS rk
FROM age_group
)

SELECT
    age_category,
    payment_mode,
    total_order,
    revenue,
    avg_discount
FROM ranking
WHERE rk = 1;






--Query 24
--Management wants to identify the best performing states for expansion.
--A state will be considered Best Performing only if it satisfies all three conditions:

--1.State Revenue > Company Average State Revenue
--2.Average Discount < Company Average Discount
--3.Total Orders > Company Average Orders per State




WITH first_cte AS(
SELECT states,
		SUM(net_sales_amount) AS revenue,
		COUNT(order_id) AS total_order,
		AVG(discount_percent) AS avg_discount
FROM lenskart_Sales
GROUP BY states
),
second_cte AS (
SELECT 
		AVG(avg_discount) AS avg_state_discount,
		AVG(revenue) AS avg_state_revenue,
		AVG(total_order) AS avg_state_order
FROM first_cte		
)
SELECT 
	states,
	revenue,
	total_order,
	avg_discount
FROM first_cte
CROSS JOIN second_cte
WHERE 
  revenue>avg_state_revenue AND
  avg_discount<avg_state_discount AND
  total_order>avg_state_order
	




-- Query 25
-- Find the highest revenue-generating product category in each quarter.


WITH first_cte AS(
SELECT EXTRACT(QUARTER FROM order_date) AS  quarter_no ,
		product_category,
		SUM(net_sales_amount) AS revenue
FROM lenskart_sales
GROUP BY quarter_no,product_category
),
second_cte AS(
SELECT product_category,
        quarter_no,
		revenue,
			ROW_NUMBER() OVER(
  			PARTITION BY quarter_no ORDER BY revenue DESC
			) AS rk
FROM first_cte
)
SELECT product_category,
		revenue,
	   quarter_no
FROM second_cte
where rk=1
ORDER BY quarter_no 



--Query 26
--Management wants to identify product categories that are consistently losing sales



WITH first_cte AS(
SELECT product_category,
 		SUM(net_sales_amount)AS revenue,
		 EXTRACT(MONTH FROM order_date) AS month
FROM lenskart_sales
GROUP BY product_category,month
),
second_cte AS(
SELECT product_category,
		revenue,
		month,
		LAG(revenue) OVER(
		PARTITION BY product_category ORDER BY month
		) AS prev_revenue
FROM first_cte
),

third_cte AS(
SELECT product_category,
		revenue,
		prev_revenue,
		month,
		 CASE
		 WHEN revenue < prev_revenue THEN 1
		 ELSE 0
		 END AS decrease_flag	
FROM second_cte
)

SELECT product_category,
		revenue,
		prev_revenue
FROM (
	SELECT *,
			LAG(decrease_flag,1) OVER(PARTITION BY product_category ORDER BY month) AS prev_flag,
			LAG(decrease_flag,2) OVER(PARTITION BY product_category ORDER BY month) AS prev2_flag
	FROM third_cte
)t
WHERE decrease_flag=1 AND
       prev_flag=1   	AND
	   prev2_flag=1
ORDER BY product_category,month



--Query 27
--The management wants to classify product categories based on their contribution to total revenue.
-- ABC (Pareto) Analysis of Product Categories



WITH category_revenue AS (
    SELECT
        product_category,
        SUM(net_sales_amount) AS revenue
    FROM lenskart_sales
    GROUP BY product_category
),

revenue_analysis AS (
    SELECT
        product_category,
        revenue,
        SUM(revenue) OVER() AS total_revenue,
        SUM(revenue) OVER(
            ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_revenue
    FROM category_revenue
)

SELECT
    product_category,
    revenue,
    ROUND((revenue * 100.0 / total_revenue), 2) AS revenue_percentage,
    ROUND((running_revenue * 100.0 / total_revenue), 2) AS cumulative_percentage,
    CASE
        WHEN (running_revenue * 100.0 / total_revenue) <= 80 THEN 'A'
        WHEN (running_revenue * 100.0 / total_revenue) <= 95 THEN 'B'
        ELSE 'C'
    END AS category
FROM revenue_analysis
ORDER BY revenue DESC





-- Query 28
--Top Payment Mode in Every State
--find the highest revenue-generating payment mode for every state.



WITH first_cte AS (
SELECT states,
		payment_mode,
		SUM(net_sales_amount) AS revenue
FROM lenskart_sales
GROUP BY states,payment_mode	
),

second_cte AS(
SELECT states,
		payment_mode,
		revenue,
		ROW_NUMBER() OVER(
 					PARTITION BY states ORDER BY revenue DESC
		) AS rk
FROM first_cte
)

SELECT states,
		payment_mode,
		revenue
FROM second_cte
WHERE rk=1
ORDER BY states

		




--Query 29
-- Highest Contributing Sales Channel in Each State




WITH first_cte AS
(
SELECT  states,
    	sales_channel,
		SUM(net_sales_amount) AS revenue
FROM lenskart_sales
GROUP BY states,sales_channel
),

second_cte AS
(
 SELECT states,
 		sales_channel,
 		revenue,
	    SUM(revenue) OVER(
		PARTITION BY states
		) AS total_revenue
FROM first_cte
),
third_cte AS(
SELECT states,
		sales_channel,
		revenue,
		total_revenue,
		ROUND((revenue * 100.0 / total_revenue), 2) AS contribution_percentage,
		 ROW_NUMBER() OVER (
            PARTITION BY states
            ORDER BY revenue DESC
        ) AS rk
FROM second_cte
)

SELECT states,
    	sales_channel,
		revenue,
    	contribution_percentage
FROM third_cte
WHERE rk = 1
ORDER BY states






-- Query 30
--Revenue Growth Ranking of States (Year-over-Year / Month-over-Month)



WITH monthly_revenue AS (
    SELECT
        states,
        EXTRACT(YEAR FROM order_date) AS year,
        EXTRACT(MONTH FROM order_date) AS month,
        SUM(net_sales_amount) AS revenue
    FROM lenskart_sales
    GROUP BY states, year, month
),

previous_month AS (
    SELECT
        states,
        year,
        month,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY states
            ORDER BY year, month
        ) AS previous_revenue
    FROM monthly_revenue
),

growth_cte AS (
    SELECT
        states,
        year,
        month,
        revenue,
        previous_revenue,
        ROUND(
            ((revenue - previous_revenue) * 100.0)
            / NULLIF(previous_revenue, 0),
            2
        ) AS growth
    FROM previous_month
),

ranking_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY states
               ORDER BY growth DESC NULLS LAST
           ) AS rk
    FROM growth_cte
    WHERE growth IS NOT NULL
)
SELECT
    states,
    year,
    month,
    revenue,
    previous_revenue,
    growth
FROM ranking_cte
WHERE rk = 1;









   
