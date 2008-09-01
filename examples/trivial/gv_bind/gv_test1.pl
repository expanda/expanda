#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Perl6::Say;
use lib qw{/usr/local/lib/graphviz/perl};
use gv;

my $graph_handle = gv::digraph('sample_graph');

#
# Add node.
#

print Dumper $graph_handle;

my $n1 =  gv::node( $graph_handle, 'node1');  #$graph_handle->node('node1');
my $n2 =  gv::node( $graph_handle, 'node2');

#
# Add Edge between existing nodes.
#
my $e1 = gv::edge($n1, $n2);

say ref($n1);
say ref($e1);

for (3..100) {
	my $tmpn = gv::node( $graph_handle, "node$_" );
	gv::setv($tmpn,'label', 'node'.$_);
	gv::edge( $graph_handle, "node".int(rand(($_))), "node$_");
}

gv::layout($graph_handle, 'dot');
gv::render($graph_handle);


my $proto = gv::protonode($graph_handle);

my $iattr = gv::firstattr($n2);
while ($iattr) {
	my $val = gv::getv($n2, $iattr);
	say gv::nameof($iattr)."\t".$val;
	$iattr = gv::nextattr($n2, $iattr);
}


#
# Node Iteration
#

my $inode = gv::firstnode($graph_handle);

while(gv::ok($inode)) {
	say gv::nameof($inode);
	my $iattr = gv::firstattr($inode);
	my $po = gv::getv($inode, 'point.x');
	print $po;
	while ($iattr) {
		my $val = gv::getv($inode, $iattr);
		say gv::nameof($iattr)."\t".$val;
		$iattr = gv::nextattr($inode, $iattr);
	}

	$inode = gv::nextnode($graph_handle, $inode);
}

exit;

my $iedge = gv::firstedge($graph_handle);

while(gv::ok($iedge)) {
	my $iattr = gv::firstattr($iedge);

	while ($iattr) {
		my $val = gv::getv($iedge, $iattr);
		say gv::nameof($iattr)."\t".$val;
		$iattr = gv::nextattr($iedge, $iattr);
	}

	$iedge = gv::nextedge($graph_handle, $iedge);
}


