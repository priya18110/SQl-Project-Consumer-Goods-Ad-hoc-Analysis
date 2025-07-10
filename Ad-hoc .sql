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
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count
