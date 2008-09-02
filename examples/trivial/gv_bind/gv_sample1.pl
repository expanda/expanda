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
	#gv::edge( $graph, "node".($_-1), "node$_");;
}

gv::setv($node2,'color','red');
gv::setv($node2,'pos','2000,501');
#gv::setv($node2,'pin','true');
gv::setv($node2,'width',"3");

#gv::layout($graph, "dot");
#gv::render($graph);

my $pos = gv::findattr($node1, 'pos');
print "Value: ".gv::getv($node1, $pos)."\n";

my $pos2 = gv::findattr($node2, 'pos');
print "Value: ".gv::getv($node2, $pos2)."\n";

my $pos_edge =  gv::findattr($edge, 'pos');
print "Value: ".gv::getv($edge, $pos_edge)."\n";

my $pos = gv::findattr($graph, 'bb');
#print "Value: ".gv::getv($graph, $pos)."\n";
gv::setv($graph, "bb", '0 0 5000 5000');
gv::setv($graph, "center", 'true');
#gv::setv($graph, "root", "node2");
print gv::getv($graph, "bb")."\n";

gv::layout($graph, "dot");
gv::render($graph, "png", 'dottest.png');

print "position of node 2 ".gv::getv($node2, 'pos')."\n";

my $ga = undef;

while ( 1 ) {
  $ga = ( defined $ga ) ? gv::nextattr($graph, $ga) : gv::firstattr($graph);
  print  "AttrName: ".gv::nameof($ga)."\t" if gv::nameof($ga);
  print "Value: ".gv::getv($graph, $ga)."\n";
  last unless gv::ok($ga);
}
exit;
__END__

my $n = undef;

while ( 1 ) {
  $n = ( defined $n ) ? gv::nextnode($graph, $n) : gv::firstnode($graph);
  

  my $a = undef;
  while ( 1 ) {
    $a = ( defined $a ) ? gv::nextattr($n, $a) : gv::firstattr($n);
    print  "AttrName: ".gv::nameof($a)."\t" if gv::nameof($a);
    print "Value: ".gv::getv($n, $a)."\n";
    last unless gv::ok($a);
  }
  last unless gv::ok($n);
}


my $e = undef;

while ( 1 ) {
  $e = ( defined $e ) ? gv::nextedge($graph, $e) : gv::firstedge($graph);

  my $a = undef;
  while ( 1 ) {
    $a = ( defined $a ) ? gv::nextattr($e, $a) : gv::firstattr($e);
    print  "AttrName: ".gv::nameof($a)."\t" if gv::nameof($a);
    print "Value: ".gv::getv($e, $a)."\n";
    last unless gv::ok($a);
  }
  last unless gv::ok($e);
}

my $ga = undef;

while ( 1 ) {
  $ga = ( defined $ga ) ? gv::nextattr($graph, $ga) : gv::firstattr($graph);
  print  "AttrName: ".gv::nameof($ga)."\t" if gv::nameof($ga);
  print "Value: ".gv::getv($graph, $ga)."\n";
  last unless gv::ok($ga);
}



gv::render($graph, "png", "sample.png");
