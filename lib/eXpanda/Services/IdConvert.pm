package eXpanda::Services::IdConvert;

use strict;
use warnings;
use Carp;
use Class::Struct;

use LWP::UserAgent;
use SOAP::Lite;
use XML::Twig;
use SWISS::Entry;
use Data::Dumper;

#constracter etc...
our $initial;

struct 'eXpanda::Services::IdConvert' =>
  {
   query    => '$' ,
   from     => '$' ,
   to       => '$',
   rawdata  => '$',
   parsed   => '*%' ,
   index    => '*@' ,
   result   => '$',
   organism => '$',
  };

BEGIN {
  my $serv = SOAP::Lite->service('http://soap.genome.jp/KEGG.wsdl');
  my $utils = 'http://www.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?';
  my ( $db, $retmode, ) = ('protein', 'xml');

  my $Params = $utils.'db='.$db.'&'.'retmode='.$retmode.'&id=';

  my $ua = LWP::UserAgent->new;

  $ua->from('t04632hn@sfc.keio.ac.jp');
  $ua->timeout(30);
  $ua->agent('Mozilla/5.0');

  my $cmp = { param => $Params, ua => $ua, };

  $$initial{NcbiServ} = $cmp;
  $$initial{KeggServ} = $serv;
}

sub init
  {
    my $self = shift;
    my $args = {
		-id => undef,
		-from => undef,
		-to => undef,
		-organism => undef,
		@_,
	       };
    carp qq{Error: No Input ID.
	  Usage: eXpanda::Services::IdConvert->new(-id => '', -from => '', -to => '');
	   } unless ( $$args{-id} || $$args{-from} || $$args{-to} );
    $self->query($$args{-id});
    $self->from($$args{-from} or 'unknown');
    $self->to($$args{-to} or 'gi');
    $self->organism($$args{-organism} or 'unknown');
    $self->index(0);
    $self->rawdata(0);
    $self->parsed(0);
    $self->result(0);

    return $self;
  }

#Main method.
sub ReturnInformation
  {
    my ( $self ) = @_;
    $self->IdSpecDetect();
    $self->GetKEGG($self->query());


    if( $self->rawdata() ){

      $self->ParseData() if defined $self->rawdata();
      $self->FindResult();
    }else{
      if( $self->from() eq 'up' or 'gi' ){
	$self->GetNCBI($self->query());
	$self->ParseData() if defined $self->rawdata();
	$self->FindResult();
      }
    }

    unless( $self->result() )
      {
	if( $self->parsed() )
	  {
	    $self->rawdata(undef);

	    for( @{$self->index()} )
	      {
		$self->GetKegg($_) if $_ =~ /prot/;
	      }

	    $self->ParseData() if defined $self->rawdata();
	    $self->FindResult();
	  }
      }

    print STDERR "." if $self->result();
    print STDERR "x" if !$self->result() or $self->result() eq 'unknown';

    return $self;
  }

sub GetInfo
 {
   my ($self, $arg) = @_;
   my $switch = 0;
   my $obj = IdConvert->new->init(
				  id => $arg,
				  );

   $switch = 1 if !$arg or $arg eq "all";

   if ( $switch == 1 ){

     for my $label (keys %{$$self{node}}){
       $obj->init(id => $$self{node}{$label}{label});
       $obj->GetKegg($obj->query) || $obj->GetNCBI($obj->query);
       $$self{node}{$label}{information} = $obj->parsed();

     }

   }else{

     $obj->IdSpecDetect();
     $obj->GetKegg($obj->query) || $obj->GetNCBI($obj->query);
     $$self{node}{$$self{node}{label}{$arg}}{information} = $obj->parsed();

   }
   return $self;
 }

# Subroutine for Search 'to' from 'index'.

sub FindResult
  {
    my ( $self ) = @_;
    my $to = $self->to();

    for my $dbentry ( @{ $self->index() } ){
      $self->result($$dbentry{ primary }) if $$dbentry{database} =~ m/$to/i;
    }

    if( !$self->result()) {
      while ( my ( $attr, $val ) = each %{$self->parsed() } ){
	$self->result($val) if $attr =~ /$to/i;
      }
    }

    $self->result('unknown') unless $self->result();

    return $self;
}

#Id specification detect method.
sub IdSpecDetect
  {
    my ( $self ) = @_;

    if($self->from() eq 'unknown'){

      $_ = $self->query();

      if(/^[O-Q]\d[0-9A-Z]{3}\d$/){
	$self->from('up'); #uniprot|swissprot
      }elsif(/^[O-Q]\d[A-Z0-9]{4}_[A-Z0-9]{5}$/){
	$self->from('tr'); #trEMBL
      }elsif(/^\d{6-8}$/){
	$self->from('ncbi'); #ncbi gi
      }elsif( /^N[MTGP]\_\d{6}$/ ){
	$self->from('ncbi'); #ncbi gi
      }elsif(/^[A-Z]{3}\d{5}$/){
	$self->from('ncbi'); #ncbi gi
      }elsif(/^b\d+$/){
	$self->from('kegg'); #kegg
      }elsif(/^\d{7}[A-Z]$/){
	$self->from('prf'); #prf
      }elsif(/^[A-Z0-9]{4,6}$/){
	$self->from('pir'); #pir
      }else{
	$self->from('name'); #supposably gene||protein name.
      }

    }else{

      $_ = $self->from();

      if(/(?:swiss|uni)prot/i){
	$self->from('up'); #uniprot|swissprot
      }elsif($_ eq 'pir' or $_ eq 'PIR'){
	$self->from('pir'); #pir
      }elsif(/ncbi/i or /gi/i){
	$self->from('ncbi'); #ncbi gi or accessionNo
      }elsif(/kegg/i){
	$self->from('kegg'); #kegg
      }elsif(/name/i){
	$self->from('name'); #supposably gene||protein name.
      }else{
	$self->from(lc $_); #unknowdb.
      }

    }
      return $self;
  }

#parse methods
sub ParseData
  {
    my ( $self ) = @_;

    $self->UpParse() if $self->from() eq 'up';
    $self->PirParse() if $self->from() eq 'pir';
    $self->GbParse() if $self->from() eq 'ncbi';
    $self->KeggParse() if $self->from() eq 'kegg';

    return $self;
  }


sub UpParse
  {
    my ( $self ) = @_;

    my $obj = SWISS::Entry->fromText($self->rawdata());

    my @CCs = $obj->CCs->elements();
    my $CCs;
    for(@CCs){
      unless($_->topic eq 'Copyright'){
	$CCs .= $_->toString();
      }
    }
    
    my @DRs = $obj->DRs->elements;
    my @indexs =();

    for my $DR (@DRs){

      my $index = {
		   'database' => $$DR[0],
		   'primary' => $$DR[1],
		   'secondary' => $$DR[2] || 'unknown',
		   'other' => $$DR[3] || 'unknown',
		  } if $#{$DR} > '1';

      push @indexs, $index;
    }

    my @Synonyms;
    for($obj->GNs->list){
      for my $GG (@{$_}){
	@Synonyms = $GG->Synonyms;
      }
    }

    my @taxid;
    for($obj->OXs->NCBI_TaxID()->elements()){
      push @taxid, $_->text;
    }

    my @keywords;
    for my $KW ( $obj->KWs->elements ){
      push @keywords, $KW->text;
    }

    my ( $pubmedid, @references );
    for my $Ref ( $obj->Refs->elements() ){
      my ( $tmp, $RX );
      $RX = $Ref->RX;
      $pubmedid = $$RX{'PubMed'} if exists $$RX{'PubMed'};
      
      for('RP','RG','RL','RT'){
	$tmp .= $Ref->$_().";" if $Ref->$_;
      }

      $tmp .= "Author:";
      for my $au ($Ref->RA->elements()){
	$tmp .= "$au,";
      }
      $tmp .= ";";
      push @references,$tmp;
    }
    
    my @organelle;
    for( $obj->OGs->elements ){
      push @organelle, $_->text;
    }

    my @spiecies;
    for( $obj->OSs->elements ){
      push @spiecies, $_->text;
    }

    my @feats;
    for my $FT ( $obj->FTs->list() ){
      for (@{$FT}){
	my $tmpolal;
	for my $txt (@{$_}){
	  $tmpolal .= $txt.";";
	}
	push @feats, $tmpolal;
      }
    }

    $self->parsed({
		   'primaryID' => $obj->ID()  || 'unknown',               # scaler #
		   'accsession' => $obj->AC() || 'unknown',               # scaler #
		   'date' => $obj->DTs->CREATED_date() || 'unknown',      # scaler #
		   'name' => $obj->GNs->getFirst() || 'unknown',          # scaler #
		   'sequence' => $obj->SQs->seq || 'unknown',             # scaler #
		   'comment' => $CCs || 'unknown',                        # scaler #
		   'description' => $obj->DEs->text() || 'unknown',       # scaler #
		   'referense' => \@references ,                        # array of scaler#
		   'index' => \@indexs ,                                # scaler(now array.)#
		   'pubmedid' => $pubmedid ,                            # array of scaler #
		   'synonyms' => \@Synonyms || 'nuknown' ,               # array of scaler #
		   'ncbi_taxid' => \@taxid ,                             # array or scaler #
		   'keywords' => \@keywords ,                            # array of scaler #
		   'organelle' => @organelle ||'unknown',               # array of scaler #
		   'organismclass' => $obj->OCs->list() ||'unknown',    # array of scaler #
		   'features' => \@feats || 'unknown' ,                 # array of scaler #
		   'spiecies' => \@spiecies || 'unknown' ,              # array of scaler #
		  });

    $self->index(\@indexs);

    my $parse_data = $self->parsed();

    for(@indexs)
      {
	$$parse_data{$$_{database}} = $$_{primary};
      }
    $self->parsed( $parse_data );

    return $self;
  }

sub PirParse
  {
    my ( $self ) = @_;
    my $first = General("\n".$self->rawdata());
    my @refs = $$first{REFERENCE};
    my ( $reftext , $creftext);

    $$first{SEQUENCE} =~ s/[0-9 \/]//g;
    $$first{ENTRY} =~ s/(?:\#.+?)$//g;
    $$first{DATE} =~ s/\s\#.+$//g;

    my @keywords;
    @keywords = split(/;/, $$first{KEYWORDS});
    @keywords = map{(my $x = $_) =~ s/^\s+//g; $x }(@keywords);

    my @feats;
    @feats = split(/\\/m , $$first{FEATURE});
    @feats = map{(my $x = $_) =~ s/^\s+//g; $x }(@feats);

    my $pubmedid;
    my (@reference, @indexs) = ();
    for my $line ( @{$$first{REFERENCE}} ){

      @reference = split(/(?<!\#)\#(?!\#)/, $line );
      for (@reference){
	if( /cross-references\s(.+)/ ){
	  my @tmp = split(/;/, $1);

	  for my $refer(@tmp){
	    $refer =~ s/\s//g;
	    $refer =~ /^(.+?)\:(.+?)$/;
	    $pubmedid = $2 if $1 eq 'PMID';
	    push @indexs, { database => $1,
			   primary => $2,
			   secondary => undef,
			   other => undef,
			 };
	  }
	}
      }
    }

    $self->parsed({
		   'primaryID' => $$first{ENTRY} || 'unknown',       # ENTRY # scaler #
		   'accsession' => $$first{ACCESSIONS} || 'unknown', # ACCESSIONS # scaler #
		   'date' => $$first{DATE} || 'unknown',             # DATE # scaler #
		   'name' => $$first{GENETICS} || 'unknown',         # GENETICS # scaler #
		   'sequence' => $$first{SEQUENCE}||'unknown',       # SEQUENCE # scaler #
		   'comment' => $$first{SUMMARY} || 'unknown',       # ##description # scaler #
		   'description' => $$first{TITLE} || 'unknown',     # TITLE # scaler #
		   'organelle' => undef ,                            # NULL # scaler #
		   'synonyms' => undef ,                             # NULL # array? #
		   'ncbi_taxid' => undef ,                           # NULL # array  #
		   'spiecies' => $$first{ORGANISM} || 'unknown',     # ORGANISM # scaler #
		   'organismclass' => $$first{ORGANISM} || 'unknown',# ORGANISM # scaler #
		   'keywords' => \@keywords || 'unknown',                    # KEYWORDS # array? #
		   'features' => \@feats || 'unknown',                  # FEATURE # array of scaler #
		   'pubmedid' => $pubmedid ||'unknown',             # #cross-references/NULL # array  #
		   'reference' => \@reference || 'unknown',              # REFERENCE # scaler #
		   'index' => \@indexs || 'unknown',                  # ##cross-references # array of hash #
		  });

    $self->index(\@indexs);  # array of hash #

    my $parse_data = $self->parsed();

    for(@indexs)
      {
	$$parse_data{$$_{database}} = $$_{primary};
      }
    $self->parsed( $parse_data );

    return $self;
  }

sub General
  {
    my $text = shift;
    my $str = ();
    my @text_arr = split( /\n([A-Z]{3,15})/, $text );
    @text_arr = grep(!/^\s+$/,@text_arr);
    @text_arr = map{ (my $x = $_) =~ s/(^\s+|\s+$|\n)//g; $x }(@text_arr);
    my $count = 0;
    my @refs = ();
    
    for(@text_arr){
      #make hash. keys are Category.
      if( /REFERENCE/ ){
	push @refs , $text_arr[$count+1];
      }elsif( /^([A-Z]+?$)/ ){
	$$str{$1} = $text_arr[$count+1];
      }
      $count++;
    }
    $$str{REFERENCE} = \@refs;
    return $str;
  }



sub GbParse
  {
    my ( $self ) = @_;
    our ( $refs, $GBfeats ) = (); #( hashref, hashref )#

    our @tags = ('GBSeq_locus','GBSeq_length','GBSeq_update-date',
                 'GBSeq_create-date','GBSeq_definition','GBSeq_primary-accession',
                 'GBSeq_other-seqids','GBSeq_keywords', 'GBSeq_source',
                 'GBSeq_organism', 'GBSeq_taxonomy', 'GBSeq_source-db',
                 'GBSeq_comment','GBSeq_sequence','GBSeq_other-seqids','GBSeq_references',
                 );

    my $path = '/GBSet/GBSeq';
    my $feature = '/GBSet/GBSeq/GBSeq_feature-table';

    my $twig = new XML::Twig(
			     TwigHandlers => {
					      $path => \&gbseq,
					      $feature => \&feat,
					     });
    return 0 unless defined( $self->rawdata() );

    $twig->parse( $self->rawdata() );
    $twig->purge;
    $refs = &fix( $refs );

    my $newref = ();

    while(my ($key, $ref1) = each %{$refs}){
      my @keys = keys %{$ref1};
      $$newref{$key} = $keys[0] if $#keys == 0;
      $$newref{$key} = \@keys if $#keys > 1;
    }

    my $usefeat = {
		   'comment' => '',
		   'description' => '',
		   'index' => '',
		   'indexarr' => '',
#		   'organismclass' => '',
		   'ncbi_taxid' => '',
		   'allfeatures' => '',
		   'name' => '',
		  };

    my ( @indexs, @feats );
    for my $feat (@{$GBfeats}){
      $$usefeat{'allfeatures'} .= $$feat{key}."|".$$feat{location}."|";
      for my $qual (@{$$feat{qualifiers}}){
	$$usefeat{'allfeatures'} .= $$qual{name}.":".$$qual{value}.";" unless $$qual{name} eq 'db_xref';
	push @feats, $$qual{name}.":".$$qual{value};
	$$usefeat{'comment'} .= $$qual{value}.";" if $$qual{name} eq 'note';
	$$usefeat{'name'} = $$qual{value} if $$qual{name} eq 'gene';
	$$qual{value} =~ /taxon:(\d+)$/m if $$qual{name} eq 'db_xref';
	$$usefeat{'ncbi_taxid'} = $1;
	$$usefeat{organelle} = $$qual{value} if $$qual{name} eq 'organelle';
	$$usefeat{index} .= $$qual{value}.";" if $$qual{name} eq 'db_xref';
	
	if($$qual{name} eq 'db_xref'){
	  $$qual{value} =~ /^(.+?)\:(.+?)$/m;
	  push @indexs, {
			 'database' => $1,
			 'primary'  => $2,
			 'secondary'=> undef,
			 'other'    => undef,
			} if $1 and $2;
	}
      }

      $$usefeat{'allfeatures'} .= "\\";
    }
    my @otherseqid = split(/\|/, $$newref{'GBSeq_other-seqids'}) 
      if $$newref{'GBSeq_other-seqids'};
    my $flag = 0;
    for my $part (@otherseqid){
      push @indexs, {'database'  => $part,
		       'primary'   => $otherseqid[$flag+1],
		     'secondary' => undef,
		       'other'     => undef,
		    } if $flag%2 eq 0;
      $flag++;
    }
    
    $self->parsed({
                   'primaryID' => $$newref{'GBSeq_locus'} || 'unknown',
		   # scaler # GBSeq_locus # gbseq #
                   'accsession' => $$newref{'GBSeq_primary-accession'}|| 'unknown',
		   # scaler # GBSeq_primary-accession # gbseq #
                   'date' => $$newref{'GBSeq_update-date'}|| 'unknown',
		   # scaler # GBSeq_update-date # gbseq #
                   'name' => $$usefeat{'name'} || $$newref{'GBSeq_definition'},
		   # scaler # GBSeq_definition # gbseq #
                   'sequence' => $$newref{'GBSeq_sequence'}|| 'unknown',
		   # scaler # GBSeq_sequence # gbseq #
                   'referense' => $$newref{'GBSeq_references'}|| 'unknown',
		   # scaler # GBSeq_references # gbseq #
                   'pubmedid' => $$newref{'GBReference_pubmed'}||'unknown',
		   # array of scaler # <GBReference_pubmed>/or NULL # gbseq #
                   'spiecies' => $$newref{'GBSeq_organism'}|| 'unknown',
		   # scaler? but in up ,array # <GBSeq_organism> # seq #
                   'organismclass' => $$newref{'GBSeq_taxonomy'}|| 'unknown',
		   # array of scaler # GBSeq_taxonomy # seq #
                   'comment' => $$usefeat{'comment'}|| 'unknown',
		   # scaler #<GBQualifier_name>note</GBQualifier_name># feat #
                   'description' =>  $$newref{'GBSeq_definition'}||  $$usefeat{allfeatures},
		   # scaler # GBQualifier # feat #
                   'index' => $$usefeat{'index'}|| 'unknown',
		   # scaler # GBSeq_other-seqids , GBSeq_source-db,GBFeature_quals/GBQualifier# feat #
                   'ncbi_taxid' => $$usefeat{'ncbi_taxid'}|| 'unknown',
		   # array of array  # <GBQualifier_value>taxon:1916</GBQualifier_value> # feat #
                   'features' => \@feats || 'unknown',
		   # array? # all of GBSeq_feature-table # feat #
                   'synonyms' => 'unknown',
		   # array of scaler # NULL #
                   'organelle' => $$usefeat{organelle} || 'unknown',
		   # scaler # NULL# 
                   'keywords' =>  $$newref{'GBSeq_keywords'} ||'unknown',
		   # array? # NULL #
		});

    $self->index(\@indexs);

    my $parse_data = $self->parsed();

    for(@indexs)
      {
	$$parse_data{$$_{database}} = $$_{primary};
      }
    $self->parsed( $parse_data );

    return $self;

    sub feat {
      my ( $tree, $elem ) = @_;
      for my $GBfeat ($elem->children()){
	my $rGBfeat = {
		       key => $GBfeat->first_child('GBFeature_key')->text(),
		       location => $GBfeat->first_child('GBFeature_location')->text(),
		       qualifiers => undef,
		      };
	my @quals = ();
	for($GBfeat->descendants('GBQualifier')){
	  my $tmp = ();
	  $tmp = {
		  name  => $_->first_child('GBQualifier_name')->text(),
		  value => $_->first_child('GBQualifier_value')->text(),
		 };
	  push @quals , $tmp;
	}
	$$rGBfeat{qualifiers} = \@quals;

	push @{$GBfeats}, $rGBfeat;
      }

    }

    sub gbseq {
      my ( $tree, $elem ) = @_;

      foreach my $tag (@tags){
=comment
	if( $tag eq 'GBSeq_references'
	  or $tag eq 'GBSeq_other-seqids'){
	}
=cut
	eval{ $$refs{$tag}{$elem->first_child($tag)->text} = 1; };
	if($@){
	  eval{ foreach($elem->first_child($tag)->children){
	    $$refs{$tag}{$_->text} = 1;
	  }};
	  $$refs{$tag}{'noentry'} = 1 if $@;
	}
      }
      foreach($elem->descendants('GBReference_pubmed')){
	$$refs{'GBReference_pubmed'}{$_->text} = 1;
      }
    }
    
    sub fix {
      my ( $ref ) = @_;

      while(my ($tag, $str1) = each %{$ref}){
	while(my ($info, $val) = each %{$str1}){
	  if($info =~ /(?:.+)\:\s/){
	    delete $$ref{$tag};
	    foreach(split(/______/, $info)){
	      $$ref{$tag}{$_} = 1;
	    }
	  }elsif($info =~ /;/){
	    delete $$ref{$tag};
	    for( split ( /;/, $info ) ){
	      s/(?:^\s|\s$)//g;
	      $$ref{$tag}{$_} = 1;
	    }
	  }
	}
      }
      return $ref;
    }
}

sub KeggParse
  {
    my $self = shift;
    return () unless $self->rawdata();

    my @chank = split( /\n(?!\s)/, $self->rawdata() );

    my $parsed;

    for( @chank ){
      /^([A-Z_]+?)\s/;
      my $key = $1;
      s/^[A-Z_]+?(?=\s)//x;
      $$parsed{$key} = $_ if $key;
    }

    my $parsed2;
    my @indexs;

    while( my ( $key, $val) = each %{$parsed} )
      {
	if( $key eq 'MOTIF' or $key eq 'DBLINKS' )
	  {
	    my @stack;
	    if( $key eq 'MOTIF' )
	      {
		@stack = split( /\n\s.+?(?=[A-Z].+?:\s)/x , $val );
	      }
	    else
	      {
		@stack = split( /\n/, $val );
	      }

	    for( @stack )
	      {
		s/\s//g;
		/^(.+?):(.+?)$/;
		if( $1 and $2 )
		  {
		    $$parsed2{$1} = $2;
		  }
		
		push @indexs, {'database'  => $1,
			       'primary'   => $2,
			       'secondary' => undef,
			       'other'     => undef,
			      };
	      }
	  }
	elsif( $key eq 'PATHWAY' )
	  {
	    $$parsed2{$key} = [];
	    my @stack = split( /\n/, $val );
	    for(@stack)
	      {
		s/^\s+//g;
		/^PATH\:(.+?)$/;
		push @{$$parsed2{'PATHWAY'}}, $1;
	      }
	  }
	elsif( $key eq 'NAME' )
	  {
	    $val =~ s/\s//g;
	    $$parsed2{NAME} = [];
	    $$parsed2{NAME} = [split( /\,\s*/, $val )];
	  }
	else
	  {
	    $$parsed2{$key} = $val;
	  }
      }
    
    $self->parsed($parsed2);
    $self->index(\@indexs);  # array of hash #
    return $self;
  }


#API access methods

sub GetKEGG
  {
    my ($self ,$query) = @_;
    if( $self->from() eq 'kegg' )
      {
	  if( $query =~ /:/ )
	  {
	      $self->rawdata( $$initial{KeggServ}->bget($query) ) or carp "L730:Cannot get form kegg. query is $query";
	  }
	  elsif( $query !~ /\?/ )
	  {

	    if($self->organism() !~ 'unknown')
	      {
		$self->rawdata( $$initial{KeggServ}->bget($self->organism().":".$query) ) or carp "L737:Cannot get form kegg. query is kegg:$query";
	      }
	    else
	      {
		$self->rawdata( $$initial{KeggServ}->bget("kegg:".$query) ) or carp "L741:Cannot get form kegg. query is kegg:$query";
	      }
	  }
	  
      }
    else
      {
	$self->rawdata( $$initial{KeggServ}->bget("protein:$query") ) or carp " cannot get form kegg! ";
      }
    return $self;
  }

sub GetNCBI
  {
    my ($self, $query) = @_;
    $query = $self->query() unless $query;
    return 0 unless $query;
    my $cmp = $$initial{NcbiServ};
    my $req = HTTP::Request->new( 'GET', "$$cmp{param}$query" );
    my $result = $$cmp{ua}->request($req);

    $self->rawdata($result->content()) if $result->is_success;
    carp "You cannnot get $query information from NCBI.$@" unless $result->is_success;
    return $self;
  }

1;
