#!/usr/bin/perl

# Check memory usage without accounting for cached and buffered data.

# Copyright (c) 2013, Mark Meyer (ofosos@gmail.com)

use strict;
use warnings;

use Nagios::Plugin;
use Data::Dumper;

sub fmt_mem {
  my ($mem) = @_;

  my @units = ('kB', 'MB', 'GB', 'TB');

  my $unit = 0;

  while ($mem > 2048 and $unit < @units) {
    $mem = $mem / 1024;
    $unit ++;
  }

  return sprintf("%.2f %s", $mem, $units[$unit]);
}

my $meminfo = `cat /proc/meminfo`;
my @memlines = split(/\n/, $meminfo);
my %data = map { my ($k,$v) = $_ =~ /^(.+):[ ]*([0-9]+)/; $k => $v } @memlines;

my $freemem = $data{MemTotal} - $data{Buffers} - $data{SwapCached} - $data{Cached};

my $memuse = $data{MemTotal} - $freemem;
my $memuse_p = 100 - $freemem * 100 / $data{MemTotal};

my $swapuse_p = 100 - $data{SwapFree} * 100 / $data{SwapTotal};

my $msg = 
 sprintf("Memory Usage physical: %.2f%% (%s of %s), swap: %.2f%% (%s of %s)\n", 
	$memuse_p, 
	fmt_mem($memuse), 
	fmt_mem($data{MemTotal}), 
	$swapuse_p, 
	fmt_mem($data{SwapTotal} - $data{SwapFree}), 
	fmt_mem($data{SwapTotal})
	);

my $us = <<FIN;
Usage:
  %s [ -v | --verbose]
     [-c|--critical=<badthreads> ]
     [-w|--warning=<badthreads> ]

For example:
  %s -w 50 -c 75

FIN

my $np = Nagios::Plugin->new( shortname => 'MEMORY',
        usage => $us,
        );

$np->add_arg(
        spec => 'warning|w=i',
        help => '-w, --warning=INTEGER warn at this percentage',
        required => 1,
        );

$np->add_arg(
	spec => 'critical|c=i',
	help => '-c, --critical=INTEGER critical at this percentage',
	required => 1,
	);

$np->getopts;

$np->add_perfdata(
	label => 'Physical memory (pct)',
	value => $memuse_p,
	uom => '%',
	);

$np->add_perfdata(
	label => 'Physical memory',
	value => $memuse,
	uom => 'kb',
	);

$np->add_perfdata(
	label => 'Swap memory (pct)',
	value => $swapuse_p,
	uom => '%',
	);

$np->add_perfdata(
	label => 'Swap memory',
	value => $data{SwapTotal} - $data{SwapFree},
	uom => 'kb',
	);

my $total_p = ($swapuse_p + $memuse_p) / 2;

if ($total_p >= $np->opts->warning) {
	if( $total_p >= $np->opts->critical) {
		$np->nagios_exit(CRITICAL, $msg);
	}

	$np->nagios_exit(WARNING, $msg);
}

$np->nagios_exit(OK, $msg);
