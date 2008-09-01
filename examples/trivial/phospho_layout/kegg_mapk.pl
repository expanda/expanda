#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use eXpanda qw/debug/;

my $expanda = eXpanda->new($ARGV[0], -filetype => 'kgml');

my @node

 for ( keys %{$expanda->{node}} ) {

#   $expanda->{node}->{$_}->{graphics}->{start} = 0;
 }

$expanda->Analyze(-method => 'degree' );

my $map = [{
	        -object => 'node:information:type',
	        -operator => 'eq',
	        -identifier => 'map',
	       }];


$expanda->Apply( -object => 'node:graphics:start',
		 -value  => 1,
		 -limit => [{
			     -object => 'node:label',
			     -identifier => 'EGFR',
			     -operator => '=~',
			    },],
	       );

$expanda->Apply(
	        -limit  => $map,
	        -object => 'node:graphics:type',
	        -value  => 'diamond',
	       );

$expanda->Apply(
		-limit  => $map,
		-object => 'node:graphics:opacity',
		-value  => 0.5,
	       );

$expanda->Apply(-object => 'node:graphics:fill',
		-from => 'node:score:degree',
		-value => 'heat' );

$expanda->Apply(-object => 'node:graphics:w',
		-value => '15' );

$expanda->Apply(-object => 'node:graphics:type',
		-value => 'oval');

$expanda->Apply(-object => 'node:graphics:font-size',
		-value  => '10');

$expanda->out('EGFR.svg',
	      '-filetype' => 'svg',
	      '-engine' => 'Phospho',
	     );

