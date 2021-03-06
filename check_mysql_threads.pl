#!/usr/bin/perl

# check_mysql_threads.pl - Check if mysql has bad threads.
#
# Mysql threads should only ever spend a long time in a single state,
# when that state is 'Sleep'. On any other occasion spending a lot of
# time is an indicator that some things are seriously wrong.

# Copyright (c) 2013 - akquinet outsourcing gGmbH
# Written by Mark Meyer (mark.meyer@akquinet.de)

# Notes:
# This requires a user with PROCESS privileges.

use strict;
use warnings;

use Nagios::Plugin;
use DBI;

my $us = <<FIN;
Usage:
  %s [ -v | --verbose]
     [-H <host>]
     [-u|--user=<database username> ]
     [-p|--password=<database password> ]
     [-c|--critical=<badthreads> ]
     [-w|--warning=<badthreads> ]
     [-t|--warnthreads=<maxthreads> ]
     [-s|--critthreads=<maxthreads> ]

FIN

my $np = Nagios::Plugin->new( shortname => 'BADTHREADS',
	usage => $us,
	);

$np->add_arg(
	spec => 'warning|w=i',
	help => '-w, --warning=INTEGER limit of bad threads',
	required => 1,
	default => 1,
	);

$np->add_arg(
	spec => 'critical|c=i',
	help => '-c, --critical=INTEGER limit of bad threads',
	required => 1,
	default => 10,
	);

$np->add_arg(
	spec => 'host|H=s',
	help => '-H, --host=STRING database host to check',
	required => 1,
	);

$np->add_arg(
	spec => 'user|u=s',
	help => '-u, --user=STRING database user',
	);

$np->add_arg(
	spec => 'password|p=s',
	help => '-p, --password=STRING database password',
	);

$np->add_arg(
	spec => 'limit|l=i',
	help => '-l, --limit=INTEGER limit in seconds to consider a thread bad',
	required => 1,
	default => 10,
	);

$np->add_arg(
	spec => 'warnthreads|t=i',
	help => '-m, --maxthreads=INTEGER warning level of threads',
	);

$np->add_arg(
	spec => 'critthreads|s=i',
	help => '-u, --critthreads=INTEGER critical level of threads',
	);

$np->getopts;

my $dbh = DBI->connect('DBI:mysql:mysql:' . $np->opts->host, $np->opts->user, $np->opts->password)
	or $np->nagios_die("Couldn't connect to database: " . DBI->errstr);

my $sth = $dbh->prepare('show full processlist');

$sth->execute();

my $threads = $sth->fetchall_arrayref({});

my @badthreads = ();

my $cntthreads = 0;
my %threadstatus = ();

for my $t (@{$threads}) {
	if ($t->{Time} > $np->opts->limit && $t->{Command} !~ /Sleep/i) {
		push @badthreads, $t;
	}
	if (defined($threadstatus{$t->{Command}})) {
		$threadstatus{$t->{Command}} ++;
	} else {
		$threadstatus{$t->{Command}} = 1;
	}
	$cntthreads ++;
}

my @msg = ();
for my $t (@badthreads) {
	push @msg, "u=" . $t->{User} . ",c=" . $t->{Command} . ",t=" . $t->{Time} . ",s=" . $t->{State} . ",i=" . $t->{Info};
}

$np->add_perfdata(
	label => 'Total threads',
	value => $cntthreads,
	);

for my $k (keys(%threadstatus)) {
	$np->add_perfdata(
		label => $k,
		value => $threadstatus{$k},
		);
}

my $msgtxt;

$msgtxt = "Overall $cntthreads active threads. ";

if (@msg > 0) {
	$msgtxt .= "Bad threads detected: " . join('; ',@msg);
} else {
	$msgtxt .= "No bad threads detected.";
}

if (@msg > $np->opts->warning) {
	if (@msg > $np->opts->critical) {
		$np->nagios_exit(CRITICAL, $msgtxt);
	}

	if ($np->opts->critthreads and $np->opts->critthreads <= $cntthreads) {
		$np->nagios_exit(CRITICAL, $msgtxt);
	} else {
		$np->nagios_exit(WARNING, $msgtxt);
	}
}

if ($np->opts->warnthreads and $np->opts->warnthreads <= $cntthreads) {
	$np->nagios_exit(WARNING, $msgtxt);
}
$np->nagios_exit(OK, $msgtxt);


