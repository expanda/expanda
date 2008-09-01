#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use eXpanda qw/debug/;

my $str = {
	   'a' => { 'b' => 1 ,
		    'c' => 1 ,
		  },
	   'b' => {
		   'g' => 1,
		   'd' => 1,
		  },
	   'c' => { 'e' => 1 ,
		    'f' => 1 ,
		  },
	   'g' => { 'd' => 1 },
	  };

my $expanda = eXpanda->new($str, -filetype => 'str');

$expanda->{node}->{a}->{graphics}->{start} = 1;

$expanda->{node}->{a}->{component}->{nameA} = {
					       label => 'cmpA',
					       graphics => {
							    'font-color' => '#000000',
							    fill       => 'blue',
							   }
					      };
$expanda->{node}->{a}->{component}->{nameB} = {
					       label => 'cmpB',
					       graphics => {
							    'font-color' => '#000000',
							    fill       => 'blue',
							    opacity    => 0.5,
							   }
					      };
$expanda->{node}->{a}->{component}->{nameC} = {
					       label => 'cmpC',
					       graphics => {
							    'font-color' => '#000000',
							    fill       => 'red',
							   }
					      };
$expanda->Apply(-object => 'node:graphics:w',
		-value => '30' );

$expanda->Apply(-object => 'node:graphics:type',
		-value => 'oval');

$expanda->Apply(-object => 'node:graphics:font-size',
		-value  => '15');

$expanda->out('layout.svg',
	      '-filetype' => 'svg',
	      '-engine' => 'Phospho',
	     );


