-- This exists in both the dev and release candidate databases
exec util_WebSChedulerData
	@account = '105119',
	@plname = 'testacct',
	@pfname = 'paul',
	@deleteData = 0