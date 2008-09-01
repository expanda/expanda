package SWISS::DE;

use vars qw($AUTOLOAD @ISA @EXPORT_OK %fields);

use Exporter;
use Carp;
use strict;

use SWISS::TextFunc;
use SWISS::BaseClass;


BEGIN {
  @EXPORT_OK = qw();
  
  @ISA = ( 'Exporter', 'SWISS::BaseClass');
  
  %fields = (
	     text => undef
	    );
}

sub new {
  my $ref = shift;
  my $class = ref($ref) || $ref;
  my $self = new SWISS::BaseClass;
  
  $self->rebless($class);
  return $self;
}

sub fromText {
  my $self = new(shift);

  my $text = shift;

  # Parse out the evidence tags
  if ($text =~ s/($SWISS::TextFunc::evidencePattern)//) {
    my $tmp = $1;
    $self->evidenceTags($tmp);
  }

  $self->text($text);

  $self->{_dirty} = 0;
  return $self;
}

sub toText {
  my $self = shift;
  my $addParen = shift;
  
  return $addParen ? '(' . $self->text . ')' . $self->getEvidenceTagsString:
                           $self->text .       $self->getEvidenceTagsString;
}

1;

__END__

=head1 Name

SWISS::DE.pm

=head1 Description

Each DE object represents one protein name. The container object for all names of an entry is SWISS::DEs

=head1 Inherits from

SWISS::BaseClass

=head1 Attributes

=over

=item C<text>

The text of the name.

=back
=head1 Methods

=head2 Standard methods

=over

=item new

=item fromText

=item toText ($addParen)

 addParen : if set to true, the name will be surrounded by parentheses, but not
the evidence tags, e.g. : '(UMP SYNTHASE){E1}'.

=back
