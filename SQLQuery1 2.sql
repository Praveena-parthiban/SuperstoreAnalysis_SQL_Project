
-- DATA CLEANING...
-- 1. establish the relationship between the tables as per ER diagram 

ALTER TABLE OrdersList
ADD CONSTRAINT pk_orderid PRIMARY KEY(OrderID)

ALTER TABLE OrdersList
ALTER COLUMN OrderID nvarchar(255) NOT NULL

ALTER TABLE EachOrderBreakdown
ALTER COLUMN OrderID nvarchar(255) NOT NULL


ALTER TABLE EachOrderBreakdown
ADD CONSTRAINT fk_orderid FOREIGN KEY(OrderID) REFERENCES OrdersList(OrderID)

--2 . split city state country into 3 individual columns city. state. country

ALTER TABLE Orderslist
ADD City nvarchar(255),
    State nvarchar(255),
	Country nvarchar(255);

UPDATE OrdersList
SET City  = PARSENAME(REPLACE([City State Country], ',', '.'), 3),
    State =  PARSENAME(REPLACE([City State Country], ',', '.'),2),
	Country =  PARSENAME(REPLACE([City State Country], ',', '.'),1);

ALTER TABLE Orderslist
Drop column [City State Country]

select * from OrdersList

--3 Add a new category using the following mapping as per the first 3 characters in the product name column:
-- a. TEC- Technology
-- b. OFS - Office Suplies
-- c. FUR - Furniture

ALTER TABLE EachOrderBreakdown
ADD Category nvarchar(255)

UPDATE EachOrderBreakdown
SET Category= case when LEFT([ProductName],3)='OFS' THEN 'Office Suplies'
                    when LEFT([ProductName],3) = 'TEC' THEN 'TECHNOLOGY'
					when LEFT([ProductName],3) = 'FUR' THEN 'Furniture'
				END;
			 
select * from EachOrderBreakdown

-- 4.delete first 4 chataters from the productName column.
UPDATE  EachOrderBreakdown
SET ProductName = SUBSTRING(ProductName, 5, len(productName)-4)

-- 5. Remove duplicate rows from EachOrderBreakdown table, if all coumns values are matching
WITH CTE AS( 
SELECT *, ROW_NUMBER() OVER(PARTITION BY OrderID, ProductName, Discount, Sales, Profit, Quantity, 
         category, subCategory ORDER BY OrderID) AS rn
		 FROM EachOrderBreakdown
		

)

DELETE FROM CTE
WHERE rn > 1

-- 6.Replace blank with NA OrderPriority Column in OrderList table
select * from OrdersList
update [dbo].[OrdersList]
set OrderPriority = 'NA'
where OrderPriority = '';

-- DATA EXPLORATION
--1. List the top 10 orders with the highest sales from the EachOrderBreakdown table

SELECT top 10 * from EachOrderBreakdown Order by Sales desc

--2. Show the number of orders for each product category in the EachOrderBreakdown

SELECT category, count(*) as NoOfOrders from EachOrderBreakdown group by Category

--3. Find the total profit for each sub-category in the EachOrderBreakdown table

SELECT SubCategory, sum(Profit)
from EachOrderBreakdown 
group by SubCategory

-- Intermediate
-- 1. Identify the customer with the highest total sales across all orders.

SELECT top 1 CustomerName, SUM(sales) as TotalSales from OrdersList OL
join EachOrderBreakdown OB 
on OL.OrderID = OB.OrderID
group by CustomerName
order by TotalSales desc

-- 2. find the month with the highest aveage sales in the OrderList table.

SELECT top 1 MONTH(orderDate) as month, AVG(sales) as AverageSales from OrdersList OL
join EachOrderBreakdown OB 
on OL.OrderID = OB.OrderID
group by month(OrderDate)
order by AverageSales desc


-- 3. Find the average quantity ordered by customers whose first name starts with an alphabet 's' ?
SELECT AVG(quantity) as averageQuantity from OrdersList OL
join EachOrderBreakdown OB 
on OL.OrderID = OB.OrderID
where left(CustomerName,1) = 's'

-- ADVANCED
-- 1. Find out how many new customers were acquired in the year 2014?
select COUNT(*)as NewCustomers from (
Select CustomerName, MIN(OrderDate) as FirstOrderDate from OrdersList 
group by CustomerName
Having YEAR(min(OrderDate)) ='2014'
 )  as newCustomers
-- 2. Calculate the percentage of total profit contributed by each sub-category to the overall profit
--( Here sum(profit) is divided by total value, which needs a subquery of 'select'.)

select subcategory, sum(profit) as subcategoryProfit, sum(profit)/(Select sum(profit) from EachOrderBreakdown) * 100 as percntageProfit
from EachOrderBreakdown
group by SubCategory


-- 3. Find the average sales per customer, considering only customers who have made more than one order.

WITH CustomerAvgSales AS(
select CustomerName, COUNT(DISTINCT OL.OrderID) AS NoOfOrders ,avg(Sales) as AvgSales from OrdersList OL 
join EachOrderBreakdown OB 
on OL.OrderID = OB.OrderID
group by CustomerName
)
SELECT customername, Avgsales 
from CustomerAvgSales
where NoOfOrders > 1

-- 4. Identify the top-perfoming subcategory in each based on total sales. Incude the subcategory name, total sales, and a ranking
-- of subcategory within each other category. 

WITH topsubcategory AS (
SELECT Category, SubCategory, SUM(Sales) as TotalSales,
RANK() OVER(PARTITION BY Category ORDER BY SUM(Sales) DESC) AS SubCategoryRank
FROM EachOrderBreakdown
Group BY Category, SubCategory
)
SELECT * 
FROM topsubcategory
where SubcategoryRank =1 