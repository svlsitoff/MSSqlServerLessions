/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/
SELECT ppl.PersonId[ID], ppl.FullName[Name] 		
FROM Application.People ppl
WHERE  ppl.IsSalesperson=1 AND
ppl.PersonID NOT IN
(
SELECT SalespersonPersonID FROM Sales.Invoices
WHERE Sales.Invoices.InvoiceDate = '2015-07-04'
)

	

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
USE WideWorldImporters
SELECT itms.StockItemID [ID],itms.StockItemName,itms.UnitPrice
FROM Warehouse.StockItems itms 
WHERE UnitPrice = (Select MIN(UnitPrice) FROM Warehouse.StockItems)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
USE WideWorldImporters

SELECT DISTINCT cst.CustomerID ,cst.CustomerName, cst.DeliveryAddressLine1 FROM Sales.Customers cst
WHERE cst.CustomerID  IN  (
SELECT  TOP(5) tr.CustomerID 
FROM Sales.CustomerTransactions tr
ORDER BY tr.TransactionAmount DESC)


-------CTE
USE WideWorldImporters
;WITH TopCustCTE (CustomerId) AS 
(
	SELECT  TOP(5) ct.CustomerID [ID]   FROM Sales.CustomerTransactions ct
	ORDER BY ct.TransactionAmount DESC
)
SELECT DISTINCT cst.CustomerID ,cst.CustomerName, cst.DeliveryAddressLine1 FROM Sales.Customers cst
JOIN TopCustCTE tCTE ON cst.CustomerID = tCTE.CustomerId;



/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/
WITH MostExpensiveItems AS(
SELECT TOP(3) InvoiceID FROM Sales.InvoiceLines
ORDER BY UnitPrice DESC
),
BayersExpensivItems AS
(
	SELECT CustomerID FROM Sales.Invoices inv
	WHERE inv.InvoiceID IN ( SELECT * FROM MostExpensiveItems
 Order by inv.CustomerID))


Select cty.CityID, cty.CityName FROM Application.Cities cty
WHERE cty.CityID IN 
(
 SELECT 
)
;



-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
