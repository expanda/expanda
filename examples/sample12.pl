#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;

# eXpanda Sample Script No 12
# "Visualizing pathway database flat file."

# [NOTICE]
# Footage file is from KEGG pathway database (http://www.genome.jp/kegg/xml).
# You can download from directory 'KGML' at FTP server of KEGG.
# This script generate "sample12.svg"

my $str_original = eXpanda->new('./sampledata/eco00010.xml',
				-filetype => 'kgml');

my $count = 0;
my $str;

for my $in (
	    @{$str_original->Return(
				    -network => {
						 -operator => 'independent',
						},
				   )}
	   )
  {
    if( $count < scalar(keys %{$$in{node}}) )
      {
        $str = $in;
      }
    $count =  scalar(keys %{$$str{node}});
  }


$str->Apply(
	    -object => 'node:graphics:font-size',
	    -value  => '10',
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke-width',
	    -value  => '2.2',
	   );

$str->Apply(
	    -limit => [{
			-object => 'edge:graphics:label',
			-operator => 'eq',
			-identifier => 'maplink',
		       }],
	    -object => 'edge:graphics:opacity',
	    -value => '0.5',
	   );

my $map = [{
	    -object => 'node:information:type',
	    -operator => 'eq',
	    -identifier => 'map',
	   }];

$str->Apply(
	    -limit  => $map,
	    -object => 'node:graphics:fill',
	    -value  => '#e73562',
	   );


$str->Apply(
	    -limit  => $map,
	    -object => 'node:graphics:w',
	    -value  => '25',
	   );


$str->Apply(
	    -limit  => $map,
	    -object => 'node:graphics:type',
	    -value  => 'diamond',
	   );

$str->Apply(
	    -limit  => $map,
	    -object => 'node:graphics:stroke-width',
	    -value  => '0',
	   );

$str->Apply(
	    -limit  => $map,
	    -object => 'node:graphics:opacity',
	    -value  => '0.65',
	   );

my $enzyme = [{
	       -object => 'node:information:type',
	       -operator => 'eq',
	       -identifier => 'enzyme',
	      }];

$str->Apply(
	    -limit => $enzyme,
	    -object => 'node:graphics:w',
	    -value => '13',
	   );

$str->Apply(
	    -limit => $enzyme,
	    -object => 'node:graphics:fill',
	    -value => '#fff352',
	   );

$str->Apply(
	    -limit => $enzyme,
	    -object => 'node:graphics:stroke-width',
	    -value => '0',
	   );

my $gene = [{
	       -object => 'node:information:type',
	       -operator => 'eq',
	       -identifier => 'gene',
	      }];

$str->Apply(
	    -limit => $gene,
	    -object => 'node:graphics:fill',
	    -value => '#f08300',
	   );

$str->Apply(
	    -limit => $gene,
	    -object => 'node:graphics:w',
	    -value => '20',
	   );


# out put as SVG file.

$str->out('sample12.svg');
