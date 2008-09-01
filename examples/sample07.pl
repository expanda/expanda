#!/usr/bin/perl
use warnings;
use strict;

use eXpanda;

# eXpanda Demo Script No7
# 'Calculate normarized degree and clique, and apply score of these analysis to node and label design. then rewrite node label to reflect score of normarized degree.'
# This script generate 'sample07.svg'

my $str = eXpanda->new('./sampledata/cytoscape.gml',
		      -filetype => 'gml',);
# Analyze

$str->Analyze(
	      -method => 'normalized_degree',
	     );

$str->Analyze(
	      -method => 'clique',
	     );



# Initialize design.

$str->Apply(
	    -object => 'node:graphics:opacity',
	    -value  => '0',
	   );

$str->Apply(
	    -object => 'node:graphics:font-family',
	    -value  => 'Arial',
	   );

$str->Apply(
	    -object => 'edge:graphics:opacity',
	    -value  => '0.5',
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -value  => '1.5',
	   );

# Apply Score

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -from => 'node:score:normalized_degree',
	    -value  => {'15' => '30'},
	   );

$str->Apply(
	    -object => 'node:graphics:font-color',
	    -from => 'node:score:normalized_degree',
	    -value  => {'#e6cde3' => '#e597b2'},
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -from => 'edge:score:clique',
	    -value => { 2 => 3 },
	   );

# Out as SVG file.

$str->out( 'sample07.svg' , -no_edge_label => 1 );
