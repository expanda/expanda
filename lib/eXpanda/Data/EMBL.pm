package eXpanda::Data::EMBL;

use SWISS::Entry;

sub parse_embl {
  my ( $data ) = @_;
  my $str;
  my $obj = SWISS::Entry->fromText($data);

  my @CCs = $obj->CCs->elements();
  my $CCs;
  for (@CCs) {
    unless($_->topic eq 'Copyright'){
      $CCs .= $_->toString();
    }
  }
  my @DRs = $obj->DRs->elements;

  my @indexs =();
  for my $DR (@DRs) {
    my $index = {
		 'database' => $$DR[0],
		 'primary' => $$DR[1],
		 'secondary' => $$DR[2] || 'unknown',
		 'other' => $$DR[3] || 'unknown',
		} if $#{$DR} > '1';

    push @indexs, $index;
  }

  my @Synonyms;
  for ($obj->GNs->list) {
    for my $GG (@{$_}) {
      @Synonyms = $GG->Synonyms;
    }
  }

  my @taxid;
  for ($obj->OXs->NCBI_TaxID()->elements()) {
    push @taxid, $_->text;
  }

  my @keywords;
  for my $KW ( $obj->KWs->elements ) {
    push @keywords, $KW->text;
  }

  my ( $pubmedid, @references );
  for my $Ref ( $obj->Refs->elements() ) {
    my ( $tmp, $RX );
    $RX = $Ref->RX;
    $pubmedid = $$RX{'PubMed'} if exists $$RX{'PubMed'};

    for ('RP','RG','RL','RT') {
      $tmp .= $Ref->$_().";" if $Ref->$_;
    }

    $tmp .= "Author:";
    for my $au ($Ref->RA->elements()) {
      $tmp .= "$au,";
    }
    $tmp .= ";";
    push @references,$tmp;
  }

  my @organelle;
  for ( $obj->OGs->elements ) {
    push @organelle, $_->text;
  }

  my @spiecies;
  push @spiecies, $_->text for ( $obj->OSs->elements );


  my @feats;
  for my $FT ( $obj->FTs->list() ) {
    for (@{$FT}) {
      my $tmpolal;
      for my $txt (@{$_}) {
	$tmpolal .= $txt.";";
      }
      push @feats, $tmpolal;
    }
  }

  $str = {
	  'primaryID' => $obj->ID()  || 'unknown', # scaler #
	  'accsession' => $obj->AC() || 'unknown', # scaler #
	  'date' => $obj->DTs->CREATED_date() || 'unknown', # scaler #
	  'name' => $obj->GNs->getFirst() || 'unknown', # scaler #
	  'sequence' => $obj->SQs->seq || 'unknown', # scaler #
	  'comment' => $CCs || 'unknown',	    # scaler #
	  'description' => $obj->DEs->text() || 'unknown', # scaler #
	  'referense' => \@references , # array of scaler#
	  'index' => \@indexs ,	       # scaler(now array.)#
	  'pubmedid' => $pubmedid ,     # array of scaler #
	  'synonyms' => \@Synonyms || 'nuknown' , # array of scaler #
	  'ncbi_taxid' => \@taxid , # array or scaler #
	  'keywords' => \@keywords , # array of scaler #
	  'organelle' => @organelle ||'unknown',	# array of scaler #
	  'organismclass' => $obj->OCs->list() ||'unknown', # array of scaler #
	  'features' => \@feats || 'unknown' , # array of scaler #
	  'spiecies' => \@spiecies || 'unknown' , # array of scaler #
	 };

  for (@indexs) {
    $parse_data->{dbref}->{$$_{database}} = $$_{primary};
  }

  return $str;
}

1;
