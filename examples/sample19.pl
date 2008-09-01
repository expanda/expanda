#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;


# eXpanda Sample Script No 19
# " A protein-protein interaction network for human inherited ataxias and disorders of Purkinje cell degeneration. "
# Footage file is from IntAct Database.
# This script generate "sample19.svg"

my $str = eXpanda->new('./sampledata/16713569-01.xml',
		      -filetype => 'xml',);



$str->Analyze(
	      -method => 'clique',
	     );

$str->Apply(
	    -object => 'node:graphics:width-stroke',
	    -value => '0',
	   );

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -value => '9',
	   );


$str->Apply(
	    -object => 'node:graphics:w',
	    -from => 'node:score:clique',
	    -value => { '15' => '25' },
	   );

$str->Apply(
	    -object => 'node:graphics:fill',
	    -from   => 'node:score:clique',
	    -value  => { '#d1bada' => '#7f1184' },
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -from   => 'edge:score:clique',
	    -value  => { '1' => '2' },
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke',
	    -from   => 'edge:score:clique',
	    -value  => { '#d1bada' => '#7f1184' },
	   );


$str->out('sample19.svg');
