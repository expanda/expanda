#!/usr/bin/perl

use strict;
use warnings;
use eXpanda qw{debug};
use Carp qw[confess];
use Data::Dumper;

my $egfr = eXpanda->new($ARGV[0],
	-filetype => 'xml',
);

$egfr->out("egfr_gv.svg",
	-width => '500',-height => '500',

	-engine => 'GraphViz',
);



