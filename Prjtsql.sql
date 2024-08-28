use mini_project;  # using the created Mini_project database
# mini project on ecomerce retail sales
select * from customers_new;
alter table customers_new
rename  column ï»¿customer_Id to customerid;
select * from prod_cat_info;

select * from transactions_new;  

alter table transactions_new
rename column ï»¿transaction_id to transaction_id;


# first procedure to join the table using join 

select * from customers_new C   
join transactions_new T 
join prod_cat_info P  
on C.customerid =T.cust_id and T.prod_cat_code = P.prod_cat_code and T.prod_subcat_code = P.prod_sub_cat_code;

#Q1 what is the total no of row in each of the 3 tables in the database

select count(*) as total_c from customers_new;
select count(*) as total_P from prod_cat_info;
select count(*) as total_t from transactions_new;

# Q2 what is the tota number of transaction that have a return

select count(transaction_id) as transaction_return from transactions_new
where total_amt < 0; 

#Q3 As you would noticed,the dates provided across the dataset are not in a correct format. As first steps,pls convert the data variables into valid date formats
#before proceeding ahead.
# 4.What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously in different columns.

#Time analysis 

SET SQL_SAFE_UPDATES = 0; 
desc transactions_new;
desc customers_new;
update transactions_new
set tran_date = STR_TO_DATE(tran_date, '%d-%m-%Y')
where tran_date is not null;
alter table transactions_new
change column tran_date tran_date  date not null;
select * from transactions_new;

update customers_new
set DOB = STR_TO_DATE(DOB, '%d-%m-%Y')
where DOB is not null;
select DOB from customers_new;
alter table customers_new
change column DOB DOB  date not null;
select 
     MIN(tran_date) as min_order_date,
     MAX(tran_date) as max_delivery_date,
	 DATEDIFF(MAX(tran_date), MIN(tran_date)) AS total_days,
     timestampdiff(MONTH, MIN(tran_date), MAX(tran_date)) as total_months,
     timestampdiff(YEAR, MIN(tran_date),MAX(tran_date)) as total_years
FROM transactions_new;

     #Q5 which product category does the sub-categoru "DIY" belongs to?
     select * from prod_cat_info where prod_subcat = "DIY";
 
     
#DA:Q1 Which channel is most frequently used for transaction?
     
     select S.Store_type from
     (select count(distinct(transaction_id)) as Total_count,Store_type from transactions_new
     group by Store_type
     order by Total_count desc
     limit 1 ) S;
     
     
#DA:Q2 what is the count of male and female customer in the database
select count(distinct(customerid)),Gender from customers_new
where Gender in ("M","F")
group by Gender;

#DA:Q3 From which city do we have the maximum number of customers and how many?

select city_code, count(distinct (customerid)) as No_of_Customers from customers_new
group by city_code 
order by No_of_Customers desc 
limit 1;


 # DA:4 how many sub-categoreies are there under the books category
select prod_cat, count(prod_subcat) as No_of_Subcategories 
from prod_cat_info where prod_cat  = 'Books' group by prod_cat;
 
 
 #DA:5 What is the Maximum quantity of products ever ordered
 
 
 select max(Qty) as Max_ordered from transactions_new
 group by prod_cat_code
 order by max(Qty) desc limit 1 ;



# DA:6 What is the net total revenue generated in categories Electronics and Books?

select P.prod_cat, round(sum(T.total_amt),2) as net_total_revenue from transactions_new T
join prod_cat_info P on P.prod_cat_code = T.prod_cat_code and P.prod_sub_cat_code = T.prod_subcat_code 
group by P.prod_cat 
having P.prod_cat in('Electronics', 'Books');

#DA:8 What is the combined revenue earned from "Electronics" &"Clothing" categories from "Flagship stores"?

select T.Store_type, round(sum(total_amt),2) as combined_revenue from transactions T
join prod_cat_info P on T.prod_subcat_code = P.prod_sub_cat_code and T.prod_cat_code = P.prod_cat_code 
where P.prod_cat in ('Electronics', 'Clothing') and T.total_amt > 0
group by T.Store_type
having T.Store_type = 'Flagship store'; 


#DA:7 How many customers have > 10 transactions with us, excluding returns?

with customers as
(
select cust_id, count(transaction_id) as no_of_transactions from transactions_new T
where total_amt > 0 
group by cust_id 
having count(transaction_id) > 10
)
select count(*) as no_of_customers from customers_new;

#DA:8 What is the combined revenue earned from the "Electronics" & "Clothing" categories, from "Flagship stores"?

select T.Store_type, round(sum(total_amt),2) as combined_revenue from transactions_new T
join prod_cat_info P on T.prod_subcat_code = P.prod_sub_cat_code and T.prod_cat_code = P.prod_cat_code 
where P.prod_cat in ('Electronics', 'Clothing') and T.total_amt > 0
group by T.Store_type
having T.Store_type = 'Flagship store';   

 #DA:9 What is the total revenue generated from "Male" customers in "Electronics" category? 
 # Output should display total revenue by prod sub-cat.

select P.prod_cat, P.prod_subcat , round(sum(T.total_amt),2) as total_revenue from transactions_new T 
join customers_new C on C.customerid  = T.cust_id 
join prod_cat_info P on T.prod_subcat_code = P.prod_sub_cat_code and T.prod_cat_code = P.prod_cat_code 
where C.gender = 'M' and T.total_amt > 0 
group by P.prod_cat, P.prod_subcat
having P.prod_cat = 'Electronics'; 



#DA:10 What is percentage of sales and returns by product sub category;  display only top 5 sub categories in terms of sales?

# Top 5 subcategories 
    select P.prod_subcat, round(sum(T.total_amt),2) as total_sales
    from transactions_new T join prod_cat_info P on t.prod_subcat_code = p.prod_sub_cat_code 
    and T.prod_cat_code = P.prod_cat_code
    where T.total_amt > 0
    group by P.prod_subcat
    order by total_sales desc
    limit 5;
    
#Percentage sales and returns
  with Sales_Returns as
  (
  select P.prod_subcat,
  sum(case when T.Qty > 0 then T.Qty else 0 end) as sales_value,
  abs(sum(case when T.Qty < 0 then T.Qty else 0 end)) as returns_value
  from Transactions_new T inner join Prod_cat_info P
  on T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
  group by P.prod_subcat
  order by sales_value desc
  )
  select prod_subcat, round(((Returns_value / (Returns_value + Sales_value))*100), 2) as Returns_Percentage,
  round(((Sales_value / (Returns_value + Sales_value))*100), 2) as Sales_Percentage
  from Sales_Returns;
  
# 11.For all customers aged between 25 to 35 years find what is the net total revenue generated by 
# these consumers in last 30 days of transactions from max transaction date available in the data?
   
with max_tran_date as 
  (select max(tran_date) as max_date from transactions_new),
last_30days_trans as (
    select T.cust_id, T.tran_date, T.total_amt, M.max_date
    from transactions_new T cross join max_tran_date M
    where T.tran_date between DATE_SUB(M.max_date, interval 30 day) and M.max_date
),
age_25_30 as (
    select C.customerid, year(M.max_date) - year(C.DOB) as age
    from customers_new C
    cross join max_tran_date M
    where year(M.max_date) - year(C.DOB) between 25 and 35
),
net_rev as (
    select sum(T.total_amt) AS net_total_revenue
    from last_30days_trans T
    join age_25_30 A ON T.cust_id = A.customerid
)
select net_total_revenue from net_rev;

# DA:12 Which product category has seen the max value of returns in the last 3 months of transactions?

with max_tran_date as 
	(select max(tran_date) as max_date from Transactions_new),
last_90days_returns as (
    select P.prod_cat, sum(case when T.total_amt < 0 then T.total_amt else 0 end) as return_amount 
    from transactions_new T
    join max_tran_date M on T.tran_date between DATE_SUB(M.max_date, interval 90 day) and M.max_date
    left join prod_cat_info P on T.prod_subcat_code = P.prod_sub_cat_code and T.prod_cat_code = P.prod_cat_code 
    group by P.prod_cat
)
select prod_cat, return_amount
from last_90days_returns
order by return_amount
limit 1;


#DA:13 Which store-type sells the maximum products; by value of sales amount and by quantity sold?

select Store_type, round(sum(total_amt),2) as total_sales, count(Qty) as qty_sold from transactions_new T
where total_amt > 0 
group by Store_type 
order by total_sales desc, qty_sold desc
limit 1;

# DA:14 What are the categories for which average revenue is above the overall average.

select  p.prod_cat, avg(t.total_amt) as avg_cat_rev from transactions_new T
join prod_cat_info P on T.prod_cat_code = P.prod_cat_code and T.prod_subcat_code = P.prod_sub_cat_code
where total_amt > 0
group by P.prod_cat
having avg(T.total_amt) > (select avg(total_amt) as overall_avg_rev from transactions_new where total_amt > 0);

# DA:15 Find the average and total revenue by each subcategory for the categories
# which are among top 5 categories in terms of quantity sold.
   
with TopCategories as (
    select P.prod_cat, T.prod_cat_code, count(Qty) as qty_sold 
    from transactions_new T inner join prod_cat_info P 
    on T.prod_cat_code = P.prod_cat_code and T.prod_subcat_code = P.prod_sub_cat_code
    where T.total_amt > 0
    group by P.prod_cat, T.prod_cat_code
    order by qty_sold desc
    limit 5
)
select  P.prod_cat, round(avg(T.total_amt),2) as avg_revenue, round(sum(T.total_amt),2) as total_revenue 
from transactions_new T join prod_cat_info P 
on T.prod_cat_code = P.prod_cat_code and T.prod_subcat_code = P.prod_sub_cat_code
join TopCategories TC on T.prod_cat_code  = TC.prod_cat_code
group by P.prod_cat;

