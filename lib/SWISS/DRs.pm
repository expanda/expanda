package SWISS::DRs;

use vars qw($AUTOLOAD @ISA @EXPORT_OK %fields %DBsortField $DBorder);

use Exporter;
use Carp;
use strict;
use Data::Dumper;

use SWISS::TextFunc;
use SWISS::ListBase;


BEGIN {
  @EXPORT_OK = qw();
  @ISA       = qw(Exporter SWISS::ListBase);
  %fields    = qw( );
}

#initialization code: load dr_ord into hash
{
  # Leading and trailing spaces are MANDATORY!
  $DBorder = ' ';
  for my $path (@INC) {
    my $file = $path . '/SWISS/dr_ord';
    if (-r $file) {
      local $/ = "\n";
      open my $in, '<', $file 
        or carp "Can't load cross reference sort order from $file: $!";
      while (<$in>) {
        next if /^#/;
        s/\s+\z//;
        my ($db, $sort_field) = split /\s+/, $_;
        $DBorder .= uc($db) . ' ';
        $DBsortField{uc $db} = $sort_field;
      }
      last;
    }
  }
}

sub new {
  my $ref = shift;
  my $class = ref($ref) || $ref;
  my $self = new SWISS::ListBase;
  
  $self->rebless($class);
  return $self;
}

sub fromText {
  my $self = shift;
  my $textRef = shift;
  my (@lines,$line);
  my @tokens;
  my $tag;

  $self = new SWISS::DRs;

  if ($$textRef =~ /($SWISS::TextFunc::linePattern{'DR'})/m){
    @lines = split /\n/m, $1;
    while ($line = shift @lines) {
      
      # set flag if it's a ** line
      if ($line=~ /\A ?\*\*/ ) {
	$tag = '_HIDDEN_'
      } else {
	$tag = '';
      }

      my $indentation = $line =~ s/^ //;
      $line = SWISS::TextFunc->cleanLine($line);
      
      # Parse for evidence tags
      my $evidence =  '';
      if (($evidence) = $line =~ /($SWISS::TextFunc::evidencePattern)/m) {
	my $quotedEvidence = quotemeta $evidence;
	$line =~ s/$quotedEvidence//m;
      }

      @tokens = SWISS::TextFunc->listFromText($line, ';\s+', '\.');
      if ($tag eq '_HIDDEN_') {
	unshift @tokens, $tag;	
      }

      my $drline = $evidence ? [@tokens, $evidence] : [@tokens];
      push @{$self->list()}, $drline;
      # store DR lines which are indented
      push @{$self->{indentation}}, [@$drline] if $indentation;
    }
  };
  $self->{_dirty} = 0;
  return $self;
}

sub toText {
  my $self = shift;
  my $textRef = shift;
  my $newText = '';
  my ($dr,@comments);

  # only reformat if the object is dirty
  unless ($self->{_dirty}) {
    return;
  }

  # Sort first
  $self->update();

  foreach $dr ($self->elements) {

    my $tag;
    if (@$dr[0] eq '_HIDDEN_') {
      $tag = '**'
    } else {
      $tag = 'DR'
    }

    # reinsert indentation
    my $indent = "";
    if ($self->{indentation}) {
      INDENTED: for my $indented (@{$self->{indentation}}) {
        next unless @$dr == @$indented;
        for (my $i=0; $i<@$dr; $i++) {
          next INDENTED unless $dr->[$i] eq $indented->[$i];
        }
        $indent = " ";
        last;
      }
    }

    $newText .= ($indent . $tag . "   " . (join "; ", 
				 grep {!/_HIDDEN_/ && !/$SWISS::TextFunc::evidencePattern/} @$dr) . '.');
    
    # add evidence tags
    $newText .= $self->getEvidenceTagsString($dr);

    # add line break
    $newText .= "\n";
  }
  
  $self->{_dirty} = 0;
  return SWISS::TextFunc->insertLineGroup($textRef, $newText, $SWISS::TextFunc::linePattern{'DR'});
}  

# EMBL DR lines must never be sorted. The sort order stems from EMBL
# join statements and merges between entries. It is not possible to
# recreate the order automatically.
# MIM and HAMAP DR lines should not be sorted as they are presented
# in SWISS-PROT with an internal logic.
sub sort {
  my $self = shift;
  my @dbnames = ();
  my @sortedDRs = ();

  # get all DB names, ...
  @dbnames = map {$_->[0] eq '_HIDDEN_' ? $_->[1] : $_->[0]} $self->elements();
  # ... sort into a unique ... 
  @dbnames = SWISS::TextFunc->uniqueList(@dbnames);
  # .. and ordered list.
  @dbnames = sort {&_dbIndex($a) <=> &_dbIndex($b)} @dbnames;

  foreach my $db (@dbnames) {
    # hidden DRs (starting with **) should always be after the corresponding
    # block of visible DR lines
    my (@hiddenDR, @visibleDR);
    for my $dr (@{$self->list}) {
      if ($dr->[0] eq '_HIDDEN_') {
        push @hiddenDR, $dr if $dr->[1] eq $db;
      }
      else {
        push @visibleDR, $dr if $dr->[0] eq $db;
      }
    }
    my $sort_field = $DBsortField{uc $db};
    $sort_field = 1 unless defined $sort_field;
    # Some DR lines must never be sorted
    if ($sort_field == 0) {
      push @sortedDRs, @visibleDR, @hiddenDR;
    } elsif ($sort_field == 2) {
      # Some DR lines are sorted by ID within one database.
      # (if the ID is identical, sort by AC)
      for my $ty ([\@visibleDR, 1], [\@hiddenDR, 2]) {
        my ($drtype, $field_number) = @$ty;
        push @sortedDRs, sort {
          lc @{$a}[$field_number+1] cmp lc @{$b}[$field_number+1]
          || @{$a}[$field_number+1] cmp @{$b}[$field_number+1]
          || lc @{$a}[$field_number] cmp lc @{$b}[$field_number]
          || @{$a}[$field_number] cmp @{$b}[$field_number]
        } @$drtype;
      }
    } else {
      # The rest is sorted on AC
      for my $ty ([\@visibleDR, 1], [\@hiddenDR, 2]) {
        my ($drtype, $field_number) = @$ty;
        push @sortedDRs, sort {
          lc @{$a}[$field_number] cmp lc @{$b}[$field_number]
          || @{$a}[$field_number] cmp @{$b}[$field_number]
        } @$drtype;
      }
    }    
  }

  $self->list(\@sortedDRs);
  return 1;
}

sub update {
  my $self = shift;
  
  $self->sort(1);
  return 1;
}

# The EMBL protein identifiers introduced in 1999 are of the form
# xxxxx.yy, e.g. CAA33128.1
# If $dropVersion is set, the version number (.yy) will be dropped from
# each PID.
sub pids {
  my $self = shift;
  my $dropVersion = shift;
  my @pids;

  # read command backwards:
  # get all EMBL DR line arrays, 
  # get element 2 of each array (the pid), 
  # drop it if it's a '-' from NOT_ANNOTATED_CDS
  
  @pids = grep {!/-/} map {$$_[2]} $self->get('EMBL');

  if ($dropVersion) {
    map {s/\.\d+$//} @pids;
  };
  
  return SWISS::TextFunc->uniqueList(@pids);
}

sub emblacs {
  my $self = shift;
  my @emblacs;

  # read command backwards:
  # get all EMBL DR line arrays, 
  # get element 1 of each array (the primary accession number), 
  
  @emblacs =  map {$$_[1]} $self->get('EMBL');
  
  return SWISS::TextFunc->uniqueList(@emblacs);
}

# * Private methods/functions

sub _dbIndex {
  my $dbname = uc shift;
  my $index;

  $index = index $DBorder, ' ' . $dbname . ' ';
  if ($main::opt_warn) {
    if ($index == -1) {
      carp "Database name $dbname not found.";
    } 
  }

  # unknown databases should be at the end, not at the beginning
  if ($index == -1) {
    $index = length $DBorder;
  }
  
  return $index;
}

# * Filter functions

# true if the first element of a DR line (the DB name) matches $dbTargetName
# false otherwise
sub dbName{
  my ($dbTargetName) = @_;
  
  return sub {
    my $ref = shift;
    my $dbSourceName = @{$ref}[0];

    return ($dbSourceName =~ /^$dbTargetName$/);
  }  
}

# false if the first element of a DR line (the DB name) matches $dbTargetName
# true otherwise
sub notDbName{
  my ($dbTargetName) = @_;
  
  return sub {
    my $ref = shift;
    my $dbSourceName = @{$ref}[0];

    return ($dbSourceName !~ /^$dbTargetName$/);
  }  
}


sub deleteUnlessEvidenceCategories {
  my ($self, $evidenceCategories, @patterns) = @_;

  my @result;
  my ($i, $pat, $element);
 
  # do nothing if the list is empty
  unless ($self->size() > 0) {
    return $self->elements();
  };

  # If first list element is an array
  if (ref @{$self->list()}[0] eq 'ARRAY') {
  ELEMENT: foreach $element (@{$self->list()}) {
      # if $element has an evidence tag with a category in
      # $evidenceCategories, don't delete it
      my $evidenceTagPosition = SWISS::ListBase::evidenceTagPosition($element);
      
      if ((defined $$element[$evidenceTagPosition])
	  &&
	  ($$element[$evidenceTagPosition] =~ /E[$evidenceCategories]/)) {
	CORE::push(@result, $element);
	next ELEMENT;
      };

      # do the actual deletion if pattern matches
      for ($i=0; $i <= $#patterns; $i++) {
	if ($patterns[$i]  && ($$element[$i] !~ /^$patterns[$i]$/)){
	  CORE::push(@result, $element);
	  next ELEMENT;
	}
      }
    };
    return $self->set(@result);
  } else {
    # An undefined data type
    carp "deleteUnlessEvidenceCategory is currently not implemented for elements of type " . ref @{$self->list}[0];
    return undef;
  }
}

1;

__END__

=head1 Name

SWISS::DRs

=head1 Description

B<SWISS::DRs> represents the DR (database crossreference) lines within an SWISS-PROT + TrEMBL
entry as specified in the user manual
http://www.expasy.org/sprot/userman.html .

=head1 Inherits from

SWISS::ListBase.pm

=head1 Attributes

=over

=item C<list>

An array of arrays. Each element is an array (Database_identifier, primary_key, secondary_key[,further elements]).

=back

=head1 Methods

=head2 Standard methods

=over

=item new

=item fromText

=item toText

=item sort

=back

=head2 Reading methods

=over

=item emblacs

Returns a list of all EMBL accession numbers. These are the primary keys of EMBL crossreferences.

=item pids [$dropVersion]

Returns a list of all PIDs. These are the secondary keys of EMBL crossreferences.

B<ATTENTION:> 
The EMBL protein identifiers introduced in 1999 are of the form
xxxxx.yy, e.g. CAA33128.1
If $dropVersion is set, the version number (.yy) will be dropped from
each PID.

Example: 

If the EMBL DR line is

DR   EMBL; L37685; AAC41668.1; -.

pids(1) will only return AAC41668, NOT AAC41668.1

=back

=head2 Writing methods

=over

=item deleteUnlessEvidenceCategories $evidenceCategories, @patterns

Like del, but deletes an item only if the item has no evidence tags, or if the evidence tags are not in one of the categories given in $evidenceCategories. 

Example:

$entry->DRs->deleteUnlessEvidenceCategories('CA', 'FlyBase')

will only delete Flybase DR lines which do not have the evidence category 'A' or 'C'.   

=back

=head2 Filter functions

=over

=item dbName($dbTargetName)

True if the first element of a DR line (the DB name) matches $dbTargetName.
$dbTargetName has to match in full, not only a partial match. 

=item notDbName($dbTargetName)

True if the first element of a DR line (the DB name) does NOT macht $dbTargetName.

=back

=head2 ** lines (SWISS-PROT internal format)

Each DR line may be followed by a ** line like

 **   DR   PROSITE; PS12345; XXX_PAT; FALSE_POS_1

 These will be stored internally as DR lines with the DB identifier 
 '_HIDDEN_'. Therefore adding a ** PROSITE line is done as:

 $entry->DRs->add(['_HIDDEN_', 'PS12345', 'XXX_PAT', 'FALSE_POS_1']);
