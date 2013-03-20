monitoring-perl
===============

A repository for Nagios/Icinga perl plugins I use. All copyrighted by my
employer, but mostly developed at home.

check_mysql_threads.pl

  Verify that mysql is not hitting it's maximum number of threads.
  Also check that threads don't remain longer than <n> seconds in a state.
