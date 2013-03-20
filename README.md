monitoring-perl
===============

A repository for Nagios/Icinga perl plugins I use.

Sometimes the standard options you find on Nagios Exchange or Monitoring
Exchange just don't cut it.

check_mysql_threads.pl
----------------------

Verify that mysql is not hitting it's maximum number of threads.
Also check that threads don't remain longer than <n> seconds in a state.

check_mem.pl
------------

For use with nrpe. This plugin counts memory the right way, caches and buffers
are not used memory in my opinion. If you want to operate a system with low
resources you should be able to do so.
