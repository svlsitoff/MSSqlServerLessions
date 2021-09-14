/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

--TODO: напишите здесь свое решение
SELECT Items.StockItemID, Items.StockItemName 
FROM  Warehouse.StockItems Items
WHERE 
	Items.StockItemName like '%urgent%' 
	OR Items.StockItemName like 'Animal%' 

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

--TODO: напишите здесь свое решение

SELECT Sup.SupplierID [ID], Sup.SupplierName [Name] 
FROM Purchasing.Suppliers Sup
LEFT JOIN Purchasing.PurchaseOrders Ord
ON Sup.SupplierID = Ord.SupplierID
where Ord.PurchaseOrderID IS NULL;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

--TODO: напишите здесь свое решение
SELECT o.OrderID[ID Order],CONVERT(char(10),o.OrderDate,104) [Date],
	   DATENAME(MONTH, o.OrderDate) [Month],
	   DATEPART(q,o.OrderDate) [Quarter],
			CASE	
			WHEN MONTH(o.OrderDate) BETWEEN 1 AND 4 then '1'
			WHEN MONTH(o.OrderDate) BETWEEN 5 AND 8 then '2'
			ELSE '3'
			END  AS PartYear,
		cust.CustomerName [Customer Name]
from Sales.Orders as o
join Sales.Customers as cust ON o.CustomerID=cust.CustomerID
join Sales.OrderLines as ordl ON o.OrderID=ordl.OrderID
where (ordl.UnitPrice>100 or ordl.Quantity>20) AND ordl.PickingCompletedWhen is not null
order by [Quarter],PartYear ,[Date]



/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/
SELECT methods.DeliveryMethodName [Method Name],ord.ExpectedDeliveryDate AS [Date],sup.SupplierName [Supplier Name] , pep.FullName [Contact Person]
FROM Purchasing.PurchaseOrders ord
INNER JOIN Application.DeliveryMethods methods 
ON methods.DeliveryMethodName ='Air Freight'
OR methods.DeliveryMethodName ='Refrigerated Air Freight'
INNER JOIN Application.People pep
ON ord.ContactPersonID = pep.PersonID
INNER JOIN Purchasing.Suppliers sup
ON ord.SupplierID = sup.SupplierID
WHERE (ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31')
AND IsOrderFinalized = 1

--TODO: напишите здесь свое решение

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

--TODO: 
SELECT TOP 10 OrderDate [Order date],c.CustomerName [Customer Name],p.FullName [Person Name] From Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Application.People p ON o.SalespersonPersonID = p.PersonID
Order BY [OrderDate] Desc



/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

--TODO: напишите здесь свое решение
SELECT c.CustomerID [Customer ID],c.CustomerName [Customer Name],c.PhoneNumber [Phone]
FROM Sales.Customers c
INNER JOIN Sales.Invoices inv On inv.CustomerID = c.CustomerID
INNER JOIN Sales.OrderLines ord ON inv.OrderID = ord.OrderID
INNER JOIN Warehouse.StockItems stock ON ord.StockItemID = stock.StockItemID
WHERE stock.StockItemName LIKE 'Chocolate frogs 250g'
ORDER BY [Customer ID]


/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

--TODO: напишите здесь свое решение
SELECT YEAR (inv.InvoiceDate)[Year], MONTH (inv.InvoiceDate)[Month], AVG(l.UnitPrice) as [Average Price], SUM (l.Quantity*l.UnitPrice) as [Total]
FROM Sales.Invoices inv,Sales.InvoiceLines l
WHERE inv.InvoiceID = l.InvoiceID
GROUP BY YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate)
order by YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate)
/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
SELECT YEAR (inv.InvoiceDate)[Year], MONTH (inv.InvoiceDate)[Month], AVG(invln.UnitPrice) as [Average Price], SUM (invln.Quantity*invln.UnitPrice) as [Total]
FROM Sales.Invoices inv,Sales.InvoiceLines invln
GROUP BY YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate)
HAVING SUM (invln.Quantity*invln.UnitPrice) > 10000
order by YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate)

--TODO: напишите здесь свое решение

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
SELECT	 YEAR(inv.InvoiceDate) AS [Year],MONTH(inv.InvoiceDate) AS [Month],items.StockItemName [Name Item]
		,SUM(inls.Quantity * inls.UnitPrice)  [Total Sales],MIN(inv.InvoiceDate)  [First Sale],SUM(inls.Quantity)  [QTY]
FROM Sales.InvoiceLines inls
JOIN Sales.Invoices  [inv] ON inls.InvoiceID = inv.InvoiceID
JOIN Warehouse.StockItems [items] ON inls.StockItemID = items.StockItemID
GROUP BY  YEAR(inv.InvoiceDate)
		 ,MONTH(inv.InvoiceDate)
		 ,items.StockItemName
HAVING SUM(inls.Quantity) < 50
ORDER BY YEAR(inv.InvoiceDate),
		 MONTH(inv.InvoiceDate);

