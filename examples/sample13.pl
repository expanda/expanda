#!/usr/bin/perl

use warnings;
use strict;
use eXpanda;


# eXpanda Sample Script No13.
# "Extruct independent network from network extructed by connectivity greater or equal threshold = 10. and calculate clique and apply to edge design."
# Generate "sample13.svg"

### new object from gml file ###

my $str = eXpanda->new('./sampledata/cytoscape.gml',
		       -filetype => 'gml',);

$str->Apply(
	    -reset => 'all',
	   );

### analyze connectivity ###

$str->Analyze(
	      -method => 'connectivity',
	     );

### return network by limit ###

my $limit = [{
	      -object     => 'node:score:connectivity',
	      -operator   => 'top',
	      -identifier => '30',
	     }];

my $new_str = $str->Return(
			   -limit  => $limit,
			   -object => 'as_network',
			  );

### initialize node design ###

$new_str->Apply(
	    -object => 'node:graphics:font',
	    -value  => 'Gill Sans',
	   );

### apply connectivity score to graphics of node ###

$new_str->Apply(
		-object => 'node:graphics:font-color',
		-from => 'node:score:connectivity',
		-value => {'#3eb370' => '#0095d9'},
	       );


$new_str->Apply(
		-object => 'node:graphics:font-size',
		-from => 'node:score:connectivity',
		-value => {'5' => '25'},
	       );

### extruct largest independent netwotk ###

my $count = 0;
my $independent;
for my $net (@{$new_str->Return(-network => { -operator => 'independent',},)})
  {
    if( $count < scalar(keys %{$$net{node}}) )
      {
	$independent = $net;
      }
    $count =  scalar(keys %{$$independent{node}});
  }

print scalar(keys %{$independent});

### analyze independent network by method "clique" ###

$independent->Analyze(
		  -method => 'clique',
		 );

### apply clique score to node/edge graphics by limit option###

my $c_limit = [{
		-object => 'node:score:clique',
		-operator => '>',
		-identifier => '2',
	       }];

my $r_limit =  [{
		-object => 'node:score:clique',
		-operator => '==',
		-identifier => '2',
	       }];

my $e_limit = [{
		-object => 'edge:score:clique',
		-operator => '>',
		-identifier => '2',
	       }];

$independent->Apply(
		    -limit => [
			       -object => 'edge:label',
			       -operator => 'eq',
			       -identifier => 'pd'
			      ],
		    -object => 'edge:graphics:stroke-dash',
		    -value => '2,1',
		   );


$independent->Apply(
		    -object => 'node:graphics:w',
		    -from => 'node:score:connectivity',
		    -value => {10 => '35'},
		   );

$independent->Apply(
		    -limit => $e_limit,
		    -object => 'edge:graphics:stroke',
		    -value => 'magenta',
		   );

$independent->Apply(
		-limit => $c_limit,
		-object => 'node:graphics:fill',
		-value => 'magenta',
	       );

$independent->Apply(
		-limit => $r_limit,
		-object => 'node:graphics:opacity',
		-value => '0',
	       );

my $info = $independent->Return(
				-get_information => {
						     -object => 'node:label',
						     -from => 'kegg',
						     -to => 'DEFINITION',
						     -organism => 'sce',
						    },
				-hash => 1,
			       );

while( my ( $node, $def ) = each %{$info} )
  {
    print "$node\t$def\n";

    $def =~ /^\s+?(.+?)\s(.+?)\s/m;
    my $label = $1." ".$2."...";
    print "$node\t$label\n";

    $independent->Apply(
			-limit => [{
				    -object => 'node:label',
				    -operator => 'eq',
				    -identifier => $node,
				   }],

			-object => 'node:graphics:url',
			-value => $def,
		       );


    $independent->Apply(
			-limit => [{
				    -object => 'node:label',
				    -operator => 'eq',
				    -identifier => $node,
				   }],
			-object => 'node:label',
			-value => $label,
		       );


  }


### output as svg ###

$independent->out("sample13.svg",
		  -no_edge_label => 1,
		 );

