SET NOCOUNT ON;

DECLARE
-- Add the parameters for the stored procedure here
@company VARCHAR(10) = 'CCG',
@usercode VARCHAR(10) = 'BHUGO',
@likeString VARCHAR(10) = 'Z%';
 
select 
   'print ''' + ACCOUNT + '''' + CHAR(10) + '' +
   'exec wp_UnlinkPatientAccount_CCG @company = ''' + @company + ''', @userID = ''' + USERID + ''', @usercode = ''' + @usercode + ''';' + CHAR(10) + 
   'exec wp_updateuser @userid = ''' + USERID + ''', @newpass = '''', @newmail = '''', @newaccount = '''', @newverified = ''D'', @newforceexpire = '''', @newexpiredttm ='''', @usercode = ''' + @usercode + '''' + CHAR(10) + 'GO'
FROM WPUSER
where ACCOUNT like @likeString;


------as reference, see Case 00128945 (deletePortalAccts) for CCG
