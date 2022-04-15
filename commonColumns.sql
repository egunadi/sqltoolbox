--https://stackoverflow.com/questions/17092569/how-to-determine-which-columns-are-shared-between-two-tables
select A.COLUMN_NAME
from INFORMATION_SCHEMA.COLUMNS A
join INFORMATION_SCHEMA.COLUMNS B
  on A.COLUMN_NAME = B.COLUMN_NAME
where A.TABLE_NAME = 'table1'
  and B.TABLE_NAME = 'table2'

--or...

--https://stackoverflow.com/questions/6445573/sql-find-the-same-column-in-different-tables?rq=1
select name from syscolumns sc1 where id = object_id('table1') and exists(select 1 from syscolumns sc2 where sc2.name = sc1.name and sc2.id = object_id('table2'))


 --or...

 ;with cte as
(
select 
	o.Name as TableName,
	c.Name as FieldName
from sys.columns c
	inner join sys.objects o
		on o.object_id = c.object_id
where o.type = 'U'
	and o.Name = 'SWACTIVESRC'
)
select 
	o.Name as TableName,
	c.Name as FieldName
from sys.columns c
	inner join sys.objects o
		on o.object_id = c.object_id
	inner join cte
		on cte.FieldName = c.Name
where o.type = 'U'
	and o.Name = 'CLMASTER'