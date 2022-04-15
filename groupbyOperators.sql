use [devtest_medicalv76];
go

/*
select clc.CHGAMOUNT - clp.XACAMOUNT
from clcharge clc 
	join clpaymnt clp 
		on clc.account=clp.account 
		and clc.COMPANY=clp.COMPANY
group by clc.CHGAMOUNT - clp.XACAMOUNT
*/


--tidy up any existing data from a previous run. 
DECLARE @tbl1 table (col1 int, id int);
DECLARE @tbl2 table (col2 int, id int);

insert into @tbl1 values 
	(1,1),
	(2,2),
	(3,3),
	(4,4),
	(5,5);

insert into @tbl2 values
	(2,1),
	(3,2),
	(6,3),
	(8,4),
	(10,5);

select sum(b.col2)
	from @tbl1 a
		join @tbl2 b
			on a.id=b.id
group by b.col2-a.col1