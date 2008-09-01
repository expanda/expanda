package SWISS::DEs;

use vars qw($AUTOLOAD @ISA @EXPORT_OK %fields);

use Exporter;
use Carp;
use strict;

use SWISS::TextFunc;
use SWISS::ListBase;
use SWISS::DE;

BEGIN {
  @EXPORT_OK = qw();
  
  @ISA = ( 'Exporter', 'SWISS::ListBase');
  
  %fields = ('text' => undef,
             'hasFragment' => undef,
             'version' => undef,
             'Contains' => undef,
             'Includes' => undef,
            );
}

sub new {
  my $ref = shift;
  my $class = ref($ref) || $ref;
  my $self = new SWISS::ListBase;
  
  $self->rebless($class);
  $self->Contains (new SWISS::ListBase);
  $self->Includes (new SWISS::ListBase);
  return $self;
}

sub fromText {
  my $class = shift;
  my $textRef = shift;
  my $self = new SWISS::DEs;

  my $line = '';
  my $evidence = '';
  
  if ($$textRef =~ /($SWISS::TextFunc::linePattern{'DE'})/m) {
    $line = $1;
    $self->{indentation} = $line =~ s/^ //mg;
    $line = SWISS::TextFunc->joinWith('', ' ', '(?<! )-', 'and ',
                                      map {SWISS::TextFunc->cleanLine($_)}
                                          (split "\n", $line));

    # Drop trailing spaces and dots
    $line =~ s/[\. ]*$//;
  };

  # Parse for evidence tags
  if (($evidence) = $line =~ /($SWISS::TextFunc::evidencePattern)/m) {
    $line =~ s/$evidence//m;
    $self->evidenceTags($evidence);
  }

  $self->{text} = $line;
  $self->advancedParse();
  $self->{_dirty} = 0;
  
  return $self;
}

sub fromString {
  my $class = shift;
  my $string = shift;
  my $self = new SWISS::DEs;
  $self->{text} = $string;
  $self->advancedParse;
  $self->{_dirty} = 0;
  return $self;
} 

sub text {
  my $self = shift;
  my $text = shift;
  if ($text) {
    $self->{_dirty} = 1;
    $self->{text} = $text;
    $self->advancedParse;
  }
  else {
    $text = $self->toString();
  }
  return $text;
}

sub advancedParse {
  my $self = shift;
  my $t = $self->{text};     
  $self->initialize;
  my($hasFragment, $version);
                                                              
  #1)version
  if ($t =~ s/\s*\((Version \S+)\)//i) {
    $version = $1;
  }
  $self->version($version);
   
  #2)fragment                                                              
  if ($t =~ s/\s*\((Fragments?)\)//i) {
    $hasFragment = $1;
  }
  $self->hasFragment($hasFragment);
   
  #3)children
  $self->Contains->set();
  $self->Includes->set();

  #protect internal [] by converting to {- -}
  1 while $t =~  s/(\[[^\[\]]*)\[(.*?)\]/$1\{-$2-\}/;
  #parse Contains/Includes
  while ($t =~ s/\s*\[((?:Contains)|(?:Includes)):\s*(.*?)\]//i) {  
    my $type = lc $1 eq "contains" ? $self->Contains : $self->Includes;
    $type->push(map {s/\{-/[/g; s/-\}/]/g; SWISS::DEs->fromString($_)} split /;\s*/, $2);
  }
  # convert protected brackets back to original form
  $t =~ s/\{-/[/g; $t =~ s/-\}/]/g;

  #4)list
  $self->initialize;
  #protect internal () by converting to {- -}
  1 while $t =~  s/(\([^\(\)]*)\((.*?)\)/$1\{-$2-\}/;
  #must reverse before parsing to match successively all exprs between ()
  $t = reverse $t;
  my $ev = $SWISS::TextFunc::evidencePatternReversed;
  while ($t =~  s/^($ev)?\)(.*?)\(\s+//) {
    my $a = $3; #$2 is set by the evidence pattern
    $a = $1.$a if $1; #evidence tag
    $a =~ s/-\{/\(/g;
    $a =~ s/\}-/\)/g;
    $self->unshift(SWISS::DE->fromText(scalar reverse $a));
  }
  # convert protected brackets back to original form, 
  # then add remaining text
  $t =~ s/-\{/\(/g;
  $t =~ s/\}-/\)/g;
  $self->unshift(SWISS::DE->fromText(scalar reverse $t));
}

sub toString {
  my $self = shift;
  my $newText = '';
  
  if ($self->size > 0) {
    my $i;
    $newText = join(' ', $self->head->toText, map {$_->toText(1)} $self->tail);
  }
  for my $p (["Includes", $self->Includes], ["Contains", $self->Contains]) {
    my ($type, $obj) = @$p;
    next unless $obj->size;
    $newText .= ' ' if $newText;
    my $text = join '; ', grep {$_} map {$_->toString} $obj->elements;
    $newText .= "[$type: $text]";
  }
  for ($self->hasFragment, $self->version) {
    next unless $_;
    $newText .= ' ' if $newText;
    $newText .= '(' . $_ . ')';
  }
  return $newText;
}

sub toText {
  my $self = shift;
  my $textRef = shift;

  unless ($self->{_dirty}) {
    return;
  }

  my $newText = $self->toString . $self->getEvidenceTagsString;
  $newText .= "." if $newText;
  my $prefix = "DE   ";
  my $col = $SWISS::TextFunc::lineLength;
  $col++, $prefix=" $prefix" if $self->{indentation};
  $newText = SWISS::TextFunc->wrapOn($prefix, $prefix, $col, $newText);
  $self->{_dirty} = 0;
  return SWISS::TextFunc->insertLineGroup($textRef, $newText, 
                                          $SWISS::TextFunc::linePattern{'DE'});
};

sub sort {
  return 1;
}

#methods acting on evidence tag can be applied either to the entire DE line
#(pass a string) or to each element (passing an ARRAY reference).

sub addEvidenceTag { return ref $_[1] eq 'ARRAY' ? 
	 SWISS::ListBase::addEvidenceTag (@_) :
	SWISS::BaseClass::addEvidenceTag (@_)
}
sub deleteEvidenceTags { return ref $_[1] eq 'ARRAY' ? 
	 SWISS::ListBase::deleteEvidenceTags  (@_) :
	SWISS::BaseClass::deleteEvidenceTags  (@_)
}
sub getEvidenceTags { return ref $_[1] eq 'ARRAY' ? 
	 SWISS::ListBase::getEvidenceTags  (@_) :
	SWISS::BaseClass::getEvidenceTags  (@_)
}
sub getEvidenceTagsString { return ref $_[1] eq 'ARRAY' ? 
	 SWISS::ListBase::getEvidenceTagsString  (@_) :
	SWISS::BaseClass::getEvidenceTagsString  (@_)
}
sub hasEvidenceTag { return ref $_[1] eq 'ARRAY' ? 
	 SWISS::ListBase::hasEvidenceTag  (@_) :
	SWISS::BaseClass::hasEvidenceTag  (@_)
}
sub setEvidenceTags { return ref $_[1] eq 'ARRAY' ? 
	 SWISS::ListBase::setEvidenceTags  (@_) :
	SWISS::BaseClass::setEvidenceTags  (@_)
}

1;

__END__

=head1 Name

SWISS::DEs.pm

=head1 Description

B<SWISS::DEs> represents the DE lines of a SWISS-PROT + TREMBL
entry as specified in the user manual
http://www.expasy.org/sprot/userman.html .

For TrEMBL entries, only the C<text> attribute is safe, since the
syntax of the DE line is not constrained. For SWISS-PROT entries,
the C<list>, C<hasFragment>, C<Includes> and C<Contains> attributes 
work as follows :

 DE   CAD protein (Rudimentary protein) [Includes: Glutamine-dependent
 DE   carbamoyl-phosphate synthase (EC 6.3.5.5); Aspartate
 DE   carbamoyltransferase (EC 2.1.3.2)] (Fragment).


 -= Entry::DEs =-
 elements : "CAD protein", "Rudimentary protein"
 hasFragment : "Fragment"
 Includes : ListBase of (child1, child2)
 Contains : empty ListBase

 -= child1 =-    
 elements : "Glutamine-dependent carbamoyl-phosphate synthase", "EC 6.3.5.5"
 hasFragment : undef

 -= child2 =-    
 elements : "Aspartate carbamoyltransferase", "EC 2.1.3.2"
 hasFragment : undef

=head1 Inherits from

SWISS::ListBase.pm

=head1 Attributes

=over

=item C<text>

The text of the DE line.

=item C<list>

The SWISS::DE objects containing the different synonyms for the entry. The first element of the list is the preferred formal name.

=item C<Includes>

=item C<Contains>

Each of these is a SWISS::ListBase object whose list contains a
SWISS::DEs object for each 'child' of the protein (i.e. peptide or functional
domain). See the SWISS-PROT user manual for an explanation. It is possible
to have both Includes and Contains in a single entry:

 DE   Arginine biosynthesis bifunctional protein argJ [Includes:
 DE   Glutamate N-acetyltransferase (EC 2.3.1.35) (Ornithine
 DE   acetyltransferase) (Ornithine transacetylase) (OATASE);
 DE   Amino-acid acetyltransferase (EC 2.3.1.1)
 DE   (N-acetylglutamate synthase) (AGS)] [Contains: Arginine
 DE   biosynthesis bifunctional protein alpha chain; Arginine
 DE   biosynthesis bifunctional protein beta chain].

=item C<hasFragment>

Contains 'Fragment' or 'Fragments' (evaluates to true) if the DE lines contain the 
(Fragment(s)) indication, otherwise evaluates to false. Compare to the more robust 
Entry::isFragment which also checks the FT lines for a NON_CONS or NON_TER.


=item C<version>

If the DE lines contain a version identifier, it is stored here, e.g. for
"DE   NUCLEOCAPSID PROTEIN (VERSION 1).", version will contain "VERSION 1".

=back

=head1 Methods

=head2 Standard methods

=over

=item new

=item fromText

=item toText

=back

=head1 Evidence Tags

Since the DE line doesn't have a fixed syntax in TrEMBL, it is impossible to
reliably assign evidence tags separately to the different elements of the DE lines.
Therefore, the DE line can only be evidence tagged as a whole, and the following
methods have their prototype defined in SWISS::BaseClass instead of the direct
parent of SWISS::DEs, SWISS::ListBase :

 addEvidenceTag
 deleteEvidenceTags
 getEvidenceTags
 getEvidenceTagsString
 hasEvidenceTag
 setEvidenceTags

example :

 $evidenceTag = $entry->Stars->EV->addEvidence('P', 'DEfix', '-', 'v1.3');
 $entry -> DEs -> addEvidenceTag($evidenceTag);
