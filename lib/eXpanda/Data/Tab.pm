package eXpanda::Data::Tab;

use strict;
use warnings;
use Carp;

use eXpanda::Data::Tab::Row;

sub new {
  my $pkg = shift;
  my $file = shift;
  my $args = {
	      header => 0,
	      comment => '#',
	      @_
	     };
  my $obj = {};
  my $comment = '\\'.$$args{comment};
  open my $fh, "$file" or croak "[fatal] Cannot open file $file";

  while (<$fh>) {
    chomp;
    if ( m/^$comment/o && $. == 1 ) {
      my @column = split('\t', $_);
      for ( my $i = 0; $i <= $#column; $i++  ) {
	$obj->{column_names}->{$i} = $column[$i];
      }
    }
    else {
      my @column = split('\t', $_);
      for ( my $i = 0; $i <= $#column; $i++ ) {
	$obj->{row}->{$.}->{$i} = $column[$i];
      }
    }
  }
  close $fh;

  return bless $obj, $pkg;
}

sub rows {
  my $this = shift;
  my @ret_array;

  for my $row ( sort {$a <=> $b} keys %{$this->{row}} ) {
    my $rowobj = eXpanda::Data::Tab::Row->new($this->{row}->{$row}, $this->{column_names});
    push @ret_array, $rowobj;
  }

  return @ret_array;
}

1;
