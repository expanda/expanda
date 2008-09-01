package SWISS::Stars::EV;

use vars qw($AUTOLOAD @ISA @EXPORT_OK %fields);

use Exporter;
use Carp;
use strict;

use SWISS::TextFunc;
use SWISS::ListBase;


BEGIN {
  @EXPORT_OK = qw();
  
  @ISA = ( 'Exporter', 'SWISS::ListBase');
  
  %fields = (
	    );

}

=head2 new

=cut
sub new {
  my $ref = shift;
  my $class = ref($ref) || $ref;
  my $self = new SWISS::ListBase;
  
  $self->rebless($class);
  return $self;
}
 
=head2 fromText

=cut
sub fromText {
  my $self = new(shift);
  my $textRef = shift;
  my ($block, $line);

  # The tag for the EV section is 'EV'
  if ($$textRef =~ /((\*\*EV .*\n)+)/m) {
    $block = $1;

    # delete trailing dots and spaces
    $block =~ s/[\.\s]+\n/\n/gm;

    # unwrap multi-line evidence tags
    $block =~ s/\n\*\*EV\s{5}/ /gm;

    # now every comment is in a single line
    foreach $line (split /\n/, $block){
      $line = SWISS::TextFunc->cleanLine($line);

      push (@{$self->list()}, [split(/\;\s*/, $line)]);
    };
  };

  # we have only read, so the object is still clean
  $self->{_dirty} = 0;

  return $self;
}

=head2 toText

=cut
sub toText {
  my $self = shift;
  my ($textRef) = @_;
  my $newText = '';
  my $tag = 'EV';

  # remove old lines
  $$textRef =~ s/^(\*\*$tag .*\n)//gm;

  $self->sort();

  # assemble new lines  
  map ({$newText .= SWISS::TextFunc->wrapOn("\*\*$tag ", 
					    "\*\*$tag     ",
					    $SWISS::TextFunc::lineLengthStar,
					    $_ . '.',
					    '; ', ',\s*')} 
       (map {join("; ", @$_)} $self->elements)
      );

  # insert new text
  SWISS::Stars::insertLineGroup($self, $textRef, $newText, $tag);

  # now the object is clean
  $self->{_dirty} = 0;

  return 1;
}

=head2 sort

=cut
sub sort {
  my $self = shift;
  my ($x, $y, $u, $v);

  @{$self->list} = sort {($u, $x) = @$a[0] =~ /(E[ACIP])(\d+)/;
			 ($v, $y) = @$b[0] =~ /(E[ACIP])(\d+)/;
			 $u cmp $v
			   or
			 $x <=> $y;} $self->elements;
  $self->{_dirty} = 1;

  return 1;
};

=head2 addEvidence($category, $type, $initials, $attributes [, $date])

 Title:    addEvidence

 Usage:    $evidenceTag = $entry->Stars->EV->addEvidence($category,
                                                         $type, 
                                                         $initials,
                                                         $attributes 
                                                         [, $date])

 Function: adds the evidence to the EV block if it does not yet exist 
           or returns the correct evidence tag if the evidence already exists, 
           possibly with a different date.

 Args:    $category: the evidence category. Currently one of 'A', 'C', 'I','P'.
          $type: the evidence type
          $initials: The initals of the person doing the update.
                     For programs this should be '-'.
          $attributes: the attributes of the evidence
          $date: optional. If present, it must be in standard SWISS-PROT 
                 date format. If not present the current date will be used.

 Returns: The correct evidence tag.

=cut

sub addEvidence{
  my $self=shift;
  my ($category, $type, $initials, $attributes, $date) = @_;
  
  # set $date
  unless ($date) {
    $date = SWISS::TextFunc::currentSpDate;      
  }
  
  return $self->_addEvidence($category, $type, $initials, $attributes, $date); 
}

=head2 updateEvidence($category, $type, $initials, $attributes [, $date])

 Title:    updateEvidence

 Usage:    $evidenceTag = $entry->Stars->EV->updateEvidence($category, 
                                                            $type, 
							    $initials,
                                                            $attributes 
                                                            [, $date])

 Function: updates the evidence to the EV block to $date or inserts it 
           if it does not yet exist.

 Args:    $category: the evidence category. Currently one of 'A', 'C', 'I','P'.
          $type: the evidence type
          $initials: The initals of the person doing the update.
                     For programs this should be '-'.
          $attributes: the attributes of the evidence
          $date: optional. If present, it must be in standard SWISS-PROT 
                 date format. If not present the current date will be used.

 Returns: The correct evidence tag.


=cut

sub updateEvidence{
  my $self=shift;
  my ($category, $type, $initials, $attributes, $date) = @_;
  
  # set $date
  unless ($date) {
    $date = SWISS::TextFunc::currentSpDate;      
  }
  
  return $self->_addEvidence($category, $type, $initials, $attributes, $date, 1); 
}

# if $update is set, the evidence date will be updated if the entry already
# exists.
sub _addEvidence{
  my $self = shift;
  my ($category, $type, $initials, $attributes, $date, $update) = @_;
  my $evidenceTag = '';
   
  # check the category
  unless ($category =~ /^[ACIP]$/){
    croak("Wrong evidence category \'$category\'\n");
  }

  # set $date
  unless ($date) {
    $date = SWISS::TextFunc::currentSpDate;      
  }
  
  # if there is no other evidence in the entry, the tag is E1.
  if ($self->size == 0) {
    $evidenceTag = 'E' . $category . '1';      
  } else {
    
    # get the next available evidence tag
    my $currentTagNumber = 0;
    my $lastTagNumber = 0;
    map {($currentTagNumber) = @$_[0] =~ /\AE[ACIP](\d+)/; 
	 $lastTagNumber = max($lastTagNumber, $currentTagNumber)} $self->elements();
    
    $evidenceTag = 'E' . $category . ($lastTagNumber + 1);      
  }
  
  my $existingEvidence = $self->getObject(['.*', $type, $initials, $attributes]);
  
  # No evidence, insert new evidence
  if ($existingEvidence->size == 0) {
    $self->add([$evidenceTag, $type, $initials, $attributes, $date]);
    return $evidenceTag;      
  }
  
  if ($existingEvidence->size > 1) {
    $main::opt_warn && carp("More than one piece of evidence for $type, $initials, $attributes. Using lowest numbered evidence tag.\n");
  }

  # if $update is set, update the date of the evidence
  if ($update) {
    @{$existingEvidence->head()}[4] = $date;    
  }
  
  $self->{_dirty} = 1;

  return @{$existingEvidence->head()}[0];
}

sub max {
  my ($a, $b) = @_;
  if ($a > $b) {
    return $a;
  } else {
    return $b;
  }
}

1;				# says use was ok

=head1 Name

SWISS::Stars::EV.pm

=head1 Description

B<SWISS/Stars/EV.pm> represents the evidence section within an SWISS-PROT + TrEMBL entry. See http://www3.ebi.ac.uk/~sp/intern/projects/evidenceTags/index.html

For a usage example, see evTest.pl in the Swissknife package.

=head1 Inherits from
SWISS::ListBase.pm

=head1 Attributes

=over

=item C<list>
Each element of the list describes one evidence, itself represented as an array.

=back
