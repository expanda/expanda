#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;


# eXpanda Sample Script No 20 (2)
#
# "demonstration of converting file format XML to sif, and output SVG from Cytoscape GML which modified network form."
#
# this script generate "sample20.svg"

my $str = eXpanda->new('sample20.gml',
		      -filetype => 'gml',);




$str->Apply(
	      -object => 'node:graphics:w',
	      -value => '20',
	     );

$str->Apply(
	      -object => 'node:graphics:font-size',
	      -value => '11',
	     );

$str->Apply(
	      -object => 'node:graphics:fill',
	      -value => '#87cefa',
	     );

$str->Apply(
	      -object => 'edge:graphics:stroke-width',
	      -value => '3',
	     );



$str->out('sample20.svg');




