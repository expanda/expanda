#!/usr/bin/perl

use strict;
use warnings;
use eXpanda qw{debug};
use Carp qw[confess];
use Data::Dumper;

my $egfr = eXpanda->new($ARGV[0],
	-filetype => 'xml',
);

$egfr->Apply(-object => 'node:graphics:w',
				 -value => 20,
				);

$egfr->out("egfr_gv.svg",
	-width => '2000',
	-no_direction => 0,
	-engine => 'GraphViz',
);


__END__



