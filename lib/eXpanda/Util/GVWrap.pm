package eXpanda::Util::GVWrap;

use Moose;
use gv;
use Carp;


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

	return gv::findnode($this->_gv_graph, $name);
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
		if ( $k eq 'width' ) {
			#print "set node width to ".$this->px_inch($v)."\n";
		 my $char_val = $this->px_inch($v);
		 gv::setv($tmp_n, $k, "$char_val" );
		 gv::setv($tmp_n, 'height', "$char_val" );
		}
		else {
		  gv::setv($tmp_n, $k, "$v");
		}
	}

#  return gv::nameof($tmp_n);
	return $tmp_n;
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
			return [ $1, $2 ];
		} else {
			carp "bounding_box : does not match.". gv::getv($this->_gv_graph, 'bb') ;
			return 0;
		}
	} else {
		#my ( $pw , $ph ) = ( $this->px_pt($w) , $this->px_pt($h) );
		my ( $iw , $ih ) = ( $this->px_inch($w) , $this->px_inch($h) );
		$w = int($w * 5/3);
		$h = int( $h * 5/3);
		print "[debug] bounding box set to ${w}:${h}\n";	
		gv::setv( $this->_gv_graph, 'bb', "0,0,$iw,$ih" );
		#gv::setv( $this->_gv_graph, 'size', "0,0,$pw,$ph" );
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
				print '.';
				$result->{gv::nameof($n)}
				= $this->translate( $1, $2 );
			} else {
				carp "[warn] : return_axis : node has no position.";
			}
		});

	return $result;
}

sub png {
	my $this = shift;
	my $file = shift || 'graph.png';

	$this->layout unless ( $this->rendered );

  	gv::render($this->_gv_graph,'png', $file);
}

# default dpi is 96
# 1 inch = 72 pt
# 1point = 1/72 * 96

sub pt_px {
	my $this = shift;
	my $pt = shift;
	return ( $pt * 1/72 * 96 );
}

sub px_pt {
	my $this = shift;
	my $px = shift;
	if ( ( $px * 1/96 * 72) % 1 != 0 ) {
		return sprintf("%.2f", ($px * 1/96 * 72));
	}
	else {
		return ($px * 1/96 * 72);
	}
}

sub inch_px {
	my $this = shift;
	my $inch = shift;
	return ($inch * 96);
}

sub px_inch {
	my $this = shift;
	my $px = shift;

	if ( int($px/96) < 1 ) {
		return sprintf("%.2f",$px/96);	 	
	 }
	 else {
	 	return int($px/96)
	 }
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

1;
