/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region*/

select distinct market from dim_customer
WHERE region = "APAC";

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

with cte as(
select count(distinct product_code) as unique_products_2020
from fact_sales_monthly
where fiscal_year='2020'),
cte2 as (
select count( distinct product_code) as unique_products_2021
from fact_sales_monthly
where fiscal_year='2021')

select *, round((unique_products_2021-unique_products_2020)/unique_products_2020 *100 ,2) as percentage_chg
from cte,cte2;

/* 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
The final output contains 2 fields,
segment
product_count */

select segment, count(1) as product_count
from dim_product
group by 1
order by product_count desc;

/* 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, 
segment
product_count_2020
product_count_2021
difference*/

with cte as(
select dm.segment, count( distinct fs.product_code) as product_count_2020
from fact_sales_monthly fs
left join dim_product dm 
on fs.product_code=dm.product_code
where fs.fiscal_year='2020'
group by dm.segment),
cte2 as
(select dm.segment, count( distinct fs.product_code) as product_count_2021
from fact_sales_monthly fs
left join dim_product dm 
on fs.product_code=dm.product_code
where fs.fiscal_year='2021'
group by dm.segment)

select cte.*, cte2.product_count_2021, cte2.product_count_2021- cte.product_count_2020 as difference
from cte
left join cte2
on cte.segment=cte2.segment
order by difference desc;


/* 5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */

select mc.product_code, dm.product, mc.manufacturing_cost
from fact_manufacturing_cost mc
left join dim_product dm
on mc.product_code = dm.product_code
where mc.manufacturing_cost in (select max(manufacturing_cost) from fact_manufacturing_cost)
union
select mc.product_code, dm.product, mc.manufacturing_cost
from fact_manufacturing_cost mc
left join dim_product dm
on mc.product_code = dm.product_code
where mc.manufacturing_cost in (select min(manufacturing_cost) from fact_manufacturing_cost);



/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/

with cte as(
select customer_code, round(avg(pre_invoice_discount_pct)*100,2) as average_discount_percentage
from fact_pre_invoice_deductions
where fiscal_year='2021'
group by customer_code
)
select cte.customer_code, dm.customer, cte.average_discount_percentage
from cte
left join dim_customer dm
on cte.customer_code = dm.customer_code
where market='India'
order by average_discount_percentage desc
limit 5;

/*7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/

SELECT month(fs.date) as month, year(fs.date) as year,fs.fiscal_year, 
round( sum(fg.gross_price*fs.sold_quantity),2)as total_gross_sales
FROM fact_sales_monthly fs
LEFT JOIN dim_customer dc
on fs.customer_code=dc.customer_code
LEFT JOIN fact_gross_price fg
on fs.product_code=fg.product_code
WHERE dc.customer='Atliq Exclusive'
group by fs.fiscal_year,year(fs.date),month(fs.date) 
order by  year,month;

/* 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/

with cte as(
SELECT *, case when month(date) in (9,10,11) then 'Q1' when month(date) in (12,1,2) then 'Q2' 
when month(date) in (3,4,5) then 'Q3' else 'Q4' end as Quarter
FROM fact_sales_monthly
where fiscal_year='2020')

select Quarter, sum(sold_quantity) as total_sold_quantity
from cte
group by Quarter 
order by total_sold_quantity desc;

/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */

with cte as(
SELECT dc.channel, sum(sold_quantity*gross_price) as gross_sales
FROM fact_sales_monthly fs
LEFT JOIN fact_gross_price gp
on fs.product_code=gp.product_code
LEFT JOIN dim_customer dc
on fs.customer_code=dc.customer_code
WHERE fs.fiscal_year='2021'
GROUP BY dc.channel)

SELECT channel,concat(round(gross_sales/1000000,2) , ' M') as gross_sales_mln, 
concat(round(gross_sales/sum(gross_sales) over() * 100.0,2),'%') as percentage
from cte
order by percentage DESC;


/*10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division
product_code*/

with cte as (
SELECT product_code, sum(sold_quantity) as total
FROM fact_sales_monthly 
WHERE fiscal_year='2021'
GROUP BY product_code),
cte2 as(
select c.*, dm.division,dm.product, DENSE_RANK()over(partition by division order by total desc) as ranking
from cte c
left join dim_product dm
on c.product_code=dm.product_code)
select division, product_code,product,total as total_sold_quantity,ranking 
from cte2
where ranking <4
