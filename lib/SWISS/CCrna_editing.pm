package SWISS::CCrna_editing;

use vars qw($AUTOLOAD @ISA %fields);

use Carp;
use strict;
use SWISS::TextFunc;
use SWISS::ListBase;

BEGIN {
  @ISA = ('SWISS::ListBase');
  
  %fields = (
	      term => undef,
	      note => undef,
	    );
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
  my $self = new SWISS::CCrna_editing;
  my $text = $$textRef;
  $self->initialize();
  if ($text =~ /\bModified_positions=(.*?)(;|\.|$)/) {
    for my $pos (split ", *", $1) {
      my $ev = $pos =~ s/($SWISS::TextFunc::evidencePattern)// ? $1 : undef;
      if ($pos =~ /^[A-Za-z]/) {
        $self->{term} = $pos;
      }
      else {
        $self->add([$pos, $ev]);
      }
    }
  }
  $self->{note} = $1 if $text =~ /\bNote=(.*)/;
  $self->{_dirty} = 0;
  return $self;
}

sub toString {
  my $self = shift;
  my $text = "CC   -!- RNA EDITING: " . $self->comment . ".";
  return SWISS::TextFunc->wrapOn('',"CC       ", $SWISS::TextFunc::lineLength, $text);
}

sub topic {
  return "RNA EDITING";
}

sub comment {
  my ($self) = @_;
  my $text = "Modified_positions=";
  if ($self->size) {
    $text .= join ", ", map {
      my ($pos, $ev) = @$_;
      $pos .= $ev if defined $ev;
      $pos;
    } @{$self->{list}};
  }
  else {
    $text .= $self->{term} || "Undetermined";
  }
  if (defined $self->{note} and length $self->{note}) {
    $text .= "; Note=" . $self->{note};
  }
  $text;
  
}

1;

__END__

=head1 Name

SWISS::CCrna_editing

=head1 Description

B<SWISS::CCrna_editing> represents a comment on the topic 'RNA EDITING'
within a Swiss-Prot or TrEMBL entry as specified in the user manual
http://www.expasy.org/sprot/userman.html .  Comments on other topics are stored
in other types of objects, such as SWISS::CC (see SWISS::CCs for more information).

Collectively, comments of all types are stored within a SWISS::CCs container
object.

=head1 Inherits from

SWISS::ListBase.pm

=head1 Attributes

=over

=item topic

The topic of this comment ('RNA EDITING').

=item note

The Note of this comment, if any.

=item term

A string such as "Undetermined" or "Not_applicable", if any.

=item elements

An array of [position, evidence_tags], if any.

=back
=head1 Methods

=head2 Standard methods

=over

=item new

=item fromText

=item toString

Returns a string representation of this comment.

=back
