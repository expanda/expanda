#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;

# eXpanda Sample Script No 3
# "Changing design demo."
# This script generate 'sample03.svg'


# load gml file.
my $str = eXpanda->new('./sampledata/cytoscape.gml');

#apply design to node.
$str->Apply(
	    -object =>'node:graphics:w',
	    -value => '0',
	   );

$str->Apply(
	    -object =>'node:graphics:opacity',
	    -value => '0',
	   );

$str->Apply(
	    -object =>'node:graphics:font-size',
	    -value => '11',
	   );

$str->Apply(
	    -object =>'node:graphics:font-color',
	    -value => '#7f1184',
	   );

# apply design to edge.

$str->Apply(
	    -object =>'edge:graphics:opacity',
	    -value => '0.5',
	   );


# out as SVG file
$str->out('sample03.svg',
	 -no_edge_label => 1);
