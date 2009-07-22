package eXpanda::Output;

use strict;
use warnings;
use Carp;
use Storable qw/dclone/;
# Modules under Output/
use autouse 'eXpanda::Layout'            => qw(CalCoord);
use autouse 'eXpanda::Output::GML'       => qw(Str2Gml);
use autouse 'eXpanda::Output::Svg'       => qw(Str2Svg);
use autouse 'eXpanda::Output::Text'      => qw(Str2Sif);
use autouse 'eXpanda::Output::GraphGear' => qw(Str2GraphGear);
use eXpanda::StrMod qw/ApplyGraphics/; #Exporter.

sub _dispatcher {
  return {
    'svg' => sub {
      my ( $str, $attribute ) = @_;
      Str2Svg( CalCoord( ApplyGraphics($str, $attribute), $attribute, $str),
        $attribute);
    },
    'gml' => sub {
      my ( $str, $attribute ) = @_;
      Str2Gml( CalCoord( ApplyGraphics($str, $attribute), $attribute), $attribute);
    },
    'sif' => \&Str2Sif,
    'graphgear' => \&Str2GraphGear,
  };
}

sub layout {
  my $str = shift;
  my %attribute = (
    -filetype => 'svg',
    # graph attributes for Graph::Layout::Aesthetic
    knr => '1',	  # node_repulsion
    kmel => '1',	  # min_edge_length
    kner => '1',	  # node_edge_repulsion
    kmei2 => '0',  # min_edge_intersect2
    #for CalCoordinate
    -width => '1000',	# width
    -height => '1000',	# height
    -margin => 100,	# SVG margin
    -engine => 'Graph::Layout::Aesthetic',
    #for Str2Svg
    -no_direction => 1,	 # no direction mode
    -no_node_label => 0,	 # no label
    -no_edge_label => 0,	 # no label
    -no_node => 0,	 # no label
    -no_edge => 0,	 # no label
    -dual_arrow_spreads => 2, # no label
    -rotation => 0,	     # rotation
    '-object_size' => 1,
    '-label_size' => 1,
    #input option
    @_,
  );

  my %option_index = ();

  map{ $option_index{$_} = 1 } (
    "-filetype",
    "knr",
    "kmel",
    "kner",
    "kmei2",
    "-width",
    "-height",
    "-margin",
    "-no_direction",
    "-no_edge_label",
    "-no_node_label",
    "-no_edge",
    "-no_node",
    "-dual_arrow_spreads",
    "-rotation",
    "-object_size",
    "-label_size",
    "-engine"
  );

  my $i = 0;
  for my $option (@_) {
    if ($i % 2 == 0) {
      if ( !$option_index{$option} ) {
        croak qq{[fatal] Invalid option "$option" on out()};
      }
    }
    $i++;
  }

  print STDERR "$attribute{-filetype} dispatch\n" if $eXpanda::DEBUG;

  return CalCoord( ApplyGraphics($str, \%attribute), \%attribute, $str);
}

sub out {
  my $str = shift;
  my $out = shift;

  my %attribute = (
    -filetype => 'svg',
    # graph attributes for Graph::Layout::Aesthetic
    knr => '1',	  # node_repulsion
    kmel => '1',	  # min_edge_length
    kner => '1',	  # node_edge_repulsion
    kmei2 => '0',  # min_edge_intersect2
    #for CalCoordinate
    -width => '1000',	# width
    -height => '1000',	# height
    -margin => 100,	# SVG margin
    -engine => 'Graph::Layout::Aesthetic',
    #for Str2Svg
    -o => $out,		 # SVG filename
    -no_direction => 1,	 # no direction mode
    -no_node_label => 0,	 # no label
    -no_edge_label => 0,	 # no label
    -no_node => 0,	 # no label
    -no_edge => 0,	 # no label
    -dual_arrow_spreads => 2, # no label
    -rotation => 0,	     # rotation
    '-object_size' => 1,
    '-label_size' => 1,
    #input option
    @_,
  );

  $attribute{-o} = "graph.$attribute{-filetype}" unless ($out);

  my %option_index = ();

  map{ $option_index{$_} = 1 } (
    "-filetype",
    "knr",
    "kmel",
    "kner",
    "kmei2",
    "-width",
    "-height",
    "-margin",
    "-o",
    "-no_direction",
    "-no_edge_label",
    "-no_node_label",
    "-no_edge",
    "-no_node",
    "-dual_arrow_spreads",
    "-rotation",
    "-object_size",
    "-label_size",
    "-engine"
  );

  my $i = 0;
  for my $option (@_) {
    if ($i % 2 == 0) {
      if ( !$option_index{$option} ) {
        croak qq{[fatal] Invalid option "$option" on out()};
      }
    }
    $i++;
  }

  print STDERR "$attribute{-filetype} dispatch\n" if $eXpanda::DEBUG;

  _dispatcher()->{$attribute{-filetype}}($str, \%attribute);
}

1;
