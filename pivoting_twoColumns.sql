	CREATE TABLE #dx
		(
			icd9 varchar(10) NOT NULL,
			problem varchar(200) NOT NULL,
			ssno varchar(15) NOT NULL,
			[rank] int NOT NULL
			CONSTRAINT pk_ssnorank PRIMARY KEY (ssno, rank)
		)

	;with dxCTE as
	(
	SELECT clp.ICD9, clp.PROBLEM, clp.SSNO,
		row_number() over (partition by clp.SSNO order by [RANK], DISPLAYRANK) as [rank]
	FROM CLPROBLM clp
	WHERE (ENDDATE='1900-01-01' OR ENDDATE=CONVERT(VARCHAR(10), GETDATE(), 120))
		AND clp.ICD9!=''
		AND clp.ICD9!='0'
		AND STATUS!='Exclude'
		AND STATUS!='Past History'
		AND STATUS!='Previously Resolved'
		AND STATUS!='Inactive'
		AND STATUS!='Invalidated ICD9'
		AND clp.COMPANY='main'
		AND RANK IN ('1','2')
	)
	insert into #dx
		select icd9, problem, ssno, rank
		from dxCTE
		where rank <= 8;

-- REGULAR SQL
	select ssno,
		max(case when rank = 1 then icd9 end) as [diag1],
		max(case when rank = 2 then icd9 end) as [diag2],
		max(case when rank = 3 then icd9 end) as [diag3],
		max(case when rank = 4 then icd9 end) as [diag4],
		max(case when rank = 1 then problem end) as [diagdesc1],
		max(case when rank = 2 then problem end) as [diagdesc2],
		max(case when rank = 3 then problem end) as [diagdesc3],
		max(case when rank = 4 then problem end) as [diagdesc4]
	from #dx
	group by ssno;

-- USING PIVOT
	select
		ssno,
		max([1]) as diag1,
		max([2]) as diag2,
		max([3]) as diag3,
		max([4]) as diag4,
		max([11]) as diagdesc1,
		max([12]) as diagdesc2,
		max([13]) as diagdesc3,
		max([14]) as diagdesc4
	from (select ssno,
			[rank], [rank] + 10 as rank2,
			max(icd9) as icd9,
			max(problem) as problem
		  from #dx
		  group by ssno, [rank]) as D
		pivot(max(icd9) for [rank] in([1], [2], [3], [4])) as p1
		pivot(max(problem) for rank2 in([11], [12], [13], [14])) as p2
	group by ssno
