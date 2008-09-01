#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;


# eXpanda Sample Script No 4
# "Demonstration of Apply design demo ( changing node design )"
# This script generate "sample04.svg"

# load gml file.
my $str = eXpanda->new('./sampledata/cytoscape.gml');

# Apply design to node.

$str->Apply(
	    -object => 'node:graphics:w',
	    -value  => '25',
	   );

$str->Apply(
	    -object => 'node:graphics:fill',
	    -value  => '#ffd900',
	   );

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -value  => '10',
	   );

$str->Apply(
	    -object => 'node:graphics:opacity',
	    -value  => '0.7',
	   );

$str->Apply(
	    -object => 'node:graphics:font-family',
	    -value => 'Times',
	   );

# Out as SVG file.

$str->out('sample04.svg');
