#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;


# eXpanda Sample Script No 18
# "More than 750 interactions of human proteins with a potential role in ataxia, the neurodegenerative condition caused by cerebellar Purkinje cell degeneration. Lim et al."
# Footage file is from IntAct database.
# This script generate "sample18.svg"

my $str = eXpanda->new('./sampledata/16713569-01.xml',
		      -filetype => 'xml');


my $c_str = $str->Return(
			 -object => 'as_network',
			 -network => {
				      -operator => 'clique',
				      -threshold => 3,
				     },
			);

my $n_str;
print scalar(@{$c_str})."\n";
for (@{$c_str})
  {
    while( my ($node_id, $str) = each %{$$_{node}} )
      {
	$$n_str{node}{$node_id} = $str;
      }

    while( my ($source, $str1) = each %{$$_{edge}} )
      {
	while( my ($target, $str2 ) = each %{$str1} )
	  {
	    $$n_str{edge}{$source}{$target} = $str2;
	  }
      }

  }

bless $n_str, 'eXpanda';


$n_str->Analyze(
		-method => "degree",
	       );


$n_str->Apply(
	    -object => 'node:graphics:w',
	    -from => 'node:score:degree',
	    -value => {15 => '35'},
	   );

$n_str->Apply(
	    -object => 'node:graphics:width-stroke',
	    -value => 0,
	   );

$n_str->Apply(
	    -object => 'node:graphics:font-size',
	    -value => "13",
	   );

$n_str->Apply(
	    -object => 'node:graphics:fill',
	    -from => 'node:score:degree',
	    -value => { "#f7bd8f" => '#e95295'},
	   );


$n_str->out('sample18.svg');
