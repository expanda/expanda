#!/usr/bin/perl

use strict;
use warnings;
use eXpanda qw{debug};
use eXpanda::Graphics::Color;
use Carp qw[confess];
use Data::Dumper;

my $egfr = eXpanda->new($ARGV[0],
	-filetype => 'xml',
);

$egfr->Apply(
	-object => 'node:component',
	-file   => $ARGV[1], #'EGFR1pathway_usosites.txt',
	-component_label  => 5,
	-owner_label  => 1,
	-import_information => ['Seq', '0min', '5min', '10min', '20min' ]
);

$egfr->Apply(
	-object => 'node:graphics:start',
	-value  => 1,
	-limit => [{
		-object => 'node:label',
		-operator => '=~',
		-identifier => 'EGFR',
	}],
);

$egfr->Apply(-object => 'node:graphics:w',
	-value => '20' );

$egfr->Apply(-object => 'node:graphics:type',
	-value => 'oval');

$egfr->Apply(-object => 'node:graphics:font-size',
	-value  => '10');

# coloring component #
# #ffd900 => #fff7cc, 10
my @color = eXpanda::Graphics::Color->gradient('#ffd900', '#fff7cc', 100);

for my $minlabel ('0min','5min', '10min', '20min') {
	my @ordered_ratio;

	while ( my ($id, $nstr) = each %{$egfr->{node}} ) {
		my $comp = $nstr->{component};
		next unless defined $comp;
		while (my ($cpid, $cpstr) = each %{$comp}) {
			push @ordered_ratio, $cpstr->{information}->{$minlabel};
		}
	}
	@ordered_ratio = sort { $a cmp $b } @ordered_ratio;
	my $range = $ordered_ratio[-1] - $ordered_ratio[0];
	my $min =$ordered_ratio[0]; 
	while ( my ($id, $nstr) = each %{$egfr->{node}} ) {
		my $comp = $nstr->{component};
		next unless defined $comp;
		while (my ($cpid, $cpstr) = each %{$comp}) {
			if ($range != 0)	 {
				$cpstr->{graphics}->{fill} = $color[int( 100 * ( ($cpstr->{information}->{$minlabel} - $min) / $range ))] ;
			}
			else {
				$cpstr->{graphics}->{fill} = "#fff77cc";	
			}
		}
	}
	$egfr->out("egfr_maptest_${minlabel}.svg",
		-width => 2000,
		-no_direction => 0,
		-engine => 'GraphViz',
	);
}
