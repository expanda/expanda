package SWISS::CCbpc_properties;

use vars qw($AUTOLOAD @ISA @_properties %fields);

use Carp;
use strict;
use SWISS::TextFunc;
use SWISS::BaseClass;

BEGIN {
  @ISA = ('SWISS::BaseClass');

  @_properties = (
    ['Absorption', 'Abs(max)', 'Note'],
    ['Kinetic parameters', 'KM', 'Vmax', 'Note'],
    ['pH dependence'],
    ['Redox potential'],
    ['Temperature dependence'],
  );

  %fields = map {
      $_->[0], undef
  } @_properties;
}

sub new {
  my $ref = shift;
  my $class = ref($ref) || $ref;
  my $self = new SWISS::BaseClass;
  $self->rebless($class);
  return $self;
}

sub fromText {
  my $class = shift;
  my $textRef = shift;
  my $self = new SWISS::CCbpc_properties;
  my (@events, @newEvents, %events, $topic);
  my $text = $$textRef;
  $self->initialize();
  $text =~ s/ +/ /g;

  my $properties_re = join "|", map {$_->[0]} @_properties;

  $text =~ s/\s*-!-.*?:\s*//;
  my $last_property = $_properties[0][0]; #"default" property
  while (length $text) {
    if ($text =~ s/^\s*($properties_re):\s*(.*?)\s*(;\s*|\Z)//so) {
      my ($property, $ltext) = ($1, $2);
      $last_property = $property;
      my @content;
      #grab any evidence tags
      my $ev = $ltext =~ s/\s*($SWISS::TextFunc::evidencePattern)// ? $1 : undef;
      if ($ltext =~ s/^(\S+)=// and length $ltext) {
        @content = [$1, $ltext, $ev];
      }
      elsif (length $ltext) {
        @content = [undef, $ltext, $ev];
      }
      while ($text =~ s/^(\S+)=(.*?)\s*(;\s*|\Z)//) { #take Note=, Vmax=, ...
        my ($field, $ltext) = ($1, $2);
        next unless length $ltext;
        my $ev = $ltext =~ s/\s*($SWISS::TextFunc::evidencePattern)// ? $1 : undef;
        push @content, [$field, $ltext, $ev];
      }
      $self->{$property} = \@content;
    }
    else { #dangling text 
      my ($ltext) = $text =~ s/(.*?)\s*(;\s*|\Z)//;
      my $ev = $ltext =~ s/\s*($SWISS::TextFunc::evidencePattern)// ? $1 : undef;
      push @{$self->{$last_property}}, [undef, $ltext, $ev];
    }
  }
  $self->sort;
  $self->{_dirty} = 0;
  return $self;
}

sub sort {
  my ($self) = @_;
  if ($self) {
    for my $property (@_properties) {
      my ($property_name, @fields) = @$property;
      next unless @fields;
      my $fields = join " ", " ", @fields, " ";
      if (defined (my $val = $self->{$property->[0]})) {
        @$val = sort {index($fields, $a->[0] || "") <=> index($fields, $b->[0] || "") } @$val;
      }
    }
  }
}

sub toString {
  my $self = shift;
  my $text = "-!- BIOPHYSICOCHEMICAL PROPERTIES:\n" . $self->comment;
  $text =~ s/^/CC       /mg;
  $text =~ s/    //;
  return $text;
}

sub topic {
  return "BIOPHYSICOCHEMICAL PROPERTIES";
}

sub properties {
  my ($self) = @_;
  my @list;
  for my $property (@_properties) {
    next unless defined $self->{$property->[0]};
    push @list, $property->[0];
  }
  return @list;
}

sub fields {
  my ($self, $property) = @_;
  defined $property or confess "Must pass a property";
  my @list;
  if (defined (my $val = $self->{$property})) {
    for my $item (@$val) {
      push @list, $item;
    }
  }
  return @list;
}

sub comment {
  my ($self) = @_;
  my $text = "";
  if ($self) {
    for my $property (@_properties) {
      if (defined (my $val = $self->{$property->[0]})) {
        $text .= "$property->[0]:\n";
        for my $item (@$val) {
          my ($field, $value, $ev) = @$item;
          $value .= $ev if defined $ev;
          my $field_text = defined $field ? "$field=" : "";
          my $t = "$field_text$value;";
          $text .= SWISS::TextFunc->wrapOn('  ','  ', $SWISS::TextFunc::lineLength-9, $t);
        }
      }
    }
  }
  $text;
  
}

1;

__END__

=head1 Name

SWISS::CCbpc_properties.pm

=head1 Description

B<SWISS::CCbpc_properties> represents a comment on the topic 'BIOPHYSICOCHEMICAL PROPERTIES'
within a Swiss-Prot or TrEMBL entry as specified in the user manual
http://www.expasy.org/sprot/userman.html .  Comments on other topics are stored
in other types of objects, such as SWISS::CC (see SWISS::CCs for more information).

Collectively, comments of all types are stored within a SWISS::CCs container
object.

=head1 Inherits from

SWISS::BaseClass.pm

=head1 Attributes

=over

=item topic

The topic of this comment ('BIOPHYSICOCHEMICAL PROPERTIES').

=item properties

A list of all filled properties in this comment.

=item fields($properties)

A list of fields in a given property in this comment.
Each field is a reference to an array of [$field, $text, $evidence_tags].
$field is undefined for unnamed fields.

=back
=head1 Methods

=head2 Standard methods

=over

=item new

=item fromText

=item toString

Returns a string representation of this comment.

=back
