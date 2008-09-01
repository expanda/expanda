#!/usr/bin/perl
use strict;
use warnings;
#use lib qw{/home/t04632hn/lib/graphviz/perl};
use lib qw{/usr/local/lib/graphviz/perl};
use gv;

my $graph = gv::graph("sample");
my $node1 = gv::node($graph, "node1");
my $node2 = gv::node($graph, "node2");
my $edge  = gv::edge($node1, $node2);
for (3..100) {
	my $tmpn = gv::node( $graph, "node$_" );
	gv::setv($tmpn,'label', 'node'.$_);
	gv::edge( $graph, "node".int(rand(($_))), "node$_");
}


gv::layout($graph, "dot");
gv::render($graph);

my $n = undef;

while ( 1 ) {
  $n = ( defined $n ) ? gv::nextnode($graph, $n) : gv::firstnode($graph);

  my $a = undef;
  while ( 1 ) {
    $a = ( defined $a ) ? gv::nextattr($n, $a) : gv::firstattr($n);
    print "AttrName: ".gv::nameof($a)."\t" if gv::nameof($a);
    print "Value: ".gv::getv($n, $a)."\n";
    last unless gv::ok($a);
  }
  last unless gv::ok($n);
}

gv::render($graph, "png", "sample.png");
