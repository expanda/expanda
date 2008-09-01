#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;


# eXpanda Sample Script No 21 (2)
# "Demonstration of editing label of sample 20. This script load GML file , and visualze."
# Footage file is Ecoli interaction file from DIP database ('http://dip.doe-mbi.ucla.edu/')
# This script generate "sample21.svg"


my $str = eXpanda->new('sample21.gml',
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



$str->out('sample21.svg');

