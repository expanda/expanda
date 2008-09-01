package eXpanda::Layout::Phospho;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use eXpanda::Analysis::BFS;
sub say ($) { print STDERR "[debug] ".$_[0]."\n" if $eXpanda::DEBUG; }

=head1 NAME

  eXpanda::Layout::Phospho

=head1 DESCRIPTION

  Phospho layout.

=head1 FUNCTIONS

=over 4

=item Calcoord

Calcoord($str, %attribute);

=head2 Options

=over 4

=item -width

=item -height

=back

=cut

sub CalCoord_phospho {
  say "CalCoord_phospho";
  my $str = shift;
  my %attribute = %{shift(@_)};
  my $w = $attribute{-width};
  my $h = $attribute{-height};
  $attribute{'-no_direction'} = 0;
  my @nodes = sort keys %{$str->{node}};
  my @start_nodes = grep { defined($str->{node}->{$_}->{graphics}->{start}) &&
			     $str->{node}->{$_}->{graphics}->{start} == 1
			   } sort keys %{$str->{node}};

  # calc structure depth
  my $lstr = eXpanda::Operator::MultiSort($str);
  my $array_indep = eXpanda::ReturnElement::ReturnIndependentNetworks($str, $lstr);
  print "idepd-->".scalar(@{$array_indep})."\n" if $eXpanda::DEBUG;

  my $gloval_s_i;
  $gloval_s_i->{$_} = 1 for @start_nodes;

  for my $istr ( @{$array_indep} ) {
    my $sn_in_str = 0;

    for (@start_nodes) {
      $sn_in_str = 1 if ( defined($istr->{node}->{$_}) );
    }

    # indexing with BFS. O(|V|+|E|)
    # queue : LIFO ( last-in-first-out )
    my $bfs = eXpanda::Analysis::BFS->new($istr);
    #  enqueue(v)
    my $s_i;

    if ( $sn_in_str ) {
      for (@start_nodes) {
	$bfs->enqueue( $_ );
	$bfs->depth($_, 1);
	$s_i->{$_} = 1;
      }
    }
    else {
      my $max_deg_node = eXpanda::Util::return_max_deg_node($istr);
      $bfs->enqueue( $max_deg_node );
      $bfs->depth($max_deg_node, 2);
      $s_i->{$max_deg_node} = 1;
    }

    my $depth = 1;
    while ( my $v = $bfs->dequeue() ) {
      # mark v as visited
      print STDERR "[debug] mark $v as visited.\n" if $eXpanda::DEBUG;
      $bfs->visited($v);

      # process(v)
      $depth = $bfs->father_tell_me_about_my_depth($v) unless defined($s_i->{$v});

      if ( $depth == 1 && !defined($gloval_s_i->{$v}) ) {
	$depth = $bfs->max_depth();
      }

      $bfs->depth($v, $depth);
      indexing($v, $depth);

      # for all unvisited vertices i adjacent to v
      for my $i ( $bfs->nodes_from_v_or_to_v($v) ) {
	unless ( $bfs->is_visited($i) ) {
	  #my $parent_index = index_search($v);
	  indexing($i, $depth);
	  # mark i as visited
	  say "mark $i as visited";
	  $bfs->visited($i);
	  say "enqueue $i";
	  $bfs->enqueue($i);
	}
      }
    }
    undef($bfs);
  }


  my $depth_index = return_index();
  print STDERR "Num of depthindex : ".scalar(keys %{$depth_index})."\n" if $eXpanda::DEBUG;
  print STDERR "Num of nodes : ".scalar(keys %{$str->{node}})."\n" if $eXpanda::DEBUG;

  my $max_depth = max_depth();

  # y axis setting.
  my $ylines_h = [];
  my $hbase = $h / ($max_depth + 1);

  for ( 0..$max_depth ) {
    push @{$ylines_h}, $hbase*($_ + 1);
  }

  my $rev_index = reverse_index();
  my $axis_index;

  # setting axis.
  while ( my ($node, $depth) = each %{$depth_index} ) {
    my $r = $str->{node}->{$node}->{graphics}->{w} / 2;

    # y axis.
    my $y = $ylines_h->[ $depth - 1 ];

    unless ($y) {
      print "$depth\t$node\n";
      exit;
    }

    # x axis.
    my $x = (scalar( keys %{$rev_index->{$depth}} )) * ( $w / ( $rev_index->{$depth}->{$node} + 1) );

    delete( $rev_index->{$depth}->{$node} );
    $axis_index->{$node} = { x => $x, y => $y  };
    $str->{node}->{$node}->{graphics}->{x} = $x;
    $str->{node}->{$node}->{graphics}->{y} = $y;
  }

  $str->{graphed} = 1;

  return $str;
}

{
  my $index;

  sub reverse_index {
    my $rev;
    my $d_count;
    while ( my ($name, $d) = each %{$index} ) {
      $rev->{$d}->{$name} = 1;
      $d_count->{$d}++;
    }

    for my $d (keys %{$rev}) {
      for ( keys %{$rev->{$d}} ) {
	$rev->{$d}->{$_} = $d_count->{$d};
      }
    }
    return $rev;
  }

  sub max_depth {
    my @max = sort { $b <=> $a } values %{$index};
    return shift @max;
  }

  sub return_index {
    return $index;
  }

  sub indexing {
    my ( $node, $num ) = @_;
    $index->{$node} = $num;
  }

  sub index_search {
    my $node =shift;
    if ( defined($index->{$node}) ) {
      return $index->{$node};
    }
    else {
      carp "[error] no index about $node\n";
      return undef;
    }
  }

  sub is_indexed {
    if ( defined($index->{$_[0]}) ) {
      return 1;
    }
    else { return 0; }
  }

}

1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
