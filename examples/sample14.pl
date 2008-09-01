#!/usr/bin/perl

use strict;
use warnings;
use eXpanda;

# eXpanda Sample Script No14
# "demonstration of Apply Score of connectivity to label of node, apply style from Style-file."
# Generate "sample14.svg"

### new from gml file and import kegg pathway through KEGG API. ###

my $str = eXpanda->new('./sampledata/cytoscape.gml');

my $str_kegg = eXpanda->new('',
			    kegg => 'sce',
			   );

### analyze connectivity ###

$str->Analyze(
	      -method => 'connectivity',
	      );

### apply score of connectivity to node graphics ###

$str->Apply(
	    -from => 'node:score:connectivity',
	    -object => 'node:graphics:font-size',
	    -value => {8 => 18},
	    );

### apply score from sample style file to all graphics ###

$str->Apply(
	    -file => './samplestyle/sample.style',
	    -object => 'all:graphics'
	    );

### print to SATDOUT return array of node label which is match 'Y' by regexp ###

print @{$str->Return(
	    -limit => [{
		-object => 'node:label',
		-operator => '=~',
		-identifier => 'Y',
	    }],
	     -object => 'node:label'
	     )};

### initialize node/edge graphics ###

$str->Apply(
	    -object => 'node:graphics:opacity',
	    -value => 1,
	    );
$str->Apply(
	    -object => 'node:graphics:fill',
	    -value => "#000000",
	    );
$str->Apply(
	    -object => 'node:graphics:stroke-opacity',
	    -value => 0,
	    );

$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -value => 1,
	    );
$str->Apply(
	    -object => 'edge:graphics:opacity',
	    -value => 0.5,
	    );

$str->Apply(
	    -object => 'node:graphics:w',
	    -value => 6,
	    );

### rewrite label by connectivity score ###

$str->Apply(
	    -label => 'node:score:connectivity',
	    );


### output as svg file ###


$str->out('sample14.svg',
	  -no_edge_label => 1,
	  );
