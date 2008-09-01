package eXpanda::Util;

use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

  eXpanda::Util

=head1 DESCRIPTION

eXpanda::Util is package of utility functions for eXpanda.

=head1 SYNOPSYS

# add methods to a package by arrayref
eXpanda::Util::extend 'eXpanda', 'eXpanda::Some::Module', ['method1', 'method2', 'method3'..];

# add a method to package.
eXpanda::Util::extend 'eXpanda', 'eXpanda::Some::Module', 'add_method';

=head1 FUNCTIONS

=over 4

=item extend

extend 'extend-to package name', 'extend-by package name', ['extend methods name'...]

=cut

sub extend($$;$) {
  no strict 'refs';
  my $org_pkg = shift;
  my $extend_pkg = shift;
  my $methods = shift;
  my $extend_methods = {};
  my $org_subs;
  my @extend_subs;

  if ( $methods ) {
    if (ref $methods eq 'ARRAY') {
      $extend_methods->{$_} = 1 for @{$methods};
    }
    else {
      $extend_methods->{$methods} = 1;
    }
  }

  while (my ($name , $ref) = each %{$org_pkg.'::'} ) {
    if ( *{$ref}{CODE} ) {
      $org_subs->{*{$ref}{NAME}} = 1;
    }
  }

  while (my ($name , $ref) = each %{$extend_pkg.'::'} ) {

    if ( *{$ref}{CODE} && !defined( $org_subs->{*{$ref}{NAME}}) ) {
      my $refname = *{$ref}{NAME};
      if ($methods and defined($extend_methods->{$refname})) {
	print STDERR "[debug] add $refname\n" if $eXpanda::DEBUG;
	*{$org_pkg.'::'.$refname} = *{$ref}{CODE};
      }
      elsif ( !$methods ) {
	print STDERR "[debug] add ".*{$ref}{NAME}."\n" if $eXpanda::DEBUG;
	*{$org_pkg.'::'.$refname} = *{$ref}{CODE};
      }
    }

  }
}

=item dextend

extend 'original package name', ['remove methods name'...]

=cut

sub dextend($;$) {
  no strict 'refs';
  my $org_pkg = shift;
  my $methods = shift;

  #__TODO__

}

=item say

print debug message to stderr.

=cut

sub say ($) { print STDERR "[debug] ".$_[0]."\n" if $eXpanda::DEBUG; }

=item return_max_deg_node

Return node id which has max degree.

=cut

sub return_max_deg_node {
  my $str = shift;
  carp "[warn] return_max_deg_node need structure." if !$str;
  my $current_max;

  my %countedge = ();
  while( my ( $source, $tstr) =  each %{$str->{edge}} ) {
    while( my ( $target, $vstr) =  each %{$tstr} ) {
      $countedge{$source}++;
      $countedge{$target}++;
    }
  }
  return shift @{[( sort {$countedge{$b} cmp $countedge{$a}} keys %countedge )]};
}

1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
