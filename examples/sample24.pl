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

$str->Analyze(-method => 'degree');

$str->Apply(
	    -object => 'node:graphics:w',
	    -value  => { 15 => 25 },
	    -from   => 'node:score:degree',
	   );

$str->Apply(
	    -object => 'node:graphics:fill',
	    -value  => 'heat',
	    -from   => 'node:score:degree',
	   );

$str->out('sample24.svg',
	  -filetype=>'svg',
	  -no_direction => 0,
	 );
