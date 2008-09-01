package eXpanda::Data::GML;

use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

  eXpanda::Data::GML

=head1 DESCRIPTION

eXpanda::Data::GML is GML(Graph Markup Language) file parser for eXpanda.

=head1 FUNCTIONS

=over 4

=item Gml2Str

Gml2Str($str, $filepath);

str is graphics structure.

=cut

sub Gml2Str{
  my $gmlfile = shift;
  my $gstr;
  my $gra = 0;
  my $type = 0;
  my $id = 0;
  my $source = 0;
  my $target = 0;
  my $key = 0;
  my $val = 0;

  my $dir = undef;

  open(F, "$gmlfile");
  while (<F>) {
    chomp;
    if (/^\s+node/) {
      $type = 'node';
      $gra = 0;
    } elsif (/^\s+edge/) {
      $type = 'edge';
      $gra = 0;
    } elsif (/graphics/) {
      $gra = 1;
    } elsif (/^\s+?(label)\s+?(.*)/ && $type eq 'node') {
      $key = $1;
      $val = $2;
      $val =~ s/\"//g;
      $gstr->{$type}->{$id}->{$key} = $val;
    } elsif (/^\s+?([^\s+?]*)\s+?(.*)/ && $gra != 1 && $type eq 'node') {
      $key = $1;
      $val = $2;
      $val =~ s/\"//g;
      print "$1\t$2\n";
      if ($key eq 'id' || $key eq 'root_index') {
	$id = $val;
      }

      $gstr->{$type}->{$id}->{$key} = $val;
    } elsif (/^\s+?([^\t]*)\s+?(.*)/ && $gra != 1 && $type eq 'edge') {
      $key = $1;
      $val = $2;
      $val =~ s/\"//g;
      if ($key eq 'source') {
	$source = $val;
      } elsif ($key eq 'target') {
	$target = $val;
      } else {
	$gstr->{$type}->{$source}->{$target}->{$key} = $val;
	$gstr->{$type}->{$source}->{$target}->{source} = $source;
	$gstr->{$type}->{$source}->{$target}->{target} = $target;
      }
    } elsif (/^s+?([^\t]*)\s+?(.*)/ && $gra == 1 && $type) {
      $key = $1;
      $val = $2;
      $val =~ s/\"//g;

      #follows are comversion for svg
      $key =~ s/outline/stroke/g;
      $key =~ s/\_/\-/g;
      $val = 'oval' if($key eq 'type');

      $gstr->{$type}->{$id}->{graphics}->{$key} = $val if($type eq 'node');
      if ($type eq 'edge') {
	if ($key eq 'width') {
	  $gstr->{$type}->{$source}->{$target}->{graphics}->{'stroke-width'} = $val;
	} else {
	  $gstr->{$type}->{$source}->{$target}->{graphics}->{$key} = $val;
	}
      }
    }
  }
  close F;

  delete $gstr->{node}->{''};
  delete $gstr->{edge}->{''};
  delete $gstr->{node}->{'0'};
  delete $gstr->{edge}->{'0'};

  print Dumper $gstr;

  $gstr->{graphed} = 1;
  my @edgekey = keys %{$gstr->{edge}};
  croak qq{[fatal] No network imported from "$gmlfile" for gml format. check import file;} if($#edgekey == -1);

  $gstr->{filetype} = 'gml';

  return $gstr;
}

1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
