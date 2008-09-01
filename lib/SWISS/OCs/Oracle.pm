package SWISS::OCs::Oracle;

use DBI;
use DBD::Oracle; 
use Exporter;
use Carp;
use SWISS::TextFunc;
use SWISS::OCs;
use Utils qw(_print_args);

my $connection=undef;
my $CACHING=1;

my %SWISSID2TAXID=();
my %TAXID2OC=();
my $TAXID2OC_counter=0;

BEGIN {
  #print STDERR "Loading package SWISS::OCs::Oracle.pm\n";
}

sub _connect {
  carp "Connecting..." if $main::opt_debug;
  $connection = DBI->connect('dbi:Oracle:','/@PRDB1','', 
			     {PrintError => 1, RaiseError => 1})
    || die "Cannot connect to server: $DBI::errstr\n";
}

sub _disconnect {
  if ($connection){
    carp "Disconnecting..." if $main::opt_debug;
    $connection->disconnect;
    undef $connection;
  }
}


sub fetch_by_swiss_id {
  my $self = shift;
  my $oscode = shift;
  my $tax_id = oscode2tax_id($swiss_id);
  if ($tax_id){
    return $self->fetch_by_tax_id($tax_id);
  } else {
    carp "swiss_id '$swiss_id' not found" if $main::opt_warn;
  }
  return undef;
}

sub fetch_by_emblacs {
  &_print_args;
  my $self = shift;
  my @emblacs = @_;
  my $tax_id = emblacs2tax_id(@emblacs);
  if ($tax_id){
    return $self->fetch_by_tax_id($tax_id);
  }
  return undef;
}

sub fetch_by_species {
  &_print_args;
  my $self = shift;
  my $species = shift;
  return undef;
} 

sub ncbi_scientific2tax_id {
  &_print_args;
  my $species = shift;
  _connect() unless $connection;
  unless ($FETCH_NCBISCI2TAXID){
    $FETCH_NCBISCI2TAXID = $connection->prepare(q{
       select tax_id
         from datalib.ntx_synonym
        where upper_name_txt = ?
          and name_class = 'scientific name'
    }) || die "$DBI:errstr";
  }

  if ($FETCH_NCBISCI2TAXID->execute(uc($species))){
    my ($tax_id) = $FETCH_NCBISCI2TAXID->fetchrow_array;
    return $tax_id;
  } else {
    return undef;
  }
}

sub ncbi_synonym2tax_id {
  &_print_args;
  my $species = shift;
  _connect() unless $connection;
  unless ($FETCH_NCBISYN2TAXID){
    $FETCH_NCBISYN2TAXID = $connection->prepare(q{
       select tax_id
         from datalib.ntx_synonym
        where upper_name_txt = ?
    }) || die "$DBI:errstr";
  }

  if ($FETCH_NCBISYN2TAXID->execute(uc($species))){
    my ($tax_id) = $FETCH_NCBISYN2TAXID->fetchrow_array;
    return $tax_id;
  } else {
    return undef;
  }
}

sub ncbi_fullos2tax_id {
  &_print_args;
  my $species = shift;

  unless ($FETCH_NCBIFULL2TAXID){
    _connect() unless $connection;
    $FETCH_NCBIFULL2TAXID = $connection->prepare(q{
       select tax_id, fullname
         from opd$wfl.v_ntx_fullname
        where fulluppername = ?
    }) || die "$DBI:errstr";
  }

  if ($FETCH_NCBIFULL2TAXID->execute(uc($species))){
    my ($tax_id) = $FETCH_NCBIFULL2TAXID->fetchrow_array;
    return $tax_id;
  } else {
    return undef;
  }
}

sub ncbi_fullos2tax_id_bulk {
  &_print_args;
  my $species = shift;

  unless ($FETCH_NCBIFULL2TAXIDBULK){
    _connect() unless $connection;
    $FETCH_NCBIFULL2TAXIDBULK = $connection->prepare(q{
       select tax_id, fullname
         from ops$wfl.tmp_ntx_fullname
        where fulluppername = ?
    }) || die "$DBI:errstr";
  }
  if ($FETCH_NCBIFULL2TAXIDBULK->execute(uc($species))){
    my ($tax_id) = $FETCH_NCBIFULL2TAXIDBULK->fetchrow_array;
    return $tax_id;
  } else {
    return undef;
  }
}

sub swiss_scientific2tax_id {
  &_print_args;
  my $species = shift;
  my $tax_id;
  _connect() unless $connection;
  unless ($FETCH_SWISSSCI2TAXID){
    $FETCH_SWISSSCI2TAXID = $connection->prepare(q{
       select tax_id
         from OPS$WFL.Swiss_synonym
        where upper_name_txt = ?
          and name_class = 'scientific name'
    }) || die "$DBI:errstr";
  }

  if ($FETCH_SWISSSCI2TAXID->execute(uc($species))){
    ($tax_id) = $FETCH_SWISSSCI2TAXID->fetchrow_array;
    return $tax_id;
  } else {
    return undef;
  }
}
sub swiss_synonym2tax_id {
  &_print_args;
  my $species = shift;
  my $tax_id;
  _connect() unless $connection;
  unless ($FETCH_SWISSSYN2TAXID){
    $FETCH_SWISSSYN2TAXID = $connection->prepare(q{
       select tax_id
         from OPS$WFL.Swiss_synonym
        where upper_name_txt = ?
          and name_class = 'synonym'
    }) || die "$DBI:errstr";
  }

  if ($FETCH_SWISSSYN2TAXID->execute(uc($species))){
    ($tax_id) = $FETCH_SWISSSYN2TAXID->fetchrow_array;
    return $tax_id;
  } else {
    return undef;
  }
}

sub swiss_fullos2tax_id {
  &_print_args;
  my $species = shift;
  my $tax_id  = $SWISSFULL2TAXID{$species};
  return $tax_id if $tax_id;

  unless (%SWISSFULL2TAXID){
    _connect() unless $connection;
    carp "Loading swissfull->tax_id cache\n" if $main::opt_debug;
    my $sth = $connection->prepare
      (q{
	 select tax_id, fulluppername
           from OPS$WFL.V_swiss_fullname
	  where tax_id is not null
	}) || die "$DBI:errstr";
    $sth->execute || die "$DBI:errstr";
    while (my ($tax_id,$full_os) = $sth->fetchrow_array){
      printf "got :%7d, %s\n",$tax_id,$full_os
	if $main::opt_debug>4;
      $SWISSFULL2TAXID{$full_os}=$tax_id;
    }
    $sth->finish();
  }
  return $SWISSFULL2TAXID{uc($species)};
}

sub taxid2swissosline {
  &_print_args;
  my $tax_id = shift;
  my $osline;
  unless ($FETCH_TAXID2SWISSOSLINEBULK){
    _connect() unless $connection;
    $FETCH_TAXID2SWISSOSLINEBULK = $connection->prepare
      (q{
	       select fullname
           from OPS$WFL.Tmp_swiss_fullname
	        where tax_id = ?
	}) || die "$DBI:errstr";
  }
  if ($FETCH_TAXID2SWISSOSLINEBULK->execute($tax_id)){
    ($osline) = $FETCH_TAXID2SWISSOSLINEBULK->fetchrow_array;
    return $osline;
  } else {
    return undef;
  }
}

sub taxid2ncbiosline {
  &_print_args;
  my $tax_id = shift;
  my $osline;

  unless ($FETCH_TAXID2NCBIOSLINEBULK){
    _connect() unless $connection;
    $FETCH_TAXID2NCBIOSLINEBULK = $connection->prepare
      (q{
      	 select fullname
           from OPS$WFL.Tmp_ntx_fullname
          where tax_id = ?
	}) || die "$DBI:errstr";
  }
  if ($FETCH_TAXID2NCBIOSLINEBULK->execute($tax_id)){
    ($osline) = $FETCH_TAXID2NCBIOSLINEBULK->fetchrow_array;
    return $osline;
  } else {
    return undef;
  }
}

sub taxid2osline {
  &_print_args;
  my $tax_id = shift;
  return taxid2swissosline($tax_id) || taxid2ncbiosline($tax_id);
}


sub swiss_fullos2tax_idbulk {
  &_print_args;
  my $os = shift;
  my $tax_id;

  unless ($FETCH_SWISSFULL2OSLINE){
    _connect() unless $connection;
    $FETCH_SWISSFULL2OSLINE = $connection->prepare
      (q{
	       select tax_id
           from OPS$WFL.Tmp_swiss_fullname
	        where fulluppername = (?)
	}) || die "$DBI:errstr";
  }
  
  if ($FETCH_SWISSFULL2OSLINE->execute(uc($os))){
    ($tax_id) = $FETCH_SWISSFULL2OSLINE->fetchrow_array;
    return $tax_id;
  } else {
    return undef;
  }
}

sub swiss_fullos2osline {
  &_print_args;
  my $os = shift;
  my $osline;

  unless ($FETCH_SWISSFULL2OSLINE){
    _connect() unless $connection;
    $FETCH_SWISSFULL2OSLINE = $connection->prepare
      (q{
         select fullname
           from OPS$WFL.Tmp_swiss_fullname
          where fulluppername = ?
	    }) || die "$DBI:errstr";
  }
  
  if ($FETCH_SWISSFULL2OSLINE->execute(uc($os))){
    ($osline) = $FETCH_SWISSFULL2OSLINE->fetchrow_array;
    return $osline;
  } else {
    return undef;
  }
}

sub ncbi_fullos2osline {
  &_print_args;
  my $os = shift;
  my $osline;

  unless ($FETCH_NCBIFULL2OSLINE){
    _connect() unless $connection;
    $FETCH_NCBIFULL2OSLINE = $connection->prepare
      (q{
         select fullname
           from OPS$WFL.Tmp_ntx_fullname
          where fulluppername = upper(?)
      }) || die "$DBI:errstr";
  }
  
  if ($FETCH_NCBIFULL2OSLINE->execute(uc($os))){
    ($osline) = $FETCH_NCBIFULL2OSLINE->fetchrow_array;
    return $osline;
  } else {
    return undef;
  }
}

sub fetch_by_tax_id {
  &_print_args;
  my $self = shift;
  my $tax_id = shift;

  my $longline;  # taxnodes as returned from oracle
  my @nodes;     # array of taxnodes
  my $result;    # result: either undef or SWISS::OCs object

  if ($CACHING && ($result=$TAXID2OC{$tax_id})){
    return $result;
  }
  
  unless ($FETCH_OC){
    _connect() unless $connection;
    $FETCH_OC = $connection->prepare
      (q{
	 select swiss_ocline(?) from dual
	}) || die "$DBI:errstr";
  }
  $FETCH_OC->execute($tax_id);
  ($longline) = $FETCH_OC->fetchrow_array;
  return undef unless $longline;

  @nodes = SWISS::TextFunc->listFromText($longline, ';\s*', '.\s*');
  if (@nodes){
    $result = new SWISS::OCs();
    $result->add(@nodes);
    if ($CACHING){
      %TAXID2OC=() if $TAXID2OC_counter++ > 1000;
      $TAXID2OC{$tax_id}=$result;
    }
    return $result;
  }
  return undef;
}

sub fetch_by_tax_id_do_not_use_this_anymore {
  &_print_args;
  my $self = shift;
  my $tax_id = shift;

  my $result;
  

  if ($CACHING && ($result=$TAXID2OC{$tax_id})){
    return $result;
  }

  unless ($FETCH_TAXANDPARENT){
   _connect() unless $connection;
   $FETCH_TAXANDPARENT = $connection->prepare(q{
       select tax_id, rank
         from datalib.ntx_tax_node
        where hidden = 0 
          and not rank in ('species','subspecies','varietas','forma')
        start with tax_id = ?	
      connect by tax_id = prior parent_id		 
    }) || die "$DBI:errstr";
  }

  my @nodes=();
  $FETCH_TAXANDPARENT->execute($tax_id);
  while(my ($id,$rank)=$FETCH_TAXANDPARENT->fetchrow_array){
    my $name = tax_id2scientific_name($id);
    unshift @nodes,$name;
  }
  
  if (@nodes){
    $result = new SWISS::OCs();
    $result->add(@nodes);
    if ($CACHING){
      %TAXID2OC=() if $TAXID2OC_counter++ > 1000;
      $TAXID2OC{$tax_id}=$result;
    }
    return $result;
  }
  return undef;
}

sub oscode2tax_id {
  &_print_args;
  my $oscode = shift;
  
  unless (%SWISSID2TAXID){
    _connect() unless $connection;
    carp "Loading oscode->tax_id cache\n" if $main::opt_debug;
    my $sth = $connection->prepare(q{
       select distinct oscode, tax_id
         from ops$wfl.Swiss_synonym
        where tax_id is not null
    }) || die "$DBI:errstr";
    $sth->execute || die "$DBI:errstr";
    while (my ($sid,$tid) = $sth->fetchrow_array){
     $SWISSID2TAXID{$sid}=$tid;
    }
    $sth->finish();
  }
  return $SWISSID2TAXID{$oscode};
}


sub tax_id2swiss_scientific {
  &_print_args;
  my $tax_id = shift;

  unless ($FETCH_SWISS_SCI){
    _connect() unless $connection;
    $FETCH_SWISS_NAME = $connection->prepare
      (q{
	       select name_txt
           from ops$wfl.swiss_synonym
	        where tax_id = ?
	          and name_class = 'scientific name'
	});
  }

  if ($FETCH_SWISS_NAME->execute($tax_id)){
    my ($sci_name) = $FETCH_SWISS_NAME->fetchrow_array;
    return $sci_name;
  } else {
    return tax_id2ncbi_scientific($tax_id);
  }
}

sub tax_id2ncbi_scientific {
  &_print_args;
  my $tax_id = shift;

  unless ($FETCH_SCI_NAME){
    _connect() unless $connection;
    $FETCH_SCI_NAME = $connection->prepare(q{
       select name_txt
         from ops$wfl.v_ntx_synonym
        where tax_id = ?
          and name_class = 'scientific name'
    }) || die "$DBI:errstr";
  }

  if ($FETCH_SCI_NAME->execute($tax_id)){
    my ($sci_name) = $FETCH_SCI_NAME->fetchrow_array;
    return $sci_name;
  } else {
    return undef;
  }
}

sub tax_id2scientific_name {
  &_print_args;
  my $tax_id = shift;
  return tax_id2swiss_scientific($tax_id) 
    || tax_id2ncbi_scientific($tax_id);
}


sub tax_id2superregnum {
  &_print_args;
  my $tax_id = shift;

  unless ($FETCH_SUPERREGNUM){
    _connect() unless $connection;
    $FETCH_SUPERREGNUM = $connection->prepare
      (q{select sr.superregnum
	   from ops$wfl.Swiss_superregnum sr
	  where sr.tax_id in
                (select n.tax_id
                   from DATALIB.Ntx_tax_node n
                  start with n.tax_id = ?
                connect by n.tax_id = prior n.parent_id)
    }) || die "$DBI:errstr";
  }

  if ($FETCH_SUPERREGNUM->execute($tax_id)){
    my ($superregnum) = $FETCH_SUPERREGNUM->fetchrow_array;
    return $superregnum;
  } else {
    return undef;
  }
}

sub emblacs2tax_id {
  &_print_args;
  my @emblacs = @_;

  unless ($FETCH_TAXID_BY_EMBLAC){
    _connect() unless $connection;
    $FETCH_TAXID_BY_EMBLAC = $connection->prepare(
       'select organism as taxid '.
       '  from datalib.sourcefeature,datalib.seqfeature,datalib.dbentry '.
       ' where sourcefeature.featid = seqfeature.featid '.
       '   and seqfeature.bioseqid  = dbentry.bioseqid '.
       '   and dbentry.primaryacc# = ?'
    ) || die "$DBI:errstr";
  }

  my %tax_ids = ();
  foreach $emblac (@emblacs) {
    $FETCH_TAXID_BY_EMBLAC->execute($emblac) || die "$DBI:errstr";
    if ($FETCH_TAXID_BY_EMBLAC->rows()){
      while (($tax_id) = $FETCH_TAXID_BY_EMBLAC->fetchrow_array){
	$tax_ids{$tax_id}++;
      }
    } else {
      #print STDERR "!!!!DEAD primary emblac $emblac\n" if $main::opt_warn;
    }
  }

  return keys %tax_ids;
}


DESTROY {
 _disconnect() if $dbh;
}

1;
