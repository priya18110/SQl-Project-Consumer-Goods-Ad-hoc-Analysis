# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.

SELECT
    DISTINCT market FROM  dim_customer
WHERE region = 'APAC' AND customer = "Atliq Exclusive";

# 2.  What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg

with cte20 as
(select count(distinct product_code) as unique_products_2020
from fact_sales_monthly
where fiscal_year = 2020),

cte21 as
(select count(distinct product_code) as unique_products_2021
from fact_sales_monthly
where fiscal_year = 2021)
select *,
           round((unique_products_2021 - unique_products_2020)/unique_products_2020*100,2) as Percentage_chg
from cte20
cross join 
cte21;

# 3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains 2 fields,
segment
product_count

select segment , count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

# 4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference

with prod_20 as(
select p.segment , count(distinct fs.product_code) as products_count_2020
from fact_sales_monthly fs
join dim_product p
on fs.product_code = p.product_code
where fs.fiscal_year = 2020
group by p.segment
),
prod_21 as(
select p.segment , count(distinct fs.product_code) as products_count_2021
from fact_sales_monthly fs
join dim_product p
on fs.product_code = p.product_code
where fs.fiscal_year = 2021
group by p.segment
)
select prod_20.segment, prod_20.products_count_2020, prod_21.products_count_2021,
 (products_count_2021 - products_count_2020) AS Difference
from prod_20
join prod_21
on prod_20.segment = prod_21.segment
order by Difference desc;

#5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost

select p.product_code, p.product, m.manufacturing_cost
from dim_product p
join fact_manufacturing_cost m
on p.product_code = m.product_code
where 
    m.manufacturing_cost  = (
                     select max(manufacturing_cost) from fact_manufacturing_cost
)
or
 m.manufacturing_cost = (
                     select min(manufacturing_cost) from fact_manufacturing_cost
);

#6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage

WITH TBL1 AS
(SELECT customer_code AS A, AVG(pre_invoice_discount_pct) AS B FROM fact_pre_invoice_deductions
WHERE fiscal_year = '2021'
GROUP BY customer_code),
     TBL2 AS
(SELECT customer_code AS C, customer AS D FROM dim_customer
WHERE market = 'India')

SELECT TBL2.C AS customer_code, TBL2.D AS customer, ROUND (TBL1.B, 4) AS average_discount_percentage
FROM TBL1 JOIN TBL2
ON TBL1.A = TBL2.C
ORDER BY average_discount_percentage DESC
LIMIT 5 

#7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount

SELECT CONCAT(MONTHNAME(FS.date), ' (', YEAR(FS.date), ')') AS 'Month', FS.fiscal_year,
       ROUND(SUM(G.gross_price*FS.sold_quantity), 2) AS Gross_sales_Amount
FROM fact_sales_monthly FS JOIN dim_customer C ON FS.customer_code = C.customer_code
						   JOIN fact_gross_price G ON FS.product_code = G.product_code
WHERE C.customer = 'Atliq Exclusive'
GROUP BY  Month, FS.fiscal_year 
ORDER BY FS.fiscal_year ;

#8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity

select 
        case 
              when month(date) IN (9,10,11) then 'Q1'
              when month(date) IN (12,1,2) then 'Q2'
              when month(date) IN (3,4,5) then 'Q3'
              else 'Q4'
              end as Quarter,
 concat(cast(round(sum(sold_quantity)/1000000,2) as char), "M") as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter 
order by total_sold_quantity desc;

#9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage


WITH temp_table AS (
      SELECT c.channel,sum(s.sold_quantity * g.gross_price) AS total_sales
  FROM
  fact_sales_monthly s 
  JOIN fact_gross_price g ON s.product_code = g.product_code
  JOIN dim_customer c ON s.customer_code = c.customer_code
  WHERE s.fiscal_year= 2021
  GROUP BY c.channel
  ORDER BY total_sales DESC
)
SELECT 
  channel,
  round(total_sales/1000000,2) AS gross_sales_in_millions,
  round(total_sales/(sum(total_sales) OVER())*100,2) AS percentage 
FROM temp_table ;

#10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order


with cte as(
select
	p.division,
    p.product,
    p.product_code,
    sum(s.sold_quantity) as total_qty
from dim_product as p
join fact_sales_monthly as s
on
	p.product_code=s.product_code
where 
	s.fiscal_year=2021
group by p.division,p.product_code,p.product
order by total_qty desc),
cte1 as(
select 
	*,
    dense_rank() over(partition by division order by total_qty desc) as rank_order
from cte)
select
	division,
    product,
    product_code,
    total_qty,
    rank_order
from cte1
where rank_order<=3;
