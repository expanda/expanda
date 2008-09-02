package eXpanda::Layout::GraphViz;

use strict;
use warnings;
use Carp;
use eXpanda::Util::GVWrap;

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
	my $str = shift;
	my %attribute = %{shift(@_)};
	my $w = $attribute{-width};
	my $h = $attribute{-height};

	my $gvw = eXpanda::Util::GVWrap->new( direction => 1 );
	$gvw->bounding_box($w, $h);

	for my $source (sort keys %{$str->{edge}}) {
		for my $target (sort keys %{$str->{edge}->{$source}}) {
			unless (defined $str->{edge}->{$source}->{$target}->{disable} 
				&& $str->{edge}->{$source}->{$target}->{disable} == 1) {
				my ( $s_w, $t_w );

				$s_w = (defined($str->{node}->{$source}->{graphics}->{w})) ?
				$str->{node}->{$source}->{graphics}->{w} : 10;

				$t_w = (defined($str->{node}->{$target}->{graphics}->{w})) ?
				$str->{node}->{$target}->{graphics}->{w} : 10;

				my ( $tmp_s, $tmp_t ) = 
				(
					$gvw->add_node($source, { width => $s_w }),
					$gvw->add_node($target, { width => $t_w })
				);

				$gvw->add_edge($tmp_s, $tmp_t) if($source ne $target);
			}
		}
	}

	while ( my ( $nname , $coord ) = each %{ $gvw->return_axis } ) {
		$str->{node}->{$nname}->{graphics}->{x} = $coord->[0];
		$str->{node}->{$nname}->{graphics}->{y} = $coord->[1];
	}

	$str->{graphed} = 1;

	return $str;
}

1;
