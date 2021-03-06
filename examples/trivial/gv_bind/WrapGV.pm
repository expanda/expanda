package WrapGV;

use Moose;
use gv;
use Carp;
use Data::Dumper;

has 'name' => (is => 'rw', isa => 'Str', required => 1, default => 'graph');
has 'direction' => (is => 'ro', isa => 'Bool', required => 1, default => 1);
has 'rendered' => (is => 'rw', isa => 'Bool', default => 0);

# TODO: put bounding_box into member.
#
# has 'bounding_box' => (is => 'rw', isa => 'ArrayRef',
#		       default => sub {
#			 my $this->shift;
#		       }
#		      );

has '_gv_graph' => (is => 'ro', isa => 'Ref', lazy => 1, required => 1,
		    default => sub {
		      my $this = shift;
		      if ( $this->direction ) {
			gv::digraph($this->name);
		      } else {
			gv::graph($this->name);
		      }
		    }
		   );
__PACKAGE__->meta->make_immutable;

sub each_elt {
  my $this = shift;
  my $cat = shift
    || confess __PACKAGE__." : each : missing argument 'cat'.";
  my $sub = shift
    || confess __PACKAGE__." : find_node : missing callback subroutine.";
  
  my $dispatch = {
		  'next' => '',
		  'first' => '',
		 };

  if ( $cat eq 'node' ) {
    $dispatch->{next} = \&gv::nextnode;
    $dispatch->{first} = \&gv::firstnode;
  }
  elsif ( $cat eq 'edge' ) {
    $dispatch->{next} = \&gv::nextedge;
    $dispatch->{first} = \&gv::firstedge;
  }
  elsif ( $cat eq 'graph' ) {
    $dispatch->{next} = \&gv::nextgraph;
    $dispatch->{first} = \&gv::firstgraph;
  }
  else {
    confess __PACKAGE__.
      " : find_node : Invalid category. category are node, edge or graph";
  }

  my $el = $dispatch->{first}($this->_gv_graph);

  while (gv::ok($el)) {
    $sub->( $el );
    $el = $dispatch->{next}($this->_gv_graph, $el);
  }
}

sub find_node {
  my $this = shift;
  my $name = shift
    || confess __PACKAGE__." : find_node : missing argument 'node'.";

  return gv::findnode($name);
}

# Usage: 
#   $wrapgv->add_node('nodename', { color => 'red' });
#

sub add_node {
  my $this = shift;
  my $name = shift
    || confess __PACKAGE__." : node : missing argument 'node'.";
  my $variables = shift;

  my $tmp_n = gv::node($this->_gv_graph, $name);
	
  while ( my ($k, $v) = each %{$variables} ) {
    gv::setv($tmp_n, $k, $v);
  }

  return gv::nameof($tmp_n);
}

# Usage: 
#   $wrapgv->add_edge( $tailnode, $headnode );
#

sub add_edge {
  my $this = shift;
  my ( $tail , $head ) = @_;
  confess __PACKAGE__." : node : missing argument head / tail." unless ($tail || $head);

  if ( ref($tail) eq '_p_Agnode_t'
       || ref($head) eq '_p_Agnode_t') {
    return gv::edge($tail, $head);
  } else {
    return gv::edge( $this->_gv_graph, $tail, $head );
  }	
}

# Usage: 
#   $wrapgv->bounding_box( $w_pixel, $h_pixel );
#

sub bounding_box {
  my $this = shift;
  my ( $w, $h ) = @_;
  if (!$w || !$h ) {
    if ( gv::getv($this->_gv_graph, 'bb') =~ m/^\d+?,\d+?,(\d+?),(\d+?)$/ ) {
      return [ $this->pt_px($1), $this->pt_px($2) ];
    } else {
      carp "bounding_box : does not match.";
      return 0;
    }
  } else {
    ( $w , $h ) = ( $this->px_pt($w) , $this->px_pt($h) );
    gv::setv($this->_gv_graph, 'bb', "0,0,$w,$h");
  }
}

sub layout {
  my $this = shift;
  my $method = shift || 'dot';
  gv::layout($this->_gv_graph, $method);
  gv::render($this->_gv_graph);
  $this->rendered(1);
}

sub return_axis {
  my $this = shift;
  my $result;

  $this->layout unless ( $this->rendered );


  $this->each_elt('node', sub {
		    my $n = shift;
		    if ( gv::getv($n, 'pos') =~ m/(\d+),(\d+)/) {
		      $result->{gv::nameof($n)}
			= $this->translate( $this->pt_px($1),
					    $this->pt_px($2) );
		    } else {
		      carp "[warn] : return_axis : node has no position.";
		    }
		  });

  return $result;
}

# default dpi is 96
# 1 inch = 72 pt
# 1point = 1/72 * 96

sub pt_px {
  my $this = shift;
  my $pt = shift;
  return ($pt*1/72*96);
}

sub px_pt {
  my $this = shift;
  my $px = shift;
  return (1/($px * 1/72 * 96));
}

sub inch_px {
  my $this = shift;
  my $inch = shift;
  return ($inch * 96);
}

sub px_inch {
  my $this = shift;
  my $px = shift;
  return ($px/96);
}

#
# dimention translation
#
# ArrayRef = $this->translate(x, y);
#

sub translate {
  my $this = shift;
  my ($x, $y) = @_;
  return [ $x,
	   ( $this->bounding_box->[1] - $y  )
	 ];
}

sub return_axis_of {
  carp "not implemented ... ";
}
