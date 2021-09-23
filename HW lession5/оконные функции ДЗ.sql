

/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
USE WideWorldImporters
SELECT 
	temp.InvoiceID [ID], 
	temp.CustomerName [Customer Name], 
	temp.InvoiceDate  [Date], 
	temp.sum_invoice  [Sum Invoice],
	SUM(sum_month) [Total Month]
FROM(
SELECT 
	inv.InvoiceID, 
	cust.CustomerName, 
	inv.InvoiceDate, 
	SUM(invl.UnitPrice) as sum_invoice
		FROM Sales.Invoices inv
		JOIN Sales.InvoiceLines invl on invl.InvoiceID = inv.InvoiceID
		JOIN Sales.Customers cust on cust.CustomerID = inv.CustomerID
		WHERE inv.InvoiceDate >= '2015-01-01'
		GROUP BY inv.InvoiceID, cust.CustomerName, inv.InvoiceDate
		) temp
JOIN (
	SELECT CONCAT(YEAR(inv.InvoiceDate), RIGHT('00'+Convert(Varchar(2), MONTH(inv.InvoiceDate)),2), '01') dt, SUM(invl.UnitPrice) as sum_month
	FROM Sales.Invoices inv
	JOIN Sales.InvoiceLines invl on invl.InvoiceID = inv.InvoiceID
	WHERE inv.InvoiceDate >= '20150101'
	GROUP BY CONCAT(YEAR(inv.InvoiceDate), RIGHT('00'+Convert(Varchar(2), MONTH(inv.InvoiceDate)),2), '01')
) AS total_month on total_month.dt <= temp.InvoiceDate
group by temp.InvoiceID, temp.CustomerName, temp.InvoiceDate,temp.sum_invoice
order by temp.InvoiceDate

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io off
*/

SELECT 
	temp.InvoiceID, 
	temp.CustomerName, 
	temp.InvoiceDate, 
	temp.sum_invoice,
	SUM(temp.sum_invoice) OVER(ORDER BY year(temp.InvoiceDate),  month(temp.InvoiceDate)) AS RunningTotal
FROM(
SELECT 
	inv.InvoiceID, 
	cust.CustomerName, 
	inv.InvoiceDate, 
	SUM(invl.UnitPrice) AS sum_invoice
	FROM Sales.Invoices inv
	JOIN Sales.InvoiceLines invl ON invl.InvoiceID = inv.InvoiceID
	JOIN Sales.Customers cust ON cust.CustomerID = inv.CustomerID
	WHERE inv.InvoiceDate >= '2015-01-01'
	GROUP BY inv.InvoiceID, cust.CustomerName, inv.InvoiceDate
	) temp
/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

SELECT DISTINCT
	DATENAME(MONTH, t1.InvoiceDate) as month_name, nm as month_number,
	t1.StockItemID
	FROM(
		SELECT 
			t.InvoiceDate, MONTH(InvoiceDate) nm,
			t.StockItemID, sum_cust_month,
			DENSE_RANK() OVER (
			PARTITION BY  MONTH(t.InvoiceDate) 
			ORDER BY t.InvoiceDate, sum_cust_month desc, t.StockItemID
			)
			AS CustomerTransRank
		FROM (
				SELECT
					i.InvoiceDate, il.StockItemID,
					COUNT(il.StockItemID) OVER (PARTITION BY il.StockItemID, MONTH(i.InvoiceDate)) AS sum_cust_month
				FROM Sales.Invoices i
				JOIN Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
				WHERE i.InvoiceDate >= '2016-01-01' AND i.InvoiceDate < '2017-01-01'
		) t
	) t1
WHERE CustomerTransRank <=2
ORDER BY month_number

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт
Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select 
	StockItemID,StockItemName,Brand,UnitPrice,
	DENSE_RANK() OVER (PARTITION BY  LEFT(StockItemName, 1) ORDER BY StockItemName) as first_alfa,
	COUNT(StockItemName) OVER () as total_count,
	COUNT(StockItemName) OVER (PARTITION BY  LEFT(StockItemName, 1)) as first_alfa_count,
	LEAD(StockItemID) OVER (ORDER BY StockItemName) as next_item ,
	LAG(StockItemID) OVER (ORDER BY StockItemName) as prev_item ,
	LAG(StockItemName, 2, 'No items') OVER (ORDER BY StockItemName) as prev_item2,
	NTILE(30) OVER (ORDER BY TypicalWeightPerUnit) as ntile_20
FROM Warehouse.StockItems

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT 
	p.PersonID, p.FullName,
	c.CustomerID, c.CustomerName,
	MAX(i.InvoiceDate) AS InvoiceDate,
	SUM(il.[UnitPrice]) AS sum_deal
FROM (
		SELECT
			i.SalespersonPersonID,
			MAX(i.CustomerID) as CustomerID,
			MAX(i.InvoiceID) as InvoiceID,
			MAX(i.InvoiceDate) as InvoiceDate
		FROM Sales.Invoices i
		GROUP BY i.SalespersonPersonID) i
JOIN [Sales].[InvoiceLines] il ON il.InvoiceID = i.InvoiceID
JOIN [Application].[People] p ON p.[PersonID] = i.SalespersonPersonID
JOIN [Sales].[Customers] c ON c.CustomerID = i.CustomerID
GROUP BY p.PersonID, p.FullName, c.CustomerID, c.CustomerName
ORDER BY p.PersonID, p.FullName

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиента, его название, ид товара, цена, дата покупки.
*/

SELECT
	CustomerID,
	CustomerName,
	[StockItemID],
	[UnitPrice],
	MAX(InvoiceDate) AS InvoiceDate
FROM (
SELECT  [InvoiceLineID],
      il.[InvoiceID],
      [StockItemID],
      [UnitPrice],
	  i.CustomerID,
	  c.CustomerName,
	  i.InvoiceDate,
	  DENSE_RANK() OVER (PARTITION BY i.CustomerID ORDER BY [UnitPrice] DESC, [StockItemID]) AS CustomerTransRank
  FROM WideWorldImporters.Sales.InvoiceLines il
  JOIN Sales.Invoices i ON i.InvoiceID = il.InvoiceID
  JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
  )t
WHERE CustomerTransRank < 3
GROUP BY CustomerID, CustomerName, [StockItemID], [UnitPrice]
ORDER BY CustomerID