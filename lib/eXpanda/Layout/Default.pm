package eXpanda::Layout::Default;

use strict;
use warnings;
use Carp;
use Graph::Layout::Aesthetic;

=head1 NAME

  eXpanda::Layout::Default

=head1 DESCRIPTION

eXpanda::Layout::Default is calucurate coordinate of nodes and edges by L<Graph::Layout::Aesthetic>.
export function is CalCoord only.

=head1 FUNCTIONS

=over 4

=item Calcoord_default

Calcoord_default($str, %attribute);

=head2 Options

=over 4

=item -width

=item -height

=back

=cut

sub CalCoord_default {
  my $str = shift;
  my %attribute = %{shift(@_)};
  my $w = $attribute{-width};
  my $h = $attribute{-height};
  my @nodes = ();

  @nodes = sort keys %{$str->{node}};

  my $tmp_i = 0;

  my @num2node = undef;

  for my $node_name (@nodes) {
    unless (defined $str->{node}->{$node_name}->{disable} 
		 && $str->{node}->{$node_name}->{disable} == 1) {
		 $str->{node}->{$node_name}->{num} = $tmp_i;
		 $num2node[$tmp_i] = $node_name;
      $tmp_i ++;
    }
  }

  my $topology = Graph::Layout::Aesthetic::Topology->new_vertices($tmp_i);

  for my $source (sort keys %{$str->{edge}}) {
    for my $target (sort keys %{$str->{edge}->{$source}}) {
      unless (defined $str->{edge}->{$source}->{$target}->{disable} 
	      && $str->{edge}->{$source}->{$target}->{disable} == 1) {
	my $source_num = $str->{node}->{$source}->{num};
	my $target_num = $str->{node}->{$target}->{num};
	$topology->add_edge($source_num, $target_num) if($source_num ne $target_num);
      }
    }
  }
  $topology->finish;

  my $aglo = Graph::Layout::Aesthetic->new($topology);

  $aglo->add_force("NodeRepulsion", $attribute{knr});
  $aglo->add_force("MinEdgeLength", $attribute{kmel});
  $aglo->add_force("NodeEdgeRepulsion", $attribute{kner});
  $aglo->add_force("MinEdgeIntersect2", $attribute{kmei2});

=c

    #Following drawing parameters are tuned for tap/ivv files
    #Have to make branch for sif network
    $aglo->add_force("min_edge_length", 0.000002 * ($#nodes ** 1.7));
    $aglo->add_force("min_edge_intersect2");
    $aglo->add_force("node_repulsion");
    $aglo->add_force("node_edge_repulsion");

=cut


  $aglo->gloss;
  $aglo->normalize;

  my $x_max = 0;
  my $y_max = 0;
  $tmp_i = 0;
  for ($aglo->all_coordinates) {
    my ($x, $y) = @$_;
    $str->{node}->{$num2node[$tmp_i]}->{graphics}->{x} = $x * $w;
    $str->{node}->{$num2node[$tmp_i]}->{graphics}->{y} = $y * $h;
    $x_max = $x if($x_max < $x);
    $y_max = $y if($y_max < $y);
    $tmp_i ++;
  }


  if ($x_max > $w) {
    my $xk =  $w / $x_max;
    for my $node (keys %{$str->{node}}) {
      $str->{node}->{$node}->{graphics}->{x} *= $xk;
    }
  }

  if ($y_max > $h) {
    my $yk =  $h / $y_max;
    for my $node (keys %{$str->{node}}) {
      $str->{node}->{$node}->{graphics}->{y} *= $yk;
    }
  }

  $str->{graphed} = 1;

  return $str;
}

1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
