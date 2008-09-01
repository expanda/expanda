package SWISS::CCinteraction;

use vars qw($AUTOLOAD @ISA);

use Carp;
use strict;
use SWISS::TextFunc;
use SWISS::ListBase;

BEGIN {
  @ISA = ('SWISS::ListBase');
}

sub new {
  my $ref = shift;
  my $class = ref($ref) || $ref;
  my $self = new SWISS::ListBase;
  $self->rebless($class);
  return $self;
}

sub fromText {
  my $class = shift;
  my $textRef = shift;
  my $self = new SWISS::CCinteraction;
  my $text = $$textRef;
  $self->initialize();
  $text =~ s/ +/ /g;

  $text =~ s/\s*-!-.*?:\s*//;
  while (length $text) {
    if ($text =~ s/^\s*(([\w\-]+):(.+?)( \(xeno\))?|Self)\s*(;\s*|\Z)//so) {
      my ($t, $ac, $identifier, $xeno) = ($1, $2, $3, $4);
      my %arg;
      $arg{'accession'} = $t eq 'Self' ? $t : $ac;
      $arg{'identifier'} = $identifier if defined $identifier;
      $arg{'xeno'} = $xeno if defined $xeno;
      while ($text =~ s/^(NbExp|IntAct)=(.*?)\s*(;\s*|\Z)//) { #take Note=, Vmax=, ...
        my ($field, $ltext) = ($1, $2);
        if ($field eq 'IntAct') {
          $arg{$field} = [split /, */, $ltext];
        }
        else {
          $arg{$field} = $ltext;
        }
      }
      $self->push(\%arg);
    }
    else { #dangling text 
      carp "CC INTERACTION parse error, ignoring $text";
      last;
    }
  }
  $self->sort;
  $self->{_dirty} = 0;
  return $self;
}

sub sort {
  my ($self) = @_;
  if ($self) {
    my (@self, @nogene, @rest);
    for my $t ($self->elements) {
      if ($t->{accession} eq 'Self') {push @self, $t}
      elsif (not defined $t->{identifier}) {push @nogene, $t}
      else {push @rest, $t}
    }
    $self->set (
      @self,
      (sort {lc $a->{accession} cmp lc $b->{accession}} @nogene),
      (sort {
        lc $a->{identifier} cmp lc $b->{identifier}
        || $a->{identifier} cmp $b->{identifier}
        || lc $a->{accession} cmp lc $b->{accession}
        || $a->{accession} cmp $b->{accession}
      } @rest)
    );
  }
}

sub toString {
  my $self = shift;
  my $text = "-!- INTERACTION:\n" . $self->comment;
  $text =~ s/^/CC       /mg;
  $text =~ s/    //;
  return $text;
}

sub topic {
  return "INTERACTION";
}

sub comment {
  my ($self) = @_;
  my $text = "";
  if ($self) {
    for my $el ($self->elements) {
      $text .= $el->{accession};
      $text .= ":" . $el->{identifier} if defined $el->{identifier};
      $text .= $el->{xeno} if defined $el->{xeno};
      $text .= ";";
      $text .= " NbExp=" . $el->{NbExp} . ";" if defined $el->{NbExp};
      $text .= " IntAct=" . join (", ", @{$el->{IntAct}}) . ";" if defined $el->{IntAct};
      $text .= "\n";
    }
  }
  $text;
  
}

1;

__END__

=head1 Name

SWISS::CCinteraction

=head1 Description

B<SWISS::CCinteraction> represents a comment on the topic 'INTERACTION'
within a Swiss-Prot or TrEMBL entry as specified in the user manual
http://www.expasy.org/sprot/userman.html .  Comments on other topics are stored
in other types of objects, such as SWISS::CC (see SWISS::CCs for more information).

Collectively, comments of all types are stored within a SWISS::CCs container
object.

Each element of the list is a hash with the following keys:

  accession
  identifier
  xeno
  NbExp
  IntAct      (array reference)

=head1 Inherits from

SWISS::ListBase.pm

=head1 Methods

=head2 Standard methods

=over

=item new

=item fromText

=item toString

Returns a string representation of this comment.

=back
