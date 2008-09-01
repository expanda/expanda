#!/usr/bin/perl

use strict;
use warnings;
use eXpanda;


# eXpanda Sample Script No 21 (1)
#
# [NOTICE]
# "Demonstration of editing label of sample 20. this script load XML file and edit label, generate SIF formated file."
# Footage file is Ecoli interaction file from DIP database ('http://dip.doe-mbi.ucla.edu/')
# This script generate "sample21.sif"

my $str = eXpanda->new('Ecoli20060402.mif',
		      -filetype => 'xml',);



my $n_str = $str->Return(
			 -limit => [{
				     -object => 'node:information:fullName',
				     -operator => '=~',
				     -identifier => 'Hypothetical',
				    }],
			 -object => 'as_network',
			);

for my $label ( @{$n_str->Return(
		    -object => 'node:label',
		   )})
  {
    $label =~ /\s(.+?)$/;
    my $new_label = $1;
    $n_str->Apply(
		  -limit => [{
			      -object     => 'node:label',
			      -operator   => 'eq',
			      -identifier => $label,
			     }],
		  -object => 'node:label',
		  -value => $new_label,
		 );

  }

$n_str->out(
	    'sample21.sif',
	    -filetype => 'sif',
	   );

