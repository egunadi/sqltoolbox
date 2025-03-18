-- A query like this can be used...

create table test (a int, b varchar(10), c int)

insert into test (a, b, c)
		values
			(1, 'blue', 100),
			(1, 'blue', 200),
			(1, 'green', 100),
			(1, 'green', 200),
			(1, 'red', 100)

;with cte as (
	select row_number() over (partition by a, b order by c desc) as rownum, *
)

-- Verify that the cte pulls what I want with a query like...
select * from cte where rownum <> 1


-- Delete the unwanted rows with a statement like...
delete ...
	where rownum = 1 (or 2...)


--------------

select
	--count (*),
	ROOM,
	RMSECTION,
	ACCOUNT,
	CREATEDATE,
	CREATETIME,
	STARTTIME,
	COMPANY
from clroom
group by
	ROOM,
	RMSECTION,
	ACCOUNT,
	CREATEDATE,
	CREATETIME,
	STARTTIME,
	COMPANY
having count(*) > 1
order by count(*),
	ROOM,
	RMSECTION,
	ACCOUNT,
	CREATEDATE,
	CREATETIME,
	STARTTIME,
	COMPANY

-----------

-- for reference, see Case 00124960 (pv76_clroom) for NBCC