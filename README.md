PagerDuty OnCall Schedule to Asterisk DB
======

A small ruby script designed to run via cron to query the PagerDuty schedule and update an asterisk DB variable to allow
redirection of calls to the current on-call person e.g.

	[ops-oncall]
	exten => 123456,1,Queue(ops,tT,,,16)
	exten => 123456,2,Dial(IAX2/XXXX@XXXXX/${DB(oncall/phone)})

The source code has been released under the GPL version 3 license.

