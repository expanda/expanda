package eXpanda::Structure::Index;

use strict;
use warnings;
use Carp;

=head1 NAME

  eXpanda::Structure::Index

=head1 DESCRIPTION

eXpanda::Structure::Index is index manager.

=head1 FUNCTIONS

=over 4

=item mkindex(Structure)

Make label-id index in str:index

=cut

sub mkindex {
  my $str;
  $str = (scalar(@_) == 2) ? pop @_ : (scalar(@_) == 1) ? shift @_ : undef;
  croak "[fatal] mkindex Bad arguments." if !$str;

  while ( my ($id, $nstr) = each %{$str->{node}} ) {
    carp "[warn] mkindex: $id has no label!" unless $nstr->{label};

    if ( defined($str->{index}->{$nstr->{label}}) ) {
      carp "[warn] Redundant label. eXpanda does not support redundant label. $$nstr{label}.";
    }
    else {
      $str->{index}->{$nstr->{label}} = $id;
    }
  }

  return $str;
}

=item is_indexed('LABEL')

Return 1 if label is indexed

=cut

sub is_indexed {
  my $this = shift;
  my $label = shift;
  return ( defined($this->{index}->{$label}) ) ? 1 : 0;
}

=item label2id('LABEL')

Return corresponding id.

=cut

sub label2id {
  my $this = shift;
  my $label = shift;

  if ( defined($this->{index}->{$label}) ) {
    return $this->{index}->{$label};
  }
  else {
    carp "[warn] label2id : Cannot find id for $label.";
  }
}


1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
