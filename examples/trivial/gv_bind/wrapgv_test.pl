#!/usr/bin/perl
use lib qw{/usr/local/lib/graphviz/perl};
use WrapGV;
use Data::Dumper;

my $wgv = WrapGV->new( name => 'sample',
		       direction => 1
		     );

$wgv->bounding_box(1000, 1000);

$wgv->add_node("node0");

for (1..100) {
  $wgv->add_node("node${_}");
  $wgv->add_edge("node${_}", "node".int(rand($_ - 1)));
}

print Dumper $wgv->return_axis;
