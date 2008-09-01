package WrapGV;

use Moose;
use gv;

has 'name' => (is => 'rw', isa => 'Str', required => 1, default => 'graph');
has 'direction' => (is => 'ro', isa => 'Bool', required => 1, default => 1);
has '_gv_graph' => (is => 'ro', isa => 'Ref', lazy => 1, required => 1,
	default => sub {
		my $this = shift;
		if ( $this->direction ) {
			gv::digraph($this->name);
		}
		else {
			gv::graph($this->name);

		}
	}
);

sub node {
	my $this = shift;
	my $name = shift || confess __PACKAGE__." : node : missing argument 'node'.";	
	return gv::node($this->_gv_graph, $name);
}

sub edge {
	my $this = shift;
	my ( $tail , $head ) = @_;
	confess __PACKAGE__." : node : missing argument head / tail." unless ($tail || $head);

	if ( ref($tail) eq '_p_Agnode_t'
		|| ref($head) eq '_p_Agnode_t') {
		return gv::edge($tail, $head);
	}
	else {
		return gv::edge( $this->_gv_graph, $tail, $head );
	}	
}

sub return_axis {

}

sub return_axis_of {

}
