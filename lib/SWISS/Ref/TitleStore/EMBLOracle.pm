package SWISS::Ref::TitleStore::EMBLOracle;

use Fcntl;
use Carp;

use DBI;
use DBD::Oracle;
use SWISS::Entry;
use Utils qw(_print_args);


%MANDATORY_PARAMS = 
  (
  );

%DEFAULT_PARAMS = 
  (
   Access => O_RDONLY,
  );

# RDONLY RDWR APPEND CREAT EXCL TRUNC


sub TIEHASH {
  &_print_args;
  my $class = shift;
  my $params = shift;
  my %tmp = %$params if $params;
  my $self = {}; %$self=%tmp if %tmp;
  bless $self, $class;
    
  # set not specified parameters to their default
  foreach $param (keys %DEFAULT_PARAMS){
    next if exists $self->{$param};
    $self->{$param} = $DEFAULT_PARAMS{$param};
  }

  # check if all the required parameters are set
  foreach $param (keys %MANDATORY_PARAMS){
    next if $self->{$param};
    die "Mandatory argument '$param' is missing. ".
      $MANDATORY_PARAMS{$param};
  }

  print STDERR "Connecting...\n" if $main::opt_debug;
  $self->{CON} = DBI->connect('dbi:Oracle:','/@PRDB1','', {});
  unless ($self->{CON}){
    croak "Can't connect to server: $DBI::errstr\n";
    return 0;
  }
  print STDERR "Connected.\n" if $main::opt_debug;

  return $self;
}

sub FETCH {
  &_print_args;
  my $self = shift;
  my $key  = shift;

  my $connection=$self->{CON};
  unless ($self->{CURSOR}){
    $self->{CURSOR} = $connection->prepare
    (q{
       select primaryid as medlineid,
              title
         from datalib.pub_xref,
              datalib.publication
        where pub_xref.primaryid=?
          and pub_xref.dbcode='M'
          and pub_xref.pubid=publication.pubid
      }) || die "$DBI::errstr";
  }
  
  $self->{CURSOR}->execute($key) || die "$DBI::errstr";
  my ($muid,$title)=$self->{CURSOR}->fetchrow_array;
  return $title;
}

sub STORE {
  &_print_args;
  my $self = shift;
  die "Storing is not permitted. Sorry";
}

sub CLEAR {
  &_print_args;
  my $self = shift;
  die "Deleting is not permitted. Sorry";
}

sub EXISTS {
  &_print_args;
  my $self = shift;
  my $key  = shift;

  my $title = $self->FETCH($key);
  return $title ? 1 : 0;
}

sub FIRSTKEY {
  &_print_args;
  my $self = shift;
  my $connection=$self->{CON};
  my $key = undef;
  
  if ($self->{KEYCURSOR}){
    print STDERR "finishing keycursor\n";
    $self->{KEYCURSOR}->finish();
  }
  $self->{KEYCURSOR} = $connection->prepare
    (q{
       select primaryid as medlineid
       from datalib.pub_xref
      }) || die "$DBI::errstr";

  $self->{KEYCURSOR}->execute;
  
  ($key) = $self->{KEYCURSOR}->fetchrow_array;
  return $key;

}

sub NEXTKEY {
  &_print_args;
  my $self = shift;
  my $lastkey  = shift;
  my $key = undef;
  
  ($key) = $self->{KEYCURSOR}->fetchrow_array;
  unless ($key){
    $self->{KEYCURSOR}->finish;
    undef ($self->{KEYCURSOR});
  }
  return $key;
}

# * debuggin



1;
