#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use eXpanda qw/debug/;


# eXpanda Sample Script No 17
# "Demonstration of visualizing huge interaction network."

# [NOTICE]
# Footage file is Ecoli interaction file from DIP database ('http://dip.doe-mbi.ucla.edu/')
# This script generate "sample17.svg"

my $str = eXpanda->new($ARGV[0],
		      -filetype => 'xml');

# Return clique. threashold equal 4.

$str->Analyze(-method => 'degree');

$str->Apply(
	    -object => 'node:graphics:w',
	    -value => '30',
	   );

$str->Apply(
	    -object => 'node:graphics:font-size',
	    -value => '11',
	   );

 $str->Apply(
 	    -object => 'node:graphics:fill',
 	    -value => 'heatcolor',
 	    -from  => 'degree'
 	   );

$str->out('sample17.svg');
