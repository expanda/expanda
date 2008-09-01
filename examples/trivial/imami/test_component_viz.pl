#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use eXpanda qw/debug/;

my $str = {
	   'a' => { 'b' => 1},
	   'b' => {
		   'c' => 1,
		   'd' => 1,
		  },
	   'd' => { 'a' => 1 },
	  };

my $expanda = eXpanda->new($str, -filetype => 'str');

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


# $expanda->{node}->{a}->{component}->{nameD}->{label} = 'cmpD';
# $expanda->{node}->{a}->{component}->{nameE}->{label} = 'cmpE';
# $expanda->{node}->{a}->{component}->{nameF}->{label} = 'cmpA';
# $expanda->{node}->{a}->{component}->{nameG}->{label} = 'cmpB';
# $expanda->{node}->{a}->{component}->{nameH}->{label} = 'cmpC';
# $expanda->{node}->{a}->{component}->{nameI}->{label} = 'cmpD';
# $expanda->{node}->{a}->{component}->{nameJ}->{label} = 'cmpE';
# $expanda->{node}->{a}->{component}->{nameL}->{label} = 'cmpD';
# $expanda->{node}->{a}->{component}->{nameM}->{label} = 'cmpE';

$expanda->Apply(-object => 'node:graphics:w',
		-value => '60' );

$expanda->Apply(-object => 'node:graphics:type',
		-value => 'oval');

# $expanda->Apply(-object => 'node:graphics:smilepo',
#		-value => 'red',);

$expanda->Apply(-object => 'node:graphics:font-size',
		-value  => '15');

print Dumper $expanda;

$expanda->out('test.svg',
	      '-filetype' => 'svg'
	     );


