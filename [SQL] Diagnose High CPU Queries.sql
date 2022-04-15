-- poll ring buffers
DECLARE @ms_ticks_now BIGINT

SELECT @ms_ticks_now = ms_ticks
FROM sys.dm_os_sys_info;

SELECT TOP 15 record_id
	,dateadd(ms, - 1 * (@ms_ticks_now - [timestamp]), GetDate()) AS EventTime
	,SQLProcessUtilization
	,SystemIdle
	,100 - SystemIdle - SQLProcessUtilization AS OtherProcessUtilization
FROM (
	SELECT record.value('(./Record/@id)[1]', 'int') AS record_id
		,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS SystemIdle
		,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLProcessUtilization
		,TIMESTAMP
	FROM (
		SELECT TIMESTAMP
			,convert(XML, record) AS record
		FROM sys.dm_os_ring_buffers
		WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
			AND record LIKE '%<SystemHealth>%'
		) AS x
	) AS y
ORDER BY record_id DESC
go

-- get sql processes
SELECT
	r.session_id
	,st.TEXT AS batch_text
	,SUBSTRING(st.TEXT, statement_start_offset / 2 + 1, (
			(
				CASE
					WHEN r.statement_end_offset = - 1
						THEN (LEN(CONVERT(NVARCHAR(max), st.TEXT)) * 2)
					ELSE r.statement_end_offset
					END
				) - r.statement_start_offset
			) / 2 + 1) AS statement_text
	,qp.query_plan AS 'XML Plan'
	,r.*
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp
ORDER BY cpu_time DESC
go

-- historical queries by worker time
select top 50
    sum(qs.total_worker_time) as total_cpu_time,
    sum(qs.execution_count) as total_execution_count,
    count(*) as  number_of_statements,
    qs.plan_handle
from
    sys.dm_exec_query_stats qs
group by qs.plan_handle
order by sum(qs.total_worker_time) desc
go
