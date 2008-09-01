#!/usr/bin/perl -w
use strict;
use lib "../lib";
use eXpanda;
use Data::Dumper;

# eXpanda Demo Script No8
#
# 'Calculate normarized degree and clique, and apply score of these analysis to node and label design. then rewrite node label to reflect score of normarized degree.'
#
# Generate 'sample08.svg'

my $str = eXpanda->new( "$ARGV[0].sif",
			-filetype => 'sif',
);

# Analyze

$str->Analyze(
	      -method => 'MCL',
	      -option => {
			  -r => 2,
			  -d => 0,
			  -t => 10,
			 },
	     );

# Initialize design.

$str->Apply(
	    -object => 'node:graphics:w',
	    -value  => '30',
	   );

$str->Apply(
	    -object => 'node:graphics:font-family',
	    -value  => 'Arial',
	   );

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -value  => '10',
	   );

$str->Apply(
	    -object => 'edge:graphics:opacity',
	    -value  => '0.5',
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -value  => '1',
	   );

# Apply Score


# Out

$str->out( 'mcl_cytoscape.svg' , -no_edge_label => 1 );
