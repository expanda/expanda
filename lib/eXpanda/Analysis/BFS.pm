package eXpanda::Analysis::BFS;

use strict;
use warnings;
use Carp;
use Data::Dumper;

sub new {
  my $pkg = shift;
  my $str = shift;
  my $bfs = {
	     edge => {},
	     reversed_edge => {},
	     visited => {},
	     queue => [],
	     depth => {},
	    };

  # edge, reversed edge.
  while ( my ($source , $tstr) = each %{$str->{edge}} ) {
    while ( my ($target, $istr ) = each %{$tstr} ) {
      $bfs->{edge}->{$source}->{$target} = 1;
      $bfs->{reversed_edge}->{$target}->{$source} = 1;
    }
  }

  return bless $bfs, $pkg;
}



sub nodes_from_v_or_to_v {
  my $this = shift;
  my $v = shift;
  my @i = ();

  push @i, keys %{$this->{edge}->{$v}};
  push @i, keys %{$this->{reversed_edge}->{$v}};

  return @i;
}

sub nodes_from_v_if_from_is_nothing__to_v {
  my $this = shift;
  my $v = shift;
  my @i = ();
  push @i, keys %{$this->{edge}->{$v}};
  if ( scalar(@i) == 0 ) {
    push @i, keys %{$this->{reversed_edge}->{$v}};
  }
  return @i;
}

sub show_queue {
  my $this = shift;
  print STDERR Dumper $this->{queue};
}

sub enqueue {
  my $this = shift;
  my $v = shift;
  push @{$this->{queue}}, $v;
}

sub dequeue {
  my $this = shift;
  return shift @{$this->{queue}};
}
use Data::Dumper;
sub is_visited {
  my $this = shift;
  my $v = shift;
  if ( defined($this->{visited}->{$v}) ) {
    return 1;
  }
  else {
    return 0;
  }
}

sub visited {
  my $this = shift;
  my $v = shift;

  $this->{visited}->{$v} = 1;
}

# edge:
# source -> target

# reversed-edge
# target -> source

sub is_all_edges_to_v_visited {
  my $this = shift;
  my $v = shift;

  for my $source ( keys %{ $this->{reversed_edge}->{$v} } ) {
    unless (defined($this->{visited}->{$source})) {
      return 0
    }
  }
  return 1;
}

sub max_depth {
  my $this = shift;
  return shift @{[ sort {$b <=> $a} values %{$this->{depth}} ]};
}

sub depth {
  my $this = shift;
  my ( $v , $d ) = @_;
  if ($d) {
    $this->{depth}->{$v} = $d unless defined($this->{depth}->{$v});
  }

  return $this->{depth}->{$v};
}

sub father_tell_me_about_my_depth {
  my $this = shift;
  my $v = shift;
  my @parents_of_v = keys %{ $this->{reversed_edge}->{$v} };
  # detect father.
  my @father = grep { defined($this->{visited}->{$_}) } @parents_of_v;

  if (scalar(@father) == 0) {
    return 1;
  }
  elsif ( scalar(@father) == 1 ) {
    my $dad = shift @father;
    return ($this->{depth}->{$dad} + 1);
  }
  elsif  ( scalar(@father) > 1 ) {
    my $ret = 0;
    for my $dad (@father) {
      $ret = $this->{depth}->{$dad}
	if defined($this->{depth}->{$dad}) && ($ret < $this->{depth}->{$dad});
    }
    return ($ret + 1 );
  }
}

1;
