#!/usr/bin/perl

use warnings;
use strict;
use eXpanda;

# eXpanda Sample Script No5
#
# "Apply score of Accuracy and Degree to two networks design (node fill, node opacity, node width). and changing label SGD-id to GeneName"
#
# Generate "sample05.svg"

### New from gml & sif ###
my $str = eXpanda->new('./sampledata/cytoscape.gml',
		       -filetype => 'gml',);

my $str_kegg = eXpanda->new('./sampledata/kegg_sce2.sif');

### Analysis ####

 
$str->Analyze(
	      -method => 'accuracy',
	      -option => {
			  -with => $str_kegg,
			  -with_object => "node:label",
			 },
	     );

$str->Analyze(
	      -method => 'degree',
	     );


### Initialize design ####
$str->Apply(
	    -object => 'node:graphics:fill',
	    -value => '#008db7',
	   );

$str->Apply(
	    -object => 'node:graphics:stroke',
	    -value => '#008db7',
	   );



$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -value => '2.5',
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke',
	    -value => '#008db7',
	   );


$str->Apply(
	    -object => 'edge:graphics:opacity',
	    -value => '0.5',
	   );

$str->Apply(
	    -object => 'node:graphics:opacity',
	    -from => 'node:score:degree',
	    -value => {'0.5' => '1'},
	   );


$str->Apply(
	    -object => 'node:graphics:w',
	    -from => 'node:score:degree',
	    -value => {15 => 30},
	   );

$str->Apply(
	    -object => 'node:graphics:stroke-width',
	    -from => 'node:score:degree',
	    -value => {"0.5" => "5"},
	   );

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -from => 'node:score:degree',
	    -value => {8 => 15},
	   );



### Apply Design from Accuracy ###

my $limit =  [{
	       -object => "node:score:accuracy",
	       -operator => ">",
	       -identifier => 0,
	      }];

my $limit2 =  [{
		-object => "node:score:accuracy",
		-operator => "==",
		-identifier => 0,
	       }];

$str->Apply(
	    -limit => $limit,
	    -object => 'node:graphics:fill',
	    -value => '#c70067',
	   );

$str->Apply(
	    -limit => $limit,
	    -object => 'node:graphics:stroke',
	    -value => '#c70067',
	   );
$str->Apply(
	    -limit => [{
			-object => 'edge:score:accuracy',
			-operator => '==',
			-identifier => '1',
		       }],
	    -object => 'edge:graphics:stroke',
	    -value => '#c70067',
	   );


for( @{$str->Return(
		    -limit => [{
				-object => 'node:score:accuracy',
				-operator => '>',
				-identifier => 0,
			       }],
		    -object => 'node:label',
		   )}){
  my $original = $_;
  my $name = $str->Return( 
			  -limit => [{
				      -object => 'node:label',
				      -operator => 'eq',
				      -identifier => $_,
				     }],
			  -hash => 1,
			  -object => 'node:label',
			  -get_information => {
					       -object => "node:label",
					       -from => 'kegg',
					       -to => 'NAME',
					      });
  eval{
    $str->Apply(
		-limit => [{
			    -object => "node:label",
			    -operator => 'eq',
			    -identifier => "$original",
			   }],
		-object => "node:label",
		-value => $$name{$original}[0],
	       );};
  if($@){
    print $original."\n";
  }
}



$str->Apply(
	    -limit => $limit2,
	    -object => 'node:graphics:font-opacity',
	    -value => 0,
	   );


$str->Analyze(
	      -method => 'clique',
	     );


my $limit3 = [{
	      -object => 'edge:score:clique',
	      -operator => '==',
	      -identifier => '3',
	     }];

$str->Apply(
	    -limit => $limit3,
	    -object => 'edge:graphics:stroke',
	    -value => '#004d25',
	   );

$str->Apply(
	    -limit => $limit3,
	    -object => 'edge:graphics:opacity',
	    -value => '0.8',
	   );
$str->Apply(
	    -limit => $limit3,
	    -object => 'edge:graphics:stroke-width',
	    -value => '7.5',
	   );


### Output ###
$str->out("sample05.svg",-no_edge_label => 1);

