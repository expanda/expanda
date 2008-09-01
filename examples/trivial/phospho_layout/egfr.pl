#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use eXpanda qw/debug/;

my $expanda = eXpanda->new($ARGV[0], -filetype => 'xml');

#print Dumper $expanda;

for ( keys %{$expanda->{node}} ) {
  $expanda->{node}->{$_}->{graphics}->{start} = 0;
}

$expanda->Apply( -object => 'node:graphics:start',
		 -value  => 1,
		 -limit => [{
			     -object => 'node:label',
			     -identifier => 'EGFR',
			     -operator => '=~',
			    }],
	       );

$expanda->Analyze(-method => 'degree' );

$expanda->Apply(-object => 'node:graphics:fill',
		-from => 'node:score:degree',
		-value => 'heat' );

$expanda->Apply(-object => 'node:graphics:w',
		-value => '15' );

$expanda->Apply(-object => 'node:graphics:type',
		-value => 'oval');

$expanda->Apply(-object => 'node:graphics:font-size',
		-value  => '10');

$expanda->out('EGFR.gml',
	      '-filetype' => 'gml',
	      '-engine' => 'Phospho',
	     );

