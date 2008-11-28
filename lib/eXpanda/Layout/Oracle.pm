package eXpanda::Layout::Oracle;

use strict;
use warnings;
use Carp;
use Math::Trig;
use Data::Dumper;


=HEAD1 NAME

eXpanda::Layout::Oracle

=head1 DESCRIPTION

TODO

=head1 FUNCTIONS

=over 4

=item Calcoord_oracle

Calcoord_oracle($str, %attribute);

=head2 Options

=over 4

=item -width

=item -height

=back

=cut

sub CalCoord_oracle {
	my $str = shift;
	my %attribute = %{shift(@_)};
	my $rstr = shift;

	my $w = $attribute{-width};
	my $h = $attribute{-height};

	my $scale = 0.8;
	my $r = ( $w > $h ) ? ( $h * $scale ) / 2 : ( $w * $scale ) / 2;
	my $c = {
		x => $w/2 ,
		y => $h/2
	};

	my @nodes = ();

	@nodes = sort { $rstr->{node}->{$a}->{score}->{degree} <=>
		$rstr->{node}->{$b}->{score}->{degree} } keys %{$str->{node}};

	my $nodenum  = scalar @nodes;
	my $unit_rad = ( 2 * pi ) / $nodenum;

	for my $i (1..scalar(@nodes)) {
		my $nid = $nodes[$i-1];
		my $current_radian = $unit_rad * $i;

		$str->{node}->{$nid}->{graphics}->{x} = $c->{x} + cos ($current_radian) * $r;
		$str->{node}->{$nid}->{graphics}->{y} = $c->{y} + sin ($current_radian) * $r;
		$str->{node}->{$nid}->{graphics}->{angle} = $current_radian;
	}


	while (my ($source, $tstr) = each %{$str->{edge}}) {
		my $angle = $str->{node}->{$source}->{graphics}->{angle};
		my $x = $str->{node}->{$source}->{graphics}->{x};
		my $y = $str->{node}->{$source}->{graphics}->{y};
		my $sr = $str->{node}->{$source}->{graphics}->{w};

		while (my ($target, $gstr) = each %{$tstr}) {
			my $x2 = $str->{node}->{$target}->{graphics}->{x};
			my $y2 = $str->{node}->{$target}->{graphics}->{y};
			my $tr = $str->{node}->{$target}->{graphics}->{w};
			my $rpos = $str->{node}->{$target}->{graphics}->{angle};

			my $cp1x = $c->{x} + cos( $angle ) * ( $r / 1.5 );
			my $cp1y = $c->{y} + sin( $angle ) * ( $r / 1.5 );
			my $cp2x = $c->{x} + cos( $rpos  ) * ( $r / 1.5 );
			my $cp2y = $c->{y} + sin( $rpos  ) * ( $r / 1.5 );
			# bezer : [x, y, cp1x, cp1y, cp2x, cp2y, x2, y2]
			$gstr->{graphics}->{bezier} = [$x, $y, $cp1x, $cp1y, $cp2x, $cp2y, $x2, $y2];
		}
	}

	my $count = 0;
	$str->{graphed} = 1;

	while (my ($nodeid, $nstr) = each %{$str->{node}}) {
		unless ($nstr->{graphics}->{x}) {
			print Dumper $nstr; 
		}

	}

	return $str;
}

1;

__END__
