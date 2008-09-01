#!/usr/bin/perl

use warnings;
use Data::Dumper;
use Perl6::Say;
use lib qw{/usr/local/lib/graphviz/perl};
use gv;

my $graph_handle = gv::graph('simple_graph');

my $n1 =  gv::node( $graph_handle, '1');  #$graph_handle->node('node1');
my $n2 =  gv::node( $graph_handle, '2');

my $e = gv::edge($n1, $n2);
gv::layout($graph_handle, 'dot');

print gv::renderdata($graph_handle);

my $iattr = gv::firstattr($n2);

gv::setv($n1, 'pos', '0,0');
while ( gv::ok($iattr) ) {
	say gv::nameof($iattr);
	say gv::getv($n2, $iattr);
	$iattr = gv::nextattr($n2,$iattr);
}

my $eattr = gv::firstattr($e);
while ( gv::ok($eattr) ) {
	say  gv::nameof($eattr);
	say gv::getv($e, $eattr);
	$eattr = gv::nextattr($e,$eattr);
}
