-- update test PLQ with views

select c1.NAME, c1.SQLSCRIPT, c2.SQLSCRIPT, c1.QUERYID from CLPLQUERY c1 join CLPLQSQLSCRIPT c2 on c1.QUERYID=c2.QUERYID where c1.type='p' 
  and c1.NAME like 'test%' order by c1.NAME
begin tran
update CLPLQSQLSCRIPT set SQLSCRIPT='FROM dbo.MINotify_TestFollowUpsToBeScheduledNextMonthAndPreviousSixMonths' where QUERYID='6199CEB8-DABA-4D07-9E68-9D29FD720F9F'
select c1.NAME, c1.SQLSCRIPT, c2.SQLSCRIPT, c1.QUERYID from CLPLQUERY c1 join CLPLQSQLSCRIPT c2 on c1.QUERYID=c2.QUERYID where c1.type='p' 
  and c1.NAME like 'test%' order by c1.NAME
rollback tran
-- commit tran

----------
-- update prod PLQ with views

--select c1.NAME, c1.SQLSCRIPT, c2.SQLSCRIPT, c1.QUERYID from CLPLQUERY c1 join CLPLQSQLSCRIPT c2 on c1.QUERYID=c2.QUERYID where c1.type='p' 
  --and c1.NAME not like 'test%' order by c1.NAME
begin tran
update CLPLQSQLSCRIPT 
  set SQLSCRIPT='FROM dbo.MINotify_PatientsApptFinalizedTodayTwoToSix' 
where QUERYID='353B0414-1A5E-4EFE-8E89-90CD29B33168'
select c1.NAME, c2.SQLSCRIPT, c1.QUERYID from CLPLQUERY c1 join CLPLQSQLSCRIPT c2 on c1.QUERYID=c2.QUERYID where c1.type='p' 
  and c1.NAME not like 'test%' order by c1.NAME
--rollback tran
 commit tran

----------

-- update test GUIDs for regular jobs

begin tran
update CDNNotifyJob set RequestUUID='26' where RequestUUID='170F784C-91F9-4D69-9DF1-ACB5F100C1C6'

select * from CDNNotifyJob where len(requestUUID) < 10 order by JobID desc
commit tran

----------
-- update test GUIDs for throttled jobs

begin tran
update CDNThrottle set RequestUUID='26' where RequestUUID='170F784C-91F9-4D69-9DF1-ACB5F100C1C6'

select * from CDNThrottle where len(requestUUID) < 10 order by JobID desc
commit tran

------------
-- check notification logs

select top 10 facility, * from MWAPPTSLOG where ACCOUNT='TO10002124' order by ADATE desc


select top 10 *
from CDNNotifications c1 
  join CDNNotifyContact c2
    on c1.NotificationID = c2.NotificationID
  join CDNNotifyContactStatus c3
    on c3.ContactStatusID = c2.Status
where c1.ACCOUNT='TO10002124' 
order by c1.JobID desc

select  a.CompletedDate,c.apptno, c.status, c.userflag,b.LastContact, b.Status, c.flagnote, c.facility, c.tagdate, c.tagtime, b.invalidresponse, b.*, a.*
from CDNNotifications a 
  left join CDNNotifyContact b 
    on a.NotificationID=b.NotificationID
  left join CDNThrottleNotifications d 
    on a.NotificationID=d.NotificationID
  left join mwappts c 
    on a.Company=c.COMPANY 
    and a.Account=c.ACCOUNT 
    and a.ApptNo=c.APPTNO
where d.throttleid=47
order by a.completeddate desc

------------------
-- grant mwuser SELECT permission to all minotify views

select 'grant SELECT on ' + SCHEMA_NAME(schema_id) + '.' + Name + ' to MWUSER;' + CHAR(10) + 'GO'
from sys.views
where Name like 'minotify%';

---------------------

-- insert new message for batch ODN
-- note that newer versions allow custom messages to be typed on the fly

begin tran

select * from CLTABLESETS where FOLDER='M:\MEDINFO\TABLES\C02\' and SECTION='BATCHNOTIFY.TBL' and ACTIVE='Y'

insert into CLTABLESETS(FOLDER, SECTION, ENTRYNAME, LASTEDIT, LASTUSER, ACTIVE, DISPLAYRANK)
 select 'M:\MEDINFO\TABLES\C02\', 'BATCHNOTIFY.TBL', 'We''re getting a new appointment confirmation system. Please disregard yesterday''s message. Thank you - Fuerst Eye Center', GETDATE(), 'MEDINFO', 'Y', 1;

select * from CLTABLESETS where FOLDER='M:\MEDINFO\TABLES\C02\' and SECTION='BATCHNOTIFY.TBL' and ACTIVE='Y'
--rollback tran
commit tran