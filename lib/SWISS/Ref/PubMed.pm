package SWISS::Ref::PubMed;

use Socket;
use Carp;

$caching = 0;

$HOST   = 'www.ncbi.nlm.nih.gov';
$PORT   = 80;
$PATH   = '/htbin-post/Entrez/query?';

%CACHE=();
%REFCACHE=();

sub fetch_by_medlineid {
  my $self = new SWISS::Ref;
  my $medlineid = shift;

  carp "fetch_by_medlineid($medlineid) called" if $main::opt_debug>2;
  
  if ($caching) {
    my $cached=$REFCACHE{$medlineid};
    if ($cached){
      #print STDERR "!!!Cache hit '$medlineid'\n";
      return $cached;
    }
  }

  my $page = get_pubmed_page("uid=$medlineid".'&form=6&dopt=l&db=m&html=no');
  return unless $page;
  if ($page !~ /^UI  - (\d+)/){
    carp "Medline ID $medlineid not found" if $main::opt_warn>1;
  } elsif ($medlineid ne $1) {
    carp "Got medline ID $1 instead of $medlineid" if $main::opt_warn>1;    
  } else {
    $self->fromMedlars(\$page);
    $REFCACHE{$medlineid}=$self if $caching;
  }
  return $self;
}

sub fetch_by_fields {
  my $ref = shift;
  my $self = new SWISS::Ref;

  carp "fetch_by_fields() called" if $main::opt_debug>2;
  
  my $query = toPubMedQuery($ref);
  
  #print STDERR  "QUERY=$query\n";
  my $head ='form=4&db=m&dopt=l&html=no&term=';

  # Have we asked this question already?
  my ($number,$id);
  if (defined $CACHE{$query}){
    ($number,$id) = split(' ',$CACHE{$query});
    if (defined $id){
      #print STDERR "!!!POSITIVE cache hit '$id'\n";
      return SWISS::Ref::PubMed::fetch_by_medlineid($id);
    } else {
      #print STDERR "!!!NEGATIVE cache hit\n";
      return undef;
    }
  } else {
    $number =  count_pubmed_page($head.$query);
    if ($number == 1){
      my $page = get_pubmed_page($head.$query);
      $self->fromMedlars(\$page);
      $id = $self->get_MedlineID();
      $CACHE{$query}="$number $id";
      $REFCACHE{$id}=$self;
      return $self;
    } else {
      $CACHE{$query}= $number;
      return undef;
    }
  }
  
  return undef;

}


sub toPubMedQuery {
  my $ref = shift;

  $ref->unpackRL();
  my @query=();

  if (defined ($ref->issn)){
    push @query, $ref->issn.'[JOUR]';
  } elsif (defined ($ref->journal)) {
    my $issn = SWISS::Journal::name2issn($ref->journal);
    push @query, $issn.'[JOUR]' if $issn;
  }

  push @query, $ref->year."[PDAT]" 
    if defined($ref->year) &&$ref->year;

  if (defined ($ref->volume)){
    push @query, $ref->volume."[VOL]" if $ref->volume;
  }

  if (defined ($ref->pages)){
    my ($firstpage)= $ref->pages =~ /^(\d+)/;
    push @query, $firstpage."[PAGE]" if $firstpage;
  }

  # journal,year,volume,pages is enough to query, but if something
  # is missing, we add the authors to the query
  unless (($ref->issn||$ref->journal)&&
	  ($ref->year)&&($ref->volume)&&($ref->pages)) {
  
    if (defined ($ref->RA)){
      my @au = @{$ref->RA()->list};
      my $n=0;
      foreach $author (@au){
	last if ++$n>10;
	$author =~ s/\.//g;
	$author =~ s/\s(Jr|II|III)$//ig;
	$author =~ s/(\w)-(\w)$/$1$2/g;
	$author =~ s/^(\w+).*/$1/;
	$author =~ tr/ /+/d;
	$query .= '+' unless $query;
	push @query, $author."[AUTH]";
      }
    }
  }
  my $query = join('+and+',@query);
  return $query;
}

sub count_pubmed_page {
  my $query = shift;

  # make sure the 'count' flag is set in the query string
  ($query =~ s/\&dopt=\w/&dopt=q/) ||
   ($query .= '&dopt=q');

  my ($code,$page) = web_get_retry($HOST,$PORT,$PATH.$query);
  if ($code ne 200) {
    return -1;
  } else {
    if ($page =~ /(\d+)/){
      return $1;
    } else {
      return -1;
    }    
  }
}

sub get_pubmed_page {
  my $query = shift;
  my ($code,$page) = web_get_retry($HOST,$PORT,$PATH.$query);
  if ($code eq 200 && $page){
    $page =~ s/^Entrez Reports\n-+\n//m;
    $page =~ s/^No Documents Found[^\n]*\n//m;
    return $page;
  } else {
    return undef;
  }
}

sub web_get_retry {
  my ($code,$page);
  
  while (($code,$page)=web_get(@_)){
    last if $code ne -1;
    carp "Retrying" if $main::opt_debug;
  }
    
  return ($code,$page);
}

sub web_get {
  my ($host,$port,$url) = @_;
  
  my $code = -1;
  my $page;

  my ($proto,$local_host,$local_sock,$remote_sock);
  my $sockaddr='S n a4 x8';
  my ($status,$line,$info);
  my $save = $/; $/="\n";

  $proto = getprotobyname('tcp');
  chop($local_host=`hostname`);
  $local_sock=pack($sockaddr,AF_INET,0,(gethostbyname($local_host))[4]);
  $remote_sock=pack($sockaddr,AF_INET,$port,(gethostbyname($host))[4]);

  unless (socket(S, PF_INET, SOCK_STREAM, $proto)){
    croak "socket: $!";
    return -1;
  }
  setsockopt(S, SOL_SOCKET, SO_KEEPALIVE, pack("l",1)) or die "setsockopt: $!";
  bind(S,$local_sock) || die "$0: bind: $!\n";

  eval {
    connect(S, $remote_sock);
  };

  if ($@){
    croak "connect: $@";
    return -1;
  }

  $_=select(S); $|=1; select($_);

  carp "URL=$url\n" if $main::opt_debug>1;

  print S "GET $url HTTP/1.0\rn" .
    "User-Agent: None/1.0\r\nAccept: */*\r\n\r\n";

  if (defined(S) && defined($status=<S>)){
    chop($status);
    $status=~s/\r$//;
   ($code,$info)=($status=~m!^HTTP\S+\s+(\d\d\d)\s*(.*)$!i);
    carp "STATUS:  $code - $info -\n" if $main::opt_debug>2;

    if ($code==200){
      while(defined($line=<S>)){
	last if $line=~/^\r$/;
	carp "HEADER:  ",$line if $main::opt_debug>3;
      }
      $page = '';
      while(defined($line=<S>)){
	carp $line if $main::opt_debug>3;
	$page .= $line;
      }
    }
  } else {
    $code = '-1';
  }
  close(S);
  $/=$save;
  return ($code,$page);
}


package SWISS::Ref;
use SWISS::Journal;

sub fromPubMed{
  my $self = shift;

  my $medlineid = $self->get_MedlineID();
  if ($medlineid){
    return SWISS::Ref::PubMed::fetch_by_medlineid($medlineid);
  } else {
    return SWISS::Ref::PubMed::fetch_by_fields($self);    
  }
  return undef;
}

sub fromMedlars {
  my $self = shift;
  my $textRef = shift;


  # Parse Medline ID
  if ($$textRef =~ /^UI  - (\d+)/m){
    $self->add_MedlineID($1);
  }

  # Parse RA
  while($$textRef =~ /^AU  - (.*)/mg){
    my $author = $1;
    my $suffix;
    if ($author =~ /et al/i) {
      $self->{'etal'}=1;
      next;
    }
    
    ($author =~ s/\sJr$//)  && ($suffix=' JR.');
    ($author =~ s/\s2nd$//) && ($suffix=' II.');
    ($author =~ s/\s3rd$//) && ($suffix=' III.');
    if ($author =~ /^(.*)\s([A-Z]+)$/){
      $author = "$1 ".join('.',split('',$2)).".";
    }
    $author .= $suffix if $suffix;
    $self->add_Author($author);
  }

  # Parse RT
  if ($$textRef =~ /^TI  - ([^\n]+(\s\s\s\s\s\s[^\n]+\n)*)/m){
    my $title = $1;
    $title =~ s/\n\s+/\n/mg;
    $title =~ s/-\n/-/mg;
    $title =~ s/\n/ /mg;
    $title =~ s/^\[(.*)\]$/$1/mg;
    $title =~ s/[\.\s]+$//g;
    $title =~ s/\s\[see comments\]\s*//;
    $title =~ s/\s\[letter[^\]]*\]\s*//g;
    $title =~ s/\s\[comment[^\]]*\]\s*//g;
    $title =~ s/\s\[news\]\s*//;
    $title =~ s/\s\[editorial\]\s*//;
   #$title =~ s/ \[.+?\]$//mg;
    $self->RT($title);
    carp "Found title '$title'" if $main::opt_debug>1;
  }

  my ($journal,$vol,$pages,$year) = ('','0','0-0','0');
  my $issn;
    
  # Parse Journal
  if ($$textRef =~ /^TA  - (.*)/m){
    $journal = $1; 
  }
  
  # Parse ISSN
  if ($$textRef =~ /^IS  - (\d\d\d\d-\d\d\d[\dXx])/m){
    $issn = $1;
    carp "Found ISSN $issn" if $main::opt_debug>1;
  } else {
    carp "No ISSN found" if $main::opt_warn;
  }
  
  # Getting the proper journal name for Swissprot usage is tricky

  my $proper_name='';
  # if pubmed has an issn which is in our lookup list (SWISS::Journal),
  # we take this looked-up name
  
  if ($issn && ($proper_name = SWISS::Journal::issn2name($issn))){
    $journal = $proper_name;
    carp "Mapped ISSN $issn to '$proper_name'" if $main::opt_debug>2;
  }
      
  if (!$proper_name && ($proper_name = SWISS::Journal::name2swiss($journal))){
    $journal = $proper_name;
    carp "Mapped journal '$name' to '$proper_name'" if $main::opt_debug>2;
  }

  if (!$proper_name && $main::opt_warn){
    carp "Cant find the proper name for journal '$journal'";
  }
 
  # Parse Volume
  if ($$textRef =~ /^VI  - (.*)/m){
    $vol = $1;
    $vol =~ s/^(\d+)\s+\S+.*$/$1/;      
  }
  
  # Parse Pages
  if ($$textRef =~ /^PG  - (.*)/m){
    # handle the american way of paging "125-6" -> "125-126"
    $pages = $1;
    my $prefix;
    if ($pages =~ s/^(\D+)//) {
      $prefix = $1;
    }
    $pages =~ s/,.*$//;
    my ($from,$to)=split('-',$pages);
    if ($from && $to && $from>$to){
      $pages = $from.'-'.substr($from,0,length($from)-length($to)).$to;
    }
    $pages = $prefix.$pages if $prefix;
    # reformat page '317' to SWISS-PROT format '317-317'
    if ($pages !~ /-/){
      $pages = "$pages-$pages";
    }
  }
  
  # Parse Year
  if ($$textRef =~ /^DP  - (\d\d\d\d)/m){
    $year = $1;
  }
  
  if ($main::opt_debug>1){
    carp "Found reference '$journal|$vol|$pages|$year'";
  }
  my $rl = "$journal $vol:$pages($year)";
  $self->issn($issn) if $issn;
  $self->RL($rl);
  return $self;
}

1;

