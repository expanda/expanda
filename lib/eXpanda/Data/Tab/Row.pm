package eXpanda::Data::Tab::Row;

use strict;
use warnings;
use Carp;

=head1 NAME

  eXpanda::Data::Tab::Row

=head1 DESCRIPTION

 Row object for eXpanda::Data::Tab

=head1 FUNCTIONS

=over 4

=item new(ROWHASH, Index(optional))

Constructor

=cut

sub new {
  my $pkg = shift;
  my $rowhash = shift;
  my $index = shift;
  my @tmp;
  for ( sort {$a <=> $b} keys %{$rowhash} ) {
    push @tmp, $rowhash->{$_};
  }

  while ( my ($num, $string) = each %{$index} ) {
    $index->{$string} = $num;
  }

  my $row_obj = {
		 index => $index,
		 cols  => \@tmp,
		};

  return bless $row_obj, $pkg;
}

=item columns_as_hash

Return columns in row as hash (not hashref)

=cut

sub columns_as_hash {
  my $this = shift;
  my %ret_hash;

  for ( keys %{$this->{index}} ) {
    my $num = $this->{index}->{$_};
    my $val = $this->{cols}->[$num];
    $ret_hash{$_} = $val;
  }

  return %ret_hash;
}

=item column(number or head string)

Getter.

=cut

sub column {
  my $this = shift;
  my $get = shift;

  if ($get =~ /^[0-9]+$/ ) {
    $get--;
    return $this->{cols}->[$get];
  }
  else {
    my $num = $this->{index}->{$get};

    carp "[warn] invalid header $get" unless ($num);
    return $this->{cols}->[$num] if ($num);
  }
}

1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
