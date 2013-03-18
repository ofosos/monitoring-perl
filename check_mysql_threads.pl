#!/usr/bin/perl

# check_mysql_threads.pl - Check if mysql has bad threads.
#
# Mysql threads should only ever spend a long time in a single state,
# when that state is 'Sleep'. On any other occasion spending a lot of
# time is an indicator that some things are seriously wrong.

# Copyright (c) 2013 - akquinet outsourcing gGmbH
# Written by Mark Meyer (mark.meyer@akquinet.de)

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

$np->getopts;

my $dbh = DBI->connect('DBI:mysql:mysql:' . $np->opts->host, $np->opts->user, $np->opts->password)
	or die "Couldn't connect to database: " . DBI->errstr;

my $sth = $dbh->prepare('show full processlist');

$sth->execute();

my $threads = $sth->fetchall_arrayref({});

my @badthreads = ();

for my $t (@{$threads}) {
	if ($t->{Time} > $np->opts->limit && $t->{Command} !~ /Sleep/i) {
		push @badthreads, $t;
	}
}

my @msg = ();
for my $t (@badthreads) {
	push @msg, "u=" . $t->{User} . ",c=" . $t->{Command} . ",t=" . $t->{Time} . ",s=" . $t->{State} . ",i=" . $t->{Info};
}


my $msgtxt;
if (@msg > 0) {
	$msgtxt = "Bad threads detected: " . join('; ',@msg);
} else {
	$msgtxt = "No bad threads detected.";
}

if (@msg > $np->opts->warning) {
	if (@msg > $np->opts->critical) {
		$np->nagios_exit(CRITICAL, $msgtxt);
	}

	$np->nagios_exit(WARNING, $msgtxt);
}

$np->nagios_exit(OK, $msgtxt);


