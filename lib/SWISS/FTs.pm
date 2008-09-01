package SWISS::FTs;

use vars qw($AUTOLOAD @ISA @EXPORT_OK %fields %KEYORDER);

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

#initialization code: stuff DATA into hash
{
  # Leading and trailing spaces are MANDATORY!
  local $/="\n";
  my $index=0;
  my $line;
  while (defined ($line=<DATA>)) {
    $line =~ s/\s+\z//;
    $index++;
    $KEYORDER{$_} = $index for split /\s+/, $line;
  }
  close DATA;
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
  my $self = new SWISS::FTs;
  my $line;
  my $tmp;
  my $indentation = 0;
  my ($key, $from, $to, $description);  # attributes of one feature
  
  if ($$textRef =~ /($SWISS::TextFunc::linePattern{'FT'})/m){
    foreach $line (split /\n/m, $1) {
      my $_indent = $line =~ s/^ //;
      $line = SWISS::TextFunc->cleanLine($line);
      if ($line =~ /^(\S+)\s+(\S+)\s+(\S+)\s*(.*)$/) {
        # first line of a feature
	# if there is a previous line, write it
	if ($key) {
  
	  $description = &_cleanDescription($key, $description);
	  my $ft = [$key, $from, $to, _unpack($description)];
	  push @{$self->list()}, $ft;
	  push @{$self->{indentation}}, [$ft->[0], $ft->[1], $ft->[2], $ft->[3]] if $indentation;
	  $indentation = 0;
	}
	# assign new values
	$key = $1; $from = $2; $to = $3; $description = $4;
      }
      elsif ($line =~ /^\s+(.*)$/){
	# continuation of a feature description
	$description = SWISS::TextFunc->joinWith($description, 
						 ' ', 
						 '(?<! )[-/]', 'and ',
						 $1);
      }
      else {
	if ($main::opt_warn) {
	  carp "FT line $line parse error.";
	}
      }
      $indentation += $_indent;
    }

    # write last FT line
    
    if ($key) { 
      $description = &_cleanDescription($key, $description);
      my $ft = [$key, $from, $to, _unpack($description)];
      push @{$self->list()}, $ft;
      push @{$self->{indentation}}, [$ft->[0], $ft->[1], $ft->[2], $ft->[3]] if $indentation;
    };
  }
  else {
    $self->initialize;
  }
  
  $self->{_dirty} = 0;

  return $self;
}

sub toText {
  my $self = shift;
  my $textRef = shift;
  my $newText = '';

  if ($#{$self->list()}>-1) {
    $newText = join('', map {$self->_FTtoText($_, @{$_})} @{$self->list()});
  };
  
  $self->{_dirty} = 0;

  return SWISS::TextFunc->insertLineGroup($textRef, $newText, $SWISS::TextFunc::linePattern{'FT'});
}  

sub _unpack {
 my $text = shift;
 my ($evid, $ftid, $evidenceTags) = ('','','{}');

 return ('','','','{}') unless $text;

 if ($text =~ s/(\/FTId=\S+)$//){
   $ftid = $1;
   $ftid =~ s/\.$//;
   $text =~ s/[\n\;\.\s]+$//sg;
   
 }

 # Parse out the evidence tags
 if ($text =~ s/($SWISS::TextFunc::evidencePattern)//) {
   $evidenceTags = $1;
 }

 # Get the old-style Swiss-Prot evidence
 if ($text =~ s/ \((BY SIMILARITY|POTENTIAL|PROBABLE)\)$//i){
   $evid = $1;
 }
 elsif (grep {$_ eq uc $text} ('BY SIMILARITY', 'POTENTIAL', 'PROBABLE')) {
   $evid = $text;
   $text = "";
 }
 
 $text =~ s/[\n\;\.\s]+$//sg;
 
 return ($text, $evid, $ftid, $evidenceTags);
}

# remove wrongly inserted ' ' in description 
# of CONFLICT, VARIANT, VAR_SEQ and VARSPLIC

sub _cleanDescription {
  my ($key, $description) = @_;
  # parts of the description of CONFLICT, VARIANT, VAR_SEQ and VARSPLIC
  my ($sequence, $ref); 
  
  # Remove trailing dots and spaces
  $description =~ s/[\s\.]+$//;
  
  if (($key eq 'CONFLICT')
      ||
      ($key eq 'VARIANT')
      ||
      ($key eq 'VAR_SEQ')
      ||
      ($key eq 'VARSPLIC')) {
    # The * is allowed as part of the description for cases like
    # AC Q50855: AVWKA -> R*SVP
    
    if ($description !~ /^Missing/) {
    
      if (($sequence, $ref) = $description =~ /([A-Z \-\>\*]+)(.*)/) {
        $sequence =~ s/(?<! OR) (?!OR )//gm;
        $sequence =~ s/\-\>/ \-\> /;
        $sequence .= ' ';
        $description = $sequence . $ref;
      }
    }
  }

  if ($key eq 'MUTAGEN') {
    if ($description !~ /^Missing/) {
      if (($sequence, $ref) = $description =~ /([A-Z \-\>\*,]+)(.*)/) {
        $sequence =~ tr/ //d;
        $description = $sequence . $ref;
      }
    }
  }

  return $description;
}


sub _FTtoText {
  my ($self, $ft, $key, $from, $to, $description, $evidence, $ftid,
      $evidenceTags) = @_;
  my ($prefix, $text);

  $text = '';
  $prefix = sprintf("FT   %-8s  %5s  %5s       ", 
		    $key, $from, $to);
  if ($evidence) {
    if (length $description){
      $description = "$description ($evidence)";
    } else {
      $description = $evidence;
    }
  }

  # add the evidence tags
  if ($evidenceTags &&
      ($evidenceTags ne '{}')) {
    $description .= $evidenceTags;
  }

  if (length $description ) {
    $text = $description;
    # Add a dot at the end if the description does not consist only of 
    # evidence tags.
    unless ($description =~ /\A$SWISS::TextFunc::evidencePattern\Z/) {
      $text .= '.';
    }
  } else {
    # Text must not be empty, otherwise the wrapping will return ''
    $text .= ' ';
  }

  # Complex rules for the formatting of FT VARIANT, FT CONFLICT, FT VARSPLIC
  # according to softuse.txt, SFT006
  if ($prefix =~  /CONFLICT|VARIANT|VAR_SEQ|VARSPLIC/) {
    $text = SWISS::TextFunc->wrapOn($prefix, 
        "FT                                ", 
        $SWISS::TextFunc::lineLength, $text,
        ['(?!\>)\s*', '\(', "/|$SWISS::TextFunc::textWrapPattern1", '[^\s\-/]'], 
        "/|$SWISS::TextFunc::textWrapPattern2"
        );
  } else {
    $text = SWISS::TextFunc->wrapOn($prefix, 
        "FT                                ", 
        $SWISS::TextFunc::lineLength, $text, $SWISS::TextFunc::textWrapPattern1,
        "/|$SWISS::TextFunc::textWrapPattern2"
        );
  };
  
  # add a /FTId line if necessary
  if (length $ftid){
    $text .= "FT                                $ftid.\n";
  }
 
  # reinsert indentation
  if ($self->{indentation}) {
    for my $indented (@{$self->{indentation}}) {
      next unless $ft->[0] eq $indented->[0]
        and $ft->[1] eq $indented->[1]
        and $ft->[2] eq $indented->[2]
        and $ft->[3] eq $indented->[3];
      $text =~ s/^/ /mg;
      last;
    }
  }
  return $text;
}

#sorting based on annotation rule ANN027,
#and additional instructions from Amos.
#FTs should be sorted based on :
#-the priority index, or
#-the starting position (lesser goes first), or
#-the ending position (longer goes first), or
#-the FT comment as a last resort.
sub sort {
	my $self = shift;

	my $self_list = $self->list;

	my @indices = sort {
		my $item1 = ${$self_list}[$a];
		my $item2 = ${$self_list}[$b];
		my $sv =
			#sort by virtual key
			($KEYORDER{$item1->[0]} || 0) <=> ($KEYORDER{$item2->[0]} || 0) ||
			#or by start position
			_numericPosition($item1->[1], $item1->[2]) <=> _numericPosition($item2->[1], $item2->[2]) ||
			#or by end position (reversed)
			_numericPosition($item2->[2], $item2->[1]) <=> _numericPosition($item1->[2], $item1->[1]);
			#for FT VARSPLIC and VAR_SEQ:
			#as a penultimate resort, alphabetically on what follows the parenthesis
			#in the FTcomment
			if (!$sv and $item1->[0] =~ /^VARSPLIC|VAR_SEQ$/
					and my ($t1) = $item1->[3] =~ /\((.*)/
					and my ($t2) = $item2->[3] =~ /\((.*)/
					) {
				$sv = lc($t1) cmp lc($t2) || $t1 cmp $t2;
			}
			#for FT CONFLICT+VARIANT:
			#as a penultimate resort, alphabetically on FTcomment
			#(except "Missing" that should go at the end)
			unless ($sv) {
				if (grep {$_ eq $item1->[0]} ("CONFLICT", "VARIANT")) {
					if ($item1->[3] =~ /^Missing/i) {
						unless ($item2->[3] =~ /^Missing/i) {
							$sv = 1;
						}
					}
					else {
						if ($item2->[3] =~ /^Missing/i) {
							$sv = -1;
						}
					}
				}
			}
			#as a last resort, alphabetically on FTcomment (e.g. variants)
			$sv || lc($item1->[3]) cmp lc($item2->[3]) || $item1->[3] cmp $item2->[3]
		} 0..$#$self_list;
	my @newlist;
	for (@indices) {
		push @newlist, ${$self_list}[$_];
	}
	$self->list(\@newlist);
}

# For a given feature position, return the numeric position.
# This converts "fuzzy" positions for sorting purpose, according to the rule:
# 11 => 11
# >14 => 14.1
# <1 => 0.9
# ?31 => 31
# if a position is only "?", the other position should be passed as a second
# argument, to be used as a backup. For example, if a feature is
# FT   CHAIN         ?    103       Potential.
# the position 103 should be considered the best-guess start position for sorting.
sub _numericPosition {
	for my $string (@_) {
		return $1+0.1 if $string =~ />(\d+)/;
		return $1-0.1 if $string =~ /<(\d+)/;
		return $1 if $string =~ /(\d+)/;
	}
	return 0;
}

1;

=head1 Name

SWISS::FTs

=head1 Description

B<SWISS::FTs> represents the FT (feature) lines within an SWISS-PROT + TrEMBL
entry as specified in the user manual
http://www.expasy.org/sprot/userman.html .

=head1 Inherits from

SWISS::ListBase.pm

=head1 Attributes

=over

=item C<list>

An array of arrays. Each element is an array containing: a feature key, from 
position, to position, description, qualifier, FTId and an evidence tag. Example:
['CHAIN', 25, 126, 'Alpha chain', 'By similarity', '/FTId=PRO_0000023008', '{EC1}']

=back

=head1 Methods

=head2 Standard methods

=over

=item new

=item fromText

=item toText

=item sort

=back

=cut

__DATA__
INIT_MET SIGNAL PROPEP TRANSIT CHAIN PEPTIDE
TOPO_DOM TRANSMEM
DOMAIN REPEAT
CA_BIND ZN_FING DNA_BIND NP_BIND
REGION
COILED
MOTIF
COMPBIAS
ACT_SITE
METAL
BINDING
SITE
SE_CYS
MOD_RES
LIPID
CARBOHYD
DISULFID 
CROSSLNK
VARSPLIC VAR_SEQ
VARIANT
MUTAGEN
UNSURE
CONFLICT
NON_CONS
NON_TER
HELIX TURN STRAND
