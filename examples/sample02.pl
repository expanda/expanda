#!/usr/bin/perl
use strict;
use warnings;
use lib "../lib";
use eXpanda;

# eXpanda Sample Script No2
# "Most simple use-case of eXpanda."
# This script generate 'sample02.svg'

my $str = eXpanda->new('./sampledata/cytoscape.gml');

$str->out('sample02.svg')
