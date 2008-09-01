#!/usr/bin/perl
use strict;
use warnings;

use eXpanda qw/debug/;

# eXpanda Sample Script No 1
#
# Generating SVG file from sif file.
#
# footage : sample01.sif

 my $str = eXpanda->new('./sampledata/sample01.sif',
 		       -filetype => 'sif',);

$str->out('sample01.svg',
	  -filetype=>'svg',
	  -no_direction => 0,
	 );
