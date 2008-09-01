#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;

# eXpanda Sample Script No 10
# "Analyzing method  demo ( normalized_degree ). apply score to node. label is score of normarized_degree."
# This script generate "sample10.svg"

# load sif file.
my $str = eXpanda->new('./sampledata/sample01.sif',
		      -filetype => 'sif');

# analyze normarized_degree.

$str->Analyze(
	      -method => 'normalized_degree',
	     );

# apply socre to node design.

$str->Apply(
	    -object => 'node:graphics:w',
	    -from => 'node:score:normalized_degree',
	    -value => {15 => '25'},
	   );

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -value => '8',
	   );

$str->Apply(
	    -object => 'node:graphics:stroke-width',
	    -value => '0',
	   );

$str->Apply(
	    -object => 'node:graphics:fill',
	    -from => 'node:score:normalized_degree',
	    -value => {'#eb6ea5' => '#d7003a'},
	   );

$str->Apply(
	    -label => 'node:score:normalized_degree',
	   );

# change node type 'heart' for node which have score greater 10.
$str->Apply(
	    -limit => [{
			-object => 'node:score:normalized_degree',
			-operator => '>=',
			-identifier => '5',
		       }],
	    -object => 'node:graphics:type',
	    -value => 'heart',
	   );

# out as SVG file.

$str->out('sample10.svg',-no_edge_label => 1);
