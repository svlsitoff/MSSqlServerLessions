/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "07 - ������������ SQL".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*

��� ������� �� ������� "��������� CROSS APPLY, PIVOT, UNPIVOT."
����� ��� ���� �������� ������������ PIVOT, ������������ ���������� �� ���� ��������.
��� ������� ��������� ��������� �� ���� CustomerName.

��������� �������� ������, ������� � ���������� ������ ���������� 
��������� ������ �� ���������� ������� � ������� �������� � �������.
� ������� ������ ���� ������ (���� ������ ������), � �������� - �������.

���� ������ ����� ������ dd.mm.yyyy, ��������, 25.12.2019.

������, ��� ������ ��������� ����������:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (������ �������)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/
DECLARE @str AS NVARCHAR(MAX), @Col AS NVARCHAR(MAX)

select @Col = ISNULL(@Col + ',','') 
       + QUOTENAME(Name) 
	   from (
			SELECT distinct 
			c.CustomerName as Name 
			FROM Sales.Invoices inv
			JOIN Sales.Customers c on inv.CustomerID = c.CustomerID
			) 
			as tempselect 
	order by tempselect.Name

set @str =N'select * from (
    SELECT 
       DATEFROMPARTS(YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate),1) InvoiceMonth
	 , cst.CustomerName as FullName 
    FROM Sales.Invoices AS inv
	JOIN Sales.Customers cst 
	on inv.CustomerID = cst.CustomerID
) as s
pivot (count (FullName) for FullName in (' + @Col + ')) as pvt  order by InvoiceMonth'

EXEC sp_executesql @str


