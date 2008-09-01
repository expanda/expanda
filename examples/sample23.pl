#!/usr/bin/perl
use strict;
use warnings;

use eXpanda qw/debug/;
use Data::Dumper;
# eXpanda Sample Script No 23
#
# Draw inhibit mark as edge arrow.
#
# footage : sample23.sif

 my $str = eXpanda->new('./sampledata/sample01.sif',
			-filetype => 'sif',);

$str->Apply(-object => 'edge:graphics:stroke',
	    -value => '#777' );

$str->Apply(-object => 'edge:graphics:type',
	    -value => 'inhibit' );

$str->Apply(-object => 'node:graphics:w',
	    -value => 15 );

$str->Apply(-object => 'edge:graphics:stroke-width',
	    -value => 2 );

#$str->Apply(-object => 'edge:graphics:stroke-dash',
#	    -value => '1,1' );

# node:information:foovar = makutanpaku
#

$str->out('sample23.svg',
	  -filetype=>'svg',
	  -no_direction => 0,
	 );
