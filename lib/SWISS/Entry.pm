package SWISS::Entry;

use 5.005;

use vars qw($AUTOLOAD @ISA @EXPORT_OK $VERSION %fields %objects);
use Exporter;
use Carp;
use strict;

use SWISS::TextFunc;

$VERSION='1.63';

# * Initialisation

# The objects for the different line types
my %objects = (
	       IDs => undef,
	       ACs => undef,
	       DTs => undef,
	       DEs => undef,
	       GNs => undef,
	       OSs => undef,
	       OGs => undef,
 	       OCs => undef,
 	       OXs => undef,
 	       OHs => undef,
	       Refs => undef,
	       CCs => undef,
	       DRs => undef,
	       PE => undef,
	       KWs => undef,
	       FTs => undef,
	       Stars => undef,
	       SQs => undef,
	      );	       

# All attributes
my %fields = (
	      _dirty => undef,
	      _text => undef,
	      _internalComments => undef,
	      %objects,
	     );

BEGIN {
  @EXPORT_OK = qw();
  @ISA = ( 'Exporter');
}

# * Methods

sub new {
  my $ref = shift;
  my $class = ref($ref) || $ref;
  my $self = { '_permitted' => \%fields,
	       %fields };
  
  bless $self, $class;

  $self->initialize();
  
  return $self;
}

sub initialize {
  my $self = shift;
  my $text = "\/\/\n";
  
  $self->{_text} = \$text;

  return $self;
}
  
sub AUTOLOAD {
  my $self = shift;
  my $value;
  my $type = ref($self) || carp "Ok, $self is not an object of mine!";
  my $name = $AUTOLOAD;
  
  # * Initialise
  if (@_) {
    $value = shift;
  }
  else {
    undef $value;
  }

  # get only the bit we want
  $name =~ /::DESTROY/ && return;
  $name =~ s/.*://;		

  # Verify if the demanded name is permitted
  unless (exists $self->{'_permitted'}->{$name} ) {
    confess "In type $type, can't access $name - probably passed a wrong variable into $self ";
  };

  # * If a value is passed, set it
  if (defined $value) {
    # if a subobject is set, it's dirty
    if (defined $value->{_dirty}) {
      $value->{_dirty} = 1;
    };
    $self->{_dirty} = 1;
    return $self->{$name} = $value;
  }
  else {
    # nothing is set, a value has to be returned
    if (defined $self->{$name}) {
      # The object is defined, return it
      return $self->{$name};
    }
    else {
      require 'SWISS/' . $name . '.pm';
      if (exists $objects{$name}) {
	# create and return new object
	return $self->{$name} = ('SWISS::' . $name)->fromText($self->{_text});
      }
      else {
	# return the undefined value 
	return $self->{$name};
      }
    }
  }
};

sub update {
  my $self = shift;
  my $force = shift;                  # force update
  my $lineObject; 

  # recursively check and update all existing line objects
  if ($force) {
    foreach $lineObject (grep {$self->{$_}} keys %objects) {
      $self->{$lineObject}->update($force);
      $self->{_dirty} = 1;
    };
  };

  # The entry itself
  # update interdependent lines
  if ($self->{IDs} && $self->{SQs}) {
    $self->IDs->length($self->SQs->length());
  };
  
  return 1;
}

sub fullParse {
  my $self = shift;
  my $lineObject; 
  my $tmp;
  # Parse all known objects
  foreach $lineObject (@SWISS::TextFunc::lineObjects){
    $tmp = $self->$lineObject();
  }
}

sub reformat {
  my $self = shift;
  my $force = shift;
  my $lineObject; 

  $self->fullParse;
  # recursively reformat all existing line objects
  foreach $lineObject (grep {$self->{$_}} keys %objects) {
    $self->{$lineObject}->{_dirty} = 1;
  };
  return 1;
}

sub fromText {
  my $class = shift;
  my $text = shift;
  my $fullParse = shift;
  my $removeInternalComments = shift;
  my $lineObject;

  unless ($text) {
    confess "fromText called with an empty text reference.";
  };

  my $self = new $class;
  $self->{_text} = \$text;
  
  #handle internal comments
  if ($removeInternalComments) {
    my $internalComments = SWISS::TextFunc::removeInternalComments(\$text);

    $self->{_internalComments} = $internalComments;

  }


  if ($fullParse) {
	  $self->fullParse;
  }

 
  
  return $self;
}

sub toText {
  my $self = shift;
  my $insertCommentLines = shift;
  my $lineObject;
  
  # update the object
  $self->update();
  # recursively update the text representation
  foreach $lineObject (keys %objects) {
    if (defined $self->{$lineObject}) {
      $self->$lineObject()->toText($self->{_text});
    }
  };

  #handle internal comments
  if ($insertCommentLines) {
    my $internalComments = $self->{_internalComments};
 
    if ($internalComments) {
      my @remainingComments = SWISS::TextFunc::restoreInternalComments($self->{_text}, $internalComments);
      if (@remainingComments) {
        $self->Stars->ZZ->add(@remainingComments);
        #update Stars section
        $self->Stars->toText($self->{_text});
      }
    }
  }

  
  # Now the object is clean
  $self->{_dirty}=0;
  
  return ${$self->{_text}};
}

sub toFasta {
  my $self = shift;
  my $FASTA_HEADERLEN = 255;
  my $FASTA_LINELEN = 60;
  my $result;
  
  # if there is no AC or sequence, return 0 and warn
  unless ($self->AC && $self->SQ){
    if ($main::opt_warn) {
      carp "No Fasta written for $self";
    };
    return 0;
  }
  # fasta header ">ID (AC) DE"
  $result = ">" . $self->ID . " \(" . $self->AC . "\) " . $self->DEs->text;
  if ((length $result) > $FASTA_HEADERLEN) {
    $result = substr($result, 0, $FASTA_HEADERLEN);
  };
  $result .= "\n";

  # format the sequence, $FASTA_LINELEN AAs per line
  $result .= join "\n", ($self->SQ =~ m/.{1,$FASTA_LINELEN}/g);
  $result .= "\n";
  
  return $result;
}

# If this funtion returns true for an entry, the entry should be
# processed correctly by swissknife. It does not mean that the entry
# is syntactically correct. 
sub syntaxOk {
  my $self = shift;
  my $text = '';

  $text = $self->text;
  if ($text =~ /
      \A                 # Beginning of the entry
      ((ID   .*\n)+(\*\*   .*\n)*){1}
      ((AC   .*\n)+(\*\*   .*\n)*){1}
      (DT   .*\n){3}
      (DE   .*\n)*
      (GN   .*\n)*
      (OS   .*\n)+
      (OG   .*\n)*
      (OC   .*\n)+ 
      # Complex expression for Reference blocks
      ((RN   .*\n){1}
       (RP   .*\n){1}(\*\*   .*\n)*
       (RC   .*\n)*(\*\*   .*\n)*
       (RX   .*\n)*
       (RG   .*\n)*
       (RA   .*\n)*
       (RT   .*\n)*
       (\*\*   .*NO TITLE.*\n)*
       (RL   .*\n)+)+
      (CC   .*\n)*
      # Each DR line may be followed by a ** line
      ((DR   .*\n)+(\*\*   [^\*].+\n)*)*
      (KW   .*\n)*
      (PE   .+?\n)?
      (FT   .*\n)*
      (\*\*.*\n)*
      (SQ   .*\n){1}
      (     .*\n)+
      (\/\/\n){1}        # end-of-entry marker
      \Z                 
      /x) {
    return 1;
  } 
  else {
    return 0;
  };
}

# * Data access
sub text {
  my $self = shift;
  
  return ${$self->{_text}};
}


# * Convenience methods
sub ID {
  my $self = shift;
  
  if (@_) {
    carp "Entry::ID is a short cut for reading access. To modify data please use e.g. Entry::IDs::add, Entry::IDs::set\n";
  }
  else {
    return $self->IDs->head;  
  };
}

sub AC {
  my $self = shift;
  if (@_) {
    carp "Entry::AC is a short cut for reading access. To modify data please use e.g. Entry::ACs::add, Entry::ACs::set\n";
  }
  else {
    return $self->ACs->head;
  }
}

sub SQ {
  my $self = shift;
  
  return $self->SQs->seq(@_);
}

sub EV {
  my $self = shift;
  
  return $self->Stars->EV;
}

# is it a SWISS-PROT, TREMBL or TREMBLNEW entry?
# database_code tries to find it out
sub database_code {
  my $self = shift;

  # look at the dataclass in the ID line.
  # it says STANDARD for SWISS-PROT but
  #         PRELIMINARY for TREMBL and TREMBLNEW
  # 
  # look at the release in the DT line
  # it says REL.       for SWISS-PROT
  #         TREMBLREL. for TREMBL
  #         EMBLREL.   for TREMBLNEW

  my $dataclass = $self->IDs->dataClass;
  if ($dataclass eq 'STANDARD') {
    # we have found a gold-standard ;-) protein: SWISS-PROT
    return 'S';
  } elsif ($dataclass eq 'PRELIMINARY') {
    # we have found an "avalanche of data" protein
      my $release   = $self->DTs->CREATED_rel || '';
    if ($self->AC =~ /[OPQ]\w{5}/) {
      return '3';
    }
    }
  return '?';
}

sub equal {
  my ($self, $other) = @_;
  return SWISS::BaseClass::equal($self, $other);
};

sub isFragment {
  my $self = shift;
  return $self->DEs->hasFragment || $self->FTs->get('NON_TER|NON_CONS');
}

sub isCurated {
  my $self = shift;
  return 
    (($self->text() =~ /^\s*ID.*STANDARD/)
      ||
     ($self->text() =~ /\n\*\*ZZ CURATED/))
      || 0;
}

sub isVariant {
  my $self = shift;
  return $self->AC =~ /\-/ || 0;
}

1;

__END__

=head1 Name

SWISS::Entry

=head1 Description

Main module to handle SWISS-PROT entries. One Entry object represents one SWISS-PROT entry and provides an API for its modification.  

The basic concept is the idea of lazy parsing. If an Entry object is created from the entry in flat file format, the text is simply stored in the private text attribute of the entry object. The member objects of the entry are only created if they are dereferenced. 

=head1 Example

=for html
<PRE>
use SWISS::Entry;
# Read an entire record at a time
$/ = "\/\/\n";
while (<>){
  $entry = SWISS::Entry->fromText($_);
  print $entry->AC, "\n";
}
</pre>

This minimum program reads entries from a file in SWISS-PROT format and prints the primary accession number for each of the entries.
 

=head1 Attributes

The following attributes represent member objects. They can be accessed like e.g. $entry->IDs

=over

=item IDs

ID line object

=item ACs

=item DTs

=item DEs

=item GNs

=item OSs

=item OCs

=item Refs

The reference block object

=item CCs

=item KWs

=item DRs

=item FTs

=item Stars 

Object for the annotator's section stored in the ** lines.

=item SQs

The sequence object.

=back

=head1 Methods 

=over 

=item new

Return a new Entry object 

=item initialize

Initialise an Entry object and return it.  

=item update [force]

Update an
entry. The content of the member objects is written back into the private text
attribute of the entry if necessary. If $force is true, an update of all 
member objects is forced.

=item reformat

Reformat all fields of an entry.

=item fromText $text [, $fullParse[, $removeInternalComments]]

Create an Entry object from the text $text. If $fullParse is true, the entry is
parsed at creation time. Otherwise the individual line objects are only 
created if they are dereferenced. If $removeInternalComments is true, wild comments
and indentation will be removed from the text before the parsing is done. [NOTE: 
wild comments are lines starting with a double asterisk located outside the Stars
section, and indented lines are lines starting with spaces. Both are used internally
by SWISS-PROT annotators during their work and excluded from internal and external
releases.]

=item toText [$insertInternalComments]

Return the entry in flat file text format. If internal comments and indentation
have been removed as specified in the parameters to fromText(), you may wish
to reinsert them in the text output by setting $insertInternalComments to true.

=item toFasta

Return the entry in Fasta format.

=item equal

Returns True if two entries are equal, False otherwise

=back

The following methods are provided for your convenience. They are shortcuts for methods of the individual line objects.

=over

=item ID

Returns the primary ID of the entry.

=item AC

Returns the primary AC of the entry.

=item SQ

Returns the sequence of the entry.

=item EV

Returns the EV (evidence) object of an entry. SWISS-PROT internal method.

=back

=head2 Data access methods

=over

=item text

Returns the current text of the entry. 
B<Quick and dirty!> No update of the text is performed before.

=item database_code

Is it a SWISS-PROT, TREMBL or TREMBLNEW entry?
database_code tries to find it out.
Return values are S for SWISS-PROT, 3 for TREMBL, Q for TREMBLNEW, ? for unknown.

=item isFragment

Returns true if the DE line indicates a fragment, or of the entry 
contains a NON_CONS or NON_TER feature.

=item isCurated

Returns 1 if the entry is a curated entry, 
0 otherwise.

SWISS-PROT internal use only.
