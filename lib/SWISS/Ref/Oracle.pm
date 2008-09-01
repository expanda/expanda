package SWISS::Ref;

use DBI;
use DBD::Oracle;
use SWISS::Journal;

my $dbh=undef;



sub fromOracle{
  my $self = shift;

  my $rn = $self->RN();
  if ($rn && $rn>10000){
    $self->fetch_by_pubid($rn);
    return $self;
  }

  my $muid = $self->get_MedlineID();
  if ($muid){
    $self->fetch_by_medlineid($muid);
    return $self;
  }

}

sub fetch_by_pubid {
  my $self = shift;
  my $pubid = shift;

#  print STDERR "fetch_by_pubid($pubid) called\n";
  _connect() unless $dbh;

  $self->fetch_titleandyear($pubid);
  $self->fetch_authors($pubid);
  $self->fetch_journalarticle($pubid);
  $self->fetch_medlinexref($pubid);
  
  return $self;
}

sub fetch_by_medlineid {
  my $self = shift;
  my $medlineid = shift;

  print STDERR "fetch_by_medlineid($medlineid) called\n";
  _connect() unless $dbh;
  unless ($STH_MEDLINE2PUBID){
    $STH_MEDLINE2PUBID = $dbh->prepare(q{
      select pubid
        from datalib.Pub_xref
	where primaryid = ?
	  and dbcode='M'
    })|| die "$DBI::errstr"; 
  }
  if ($STH_MEDLINE2PUBID->execute($medlineid)==1){
    my ($pubid)=$STH_MEDLINE2PUBID->fetchrow_array;
    print STDERR "got PUBID $pubid\n";
    $self->fetch_titleandyear($pubid);
    $self->fetch_authors($pubid);
    $self->fetch_journalarticle($pubid);
  }
  
  $self->fetch_authors($pubid);
  return $self;
}

sub fetch_titleandyear {
  my $self = shift;
  my $pubid = shift;

  unless ($STH_PUBLICATION){
    $STH_PUBLICATION = $dbh->prepare(q{
      select to_char(pubdate,'YYYY'),title
	from datalib.Publication
       where pubid = ?
     })|| die "$DBI::errstr"; 
  }

  if ($STH_PUBLICATION->execute($pubid)==1){
    my ($pubdate,$title)=$STH_PUBLICATION->fetchrow_array;
    $self->year($pubdate) if $pubdate;
    $self->RT($title) if $title;
  }
}

sub fetch_authors {
  my $self = shift;
  my $pubid = shift;

#  print STDERR "fetch_authors($pubid) called\n";

  unless ($STH_PUBAUTHOR){
    $STH_PUBAUTHOR = $dbh->prepare(q{
      select surname,firstname
	from datalib.Pubauthor a,
	     datalib.Person p
       where a.person = p.personid
	 and a.pubid = ?
    })|| die "$DBI::errstr"; 
  }
 
  $self->RA();
  $STH_PUBAUTHOR->execute($pubid);
  while(my ($surname,$firstname)=$STH_PUBAUTHOR->fetchrow_array){
    my $name;
    $name = $surname if $surname;
    $name .= " $firstname" if $firstname;
    $self->add_Author($name) if $name;
  }
}

sub fetch_journalarticle {
  my $self = shift;
  my $pubid = shift;
  
 # print STDERR "fetch_journalarticle($pubid) called\n";

   unless ($STH_JOURNALARTICLE){
     $STH_JOURNALARTICLE = $dbh->prepare(q{
      select a.issn,jn.embl_abbrev,a.volume,a.issue,a.firstpage,a.lastpage
        from datalib.Journalarticle a,
	     datalib.cv_journal jn
	where a.issn = jn.issn#
	  and a.pubid = ?
    })|| die "$DBI::errstr"; 
  }
 
  if ($STH_JOURNALARTICLE->execute($pubid)==1){
    my ($issn,$name,$vol,$issue,$fpage,$lpage)=
      $STH_JOURNALARTICLE->fetchrow_array;

    
    if ($issn && $issn !~ /^EMBL/){
      $self->issn($issn);
      my $proper_name = SWISS::Journal::issn2name($issn);
      if ($proper_name){
	carp "Mapped ISSN $issn to '$proper_name'" if $main::opt_debug;
	$name = $proper_name;
      }
    }
    $self->volume($vol) if $vol;

    my $pages = '0-0';
    $pages = (sprintf "%0d-%0d",$fpage,$lpage) if $fpage && $lpage;
    $self->pages($pages);
    my $year=$self->year();
    $year |= '0';
    $vol |= '0';

    my $rl = "$name $vol:$pages($year)";
    $self->RL($rl);
  } else {
    $self->fetch_acceptedarticle($pubid);
  }
}

sub fetch_acceptedarticle {
  my $self = shift;
  my $pubid = shift;
  
   unless ($STH_ACCEPTEDARTICLE){
     $STH_ACCEPTEDARTICLE = $dbh->prepare(q{
      select a.issn,jn.embl_abbrev,a.volume,a.issue,a.firstpage,a.lastpage
        from datalib.Accepted a,
	     datalib.cv_journal jn
	where a.issn = jn.issn#
	  and a.pubid = ?
    })|| die "$DBI::errstr"; 
  }
 
  if ($STH_ACCEPTEDARTICLE->execute($pubid)==1){
    my ($issn,$name,$vol,$issue,$fpage,$lpage)=
      $STH_ACCEPTEDARTICLE->fetchrow_array;

    if ($issn && $issn !~ /^EMBL/){
      $self->issn($issn);
      my $proper_name = SWISS::Journal::issn2name($issn);
      if ($proper_name){
	carp "Mapped ISSN $issn to '$proper_name'" if $main::opt_debug;
	$name = $proper_name;
      }
    }
    unless ($name) {
      $name='';
      carp "No journal name" if $main::opt_warn;
    }

    $self->volume($vol) if $vol;
    $vol |= '0';

    my $pages = '0-0';
    $fpage |= '0';
    $lpage |= $fpage;
    $pages = $fpage.'-'.$lpage if $fpage && $lpage;
    $self->pages($pages);

    my $year=$self->year();
    $year |= '0';

    my $rl = "$name $vol:$pages($year)";
    $self->RL($rl);
  }
}

sub fetch_medlinexref {
  my $self = shift;
  my $pubid = shift;
  
#  print STDERR "fetch_medlinexref($pubid) called\n";

  unless ($STH_MEDLINEXREF){
    $STH_MEDLINEXREF = $dbh->prepare(q{
      select primaryid
        from datalib.Pub_xref
	where pubid = ?
	  and dbcode='M'
    })|| die "$DBI::errstr"; 
  }
  
  if ($STH_MEDLINEXREF->execute($pubid)==1){
    my ($muid) = $STH_MEDLINEXREF->fetchrow_array;
    $self->RX();
    $self->add_MedlineID($muid);
  }
}


sub _connect {
  carp "Connecting..." if $main::opt_debug;
  $dbh = DBI->connect('dbi:Oracle:','/@PRDB1','',
		      {PrintError => 1})||
			die "Cannot connect to server: $DBI::errstr\n";
}

sub _disconnect {
  if ($dbh){
    carp "Disconnecting..." if $main::opt_debug;
    $dbh->disconnect;
    undef $dbh;
  }
}

BEGIN {
  #print STDERR "Loading package SWISS::Ref::Oracle.pm\n";
}

DESTROY {
 # _disconnect() if $dbh;
}

1;
