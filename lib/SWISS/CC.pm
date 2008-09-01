package SWISS::CC;

use vars qw($AUTOLOAD @ISA @EXPORT_OK %fields);

use Exporter;
use Carp;
use strict;

use SWISS::BaseClass;
use SWISS::TextFunc;


BEGIN {
  @EXPORT_OK = qw();
  
  @ISA = ( 'Exporter', 'SWISS::BaseClass');
  
  %fields = (
	     topic => undef,
       comment => undef
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
  
  my $class = shift;
  my $textRef = shift;
  my $self = new SWISS::CC;
  my $text = $$textRef;
  my ($topic, $comment, $evidence);
  
  if ($text ne '') {
  
    # split into topic and comment.
    if ($text =~ /\-\!\-\s+(.*?):\s*(.*)$/x ){
	    $topic = $1; $comment = $2;
    } else {
	    $topic = ''; 
      $comment = $text;
    }

    # Parse for evidence tags
  
    if (($evidence) = $comment =~ /($SWISS::TextFunc::evidencePattern)/m) {
	    my $quotedEvidence = quotemeta $evidence;
	    $comment =~ s/$quotedEvidence//m;
    }

    $self->{topic} = $topic;
    $self->{comment} = $comment;
    $self->evidenceTags($evidence);
  }
  else {
    $self->initialize;
  };
  $self->{_dirty} = 0;
  
  return $self;
}

sub toString {
  
  my $self = shift;   
  my $topic = $self -> {topic}; 
  my $comment = $self -> {comment}; 
  my $evidence = $self -> evidenceTags;
  my $text = "CC   -!- ";

  if ($topic) {
    $text = $text . $topic . ": ";
  };

  if ($comment) {
    $text = $text . $comment;
  };
  
  if ($evidence &&
      ($evidence ne '{}')) {
    $text = $text . $evidence;
  }

  $text .= '.';
  
  # specific fix for dealing with the format of 1 special CC section
  
  # note in general text wraping in comments is not guuaranteed to be read-safe 
  # by SWISSKNIFE
  
  # this specific fix keeps waraping correct for 1 strcutred CC lin
  
  # a better alternative would be to implment this section as a new class
  
  if (defined($topic) and $topic =~ /^DATABASE|WEB RESOURCE$/) {
  
    my @texts = split /; /, $text;
    my $size = scalar @texts;
    my $newText = "";
    my $currentLength = 0;
	my $lineLength = $SWISS::TextFunc::lineLength - 8;

    
    for (my $i = 0; $i < $size; $i++) {
    
      $texts[$i] .= ';' if $i<$size-1;
      if ($texts[$i] !~ /\S{$lineLength}/) {
        $text = SWISS::TextFunc->wrapOn('',
                                        "CC       ",
                                        $SWISS::TextFunc::lineLength,
                                        $texts[$i]
                        );
      }
      else {
        $text = $texts[$i] . "\n";
      }
      
      # extra manipulation
      
      my $potentialLength = $currentLength + (length $text) - 1;
      
      if (($currentLength != 0) && ($potentialLength < $SWISS::TextFunc::lineLength + 1)) {
        
        $newText =~  s/\n$/ /;
        $newText = $newText . $text;
        $currentLength = $currentLength + (length $text);
        
      } else {
      
        if ($i != 0) {
          
          $text = "CC       " . $text;
          $currentLength = length $text;
          
        } else {
        
          $currentLength = (length $text) - 1;
        }  
          
        $newText = $newText . $text;
           
      }
     
    }
    
    return $newText;
    
  } else {
  
    $text = SWISS::TextFunc->wrapOn('',"CC       ", $SWISS::TextFunc::lineLength, $text);
    return $text;
  }            
}

sub topic {

  my ($self,$value) = @_;
    
  if (defined $value) {
        
    $self->{'topic'} = $value;
  }
    
  return $self->{'topic'};
}

sub comment {

  my ($self,$value) = @_;
    
  if (defined $value) {
        
    $self->{'comment'} = $value;
  }
    
  return $self->{'comment'};
}

1;

__END__

=head1 Name

SWISS::CC.pm

=head1 Description

B<SWISS::CC> represents a comment on a single topic within a SWISS-PROT or TrEMBL
entry as specified in the user manual
http://www.expasy.org/sprot/userman.html .  Each comment is stored in a
separate object, either of the type SWISS::CC or of another type,
depending on its topic (see SWISS::CCs for more information).
   
Collectively, comments of all types are stored within a SWISS::CCs container
object.

=head1 Inherits from

SWISS::BaseClass.pm

=head1 Attributes

=over

=item topic

The topic of this comment.

=item comment

The text of this comment.

=back

=head1 Methods

=head2 Standard methods

=over

=item new

=item fromText

=item toString

Returns a string representation of this comment.

=back
