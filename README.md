monitoring-perl
===============

A repository for Nagios/Icinga perl plugins I use.

check_mysql_threads.pl
----------------------

Verify that mysql is not hitting it's maximum number of threads.
Also check that threads don't remain longer than <n> seconds in a state.
