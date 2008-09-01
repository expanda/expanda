#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;

# eXpanda Sample Script No15
# "Extruct largest independent network from sample sif file."
# Generate "sample15.svg"


# Load sif file.
my $str = eXpanda->new('./sampledata/sample01.sif',
		       -filetype => 'sif',);


my $count = 0;
my $independent;

# return largest independent network.
for my $in (@{$str->Return(
			   -network => {
					-operator => 'independent',
				       },
			  )})
  {
    if( $count < scalar(keys %{$$in{node}}) )
      {
	$independent = $in;
      }
    $count =  scalar(keys %{$$independent{node}});
  }


# Apply graphics to node.
$independent->Apply(
		    -object => 'node:graphics:w',
		    -value => '30',
		   );

$independent->Apply(
		    -object => 'node:graphics:font-size',
		    -value => '10',
		   );

$independent->Apply(
		    -object => 'node:graphics:fill',
		    -value => '#00a968',
		   );


# Out as SVG file.
$independent->out('sample15.svg');
