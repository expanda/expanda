package eXpanda::Output::Svg;

use strict;
use warnings;
use Carp qw{confess croak carp};
use SVG;
use Storable qw(dclone);
#use base qw{Exporter};
#our @EXPORT_OK = qw{Str2Svg};

sub say ($) { no warnings; print "[debug] ".(shift)."\n" if $eXpanda::DEBUG; }

=head1 NAME

  eXpanda::Out::Svg

=head1 DESCRIPTION

eXpanda::Output::Svg is svg output module for eXpanda.
export function is Str2Svg only.

=head1 FUNCTIONS

=over 4

=item Str2Svg

Str2Svg($gstr);

gstr is graphics structure.

=cut

sub Str2Svg{
  say 'svg output start';
  my $gstr = shift;
  my %attribute = %{shift(@_)};

  our $svg = undef;
  our $w = $attribute{-width};
  our $h = $attribute{-height};
  our $m = $attribute{-margin};
  our $o = $attribute{-o};
  our $d = $attribute{-no_direction};
  our $s = $attribute{-dual_arrow_spreads};
  our $nl = $attribute{-no_node_label};
  our $el = $attribute{-no_edge_label};
  our $nn = $attribute{-no_node};
  our $ne = $attribute{-no_edge};
  our $r = $attribute{-rotation};

  $svg = SVG->new(
		  width => $w,
		  height => $h,
		 );

  $gstr = &MatchField($gstr);

  if ( $eXpanda::DEBUG ) {
      my $path = $svg->get_path(
				x => [0, $w, $w, 0 ,0],
				y => [0, 0,  $h, $h, 0],
				-type => 'polygon',
				-relative => '1',
				-closed => 'true',
			       );
      $svg->polygon(
		    %$path,
		    stroke => '#000000',
		    fill   => '#FFFFFF',
		    'stroke-width' => 1,
		    'opacity' => 0.5,
		   );
  }

  use Data::Dumper;
#	print Dumper $gstr;

  $svg->image(
  	x => '40',
	y => '15',
	width => $w,
	height => $h,
	title => 'kegg background',
	id => 'bk',
	-href => $gstr->{background}
  ) if $gstr->{background};

  DrawEdge($gstr) unless $ne;
  DrawNode($gstr);
  DrawEdgeLabel($gstr) unless($el);
  DrawNodeLabel($gstr) unless($nl);

  my $out = $svg->xmlify;
  open(F, ">$o");
  print F $out;
  close F;

=item DrawNodeLabel

  DrawNodeLabel($gstr);

=cut

    sub DrawNodeLabel{
      my $gstr = shift;

      foreach my $id (keys %{$gstr->{node}}) {
	unless (defined $gstr->{node}->{$id}->{disable} && $gstr->{node}->{$id}->{disable} == 1) {
	  my %c = %{$gstr->{node}->{$id}->{graphics}};

	  my $fontsize = $c{'font-size'};
	  $fontsize =~ s/px|pt//g;
	  if ($c{url}) {
	    $svg->anchor(
			 -href => $c{url},
			 -target => 'new_window',
			)->text(
				x => $c{x},
				y => $c{y}+($fontsize / 3),
				'font-family' => $c{'font-family'},
				'font-size' => $c{'font-size'},
				'fill' => $c{'font-color'},
				'stroke-width' => 1,
				'stroke' => 'white',
				'text-anchor' => 'middle',
				'opacity' => $c{'font-opacity'},
			       )->cdata($gstr->{node}->{$id}->{label});
	    $svg->anchor(
			 -href => $c{url},
			 -target => 'new_window',
			)->text(
				x => $c{x},
				y => $c{y}+($fontsize / 3),
				'font-family' => $c{'font-family'},
				'font-size' => $c{'font-size'},
				'fill' => $c{'font-color'},
				'text-anchor' => 'middle',
				'opacity' => $c{'font-opacity'},
			       )->cdata($gstr->{node}->{$id}->{label});
	  } else {
	    $svg->text(
		       x => $c{x},
		       y => $c{y}+($fontsize / 3),
		       'font-family' => $c{'font-family'},
		       'font-size' => $c{'font-size'},
		       'fill' => $c{'font-color'},
		       'stroke-width' => 1,
		       'stroke' => 'white',
		       'text-anchor' => 'middle',
		       'opacity' => $c{'font-opacity'},
		      )->cdata($gstr->{node}->{$id}->{label});
	    $svg->text(
		       x => $c{x},
		       y => $c{y}+($fontsize / 3),
		       'font-family' => $c{'font-family'},
		       'font-size' => $c{'font-size'},
		       'fill' => $c{'font-color'},
		       'text-anchor' => 'middle',
		       'opacity' => $c{'font-opacity'},
		      )->cdata($gstr->{node}->{$id}->{label});
	  }
	}
      }
    }

=item DrawEdgeLabel

    DrawEdgeLabel($gstr);

=cut

    sub DrawEdgeLabel{
      my $gstr = shift;
      for my $source (keys %{$gstr->{edge}}) {
	for my $target (keys %{$gstr->{edge}->{$source}}) {
	  unless (defined $gstr->{edge}->{$source}->{$target}->{disable} 
		  && $gstr->{edge}->{$source}->{$target}->{disable} == 1) {
	    my $cb = $gstr->{edge}->{$source}->{$target};
	    my %Es = %{$gstr->{node}->{$source}->{graphics}};
	    my %Et = %{$gstr->{node}->{$target}->{graphics}};
	    my %c = %{$cb->{graphics}};
	    my $elx = ($Es{x} + $Et{x}) / 2;
	    my $ely = ($Es{y} + $Et{y}) / 2;
	    my $fontsize = $c{'font-size'};
	    $fontsize =~ s/px|pt//g;
	    if ($c{url}) {
	      $svg->anchor(
			   -href => $c{url},
			   -target => 'new_window',
			  )->text(
				  x => $elx,
				  y => $ely+($fontsize / 3),
				  'font-family' => $c{'font-family'},
				  'font-size' => $c{'font-size'},
				  'fill' => $c{'font-color'},
				  'stroke-width' => 1,
				  'stroke' => 'white',
				  'text-anchor' => 'middle',
				  'opacity' => $c{'font-opacity'},
				 )->cdata($gstr->{edge}->{$source}->{$target}->{label});
	      $svg->anchor(
			   -href => $c{url},
			   -target => 'new_window',
			  )->text(
				  x => $elx,
				  y => $ely+($fontsize / 3),
				  'font-family' => $c{'font-family'},
				  'font-size' => $c{'font-size'},
				  'fill' => $c{'font-color'},
				  'text-anchor' => 'middle',
				  'opacity' => $c{'font-opacity'},
				 )->cdata($gstr->{edge}->{$source}->{$target}->{label});
	    } else {
	      $svg->text(
			 x => $elx,
			 y => $ely+($fontsize / 3),
			 'font-family' => $c{'font-family'},
			 'font-size' => $c{'font-size'},
			 'fill' => $c{'font-color'},
			 'stroke-width' => 1,
			 'stroke' => 'white',
			 'text-anchor' => 'middle',
			 'opacity' => $c{'font-opacity'},
			)->cdata($gstr->{edge}->{$source}->{$target}->{label});
	      $svg->text(
			 x => $elx,
			 y => $ely+($fontsize / 3),
			 'font-family' => $c{'font-family'},
			 'font-size' => $c{'font-size'},
			 'fill' => $c{'font-color'},
			 'text-anchor' => 'middle',
			 'opacity' => $c{'font-opacity'},
		 )->cdata($gstr->{edge}->{$source}->{$target}->{label});
	 }
 }
	}
}
	 }

=item DrawNode

  DrawNode($gstr);

=cut

sub DrawNode{
my $gstr = shift;

foreach my $id (sort keys %{$gstr->{node}}) {

	unless (defined $gstr->{node}->{$id}->{disable}
		&& $gstr->{node}->{$id}->{disable} == 1) {

		my $c = $gstr->{node}->{$id}->{graphics};
		my $label = $gstr->{node}->{$id}->{label};
		my $cmps = $gstr->{node}->{$id}->{component};
		unless ($nn) {
			if ($c->{type} eq 'oval' || $c->{type} eq 'circle') {
				&DrawCircle($c, $label);
			} elsif ($c->{type} eq 'star') {
				&DrawStar($c, $label);
			} elsif ($c->{type} eq 'heart') {
				&DrawHeart($c, $label);
			} elsif ($c->{type} eq 'diamond') {
				&DrawDiamond($c, $label);
			}

			if (defined($c->{smile})) {
				&DrawSmile($c);
			} elsif (defined($c->{smilepo})) {
				&DrawSmilepo($c);
			}
		}	
		&DrawComponent( $c, $cmps ) if $cmps;
	}
}
	}

=item DrawDiamond

    DrawDiamond($c);

=cut

    sub DrawDiamond{
      my $label = $_[1];
      my %c = (
	       stroke => 'gray',
	       'stroke-width' => 1.0,
	       opacity => 1,
	       url => '',
	       %{$_[0]},
	      );

      my @x = ();
      my @y = ();

      ($x[0], $y[0]) = (
			$c{x},
			$c{y} - $c{w} * 0.6,
		       );
      ($x[1], $y[1]) = (
			$c{x} + $c{w} * 0.6,
			$c{y},
		       );
      ($x[2], $y[2]) = (
			$c{x},
			$c{y} + $c{w} * 0.6,
		       );
      ($x[3], $y[3]) = (
			$c{x} - $c{w} * 0.6,
			$c{y},
		       );

      my $path = $svg->get_path(
				x => \@x,
				y => \@y,
				-type => 'polygon',
				-relative => '1',
				-closed => 'true',
			       );
      if ($c{url}) {
	$svg->anchor(
		     -href => $c{url},
		     -target => 'new_window',
		    )->polygon(
			       %$path,
			       stroke => $c{stroke},
			       fill => $c{fill},
			       'stroke-width' => $c{'stroke-width'},
			       'opacity' => $c{opacity},
			       'stroke-opacity' => $c{'stroke-opacity'},
			       'stroke-dasharray' => $c{'stroke-dash'},
			      );
      } else {
	$svg->polygon(
		      %$path,
		      stroke => $c{stroke},
		      fill   => $c{fill},
		      'stroke-width' => $c{'stroke-width'},
		      'opacity' => $c{opacity},
		      'stroke-opacity' => $c{'stroke-opacity'},
		      'stroke-dasharray' => $c{'stroke-dash'},
		     );
      }
    }

=item DrawHeart

    DrawHeart($c, $label);

=cut

    sub DrawHeart{
      my $label = $_[1];
      my %c = (
	       stroke => 'gray',
	       'stroke-width' => 1.0,
	       opacity => 1,
	       url => '',
	       %{$_[0]},
	      );
      my @x = ();
      my @y = ();
      ($x[0], $y[0]) = (
			$c{x} + ($c{w} * 0),
			$c{y} - ($c{w} * 0.3),
		       );
      ($x[1], $y[1]) = (
			$c{x} + ($c{w} * 0.3),
			$c{y} - ($c{w} * 0.9),
		       );
      ($x[2], $y[2]) = (
			$c{x} + ($c{w} * 0.8),
			$c{y} - ($c{w} * 0.2),
		       );
      ($x[3], $y[3]) = (
			$c{x} + ($c{w} * 0.5),
			$c{y} + ($c{w} * 0.1),
		       );
      ($x[4], $y[4]) = (
			$c{x} + ($c{w} * 0.5),
			$c{y} + ($c{w} * 0.1),
		       );
      ($x[5], $y[5]) = (
			$c{x} + ($c{w} * 0),
			$c{y} + ($c{w} * 0.6),
		       );
      ($x[6], $y[6]) = (
			$c{x} + ($c{w} * 0),
			$c{y} + ($c{w} * 0.6),
		       );
      ($x[7], $y[7]) = (
			$c{x} + ($c{w} * 0),
			$c{y} + ($c{w} * 0.6),
		       );
      ($x[8], $y[8]) = (
			$c{x} - ($c{w} * 0.5),
			$c{y} + ($c{w} * 0.1),
		       );
      ($x[9], $y[9]) = (
			$c{x} - ($c{w} * 0.5),
			$c{y} + ($c{w} * 0.1),
		       );
      ($x[10], $y[10]) = (
			  $c{x} - ($c{w} * 0.8),
			  $c{y} - ($c{w} * 0.2),
			 );
      ($x[11], $y[11]) = (
			  $c{x} - ($c{w} * 0.3),
			  $c{y} - ($c{w} * 0.9),
			 );
      ($x[12], $y[12]) = (
			  $c{x} - ($c{w} * 0),
			  $c{y} - ($c{w} * 0.3),
			 );

      my $d = '';
      for my $cnt (0..12) {
	$d .= 'M' if($cnt == 0);
	$d .= 'C' if($cnt == 1);
	$d .= "$x[$cnt],$y[$cnt]";
	$d .= ' ' if($cnt != 12);
	$d .= 'Z' if($cnt == 12);
      }
    
      if ($c{url}) {
	$svg->anchor(
		     -href => $c{url},
		     -target => 'new_window',
		    )->path(
			    d => $d,
			    stroke => $c{stroke},
			    fill => $c{fill},
			    'stroke-width' => $c{'stroke-width'},
			    'fill-opacity' => $c{opacity},
			    'stroke-dasharray' => $c{'stroke-dash'},
			   );
      } else {
	$svg->path(
		   d => $d,
		   stroke => $c{stroke},
		   fill => $c{fill},
		   'stroke-width' => $c{'stroke-width'},
		   'opacity' => $c{opacity},
		   'stroke-opacity' => $c{'stroke-opacity'},
		   'stroke-dasharray' => $c{'stroke-dash'},
		  );
      }
    }

=item DrawSmile

    DrawSmile($c, $label);

=cut

    sub DrawSmile{
      my $c = shift;

      $svg->circle(
		   cx => $c->{x} + (0.15 * $c->{w}),
		   cy => $c->{y} - (0.2 * $c->{w}),
		   r => $c->{w} * 0.04,
		   stroke => 'none',
		   fill => $c->{smile},
		  );
      $svg->circle(
		   cx => $c->{x} - (0.15 * $c->{w}),
		   cy => $c->{y} - (0.2 * $c->{w}),
		   r => $c->{w} * 0.04,
		   stroke => 'none',
		   fill => $c->{smile},
		  );
      my @x = ();
      my @y = ();

      ($x[0], $y[0]) = (
			$c->{x} + (0.2 * $c->{w}),
			$c->{y},
		       );
      ($x[1], $y[1]) = (
			$x[0],
			$y[0] + (0.1 * $c->{w}),
		       );
      ($x[3], $y[3]) = (
			$c->{x},
			$c->{y} + (0.2 * $c->{w}),
		       );
      ($x[2], $y[2]) = (
			$x[3] + (0.1 * $c->{w}),
			$y[3],
		       );
      ($x[4], $y[4]) = (
			$x[3] - (0.1 * $c->{w}),
			$y[3],
		       );
      ($x[6], $y[6]) = (
			$c->{x} - (0.2 * $c->{w}),
			$c->{y},
		       );
      ($x[5], $y[5]) = (
			$x[6],
			$y[6] + (0.1 * $c->{w}),
		       );



      my $d = '';
      for my $cnt (0..6) {
	$d .= 'M' if($cnt == 0);
	$d .= 'C' if($cnt == 1);
	$d .= "$x[$cnt],$y[$cnt]";
	$d .= ' ' if($cnt != 6);
      }

      $svg->path(
		 d => $d,
		 stroke => $c->{smile},
		 fill => 'none',
		 'stroke-width' => 0.05 * $c->{w},
		 'stroke-linecap' => 'round',
		);
    }

  sub DrawSmilepo{
    my $c = shift;

    $svg->line(
	       x1 => $c->{x} + (0.25 * $c->{w}),
	       y1 => $c->{y} - (0.25 * $c->{w}),
	       x2 => $c->{x} + (0.25 * $c->{w}),
	       y2 => $c->{y} + (0.05 * $c->{w}),
	       stroke => $c->{smilepo},
	       'stroke-width' => 0.05 * $c->{w},
	      );

    $svg->line(
	       x1 => $c->{x} - (0.25 * $c->{w}),
	       y1 => $c->{y} - (0.25 * $c->{w}),
	       x2 => $c->{x} - (0.25 * $c->{w}),
	       y2 => $c->{y} + (0.05 * $c->{w}),
	       stroke => $c->{smilepo},
	       'stroke-width' => 0.05 * $c->{w},
	      );

    my @x = ();
    my @y = ();

    ($x[0], $y[0]) = (
		      $c->{x} + (0.25 * $c->{w}),
		      $c->{y} + (0.2 * $c->{w}),
		     );
    ($x[1], $y[1]) = (
		      $x[0],
		      $y[0] + (0.15 * $c->{w}),
		     );
    ($x[3], $y[3]) = (
		      $c->{x} - (0.25 * $c->{w}),
		      $c->{y} + (0.2 * $c->{w}),
		     );
    ($x[2], $y[2]) = (
		      $x[3],
		      $y[3] + (0.15 * $c->{w}),
		     );

    my $d = '';
    for my $cnt (0..3) {
      $d .= 'M' if($cnt == 0);
      $d .= 'C' if($cnt == 1);
      $d .= "$x[$cnt],$y[$cnt]";
      $d .= ' ' if($cnt != 3);
    }

    $svg->path(
	       d => $d,
	       stroke => $c->{smilepo},
	       fill => 'none',
	       'stroke-width' => 0.05 * $c->{w},
	      );
    @x = ();
    @y = ();

    ($x[0],$y[0]) = (
		     $c->{x} + 0.2 * $c->{w},
		     $c->{y} + 0.4 * $c->{w},
		    );
    ($x[1],$y[1]) = (
		     $c->{x} - 0.2 * $c->{w},
		     $c->{y} + 0.4 * $c->{w},
		    );
    ($x[2],$y[2]) = (
		     $c->{x} - 0.1 * $c->{w},
		     $c->{y} + 0.6 * $c->{w},
		    );
    ($x[3],$y[3]) = (
		     $c->{x} + 0.1 * $c->{w},
		     $c->{y} + 0.6 * $c->{w},
		    );

    my $path = $svg->get_path(
			      x => \@x,
			      y => \@y,
			      -type => 'polygon',
			      -relative => '1',
			      -closed => 'true',
			     );

    $svg->polygon(
		  %$path,
		  stroke => 'none',
		  fill => $c->{smilepo},
		 );

    @x = ();
    @y = ();

    ($x[0],$y[0]) = (
		     $c->{x} + 0.4 * $c->{w},
		     $c->{y} - 0.15 * $c->{w},
		    );
    ($x[1],$y[1]) = (
		     $c->{x} + 0.05 * $c->{w},
		     $c->{y} - 0.15 * $c->{w},
		    );
    ($x[2],$y[2]) = (
		     $c->{x} + 0.05 * $c->{w},
		     $c->{y} - 0.0 * $c->{w},
		    );
    ($x[3],$y[3]) = (
		     $c->{x} + 0.4 * $c->{w},
		     $c->{y} - 0.0 * $c->{w},
		    );

    $path = $svg->get_path(
			   x => \@x,
			   y => \@y,
			   -type => 'polygon',
			   -relative => '1',
			   -closed => 'true',
			  );

    $svg->polygon(
		  %$path,
		  stroke => $c->{smilepo},
		  fill => 'none',
		  'stroke-width' => 0.025 * $c->{w},
		 );
    @x = ();
    @y = ();

    ($x[0],$y[0]) = (
		     $c->{x} - 0.4 * $c->{w},
		     $c->{y} - 0.15 * $c->{w},
		    );
    ($x[1],$y[1]) = (
		     $c->{x} - 0.05 * $c->{w},
		     $c->{y} - 0.15 * $c->{w},
		    );
    ($x[2],$y[2]) = (
		     $c->{x} - 0.05 * $c->{w},
		     $c->{y} - 0 * $c->{w},
		    );
    ($x[3],$y[3]) = (
		     $c->{x} - 0.4 * $c->{w},
		     $c->{y} - 0 * $c->{w},
		    );

    $path = $svg->get_path(
			   x => \@x,
			   y => \@y,
			   -type => 'polygon',
			   -relative => '1',
			   -closed => 'true',
			  );

    $svg->polygon(
		  %$path,
		  stroke => $c->{smilepo},
		  fill => 'none',
		  'stroke-width' => 0.025 * $c->{w},
		 );


    $svg->line(
	       x1 => $c->{x} + 0.05 * $c->{w},
	       y1 => $c->{y} - 0.075 * $c->{w},
	       x2 => $c->{x} - 0.05 * $c->{w},
	       y2 => $c->{y} - 0.075 * $c->{w},
	       stroke => $c->{smilepo},
	       'stroke-width' => 0.025* $c->{w},
	      )
  }

=item DrawComponentLabel

    DrawComponentLabel($f, $label);

=cut

    sub DrawComponentLabel {
      my $f = shift;
      my $label = shift;

		for ( qw{font-size font-family font-color font-opacity} ) {
			carp "[warn] DrawComponentLabel : $_ is missing!" unless defined($f->{$_});
		}	

      $svg->text(
		 x => $f->{x},
		 y => $f->{y}+($f->{'font-size'} / 3),
		 'font-family' => $f->{'font-family'},
		 'font-size' => $f->{'font-size'},
		 'fill' => $f->{'font-color'},
		 'stroke-width' => 1,
		 'stroke' => 'white',
		 'text-anchor' => 'middle',
		 'opacity' => $f->{'font-opacity'},
		)->cdata($label);
      $svg->text(
		 x => $f->{x},
		 y => $f->{y}+($f->{'font-size'} / 3),
		 'font-family' => $f->{'font-family'},
		 'font-size' => $f->{'font-size'},
		 'fill' => $f->{'font-color'},
		 'text-anchor' => 'middle',
		 'opacity' => $f->{'font-opacity'},
		)->cdata($label);
    }

=item DrawComponent

    DrawComponent($c, $components);

=cut

sub DrawComponent {
	my ( $c, $cmps ) = @_;
	my $type = $c->{type};

	# TypeDispatchTable
	my $table = {
		oval => \&DrawCircle,
		circle => \&DrawCircle,
		star => \&DrawStar,
		heart => \&DrawHeart,
		diamond => \&DrawDiamond,
		smile => \&DrawSmile,
		smilepo => \&DrawSmilepo,
	};
	# Main circle positions.
	my $X = $c->{x};
	my $Y = $c->{y};
	my $R = $c->{w};

	# component info
	my $pi = 3.141592653589793238462643383279;
	my $n  = scalar( keys %{$cmps} );
	$n = 2 if ($n == 1);
	my $theta = (180/$n) * ($pi/180);
	my $r = sin($theta) * $R / ( sin($theta) + 1 );
	my $d = $R - $r;
	my $rotate_sub_degree = 180 / $n;
	my $rotation_degree   = 360 / $n;
	my $count = 1;

	while (my ($name, $str) = each %{$cmps}) {
		my $cc = {
			'font-color' => '#000000',
			'fill'       => 'blue',
			'fill-stroke'       => 'blue',
			'opacity'       => 0.5,
			'stroke-width'    => 0.5,
			'stroke'    => 'blue',
			'stroke-opacity'    => 1,
			'stroke-dash'    => 'none',
			'font-color'    => '#000000',
			'width-scale' => 1,
			%{$str->{graphics}}};

		for (qw{stroke-width stroke opacity stroke-opacity font-color  }) {
			carp "[warn] DrawComponent : $_ missing! " unless defined($cc->{$_});
		}

		my $deg = $rotation_degree * $count - $rotate_sub_degree;
		$cc->{y} = $Y + $d * sin($deg * ($pi/180));
		$cc->{x} = $X + $d * cos($deg * ($pi/180));
		$cc->{w} = $r  * $cc->{'width-scale'};
		$cc->{'stroke-width'} = $c->{'stroke-width'} / $n;
		$cc->{'stroke'} = $c->{'stroke'};
		$cc->{'opacity'} = $c->{opacity};
		$cc->{'stroke-opacity'} = $c->{'stroke-opacity'};
		$cc->{$type} = '#000000' if $type eq 'smile' or $type eq 'smilepo';
		for ( keys(%{$cc}) ) {
			delete $cc->{$_} unless defined($cc->{$_});
		}
		# Draw Component
		$table->{$type}($cc);
		# Draw Component Label
		my $f = {
			x => $cc->{x},
			y => $cc->{y},
			'font-size' => $c->{'font-size'}/$n,
			'font-family' => $c->{'font-family'},
			'font-opacity' => $c->{'font-opacity'},
			'font-color'  => $cc->{'font-color'},
		};
		DrawComponentLabel($f, $str->{label});
		$count++;
	}
}

=item DrawCircle

    DrawCircle($c, $label);

=cut

    sub DrawCircle{
      my $label = $_[1];
      my %c = (
	       stroke => 'gray',
	       fill => 'red',
	       'stroke-width' => 1.0,
	       opacity => 1,
	       url => '',
	       %{$_[0]},
	      );

      if ( $c{url} ) {
	$svg->anchor(
		     -href => $c{url},
		     -target => 'new_window',
		    )->circle(
			      cx => $c{x},
			      cy => $c{y},
			      r => $c{w}/2,
			      stroke => $c{stroke},
			      fill => $c{fill},
			      'stroke-width' => $c{'stroke-width'},
			      'fill-opacity' => $c{opacity},
			      'stroke-dasharray' => $c{'stroke-dash'},
			     );
      } else {
	$svg->circle(
		     cx => $c{x},
		     cy => $c{y},
		     r => $c{w}/2,
		     stroke => $c{stroke},
		     fill => $c{fill},
		     'stroke-width' => $c{'stroke-width'},
		     'opacity' => $c{opacity},
		     'stroke-opacity' => $c{'stroke-opacity'},
		     'stroke-dasharray' => $c{'stroke-dash'},
		    );
      }
    }

=item DrawStar

    DrawStar($c, $label);

=cut

    sub DrawStar{
      my $id = $_[1];
      my %c = (
	       stroke => 'gray',
	       'stroke-width' => 1.0,
	       wing => 0.4,
	       opacity => 1,
	       url => '',
	       %{$_[0]},
	      );
      my @x = ();
      my @y = ();
      my $rad = 2 * 3.1416 / 10;
   
      for my $i (0..9) {
	my $wing = 1;
	if ($i % 2 != 0) {
	  $wing = 1 * $c{wing};
	}
	push @x, $c{x} + ($wing * $c{w} * sin($i * $rad));
	push @y, $c{y} - ($wing * $c{w} * cos($i * $rad));
      }
      my $path = $svg->get_path(
				x => \@x,
				y => \@y,
				-type => 'polygon',
				-relative => '1',
				-closed => 'true',
			       );
    
      if ($c{url}) {
	$svg->anchor(
		     -href => $c{url},
		     -target => 'new_window',
		    )->polygon(
			       %$path,
			       stroke => $c{stroke},
			       fill => $c{fill},
			       'stroke-width' => $c{'stroke-width'},
			       'fill-opacity' => $c{opacity},
			       'stroke-dasharray' => $c{'stroke-dash'},
			      );
      } else {
	$svg->polygon(
		      %$path,
		      stroke => $c{stroke},
		      fill => $c{fill},
		      'stroke-width' => $c{'stroke-width'},
		      'opacity' => $c{opacity},
		      'stroke-opacity' => $c{'stroke-opacity'},
		      'stroke-dasharray' => $c{'stroke-dash'},
		     );
      }
    }

=item DrawEdge

    DrawEdge($gstr);

=cut

    sub DrawEdge{
      my $gstr = shift;

      foreach my $source (keys %{$gstr->{edge}}) {
	foreach my $target (keys %{$gstr->{edge}->{$source}}) {
	  unless (defined $gstr->{edge}->{$source}->{$target}->{disable} 
		  && $gstr->{edge}->{$source}->{$target}->{disable} == 1) {
	    my $cb = $gstr->{edge}->{$source}->{$target};

	    my $Es = dclone($gstr->{node}->{$source}->{graphics});
	    my $Et = dclone($gstr->{node}->{$target}->{graphics});
	    my $c = dclone($cb->{graphics});
	    if ( $d ) {
	      &DrawLine($c, $Es, $Et);
	    } else {
	      if ($source eq $target) {
		&DrawSelf($c, $Es, $source, \$gstr);
	      } elsif (defined $gstr->{edge}->{$target}->{$source}) {
		$c->{revwidth} = $gstr->{edge}->{$target}->{$source}->{graphics}->{"stroke-width"};
		my $M = sqrt(($Es->{x} - $Et->{x}) ** 2 + ($Es->{y} - $Et->{y}) ** 2);
		$Es->{x} = $Es->{x} + ($Et->{x} - $Es->{x}) * ($Es->{w} / 2) / $M;
		$Es->{y} = $Es->{y} + ($Et->{y} - $Es->{y}) * ($Es->{w} / 2) / $M;
		$Et->{x} = $Et->{x} - ($Et->{x} - $Es->{x}) * ($Et->{w} / 2) / $M;
		$Et->{y} = $Et->{y} - ($Et->{y} - $Es->{y}) * ($Et->{w} / 2) / $M;
		&DrawDualLine($c, $Es, $Et);
	      } else {
		my $M = sqrt(($Es->{x} - $Et->{x}) ** 2 + ($Es->{y} - $Et->{y}) ** 2);
		$Es->{x} = $Es->{x} + ($Et->{x} - $Es->{x}) * ( $Es->{w} / 2) / $M;
		$Es->{y} = $Es->{y} + ($Et->{y} - $Es->{y}) * ( $Es->{w} / 2) / $M;
		$Et->{x} = $Et->{x} - ($Et->{x} - $Es->{x}) * (( $Et->{w} + $c->{'stroke-width'}*2 ) / 2) / $M;
		$Et->{y} = $Et->{y} - ($Et->{y} - $Es->{y}) * (( $Et->{w} + $c->{'stroke-width'}*2 ) / 2) / $M;
		($Et->{x}, $Et->{y}) = DrawArrow($c, $Es, $Et);
		#$Et->{x} = $Et->{x} - ($Et->{x} - $Es->{x}) * ($c->{'stroke-width'}) / $M;
		#$Et->{y} = $Et->{y} - ($Et->{y} - $Es->{y}) * ($c->{'stroke-width'}) / $M;
		DrawLine($c, $Es, $Et);
	      }
	    }
	  }
	}
      }
    }

=item DrawSelf

    DrawSelf($c, $Es, $sl, $gstr);

=cut

    sub DrawSelf{
      my $c = $_[0];
      my %c = (
	       stroke => 'gray',
	       width => 1.0,
	       %{$c},
	      );
      my $Es = $_[1];
      my $sl = $_[2];
      my $gstr = $_[3];
    
      my $tnodes = undef;

      while (my ($type, $Str_A) = each %{${$gstr}}) {
	if ($type eq 'edge') {
	  for my $tmps (keys %{$Str_A}) {
	    for my $tmpt (keys %{$Str_A->{$tmps}}) {
	      if ($tmps ne $tmpt) {
		if ($tmps eq $sl) {
		  $tnodes->{$tmpt} = ${$gstr}->{node}->{$tmpt}->{graphics};
		} elsif ($tmpt eq $sl) {
		  $tnodes->{$tmps} = ${$gstr}->{node}->{$tmps}->{graphics};
		}
	      }
	    }
	  }
	}
      }

      my $Sum = undef;
      $Sum->{x} = 0;
      $Sum->{y} = 0;
      if (keys %{$tnodes}) {
	for my $tnode (keys %{$tnodes}) {
	  my $Eot = $tnodes->{$tnode};
	  my $M = sqrt(($Es->{x} - $Eot->{x}) ** 2 + ($Es->{y} - $Eot->{y}) ** 2);

	  $Sum->{x} -= ($Eot->{x} - $Es->{x}) / $M;
	  $Sum->{y} -= ($Eot->{y} - $Es->{y}) / $M;
	}
      } else {
	$Sum->{x} = 1;
	$Sum->{y} = 1;
      }
      my $SM = sqrt($Sum->{x} ** 2 + $Sum->{y} ** 2);
      $Sum->{x} /= $SM;
      $Sum->{y} /= $SM;
      my @x = ();
      my @y = ();
      ($x[0], $y[0]) = (
			$Es->{x},
			$Es->{y},
		       );
      ($x[1], $y[1]) = (
			$Es->{x} + $Sum->{y} * $Es->{w} * 0.5,
			$Es->{y} - $Sum->{x} * $Es->{w} * 0.5,
		       );
      ($x[3], $y[3]) = (
			$Es->{x} + ($Sum->{x} + $Sum->{y}) * $Es->{w},
			$Es->{y} + (- $Sum->{x} + $Sum->{y}) * $Es->{w},
		       );
      ($x[2], $y[2]) = (
			$x[3] - $Sum->{x} * $Es->{w} * 0.5,
			$y[3] - $Sum->{y} * $Es->{w} * 0.5,
		       );
      ($x[4], $y[4]) = (
			$x[3] + $Sum->{x} * $Es->{w} * 0.5,
			$y[3] + $Sum->{y} * $Es->{w} * 0.5,
		       );
      ($x[6], $y[6]) = (
			$Es->{x} + $Sum->{x} * $Es->{w} * 2,
			$Es->{y} + $Sum->{y} * $Es->{w} * 2,
		       );
      ($x[5], $y[5]) = (
			$x[6] + $Sum->{y} * $Es->{w} * 0.5,
			$y[6] - $Sum->{x} * $Es->{w} * 0.5,
		       );
      ($x[7], $y[7]) = (
			$x[6] - $Sum->{y} * $Es->{w} * 0.5,
			$y[6] + $Sum->{x} * $Es->{w} * 0.5,
		       );
      ($x[9], $y[9]) = (
			$Es->{x} + ($Sum->{x} - $Sum->{y}) * $Es->{w},
			$Es->{y} + ($Sum->{x} + $Sum->{y}) * $Es->{w},
		       );
      ($x[8], $y[8]) = (
			$x[9] + $Sum->{x} * $Es->{w} * 0.5,
			$y[9] + $Sum->{y} * $Es->{w} * 0.5,
		       );
      ($x[10], $y[10]) = (
			  $x[9] - $Sum->{x} * $Es->{w} * 0.5,
			  $y[9] - $Sum->{y} * $Es->{w} * 0.5,
			 );
      ($x[11], $y[11]) = (
			  $x[0] - $Sum->{y} * $Es->{w} * 0.5,
			  $y[0] + $Sum->{x} * $Es->{w} * 0.5,
			 );
      ($x[12], $y[12]) = (
			  $x[0] - $Sum->{y} * $c{'stroke-width'},
			  $y[0] + $Sum->{x} * $c{'stroke-width'},
			 );

      my $d = '';
      for my $cnt (0..12) {
	$d .= 'M' if($cnt == 0);
	$d .= 'C' if($cnt == 1);
	$d .= "$x[$cnt],$y[$cnt]";
	$d .= ' ' if($cnt != 12);
      }

      $svg->path(
		 d => $d,
		 stroke => $c{stroke},
		 fill => 'none',
		 'stroke-width' => $c{'stroke-width'},
		 'opacity' => $c{'opacity'},
		 'stroke-dasharray' => $c{'stroke-dash'},
		);

      my $dEt = undef;
      ($dEt->{x}, $dEt->{y}) = ($x[11], $y[11]);
      &DrawArrow($c, $dEt, $Es);

    }

=item DrawLine

    DrawLine($Es, $Et);

=cut

    sub DrawLine{
      my %c = (
	       %{$_[0]},
	      );
      my $Es = $_[1];
      my $Et = $_[2];

      $svg->line(
		 x1 => $Es->{x},
		 x2 => $Et->{x},
		 y1 => $Es->{y},
		 y2 => $Et->{y},
		 stroke => $c{stroke},
		 fill => 'none',
		 'stroke-width' => $c{'stroke-width'},
		 'opacity' => $c{'opacity'},
		 'stroke-dasharray' => $c{'stroke-dash'},
		);
    }

=item DrawDualLine

    DrawDualLine($c, $Es, $Et);

=cut

    sub DrawDualLine{
      my $c = shift;
      my $Es = shift;
      my $Et = shift;

      my $dx = $Et->{x} - $Es->{x};
      my $dy = $Et->{y} - $Es->{y};

      my $M = sqrt($dx ** 2 + $dy ** 2) / 4;
      my $r = ($Et->{w} + $Es->{w}) / 4;

      my @x = ();
      my @y = ();

      ($x[1], $y[1]) = (
			$Es->{x} + ($dx / 4) + (($dy * $r / $s) / $M),
			$Es->{y} + ($dy / 4) - (($dx * $r / $s) / $M),
		       );
      ($x[2], $y[2]) = (
			$Et->{x} - ($dx / 4) + (($dy * $r / $s) / $M),
			$Et->{y} - ($dy / 4) - (($dx * $r / $s) / $M),
		       );
      ($x[5], $y[5]) = (
			$Es->{x} + ($dx / 4) - (($dy * $r / $s) / $M),
			$Es->{y} + ($dy / 4) + (($dx * $r / $s) / $M),
		       );
      ($x[6], $y[6]) = (
			$Et->{x} - ($dx / 4) - (($dy * $r / $s) / $M),
			$Et->{y} - ($dy / 4) + (($dx * $r / $s) / $M),
		       );

      my $M2 = sqrt(($Et->{x} - $x[2]) ** 2 + ($Et->{y} - $y[2]) ** 2);

      ($x[3], $y[3]) = (
			$Et->{x} - ($Et->{x} - $x[2]) * $c->{'stroke-width'} / $M2,
			$Et->{y} - ($Et->{y} - $y[2]) * $c->{'stroke-width'} / $M2,
		       );

      my $M3 = sqrt(($Es->{x} - $x[5]) ** 2 + ($Es->{y} - $y[5]) ** 2);

      ($x[4], $y[4]) = (
			$Es->{x} - ($Es->{x} - $x[5]) * $c->{revwidth} / $M3,
			$Es->{y} - ($Es->{y} - $y[5]) * $c->{revwidth} / $M3,
		       );


      my $d1 = "M$Es->{x},$Es->{y} C$x[1],$y[1] $x[2],$y[2] $x[3],$y[3]";
      my $d2 = "M$x[4],$y[4] C$x[5],$y[5] $x[6],$y[6] $Et->{x},$Et->{y}";

      $svg->path(
		 d => $d1,
		 stroke => $c->{stroke},
		 'stroke-width' => $c->{'stroke-width'},
		 'opacity' => $c->{'opacity'},
		 fill => 'none',
		 'stroke-dasharray' => $c->{'stroke-dash'},
		);

      $svg->path(
		 d => $d2,
		 stroke => $c->{stroke},
		 'stroke-width' => $c->{revwidth},
		 opacity => $c->{opacity},
		 fill => 'none',
		 'stroke-dasharray' => $c->{'stroke-dash'},
		);

      my $dEt = undef;
      my $dEs = undef;
      ($dEt->{x}, $dEt->{y}) = ($x[2], $y[2]);
      ($dEs->{x}, $dEs->{y}) = ($x[5], $y[5]);
      &DrawArrow($c, $dEt, $Et);

      $c->{'stroke-width'} = $c->{revwidth};
      &DrawArrow($c, $dEs, $Es);
    }

=item DrawInhibit

    DrawLine($c, $x, $y);
  DrawLine only called by DrawArrow.

=cut

      sub DrawInhibit {
	my $c = shift;
	my $x = shift;
	my $y = shift;

	my $path = $svg->get_path(
				  x => $x,
				  y => $y,
				  -type => 'polyline',
				  -relative => '1',
				  -closed => 'false',
				 );

	$svg->polygon(
		      %$path,
		      fill => $c->{stroke},
		      stroke => $c->{stroke},
		      fill => 'none',
		      'stroke-width' => $c->{'stroke-width'},
		      'opacity' => $c->{'opacity'},
		     );

	return $_[0]->();
      }

=item DrawArrow

    DrawArrow($c, $Es, $Et);

=cut

    sub DrawArrow{
      my $c = shift;
      my $Es = shift;
      my $Et = shift;

      my $M = sqrt(($Es->{x} - $Et->{x}) ** 2 + ($Es->{y} - $Et->{y}) ** 2);
      my $ax = $Et->{x};
      my $ay = $Et->{y};

      my $dx_x = ($Es->{y} - $Et->{y}) * $c->{'stroke-width'} / $M;
      my $dx_y = ($Et->{x} - $Es->{x}) * $c->{'stroke-width'} / $M;
      my $dy_x = ($Es->{x} - $Et->{x}) * $c->{'stroke-width'} / $M;
      my $dy_y = ($Es->{y} - $Et->{y}) * $c->{'stroke-width'} / $M;

      if ( defined($c->{type}) && $c->{type} eq 'inhibit' ) {
	@_ = ($c,
	      [ $ax + 3 * $dx_x + 2 * $dy_x ,
		$ax - 3 * $dx_x + 2 * $dy_x ], # x
	      [ $ay + 3 * $dx_y + 2 * $dy_y ,
		$ay - 3 * $dx_y + 2 * $dy_y ], # y

	      sub { return ( $ax + 3 * $dy_x ,  $ay + 3 * $dy_y ); },
	     );
	goto &DrawInhibit;
      }

      my @x = ();
      my @y = ();

      push @x, $ax;
      push @y, $ay;

      push @x, $ax + 3 * $dx_x +  6 * $dy_x;
      push @x, $ax + 3 * $dy_x;
      push @x, $ax - 3 * $dx_x +  6 * $dy_x;

      push @y, $ay + 3 * $dx_y +  6 * $dy_y;
      push @y, $ay + 3 * $dy_y;
      push @y, $ay - 3 * $dx_y +  6 * $dy_y;

      my $path = $svg->get_path(
				x => \@x,
				y => \@y,
				-type => 'polygon',
				-relative => '1',
				-closed => 'true',
			       );

      $svg->polygon(
		    %$path,
		    fill => $c->{stroke},
		    'stroke-width' => 0,
		    'fill-opacity' => $c->{opacity},
		   );

      return ( $ax + 3 * $dy_x ,  $ay + 3 * $dy_y );
    }

=item MatchField

    MatchField($gstr, $xmax, $xmin, $ymax, $ymin);

=cut

    sub MatchField{
      my $gstr = shift;
      my $xmax = -10000;
      my $xmin = 10000;
      my $ymax = -10000;
      my $ymin = 10000;
      my $rad = 2 * 3.1415926535897 / 360;

      foreach my $id (keys %{$gstr->{node}}) {
	unless (defined $gstr->{node}->{$id}->{disable} && $gstr->{node}->{$id}->{disable} == 1) {
	  if ($r) {
	    my $tmpx = $gstr->{node}->{$id}->{graphics}->{x};
	    my $tmpy = $gstr->{node}->{$id}->{graphics}->{y};

	    $gstr->{node}->{$id}->{graphics}->{x} = 
	      $tmpx * cos($rad * $r) - $tmpy * sin($rad * $r);

	    $gstr->{node}->{$id}->{graphics}->{y} = 
	      $tmpx * sin($rad * $r) + $tmpy * cos($rad * $r);
	  }

	  my $c = $gstr->{node}->{$id}->{graphics};
	  if ($c->{x} > $xmax) {
	    $xmax = $c->{x};
	  }
	  if ($c->{x} < $xmin) {
	    $xmin = $c->{x};
	  }
	  if ($c->{y} > $ymax) {
	    $ymax = $c->{y};
	  }
	  if ($c->{y} < $ymin) {
	    $ymin = $c->{y};
	  }
	}
      }

      if ($xmax < 0) {
	my $tmpxmin = $xmin;
	$xmax = $xmax - $xmin;
	$xmin = 0;
	foreach my $id (sort keys %{$gstr->{node}}) {
	  unless (defined $gstr->{node}->{$id}->{disable} && $gstr->{node}->{$id}->{disable} == 1) {

	    $gstr->{node}->{$id}->{graphics}->{x} -= $tmpxmin;
	  }
	}
      }

      if ($ymax < 0) {
	my $tmpymin = $ymin;
	$ymax = $ymax - $ymin;
	$ymin = 0;
	foreach my $id (keys %{$gstr->{node}}) {
	  unless (defined $gstr->{node}->{$id}->{disable} && $gstr->{node}->{$id}->{disable} == 1) {
	    $gstr->{node}->{$id}->{graphics}->{y} -= $tmpymin;
	  }
	}
      }

      my $xk = undef;
      my $yk = undef;
      if ($xmax - $xmin > 0) {
	$xk = ($w - (2 * $m)) / ($xmax - $xmin);
      } else {
	$xk = 10000;
      }
      if ($ymax - $ymin > 0) {
	$yk = ($h - (2 * $m)) / ($ymax - $ymin);
      } else {
	$yk = 10000;
      }

      my $kflag = undef;
      if ($xk > $yk) {
	$xk = $yk;
	$kflag = 1; 
      } else {
	$yk = $xk;
      }

      my $k = $xk;
      $k = 1 if($k == 0);

      my $cntring = undef;
      if ($kflag) {
	$cntring = ($w - 2 * $m) / 2 - ($xmax - $xmin)  * $xk / 2;
      } else {
	$cntring = ($h - 2 * $m) / 2 - ($ymax - $ymin)  * $yk / 2;
      }

      foreach my $id (keys %{$gstr->{node}}) {
	unless (defined $gstr->{node}->{$id}->{disable} && $gstr->{node}->{$id}->{disable} == 1) {
	  $gstr->{node}->{$id}->{graphics}->{x} -= $xmin;
	  $gstr->{node}->{$id}->{graphics}->{y} -= $ymin;
	  $gstr->{node}->{$id}->{graphics}->{x} *= $xk;
	  $gstr->{node}->{$id}->{graphics}->{y} *= $yk;
	  $gstr->{node}->{$id}->{graphics}->{x} += $m;
	  $gstr->{node}->{$id}->{graphics}->{y} += $m;
	  $gstr->{node}->{$id}->{graphics}->{x} += ($w - 2 * $m) / 2 
	    if (!($xk));
	  $gstr->{node}->{$id}->{graphics}->{y} += ($h - 2 * $m) / 2 
	    if (!($yk));

	  if ($kflag) {
	    $gstr->{node}->{$id}->{graphics}->{x} += $cntring;	    
	  } else {
	    $gstr->{node}->{$id}->{graphics}->{y} += $cntring;
	  }

	  #	    if(defined($gstr->{node}->{$id}->{graphics}->{r})){
	  #		$gstr->{node}->{$id}->{graphics}->{r} *= $k;
	  #	    }else{
	  #		$gstr->{node}->{$id}->{graphics}->{r} = 
	  #		    $gstr->{node}->{$id}->{graphics}->{w} * $k / 2;
	  #	    }

	  #	    $gstr->{node}->{$id}->{graphics}->{'stroke-width'} *= $k 
	  #		if(defined($gstr->{node}->{$id}->{graphics}->{'stroke-width'}));
	}
      }

      foreach my $source (keys %{$gstr->{edge}}) {
	foreach my $target (keys %{$gstr->{edge}->{$source}}) {
	  unless (defined $gstr->{edge}->{$source}->{$target}->{disable} 
		  && $gstr->{edge}->{$source}->{$target}->{disable} == 1) {
	    #		$gstr->{edge}->{$source}->{$target}->{graphics}->{'stroke-width'} *= $k
	    #		    if(defined($gstr->{edge}->{$source}->{$target}->{graphics}->{'stroke-width'}));
	    #		$gstr->{edge}->{$source}->{$target}->{graphics}->{revwidth} *= $k
	    #		    if(defined($gstr->{edge}->{$source}->{$target}->{graphics}->{revwidth}));
	  }
	}
      }
      return $gstr;
    }

}

1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
