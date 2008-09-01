package SWISS::CCalt_prod;

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
	      events => undef
	    );
}

# hash to describe order of events lines

my %order;
$order{"Alternative promoter usage"} = 1;
$order{"Alternative splicing"} = 2;
$order{"Alternative initiation"} = 3;

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
  my $self = new SWISS::CCalt_prod;
  my (@events, @newEvents, %events, $topic, $comment, $commentTag);
  my $text = $$textRef;
  ($topic, @events) = ($text =~ /(.+?)(Event=.+?)(?=(Event=.*|$))/gm);
 
  for my $event (@events) { 
  
    if ($event  ne "") {
    
      push @newEvents, $event;
    }
  }
  
  my %eventHash;
  
  # want to be able to read old format data (i.e pre release 8.0)
  
  for my $event (@newEvents) {
  
    my ($eventType, $typeOnly, $comment, $namedForms, $rest, $isoformCount);
    my (@namedForms, @formsList);
    $event = $event . ";" if $event !~ /;\s*$/;
    ($eventType, $rest) = ($event =~ /(Event=.+?;)(.*)/m);
    ($comment, $namedForms) = ($rest =~ /(.*?)(Name=.*)/);
    
    if (! defined $comment) {
    
      $comment = $rest;
    }
    
    # tidy up
    
    $eventType =~ s/Event=//;
    $eventType =~ s/;$//;
    
    # original model had isoforms stored under one of potentially several 
    # Event lines
    # new model (UniProt 8.0) has only one Event key per entry (though this may 
    # describe many events)
    
    # this change has been accomodated in Swissknife with the specific 
    # intention of maintaining the API, which is event-centric
   
    # i.e. all isoforms are stored under each event that features in the
    # event line of the entry
    
    # note that the API itself could be improved/extended to better fit the
    # new data model
    
    # one hash to store all isoform data
    
    if ($comment ne "") {
    
      $comment =~ s/.+?Named isoforms=\d+;\s*//;
    
    } else {
    
      $comment = $rest;
      $comment =~ s/^\s*//;
    } 
    
    $comment =~ s/Comment=//;
    $comment =~ s/\s\s+/ /g;
    $comment =~ s/;\s*$//;
    $comment =~ s/^\s*//;
    
    # look for tags
    # if parsing old format entries, aggregate comments from all Event blocks
    
    if (my ($realComment, $commentTags) = ($comment =~ /(.+?)\{(.+?)\}$/)) {
    
      my @commentTags = split /,/, $commentTags;
      
      if (defined $eventHash{"Comment"}) {
      
        $eventHash{"Comment"} = $eventHash{"Comment"} . $realComment;
      
      } else {
      
        $eventHash{"Comment"} = $realComment;
      }
      
      if (defined $eventHash{$commentTags}) {
      
        my @newTags = @{$eventHash{"CommentTags"}};
        push @newTags, \@commentTags;
        $eventHash{"CommentTags"} = \@newTags;
      }
    
    } elsif ($comment) {
    
      $eventHash{"Comment"} .= $comment;
    }
     
    if (defined $namedForms) {
    
      # under both new and old formats, there will only be a maximum of one 
      # Event line with named forms attached
    
      $namedForms =~ s/Named isoforms\=\d+;\s*//;
      @namedForms = split /;\s+(?=Name)/, $namedForms;
     
      for my $namedForm (@namedForms) {
    
        my %thisFormHash;
        $namedForm = $namedForm . ";";
        
        my (@fields) = ($namedForm =~
/(Name\=.+?;)\s+(Synonyms\=.+?;)*\s*(IsoId\=.+?;)\s+(Sequence\=.+?;)\s*(Note\=.+?;)*/);
  
        if (! defined $fields[0]) {
        
           die "Incorrect syntax.  Can't parse entry at " . $namedForm . "\n";
        }
        
        FIELD: for my $field (@fields) {
      
         if (defined $field) {
      
            my ($key, $value);
          
            ($key, $value) = ($field =~ /(.+?)=(.*?);/);
            $value =~ s/ \s+/ /g;
        
            if ($value eq "") {
            
              next FIELD;
            }
        
            # isoform count is made dynamically, no need to store it
        
            if ($key ne 'Named isoforms') {
        
              if ($key eq "Synonyms") {
          
                # complex data item, possibly with synonyms attached to each 
                # element
        
                my (@values) = split /,\s+/, $value;
                my @realValues;
            
                foreach $value (@values) {
            
                  if (my ($realData, $tags) = ($value =~ /(.+?)\{(.+?)\}$/)) {
              
                    push @realValues, $realData;
                    my (@tagValues) = split /,\s+/, $tags;
                    ${$thisFormHash{"SynonymsTags"}}{$realData} = \@tagValues;
                
                  } else {
              
                    push @realValues, $value;
                  }
                }
            
                $thisFormHash{$key} = \@realValues;
          
              } elsif ($key eq "IsoId" || $key eq "Sequence") {
          
                # complex data item, no synonyms
            
                my (@values) = split /,\s+/, $value;
                $thisFormHash{$key} = \@values;
          
              } elsif (my ($realData, $tags) = ($value =~ /(.+?)\{(.+?)\}$/)) {
        
                # simple data item, with tags
            
                $thisFormHash{$key} = $realData;
                my @tags = split /,/, $tags;
                my $tagKey = $key . "Tags";
                $thisFormHash{$tagKey} = \@tags;      
            
              } elsif ($key =~ /\w/) {  
          
                # simple data item, no tags
          
                $thisFormHash{$key} = $value; 
              }
            }
          }
        }
      
        push @formsList, \%thisFormHash; 
      }
    
      $eventHash{"FormsList"} = \@formsList;
    }
  
    my @derivedEvents = split /, /, $eventType;
    
    for my $thisEvent (@derivedEvents) {
    
      # in the data model, the same event hash is keyed by each individual 
      # event that references it
      
      $events{$thisEvent} = \%eventHash;
    }
    
    # this field is just a value that can be used to access the event hash,
    # when we are not interested in filtering by event
    
    if (! defined $self->{keyEvent}) {
    
      $self->{keyEvent} = $derivedEvents[0];
    }
  }
  
  $self->{events} = \%events;
  $self->{_dirty} = 0;
  return $self;
}

sub toString {

  my $self = shift;
  my $text = "CC   -!- ALTERNATIVE PRODUCTS:\n";
  my @keys = keys %{$self->{'events'}};
  my @sortedKeys = sort _byEvent @keys;
  my $eventText = "";
  
  # reconstitute full Event header
  
  for my $event (@sortedKeys) {
    
    if ($eventText eq "") {
    
      $eventText = $event;
     
    } else {
    
      $eventText = $eventText . ", " . $event;
    }
  }  

  if ($eventText !~ /;$/) {
    
    $eventText = $eventText . ";";
  }
    
  # all the events key the same form hash, so we merely need one of these to
  # access the hash
  
  my $event = $self->{'keyEvent'}; 
  my $commentText = ${${$self->{'events'}}{$event}}{"Comment"} || '';
	$commentText =~ s/\s+$//;
  my $evTags = $self -> getEvidenceTagsString($event, "Comment");
    
  if (defined $evTags) {
    $commentText = $commentText . $evTags;
  }
    
  if ($commentText !~ /\;$/) {
    $commentText = $commentText . ";";
  }
    
  my $headerText;
    
  if ($eventText !~ /^Event=/) {
    
    $headerText = "Event=" . $eventText;
    
  } else {
    
    $headerText = $eventText;
  }
    
  # named isoform count only for certain events
    
  my $count = $self -> getNamedFormCount($event);
  $headerText = $headerText . " Named isoforms=" . $count . ";";
  $text = $text .  "CC       " . $headerText . "\n";
  
  
  #$text = $text . SWISS::TextFunc->
  #          wrapOn("CC       ", 
  #                 "CC       ", 
  #                 $SWISS::TextFunc::lineLength, $headerText , '\s+'); 
    
  if ($commentText ne ';') {
    
    $headerText = "Comment=" . $commentText;
    $text = $text . SWISS::TextFunc->
            wrapOn("CC         ", 
                   "CC         ", 
                   $SWISS::TextFunc::lineLength, $headerText , '\s+'); 
  }
   
  my $allFormsText; 
    
  if (${${${${$self->{'events'}}{$event}}{"FormsList"}}[0]}{"Name"}) {
    
    # forms list is not sorted, may contain blank elements in among the real
    # elements!
    
    FORM: for my $namedForm (@{${${$self->{'events'}}{$event}}{"FormsList"}}) {
     
      # quick fix until we find the real bug
     
      if (! defined $$namedForm{"IsoId"}) {
        
        die "Named isoforms incorrectly defined"; 
      }
        
      ## form details
        
      # name, synonyms
        
      my $formText;
        
      if ($namedForm !~ /;$/) {
        
        $formText = $formText . ";";
      }
        
      $formText = "Name=" . $$namedForm{"Name"};
      my $evTags = $self -> getEvidenceTagsString($event, 
                                                  "Name", 
                                                  $$namedForm{"Name"});
                                                    
      if (defined $evTags) {                                            
        
        $formText = $formText . $evTags;
      }
        
      $formText = $formText . "; ";
        
      my $synonymText = "";
      $synonymText = $self -> _printList("Synonyms",
                                         $$namedForm{"Synonyms"}, 
                                         $$namedForm{"Name"});
        
      if (defined $synonymText) {
          
        $formText = $formText . $synonymText;
      }
                                
      $formText = SWISS::TextFunc->
                      wrapOn("CC       ", 
                             "CC       ", 
                             $SWISS::TextFunc::lineLength, $formText , 
                             '\s+');
      
      $allFormsText = $allFormsText . $formText;
      my $nb_isoid = scalar @{$$namedForm{"IsoId"}};
      my $header_width = $nb_isoid > 1 ? 20 : 36;
      my $id_width = 10;
      my $separator_width = 2; 
      
      my $ids_per_line = int (($SWISS::TextFunc::lineLength - $header_width - 
                              $id_width ) / ( $id_width + $separator_width ) +
                              1);

      # isoform ID, sequence
       
      if ($nb_isoid == 1) {
        
        if (scalar @{$$namedForm{"Sequence"}} < $ids_per_line+1) {
          
        # regular case, everything in one line
          
          $formText = $self -> _printList("IsoId", $$namedForm{"IsoId"}) .
                      $self -> _printList("Sequence", $$namedForm{"Sequence"});
          
          $formText = SWISS::TextFunc -> 
              wrapOn("CC         ", 
                     "CC         ", 
                     $SWISS::TextFunc::lineLength, 
                     $formText, 
                     '\s+');
          $allFormsText = $allFormsText  . $formText; 
          
        } else {
          
          # need to split up VSPs across several lines, and format them
          # accordingly
          
          my $wrapperText = "CC";
          
          for (my $i = 0; 
               $i < scalar @{$$namedForm{"Sequence"}}; 
               $i = $i + $ids_per_line) {
            
            my @tempList;
              
            for (my $j = $i; $j < ($i + $ids_per_line); $j++) {
              
              if (defined $$namedForm{"Sequence"}[$j]) {
                
                push @tempList, $$namedForm{"Sequence"}[$j] 
              }
            }
              
            if ($i == 0) {
                
              # first line
                
              $formText = $self ->  _printList("IsoId", $$namedForm{"IsoId"}) .
                          $self -> _printList("Sequence", \@tempList);
              
              $formText = SWISS::TextFunc -> 
                 wrapOn("CC         ", 
                        "CC         ", 
                        $SWISS::TextFunc::lineLength, 
                        $formText, 
                        '\s+');
                
              $formText =~ s/;$/,/;
              $allFormsText = $allFormsText  . $formText; 
              my ($initialText) = ($formText =~ /(.*Sequence=)/);
              my $offset = (length $initialText) - 2;
                
              for (my $j = 0; $j < $offset; $j ++) {
                
                $wrapperText = $wrapperText . " ";
              }
              
            } else {
              
              $formText = join ', ', @tempList;
              # end in ',' if more lines are coming
              my $term = $i < scalar @{$$namedForm{"Sequence"}} - $ids_per_line ? ',' : ';';
              $formText = $formText . $term; 
              
              $formText = SWISS::TextFunc -> 
                wrapOn($wrapperText, 
                $wrapperText, 
                $SWISS::TextFunc::lineLength, 
                $formText, 
                '\s+');
              
              $allFormsText = $allFormsText  . $formText; 
            }
          }
        }
          
      } else {
        
        # ISO IDs and Sequence in separate lines
          
        if (scalar @{$$namedForm{"Sequence"}} < 5) {
          
            
          $formText = $self -> _printList("IsoId", $$namedForm{"IsoId"});
          
          $formText = SWISS::TextFunc -> 
              wrapOn("CC         ", 
                     "CC         ", 
                     $SWISS::TextFunc::lineLength, 
                     $formText, 
                     '\s+');
          
          $allFormsText = $allFormsText  . $formText;
          
          $formText = $self -> _printList("Sequence", 
                                          $$namedForm{"Sequence"});
          
          $formText = SWISS::TextFunc -> 
              wrapOn("CC         ", 
                     "CC         ", 
                     $SWISS::TextFunc::lineLength, 
                     $formText, 
                     '\s+');
                     
          $allFormsText = $allFormsText  . $formText; 
          
        } else {
          
          # ISO IDs in separate lines from sequence, AND sequences spread over
          # several lines
            
          $formText = $self -> _printList("IsoId", $$namedForm{"IsoId"});
          
          $formText = SWISS::TextFunc -> 
              wrapOn("CC         ", 
                     "CC         ", 
                     $SWISS::TextFunc::lineLength, 
                     $formText, 
                     '\s+');
          
          $allFormsText = $allFormsText  . $formText;
            
          # in this case, we can fit in 4 VSPs per line
            
          for (my $i = 0; $i < scalar @{$$namedForm{"Sequence"}}; $i = $i + $ids_per_line) {
            
            my @tempList;
              
            for (my $j = $i; $j < ($i + $ids_per_line); $j++) {
                
              if (defined $$namedForm{"Sequence"}[$j]) {
                
                push @tempList, ${$$namedForm{"Sequence"}}[$j] 
              }
            }
              
            if ($i == 0) {
                
              $formText = $self -> _printList("Sequence", \@tempList);
              $formText = SWISS::TextFunc -> 
               wrapOn("CC         ", 
                      "CC         ", 
                      $SWISS::TextFunc::lineLength, 
                      $formText, 
                      '\s+');
                      
              $formText =~ s/;$/,/;
              $allFormsText = $allFormsText  . $formText; 
              
            } else {
              
              $formText = join ', ', @tempList;
              # end in ',' if more lines are coming
              my $term = $i < scalar @{$$namedForm{"Sequence"}} - 
                         $ids_per_line ? ',' : ';';
              $formText = $formText . $term; 
              
              $formText = SWISS::TextFunc -> 
                  wrapOn("CC                  ", 
                         "CC                  ", 
                         $SWISS::TextFunc::lineLength, 
                         $formText, 
                         '\s+');
                
              $allFormsText = $allFormsText  . $formText; 
              
            }  
          }
        }
      }
        
      # note
        
      $formText = "";
        
      if (defined $$namedForm{"Note"}) {
          
        $formText = "Note=" . 
                    $$namedForm{"Note"};
        my $evTags = $self -> getEvidenceTagsString($event, 
                                                    "Note", 
                                                    $$namedForm{"Name"}); 
          
        if (defined $evTags) {
          
          $formText =  $formText . $evTags;
        }       
          
        if ($formText !~ /\;$/) {
        
          $formText = $formText . ";";
        }
      }
        
      $formText = SWISS::TextFunc->
          wrapOn("CC         ", 
                 "CC         ", 
                 $SWISS::TextFunc::lineLength, 
                 $formText , 
                 '\s+');
                 
      $allFormsText = $allFormsText . $formText;
    }
  } 
    
  if (defined $allFormsText) {
    
    $text = $text . $allFormsText;
  }
  
  return $text;
}

sub _printList {

  # prepare fields that take a list of values

  my ($self, $keyText, $values, $name) = @_;
  my $count = 0;
  $keyText = $keyText . "=";
    
  for my $value (@$values) {
        
    if ($count != 0) {
         
      $keyText = $keyText . ", ";
    }
         
    $count ++;
    $keyText = $keyText . $value; 
    
    # slightly ugly, misplaced fix, to fetch evidence tags (Synonyms only)
    
    if (defined $name) {
    
      my $evTags = $self -> getEvidenceTagsString($self->{keyEvent},
                                                  "Synonyms",
                                                  $name,
                                                  $value);
    
      if (defined $evTags) {
      
        $keyText = $keyText . $evTags;
      }
    }
  }
  
  if ($count != 0) {
  
    return $keyText . "; ";
    
  } else {
  
    return;
  }   
}

sub _byEvent {

  $order{$a} <=> $order{$b}
}

sub topic {

  return "ALTERNATIVE PRODUCTS";
}

sub keyEvent {

  my ($self) = @_;
  return $self -> {'keyEvent'};
}

sub comment {
  my ($self) = @_;
  my $str = $self->toString;
  $str =~ s/.*\n//;
  $str =~ s/^CC       //mg;
  $str;
}

sub setEvents {

  my ($self, $eventHash) = @_;
  $self -> {'events'} = $eventHash;
}

# conveneience read/write methods

sub addEvent {

  # note that behaviour changes with UniProt relase 8.0
  # adding a new event now points this event at all existing isoforms

  my ($self, $eventName) = @_;
  ${$self -> {'events'}}{$eventName} = 
    ${$self -> {'events'}}{$self -> {keyEvent}};
}

sub addForm {

  my ($self, $eventName, $name, $synonyms, $isoIds, $featIds, $note) = @_;
  
  if (defined ${$self -> {'events'}}{$eventName}) {
  
    my %newForm;
    $newForm{"Name"} = $name;
    $newForm{"Synonyms"} = $synonyms;
    $newForm{"IsoId"} = $isoIds;
    $newForm{"Sequence"} = $featIds;
    $newForm{"Note"} = $note;
    push @{${${$self -> {'events'}}{$eventName}}{"FormsList"}}, \%newForm;
  }
}

sub getComment {

  my ($self, $eventName, $comment) = @_;
  
  if (defined ${$self -> {'events'}}{$eventName}) {
  
    return ${${$self -> {'events'}}{$eventName}}{"Comment"};
  }
  return undef;
}

sub getEventNames {

  my ($self) = @_;
  return sort _byEvent keys %{$self -> {'events'}};
}

sub getFormNames {

  my ($self, $event) = @_;
  my @formNames;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
      push @formNames, $$form{"Name"};
    }
  }
   
  return @formNames;
}

sub getSynonyms {

  my ($self, $event, $formName) = @_;
  
  for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
    if ($$form{"Name"} eq $formName) {
    
      if (defined $$form{"Synonyms"}) {
        return @{$$form{"Synonyms"}};
      }
    }
  }
  return ();
} 

sub getIsoIds {

  my ($self, $event, $formName) = @_;
  
  for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
    if ($$form{"Name"} eq $formName) {
    
      if (defined $$form{"IsoId"}) {
        return @{$$form{"IsoId"}};
      }
    }
  }
  return ();
}

sub getFeatIds {
  
  my ($self, $event, $formName) = @_;
  
  for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
    if ($$form{"Name"} eq $formName) {
    
      if (defined $$form{"Sequence"}) {
        return @{$$form{"Sequence"}};
      }
    }
  }
  return ();
} 

sub getNote {

  my ($self, $event, $formName) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
      if ($$form{"Name"} eq $formName) {
    
        if (defined $$form{"Note"}) {
      
          return $$form{"Note"};
        }
      }
    }
  }
  return undef;
}

sub getNamedFormCount {

  my ($self, $event) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    if (defined 
         ${${${${$self -> {'events'}}{$event}}{"FormsList"}}[0]}{"Name"}) {
  
      return scalar @{${${$self -> {'events'}}{$event}}{"FormsList"}};
  
    } else {
  
      return 0;
    }
  }
  return undef;
}

sub deleteEvent {

  my ($self, $event) = @_;
  return delete ${$self -> {'events'}}{$event};
}

sub deleteComment {
  
  my ($self, $event, $comment) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    return delete ${${$self -> {'events'}}{$event}}{"Comment"};
  }
  return undef;
}

sub deleteForm {

  my ($self, $event, $formName) = @_;

  if (defined ${$self -> {'events'}}{$event}) {

    my $position = 0;

    for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
      if ($$form{"Name"} eq $formName) {
    
        my @ret = splice (@{${${$self -> {'events'}}{$event}}{"FormsList"}}, $position, 1);
      
        if (scalar @{${${$self -> {'events'}}{$event}}{"FormsList"}} == 0) {
      
          delete ${${$self -> {'events'}}{$event}}{"FormsList"};
        }
      
        return @ret;
      }
    
      $position++;
    }
  }
  return undef;
}

sub setComment {

  my ($self, $eventName, $comment) = @_;
  
  if (defined ${$self -> {'events'}}{$eventName}) {
  
    ${${$self -> {'events'}}{$eventName}}{"Comment"} = $comment;
  }
}

sub setFormName {

  my ($self, $event, $oldName, $newName) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
      if ($$form{"Name"} eq $oldName) {
  
        $$form{"Name"} = $newName;
        return;
      }
    }
  }
}

sub setSynonyms {

  my ($self, $event, $name, $synonyms) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
      if ($$form{"Name"} eq $name) {
  
        $$form{"Synonyms"} = $synonyms;
        return;
      }
    }
  }
}

sub setIsoIds {

  my ($self, $event, $name, $isoIds) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
      if ($$form{"Name"} eq $name) {
  
        $$form{"IsoId"} = $isoIds;
        return;
      }
    }
  }
}

sub setFeatIds {

  my ($self, $event, $name, $featIds) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
      if ($$form{"Name"} eq $name) {
  
        $$form{"Sequence"} = $featIds;
        return;
      }
    }
  }
}

sub setNote {

  my ($self, $event, $name, $note) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    for my $form (@{${${$self -> {'events'}}{$event}}{"FormsList"}}) {
  
      if ($$form{"Name"} eq $name) {
  
        $$form{"Note"} = $note;
        return;
      }
    }
  }
}


sub hasEvidenceTag {

  my ($self, $tag, $event, $type, $name, $synonym) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    if ($type eq 'Comment') {
    
      if (defined ${${$self -> {'events'}}{$event}}{'CommentTags'}) {
    
        for my $actualTag (@{${${$self -> {'events'}}{$event}}{'CommentTags'}}) {
  
          if ($actualTag eq $tag) {
      
            return 1;
          }
        }
      }
  
    } elsif ($type eq 'Name' || $type eq 'Note') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          my $tagType = $type . "Tags";
        
          if (defined $$form{$tagType}) {
        
            for my $actualTag (@{$$form{$tagType}}) {
        
              if ($actualTag eq $tag) {
            
                return 1;
              }
            }
          }
        }
      }
  
    } elsif ($type eq 'Synonyms') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          if (defined $$form{"Synonyms"}) {
      
            for my $actualSynonym (@{$$form{"Synonyms"}}) {
        
              if ($synonym eq $actualSynonym) {
           
                # hash of tags for each synonym
           
                my $tagType = $type . "Tags";
            
                if (defined${$$form{$tagType}}{$synonym}) {
            
                  for my $actualTag (@{${$$form{$tagType}}{$synonym}}) {
            
                    if ($actualTag eq $tag) {
            
                      return 1;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  
  return 0;
}


sub getEvidenceTags {

  my ($self, $event, $type, $name, $synonym) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    if ($type eq 'Comment') {
    
      if (defined ${${$self -> {'events'}}{$event}}{'CommentTags'}) {
    
        return @{${${$self -> {'events'}}{$event}}{'CommentTags'}};
      }
  
    } elsif ($type eq 'Name' || $type eq 'Note') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          my $tagType = $type . "Tags";
        
          if (defined $$form{$tagType}) {
        
            return @{$$form{$tagType}};
          }
        }
      }
  
    } elsif ($type eq 'Synonyms') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          if (defined $$form{"Synonyms"}) {
        
            for my $actualSynonym (@{$$form{"Synonyms"}}) {
        
              if ($synonym eq $actualSynonym) {
           
                # hash of tags for each synonym
           
                my $tagType = $type . "Tags";
              
                if (defined ${$$form{$tagType}}{$synonym}) {
              
                  return @{${$$form{$tagType}}{$synonym}};
                }
              }
            }
          }
        }
      }
    }
  }
  return undef;
}

sub getEvidenceTagsString {
  
  my ($self, $event, $type, $name, $synonym) = @_;
   
  if (defined ${$self -> {'events'}}{$event}) {
  
    if ($type eq 'Comment') {
    
      if (defined ${${$self -> {'events'}}{$event}}{'CommentTags'}) {
    
        my $text = join ',', 
           @{${${$self -> {'events'}}{$event}}{'CommentTags'}}; 
        return "{" . $text . "}";
      }
  
    } elsif ($type eq 'Name' || $type eq 'Note') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          my $tagType = $type . "Tags";
        
          if (defined $$form{$tagType}) {
        
            my $text = join ',', @{$$form{$tagType}};
            return "{" . $text . "}";
          }
        }
      }
  
    } elsif ($type eq 'Synonyms') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          if (defined $$form{"Synonyms"}) {
      
            for my $actualSynonym (@{$$form{"Synonyms"}}) {
        
              if ($synonym eq $actualSynonym) {
           
                # hash of tags for each synonym
           
                my $tagType = $type . "Tags";
              
                if (defined ${$$form{$tagType}}{$synonym}) {
              
                  my $text = join ',', @{${$$form{$tagType}}{$synonym}};
                  return "{" .$text . "}";
                }
              }
            }
          }
        }
      }
    }
  }
  return undef;
}

sub setEvidenceTags {

  # don't allow tags to be added where there is no data
  
  my ($self, $tags, $event, $type, $name, $synonym) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    if ($type eq 'Comment' && 
        (defined ${${$self -> {'events'}}{$event}}{'Comment'})) {
    
      ${${$self -> {'events'}}{$event}}{'CommentTags'} = $tags;
  
    } elsif ($type eq 'Name' || $type eq 'Note') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          if (defined $$form{$type}) {
        
            my $tagType = $type . "Tags";
            $$form{$tagType} = $tags;
          }
        }
      }
  
    } elsif ($type eq 'Synonyms') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          if (defined $$form{"Synonyms"}) {
        
            for my $actualSynonym (@{$$form{"Synonyms"}}) {
        
              if ($synonym eq $actualSynonym) {
           
                # hash of tags for each synonym
           
                my $tagType = $type . "Tags";
                ${$$form{$tagType}}{$synonym} = $tags;
              }
            }
          }
        }
      }
    }
  }
}

sub addEvidenceTag {

  # don't allow tags to be added where there is no data

  my ($self, $tag, $event, $type, $name, $synonym) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) { 
  
    if ($type eq 'Comment' && 
        (defined ${${$self -> {'events'}}{$event}}{'Comment'})) {
  
      push @{${${$self -> {'events'}}{$event}}{'CommentTags'}}, $tag;
  
    } elsif ($type eq 'Name' || $type eq 'Note') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          if (defined $$form{$type}) {
        
            my $tagType = $type . "Tags";
            push @{$$form{$tagType}}, $tag;
          }
        }
      }
  
    } elsif ($type eq 'Synonyms') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          for my $actualSynonym (@{$$form{"Synonyms"}}) {
        
            if ($synonym eq $actualSynonym) {
           
              # hash of tags for each synonym
           
              my $tagType = "SynonymsTags";
              push @{${$$form{$tagType}}{$synonym}}, $tag;
            }
          }
        }
      }
    }
  }
}

sub deleteEvidenceTags {

  # this method looks strange but is basically simple
  # ferret out the requisite evidence tag and splice it from the relevent list

  my ($self, $tag, $event, $type, $name, $synonym) = @_;
  
  if (defined ${$self -> {'events'}}{$event}) {
  
    if ($type eq 'Comment') {
  
      my $offset = 0;
  
      if (defined @{${${$self -> {'events'}}{$event}}{'CommentTags'}}) {
    
        my @tags = @{${${$self -> {'events'}}{$event}}{'CommentTags'}};
  
        for my $actualTag (@tags) {
    
          if ($tag eq $actualTag) {
      
            splice @tags, $offset, 1;
          }
      
          $offset ++;
        } 
    
        if (scalar @tags == 0) {
    
         delete ${${$self -> {'events'}}{$event}}{'CommentTags'};
        }
      }
  
    } elsif ($type eq 'Name' || $type eq 'Note') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          my $tagType = $type . "Tags";
          my $offset = 0;
        
          if (defined $$form{$tagType}) {
        
            my @tags = @{$$form{$tagType}};
  
            for my $actualTag (@tags) {
    
              if ($tag eq $actualTag) {
      
                splice @tags, $offset, 1;
              }
          
              $offset ++;
            } 
    
            if (scalar @tags == 0) {
             
              delete $$form{$tagType};
            }
          }
        }
      }
  
    } elsif ($type eq 'Synonyms') {
  
      for my $form (@{${${$self -> {'events'}}{$event}}{'FormsList'}}) {
      
        if ($$form{"Name"} eq $name) {
      
          if (defined $$form{"Synonyms"}) {
      
            for my $actualSynonym (@{$$form{"Synonyms"}}) {
        
              if ($synonym eq $actualSynonym) {
           
                # hash of tags for each synonym
           
                my $tagType = "SynonymsTags";
                my $offset = 0;
             
                if (defined $$form{$tagType}) {
             
                  if (defined ${$$form{$tagType}}{$synonym}) {
              
                    for my $actualSynonymTag (@{${$$form{$tagType}}{$synonym}}) {
             
                      if ($tag eq $actualSynonymTag) {
               
                        splice @{${$$form{$tagType}}{$synonym}}, $offset, 1;
                      }
               
                      $offset++;
                    }
            
                    if (scalar @{${$$form{$tagType}}{$synonym}} == 0) {
            
                      delete ${$$form{$tagType}}{$synonym};
                    }
                  }
                }
              }
            }
          }
        }
      
        if (scalar keys %{$$form{"SynonymsTags"}} == 0) {
      
          delete $$form{"SynonymsTags"};
        }
      }
    }
  }
}


1;

__END__

=head1 Name

SWISS::CCalt_prod.pm

=head1 Description

B<SWISS::CCalt_prod> represents a comment on the topic 'ALTERNATIVE PRODUCTS'
within a Swiss-Prot or TrEMBL entry as specified in the user manual
http://www.expasy.org/sprot/userman.html .  Comments on other topics are stored
in other types of objects, such as SWISS::CC (see SWISS::CCs for more 
information).

Collectively, comments of all types are stored within a SWISS::CCs container
object.

B<Code example>:

This example is given to illustrate the internal construction of an CCalt_prod
object.  However, for most purposes it should be possible to use the convenience
methods provided (e.g. the add, delete, get and set methods doocumented below)
instead of constructing the section manually.  The use of the convenience
methods is also recommended to ensure the structual integrity of the CCalt_prod
object.

 ## Create a new named isoform
 
 my %thisFormHash;
 
 ## give this some properties
 
 # some properties are single data values
 
 $thisFormHash{"Name"} = "This";
 
 # some properties are lists of values
  
 push @{$thisFormHash{"Synonyms"}}, "That";
 push @{$thisFormHash{"Synonyms"}}, "The Other";
 push @{$thisFormHash{"IsoId"}}, "P00000-01";
 push @{$thisFormHash{"IsoId"}}, "P00000-02";
 push @{$thisFormHash{"Sequence"}}, "VSP_000001";
 push @{$thisFormHash{"Sequence"}}, "VSP_000002";
 $thisFormHash{"Notes"} = "This local note";
  
 ## put this form onto a list of all forms created by one type of event
 
 my @newFormsList;
 
 push @newFormsList, \%thisFormHash;
 
 ## put this list into a hash describing all characteristics of this event
 
 my %eventHash;
 $eventHash{"FormsList"} = \@newFormsList;
 
 ## set other values of this event
 
 $eventHash{"Comment"} = "This Comment";
 
 ## put the description of this event into a hash descrinbing all events
 
 my %eventsHash;
 $eventsHash{"Alternative splicing"} = \%eventHash;
 
 ## put a reference to this hash into the CCalt_products object
 
 my $hashRef;
 $hashRef = \%eventsHash;
 my $newCC = SWISS::CCalt_prod;
 $newCC->setEvents($hashRef);
 $newCC->toString();

B<More simply, using the convenience methods addComment and addForm>:
 
 @synonyms = ("That", "The other");
 @isoIds = ("P00000-1", "P00000-2");
 @featIds = ("VSP_00001", "VSP_00002");
 my $newCC = SWISS::CCalt_prod;
 $newCC -> addComment("Alternative splicing", "This comment");
 $newCC -> addForm("Alternative splicing", 
                   "This", 
                   \@synonyms, 
                   \@isoIds, 
                   \@featIds,
                   "This local note");
 print $newCC -> toString();

B<Output from both approaches:>

 CC   -!- ALTERNATIVE PRODUCTS:
 CC        Event=Alternative splicing; Named isoforms=1;
 CC          Comment=This comment.
 CC        Name=This; Synonyms=That, The other;
 CC          IsoId=P00000-1, P00000-2; Sequence=VSP_00001, VSP_00002;
 CC          Note=This local note.

B<Example of adding evidence tags to a synonym>:

$CC -> addEvidenceTag('EP8', "Alternative splicing", "Synonyms", "VI", "B"); 

to add the tag 'EP8' to synonym B of isoform VI, produced by alternative
splicing

B<Handling mutliple events>:

With the release of UniProt 8.0, the format of the CC ALTERNATIVE PRODUCTS
blocks has changed slightly.  In particular, isoforms are no longer stored
according to the events that have generated them, so this:

 CC   -!- ALTERNATIVE PRODUCTS:
 CC        Event=Alternative splicing; Named isoforms=1;
 CC          Comment=This comment.
 CC        Name=This; Synonyms=That, The other;
 CC          IsoId=P00000-1, P00000-2; Sequence=VSP_00001, VSP_00002;
 CC          Note=This local note.
 CC        Event=Alternative initiation;
 CC          Comment=Another comment.

has become this:

 CC   -!- ALTERNATIVE PRODUCTS:
 CC        Event=Alternative splicing, Alternative initation; Named isoforms=1;
 CC          Comment=This comment. Another comment;
 CC        Name=This; Synonyms=That, The other;
 CC          IsoId=P00000-1, P00000-2; Sequence=VSP_00001, VSP_00002;
 CC          Note=Produced by alternative splicing. This local note;
 
The API is quite event-centric, reflecting the previous file format (where
different content was available according to the event type).  To get all
isoforms (for whatever events are annotated) under the new format, do:

 $CC->keyEvent;
 
which will return an arbitrary event that can be used a parameter in other
methods.  Any of the events annotated will function as parameters to retrieve
information about assocaticated isoforms: it is not necessary to supply the
complete list.
 
=head1 Inherits from

SWISS::BaseClass.pm

=head1 Attributes

=over

=item topic

The topic of this comment ('ALTERNATIVE PRODUCTS').

=back
=head1 Methods

=head2 Standard methods

=over

=item new

=item fromText

=back

=head2 Reading/Writing methods

=over

=item addEvent ($eventName)

Allows the user to insert "events blocks" into the CCalt_prod object.

=item addEvidenceTag($tag, $event, $type, $name, $synonym)

Add $tag to the tag list associated with the specified component of a CCalt_prod
object.  The event and type (of the item to which the tag is to be added, i.e.
"Comment", "Name", "Note", or "Synonyms") must always be specified: unless the
type is "Comment", the name must also be specifed (i.e. the contents of the Name
field for the isoform to which the tag is being attached); the name of the
synonym to which the tag are being attached must also be given if the type is
"Synonyms".

=item addForm ($eventName, $formName, \@synonyms, \@isoIds, \@featIds, $note)

Allows the user to add a form into a given event block.  See code example
(above) for more details.

=item deleteComment ($eventName)

Deletes the comment associated with this event.

=item deleteEvent ($eventName)

Deletes an event from this CCalt_prod objects.

=item deleteEvidenceTag($tag, $event, $type, $name, $synonym)

Deletes $tag from the tag list associated with the specified component of a
CCalt_prod object.  The event and type (of the item from which the tag is to be
deleted, i.e. "Comment", "Name", "Note", or "Synonyms") must always be
specified: unless the type is "Comment", the name must also be specifed (i.e.
the contents of the Name field for the isoform from which the tag is being
deleted); the name of the synonym from which the tag is being deleted must also
be given if the type is "Synonyms".

=item deleteForm ($eventName, $formName)

Deletes a form associated with a given event.

=item keyEvent ()

Extracts one of the events annotated in this entry, which can then be used to
retrieve data associated with this event

=item getComment($eventName)

Returns the comment for this event.

=item getEventNames

Returns a list of all event names for this CCalt_prod object.

=item getEvidenceTags($event, $type, $name, $synonym)

Returns a list of the tags attached to the specified component of a  CCalt_prod
object. The event and type (of the item to which the tag is attached, i.e.
"Comment", "Name", "Note", or "Synonyms") must always be specified: unless the
type is "Comment", the name must also be specifed (i.e. the contents of the Name
field for the isoform whose tags are being fetched); the name of the synonym
whose tags are being fetched must also be given if the type is "Synonyms".

=item getEvidenceTagsString($event, $type, $name, $synonym)

Returns the tags attached to the specified component of a CCalt_prod object as a
string literal. The event and type (of the item to which the tag is attached,
i.e. "Comment", "Name", "Note", or "Synonyms") must always be specified: unless
the type is "Comment", the name must also be specifed (i.e. the contents of the
Name field for the isoform whose tags are being fetched); the name of the
synonym whose tags are being fetched must also be given if the type is
"Synonyms".

=item getFeatIds ($eventName, $formName)

Returns a list of all feature IDs associated with this form produced by this
event.

=item getFormNames ($eventName)

Returns a list of all form names for this form produced by this event.

=item getIsoIds ($eventName, $formName)

Returns a list of all IsoIds for this form produced by this event.

=item getNamedFormCount($eventName)

Returns the number of named and identified forms for this event.

=item getNote ($eventName, $formName)

Returns the local note of this form produced by this event.

=item getSynonyms ($eventName, $formName)

Returns a list of all synonyms of this form produced by this event.

=item hasEvidenceTag ($tag, $event, $type, $name, $synonym)

Returns 1 if the specified component of a CCalt_prod object has the specified
tag.  The event and type (of the item to which the tag is attached, i.e.
"Comment", "Name", "Note", or "Synonyms") must always be specified: unless the
type is "Comment", the name must also be specifed (i.e. the contents of the Name
field for the isoform whose tags are being fetched); the name of the synonym
whose tags are being fetched must also be given if the type is "Synonyms".

=item setComment ($eventName, $comment)

  Allows the user to add a global comment for a particular event.

=item setEvidenceTags(\@tags, $event, $type, $name, $synonym)

Sets the evidence tags of the specified component of a CCalt_prod object to the
array pointed to by \@tags.  The event and type (of the item to which the tag
are to be added, i.e. "Comment", "Name", "Note", or "Synonyms") must always be
specified: unless the type is "Comment", the name must also be specifed (i.e.
the contents of the Name field for the isoform to which tags are being
attached); the name of the synonym to which tags are being attached must also be
given if the type is "Synonyms".

=item setEvent (%eventHash)

Can be used to manually insert a hash representing one event.  Use of this
method is not recommeded, see code examples for how to use the convenience
methods to create a CCalt_prod object.

=item setFeatIds($eventName, $oldName, \@featIds)

Sets the feature Ids for the named form (associated with the specified event) to
the supplied list.

=item setFormName($eventName, $oldName, $newName)

Changes the name of the formed named $OldName, associated with this event, to
the $newName.

=item setIsoIds($eventName, $oldName, \@isoIds)

Sets the Isoform Ids for the named form (associated with the specified event) to
the supplied list.

=item setNote($eventName, $name, $note)

Sets the local note for the named form (associated with the specified event).

=item setSynonyms($eventName, $name, \@synonyms)

Sets the synonyms for the named form (associated with the specified event) to
the supplied list.

=item toString

Returns a string representation of this comment.

=back
