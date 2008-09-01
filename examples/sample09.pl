#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;


# eXpanda Sample Script No 9
#
# "Analyze demo 1. Apply connectivity to node graphics."
#
# This script generate "sample09.svg"

# load gml file.
my $str = eXpanda->new('./sampledata/cytoscape.gml');

# analyze degree.
$str->Analyze(
	      -method => 'degree'
	     );

# initialize graphics.
$str->Apply(
	    -object => 'edge:graphics:opacity',
	    -value  => '0.6',
	   );

$str->Apply(
	    -object => 'node:graphics:stroke-width',
	    -value  => '0',
	   );

# apply score to node graphics.
$str->Apply(
	    -label   => 'node:score:degree',
	   );




$str->Apply(
	    -object => 'node:graphics:w',
	    -value  => {'10' => '30'},
	    -from   => 'node:score:degree',
	   );

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -value  => {'5' => '15'},
	    -from   => 'node:score:degree',
	   );

$str->Apply(
	    -object => 'node:graphics:fill',
	    -value  => {'#bee0ce' => '#009944'},
	    -from   => 'node:score:degree',
	   );

# apply graphics from style file.

$str->Apply(
            -file => './sample.style',
            -object => 'all:graphics'
            );

# out as SVG file.

$str->out('sample09.svg', -no_edge_label => 1);
