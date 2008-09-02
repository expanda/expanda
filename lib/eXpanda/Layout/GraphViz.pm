package eXpanda::Layout::GraphViz;

use strict;
use warnings;
use Carp;
use eXpanda::Util::GVWrap;
sub say ($) { print STDERR "[debug] ".$_[0]."\n" if $eXpanda::DEBUG; }

=head1 NAME

  eXpanda::Layout::GraphViz

=head1 DESCRIPTION

eXpanda::Layout::Default is calucurate coordinate of nodes and edges by L<gv.pm>.
export function is CalCoord only.

=head1 FUNCTIONS

=over 4

=item Calcoord

Calcoord($str, %attribute);

=head2 Options

=over 4

=item -width

=item -height

=head1 REQUIREMENT

L<GraphViz>

=back

=cut

sub CalCoord_dot {
	say "CalCoord_dot start....";
	my $str = shift;
	my %attribute = %{shift(@_)};
	my $w = $attribute{-width};
	my $h = $attribute{-height};

	my $gvw = eXpanda::Util::GVWrap->new( direction => 1 );
	$gvw->bounding_box($w, $h);
	say "bounding box size is ". $gvw->bounding_box->[0]."/".$gvw->bounding_box->[1];

	say "this graph has ".scalar( keys %{$str->{node}})." nodes.";

	for my $source (sort keys %{$str->{edge}}) {
		for my $target (sort keys %{$str->{edge}->{$source}}) {
			unless (defined $str->{edge}->{$source}->{$target}->{disable} 
				&& $str->{edge}->{$source}->{$target}->{disable} == 1) {	
				my ( $s_w, $t_w );
	
				$s_w = (defined($str->{node}->{$source}->{graphics}->{w})) ?
				$str->{node}->{$source}->{graphics}->{w} : 10;

				$t_w = (defined($str->{node}->{$target}->{graphics}->{w})) ?
				$str->{node}->{$target}->{graphics}->{w} : 10;

				my ( $tmp_s, $tmp_t ) = ();

				unless ( $gvw->find_node($source) ) {
					$tmp_s = $gvw->add_node($source, { width => $s_w });
				}
				else {
				   $tmp_s = $source;	
				}

				unless ( $gvw->find_node($target) ) {
					$tmp_t = $gvw->add_node($target, { width => $t_w });
				}
				else {
					$tmp_t = $target;	
				}
				
				$gvw->add_edge($tmp_s, $tmp_t) if($source ne $target);
			}
		}
	}

	say "coordinate calurate start";
	$gvw->layout('dot');
	my $coord_str = $gvw->return_axis; 
	say "coordinate calurate end";

	while ( my ( $nname , $coord ) = each %{ $coord_str } ) {
		$str->{node}->{$nname}->{graphics}->{x} = $coord->[0];
		$str->{node}->{$nname}->{graphics}->{y} = $coord->[1];
	}
	
	$str->{graphed} = 1;
	$gvw->png  and say "out png" if ( $eXpanda::DEBUG );
	return $str;
}

1;
