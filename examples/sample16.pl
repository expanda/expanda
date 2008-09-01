#!/usr/bin/perl -w
use strict;
use warnings;

use eXpanda;

# eXpanda Demo Script No.16
# 'Demonstration of Rewriting Label of node in cytoscape gml file.'
# This file generate 'sample16.svg'

my $str = eXpanda->new('./sampledata/circle.gml',
		      -filetype => 'gml',);
# Analyze

$str->Analyze(
	      -method => 'normalized_degree',
	     );

$str->Analyze(
	      -method => 'clique',
	     );

# Initialize graphics.

$str->Apply(
	    -object => 'node:graphics:opacity',
	    -value  => '0',
	   );

$str->Apply(
	    -object => 'node:graphics:font-family',
	    -value  => 'Futura',
	   );

$str->Apply(
	    -object => 'edge:graphics:opacity',
	    -value  => '0.75',
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -value  => '1.5',
	   );

# Apply Score

$str->Apply(
	    -object => 'node:graphics:font-opacity',
	    -value  => '1',
	   );


$str->Apply(
	    -label => 'node:score:normalized_degree'
	   );

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -from => 'node:score:normalized_degree',
	    -value  => {'10' => '45'},
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke',
	    -from   => 'edge:score:clique',
	    -value  => {'#000000' => '#FF0000'},
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -from => 'edge:score:clique',
	    -value => { 2 => 4 },
	   );

# Out

$str->out( 'sample16.svg' , -no_edge_label => 1 );
