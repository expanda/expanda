package eXpanda::Graphics::Color;

use warnings;
use strict;
use Carp qw{confess};

=head1 NAME

eXpanda::Graphics::Color

=head1 SYNOPSYS

  for (0..10) {
    @rgb = eXpanda::Graphics::Color::hexHeat($_, 0, 10);
  }

=head1 FUNCTIONS

=over 4

=cut

=item Heat

( r, g , b ) = Heat( current_position, min , max )

=cut

sub Heat {
  my ( $this, $min, $max ) = @_;
  my ( $scale, $period ) = (128, 2 * 3.14 );
  my $pos = ( $this - $min ) /( $max -$min);
  my $shft = 0.5 * $pos + 1.7 * (1 - $pos );
  my $x = $shft + $pos * $period;

  return (
	  ((cos($x) +1) * $scale),
	  ((cos(($x + 3.14 /2 )) +1 ) * $scale),
	  ((cos(($x + 3.14 )) +1 ) * $scale),
	 );
}

=item hexHeat

# Return value is scalar like '#FFFFFF'
$rgbhex = hexHeat( current_position, min, max );

=cut
sub hexHeat {
  my ( $this , $min, $max ) = @_;
  my ( $scale, $period ) = (128, 2 * 3.14 );
  my $pos = ( $this - $min ) /( $max -$min);
  my $shft = 0.5 * $pos + 1.7 * (1 - $pos );
  my $x = $shft + $pos * $period;

  return  join '', (sprintf ("%.2X",((cos($x) +1) * $scale)),
                    sprintf ("%.2X",((cos(($x + 3.14 /2 )) +1 ) * $scale)),
                    sprintf ("%.2X",((cos(($x + 3.14 )) +1 ) * $scale)),
                   );
}

=item intHeat

# Return value is rgb array of int.
( r, g , b )  = hexHeat( current_position, min, max );

=cut

sub intHeat {
  my ( $this , $min, $max ) = @_;
  my ( $scale, $period ) = (128, 2 * 3.14 );
  my $pos = ( $this - $min ) /( $max -$min);
  my $shft = 0.5 * $pos + 1.7 * (1 - $pos );
  my $x = $shft + $pos * $period;

  return (
	  int((cos($x) +1) * $scale),
	  int((cos(($x + 3.14 /2 )) +1 ) * $scale),
	  int((cos(($x + 3.14 )) +1 ) * $scale),
	 );
}

=item gradient

# Return gradient color array from start_color, end_color, range..
http://www.elifulkerson.com/projects/rgb-color-gradation.php

[color, color, color .... ]  = gradient( start_color, end_color, range );

# Example... show us 16 values of gradation between these two colors
# printchart("#999933", "#6666FF", 16)

=cut

sub gradient {
	my $this = shift;
	my ( $start, $goal , $step ) = @_;
	$step--;
	$start =~ /^\#(..)(..)(..)$/;
	my @start_rgb =($1, $2, $3);
	$goal =~ /^\#(..)(..)(..)$/;
	my @goal_rgb =($1, $2, $3);
	confess "Illigal color input in start or end color. "
	unless scalar(@start_rgb) == 3 || scalar(@goal_rgb) == 3;

	@start_rgb = map { hex($_) } @start_rgb;
	@goal_rgb =	map { hex($_) } @goal_rgb;
	
	my @diff_rgb;
	for (my$i = 0;$i<3;$i++){
		$diff_rgb[$i] = $goal_rgb[$i] - $start_rgb[$i];
	}

	my @buffer = ();

	for my $i (0..$step) {
		push @buffer, join ( '',
			(sprintf ("%.2X",( ($start_rgb[0] + ( $diff_rgb[0] * $i/$step ))))),
			(sprintf ("%.2X",( ($start_rgb[1] + ( $diff_rgb[1] * $i/$step ))))),
			(sprintf ("%.2X",( ($start_rgb[2] + ( $diff_rgb[2] * $i/$step ))))));
	}
	@buffer = map { "#$_" } @buffer;

	return @buffer;
}


=back

=cut

1;
__END__


=head1
