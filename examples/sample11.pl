#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;


# eXpanda Sample Script No 11
# "High-throughput mapping of a dynamic signaling network in mammalian cells. data from MINT database."
# Footage file is from MINT database ('http://mint.bio.uniroma2.it/mint/').
# You can download 15761153_psi1.xml from directory 'psi1' at FTP server of MINT.
# This script generate "sample11.svg"

my $str_original = eXpanda->new('./sampledata/15761153_psi1.xml');

my $count = 0;
my $str;

# return largest independent network.
for my $in (@{$str_original->Return(
				    -network => {
						 -operator => 'independent',
						},
				   )})
  {
    if( $count < scalar(keys %{$$in{node}}) )
      {
        $str = $in;
      }
    $count =  scalar(keys %{$$str{node}});
  }

# analyze connectivity.

$str->Analyze(
	      -method => 'connectivity',
	     );

#Apply Score to node width.

$str->Apply(
	    -object => 'node:graphics:w',
	    -from => 'node:score:connectivity',
	    -value => {'10' => '35'},
	   );


# initialize graphics.

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -value => '12',
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -value => '2.5',
	   );

# Apply information 'ncbiTaxid' to fill color.

my $limit_h = [{
		-object => 'node:information:ncbiTaxId',
		-operator => 'eq',
		-identifier => '9606',
	       }];

my $limit_mouse = [{
		-object => 'node:information:ncbiTaxId',
		-operator => 'eq',
		-identifier => '10090',
	       }];

$str->Apply(
	    -limit => $limit_h,
	    -object => 'node:graphics:fill',
	    -value => '#ec6800',
	   );

$str->Apply(
	    -limit => $limit_mouse,
	    -object => 'node:graphics:fill',
	    -value => '#949495',
	   );


# out as SVG

$str->out('sample11.svg');
