
   
/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "08 - Выборки из XML и JSON полей".
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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 
Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/

DECLARE @xmlStockItems  xml;

SELECT @xmlStockItems = BulkColumn
FROM OPENROWSET
(BULK 'D:\StockItems-188-11a700.xml', SINGLE_CLOB)
as data; 

SELECT @xmlStockItems as [@xmlStockItems];

DECLARE @docHandle int;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlStockItems;

SELECT @docHandle as docHandle;

SELECT *
FROM OPENXML(@docHandle, N'StockItems/Item')
WITH (
  	[StockItemName] nvarchar(100) '@Name',
	[SupplierID] int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
	[LeadTimeDays] int 'LeadTimeDays',
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18, 3) 'TaxRate',
	[UnitPrice] decimal(18, 2) 'UnitPrice',
	[TypicalWeightPerUnit] decimal(18, 3) 'Package/TypicalWeightPerUnit'
	);

DROP TABLE IF EXISTS #StockItems;

CREATE TABLE #StockItems
(
  	[StockItemName] nvarchar(100) COLLATE Latin1_General_100_CI_AS,
	[SupplierID] int,
	[UnitPackageID] int,
	[OuterPackageID] int,
	[LeadTimeDays] int,
	[QuantityPerOuter] int,
	[IsChillerStock] bit,
	[TaxRate] decimal(18, 3),
	[UnitPrice] decimal(18, 2),
	[TypicalWeightPerUnit] decimal(18, 3)
);

INSERT INTO #StockItems(StockItemName, SupplierID, UnitPackageID, OuterPackageID, LeadTimeDays,
                     QuantityPerOuter, IsChillerStock, TaxRate, UnitPrice, TypicalWeightPerUnit)
SELECT *
FROM OPENXML(@docHandle, N'StockItems/Item')
WITH (
  	[StockItemName] nvarchar(100) '@Name',
	[SupplierID] int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
	[LeadTimeDays] int 'LeadTimeDays',
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18, 3) 'TaxRate',
	[UnitPrice] decimal(18, 2) 'UnitPrice',
	[TypicalWeightPerUnit] decimal(18, 3) 'Package/TypicalWeightPerUnit'
	);

EXEC sp_xml_removedocument @docHandle

SELECT * FROM #StockItems;

UPDATE Warehouse.StockItems
SET SupplierID=t.SupplierID,
    UnitPackageID=t.UnitPackageID, OuterPackageID=t.OuterPackageID,
    LeadTimeDays=t.LeadTimeDays, QuantityPerOuter=t.QuantityPerOuter,
    IsChillerStock=t.IsChillerStock, TaxRate=t.TaxRate,
    UnitPrice=t.UnitPrice, TypicalWeightPerUnit=t.TypicalWeightPerUnit
FROM Warehouse.StockItems s, #StockItems t
WHERE s.StockItemName=t.StockItemName;

INSERT Warehouse.StockItems(StockItemID, StockItemName, SupplierID, UnitPackageID, OuterPackageID, LeadTimeDays,
 	QuantityPerOuter, IsChillerStock, TaxRate, UnitPrice, TypicalWeightPerUnit, LastEditedBy)
SELECT NEXT VALUE FOR Sequences.StockItemID,
       StockItemName, SupplierID,
       UnitPackageID, OuterPackageID,
	   LeadTimeDays, QuantityPerOuter,
	   IsChillerStock, TaxRate,
	   UnitPrice, TypicalWeightPerUnit,2
FROM #StockItems t
WHERE NOT EXISTS (SELECT 1 FROM Warehouse.StockItems s WHERE s.StockItemName=t.StockItemName);

SELECT * FROM Warehouse.StockItems;

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT 
  	StockItemName AS [@Name],
	SupplierID AS [SupplierID],
	UnitPackageID AS [Package/UnitPackageID],
	OuterPackageID AS [Package/OuterPackageID],
	QuantityPerOuter AS [Package/QuantityPerOuter],
	TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],
	LeadTimeDays AS [LeadTimeDays],
	IsChillerStock AS [IsChillerStock],
	TaxRate AS [TaxRate],
	UnitPrice AS [UnitPrice]
FROM Warehouse.StockItems
FOR XML PATH('Item'), ROOT('StockItems');

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT StockItemID,
       StockItemName,  
	   ISNULL(JSON_VALUE(CustomFields, '$.CountryOfManufacture'), '') AS CountryOfManufacture,
	   ISNULL(JSON_VALUE(CustomFields, '$.Tags[0]'), '') AS FirstTag 
FROM Warehouse.StockItems;


/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле
Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.
Должно быть в таком виде:
... where ... = 'Vintage'
Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


SELECT StockItemID,
       StockItemName   
       FROM Warehouse.StockItems
CROSS APPLY OPENJSON(CustomFields, '$.Tags') tagintag
WHERE  tagintag.value = 'Vintage'
