package eXpanda::Output::GML;

use strict;
use warnings;
#use base qw{Exporter};
#our @EXPORT_OK = qw{Str2Gml};

=head1 NAME

  eXpanda::Out::GML

=head1 DESCRIPTION

eXpanda::Output::GML is GML( Graph Markup Language ) output module for eXpanda.
export function is Str2Gml only.

=head1 FUNCTIONS

=over 4

=item Str2Svg

$gml = Str2Gml($str);

str is eXpanda structure.

=cut

sub Str2Gml{
  my $str = shift;
  my %attribute = %{shift(@_)};
  my @GML_Graphics_Tags_num = qw{x y w h width};
  my @GML_Graphics_Tags_str = qw{type fill};
  my $out = '';

  $out .= "graph";
  $out .= "\t\[\n";

  my $node = $str->{node};
  my $edge = $str->{edge};

  delete $node->{''};

  while (my ($label,$n) = each(%{$node})) {
    unless (defined $str->{node}->{$label}->{disable} && $str->{node}->{$label}->{disable} == 1) {
      $out .= "\tnode";
      $out .= "\t\t\[\n";

      if(defined $n->{id}) {
	$out .= "\t\tid\t$n->{id}\n";
      }
      elsif ($label =~ m/^\d+$/) {
	$out .= "\t\tid\t$label\n";
      }

      $out .= qq{\t\tlabel\t"$n->{label}"\n}if(defined $n->{label});

      $out .= "\t\tgraphics";
      $out .= "\t\t\t\[\n";

      if (defined $n->{graphics}) {
	$n->{graphics}->{h} = $n->{graphics}->{w} if ( defined($n->{graphics}->{w}));
	while (my ($style, $value) = each (%{$n->{graphics}})) {
	  $out .= "\t\t\t$style\t$value\n" if ( grep(/^$style$/ ,@GML_Graphics_Tags_num ) != 0);
	  $out .= qq{\t\t\t$style\t"$value"\n} if ( grep(/^$style$/ ,@GML_Graphics_Tags_str ) != 0);
	}
      }

      $out .= "\t\t\t\]\n";
      $out .= "\t\t\]\n";
    }
  }

  while (my ($labelS,$Target) = each(%{$edge})) {
    while (my ($labelT,$e) = each(%{$Target})) {
      unless (defined $str->{edge}->{$labelS}->{$labelT}->{disable} 
	      && $str->{edge}->{$labelS}->{$labelT}->{disable} == 1) {

	$out .= "\tedge";
	$out .= "\t\t\[\n";

	$out .= "\t\tsource\t$labelS\n";
	$out .= "\t\ttarget\t$labelT\n";
	$out .= qq{\t\tlabel\t"$e->{label}"\n};

	$out .= "\t\tgraphics";
	$out .= "\t\t\t\[\n";
	while (my ($style, $value) = each(%{$e->{graphics}})) {
	  if ($style eq 'stroke-width') {
	    $out .= "\t\t\twidth\t$value\n";
	  }
	  elsif ( $style eq 'stroke' ) {
	    $out .= "\t\t\tfill\t\"$value\"\n";
	  }
	  else {
	    $out .= "\t\t\t$style\t$value\n" if ( grep(/^$style$/ ,@GML_Graphics_Tags_num ) != 0);
	    $out .= qq{\t\t\t$style\t"$value"\n} if ( grep(/^$style$/ ,@GML_Graphics_Tags_str ) != 0);
	  }
	}
	$out .= "\t\t\t\]\n";
	$out .= "\t\t\]\n";
      }
    }
  }

  $out .= "\t\]\n";

  open F, ">$attribute{-o}";
  print F $out;
  close F;
}

1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
