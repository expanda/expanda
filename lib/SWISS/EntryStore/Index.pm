# *************************************************************
#
# Package:    SWISS/knife
#
# Purpose:    Fast access to a SWISS-PROT style flatfile
#             via NDBM index.
#
# Usage:      use SWISS::EntryStore::Index;
#             tie %myhash, 'SWISS::EntryStore::Index',
#                {File   => 'myswissfile.sp',
#                 Index  => 'myswissindex'.$ENV{OSTYPE},
#                 Access => O_RDWR|O_CREAT,
#                 };
#
#             my $entry1 = $myhash{'P39000'};
#
#             foreach $entry (values %myhash){
#               print $entry->toText();
#             }

# *************************************************************

package SWISS::EntryStore::Index;

use Fcntl;
use NDBM_File;
use FileHandle;
use Carp;

use PROSITE::Entry;

%MANDATORY_PARAMS = 
  (
   File  => "Please specify a file name.\n",
   Index => "Please specify an index name.\n",
  );

%DEFAULT_PARAMS = 
  (
   Access => O_RDWR|O_CREAT,
   FileAccess => O_RDONLY,
  );

$PERMISSION = 0664;
# RDONLY RDWR APPEND CREAT EXCL TRUNC


sub TIEHASH {
  my $class = shift;
  my $params = shift;
  my %tmp = %$params;
  my $self = \%tmp;
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

  $self->{FILE} = new FileHandle $self->{File}, $self->{FileAccess};
  unless ($self->{FILE}){
    croak "Cannot open file '$self->{File}'";
    return 0;
  }
  
  $self->_build_index_files()
    if $self->_check_index_files();

  my %INDEX;
  my $ok=tie(%INDEX, NDBM_File, $self->{Index}, $self->{Access}, $PERMISSION);
  if ($ok){
    carp "Opened index '$self->{Index}'" if $main::opt_debug;
    $self->{INDEX}=\%INDEX;
  } else {
    croak "Cannot open index '$self->{Index}'" if $main::opt_debug;
    return 0;
  }

  return $self;
}

sub FETCH {
  my $self = shift;
  my $key  = shift;

  # lookup the file position in the hash
  my $fpos = $self->{INDEX}->{$key};
  
  # now fetch the entries from the flatfile
  if (defined $fpos){
    my $save=$/; $/ = "\/\/\n";
    my $fh=$self->{FILE};
    seek $fh, $fpos, 0;
    my $flat=<$fh>;
    $/=$save;
    # we have got the flat entry and stuff it into an entry object
    if ($flat){
      my $entry = SWISS::Entry->fromText($flat);
      return $entry;
    }
  }
  return undef;
}

sub STORE {
  my $self = shift;
  die "Storing is not permitted. Sorry";
}

sub CLEAR {
  my $self = shift;
  die "Deleting is not permitted. Sorry";
}

sub EXISTS {
  my $self = shift;
  my $key  = shift;

  my $fpos = $self->{INDEX}->{$key};
  return defined($fpos);
}


sub FIRSTKEY {
  my $self = shift;

  my $a = keys %{$self->{INDEX}};
  return scalar each %{$self->{INDEX}}
}

sub NEXTKEY {
  my $self = shift;
  my $key  = shift;

  return scalar each %{$self->{INDEX}}
}

# * private procedures

sub _check_index_files {
  my $self = shift;

  my $index_name = $self->{Index};   
  # Check if both index files exist
  
  unless (-e "$index_name.dir"){
    return "Can't find index file '$index_name.dir'";
  }
  unless (-e "$index_name.pag"){
    return "Can't find index file '$index_name.pag'";
  }
  
  # Check if index is up-to-date
  my $idx_mtime = (stat "$index_name.dir")[9];

  my $fh = $self->{FILE};
  my $dat_mtime = (stat $fh)[9];
  if ($dat_mtime > $idx_mtime) {
    return "Index '$index_name' is outdated.";
  }
  return 0;
}

sub _build_index_files {
  my $self = shift;
  
  # because some user may try to use the indices while
  # we are rebuilding them, we build them in a temporary place

  my $index_name=$self->{Index};
  my $temp_name="$index_name.temp";

  # but, we have to check if there are already temp files
  # which we take as a hint that somebody else is building them currently
  # and die gracefully.
  if (-e "$temp_name.dir" || -e "$temp_name.pag"){
    die "someone is already rebuilding index $temp_name";
  }

  # link the (empty) index file to the hash %INDEX,
  # and create the files $temp_name.dir and .pag, if necessary

  my %TMPINDEX;
  tie(%TMPINDEX, NDBM_File, $temp_name, O_RDWR|O_CREAT, 0600);

  my $fh = $self->{FILE};
  my $save = $/; $/="\/\/\n";
  
  # scan the flatfile and save the filepositions of the beginning
  # of every entry in the index
  my $curpos; # current position in flatfile
  my $count=0;# entry count
  my $flat;   # flat entry 
  for ($curpos = -1 ; defined($flat = <$fh>); $curpos = tell $fh) {
    my $id;     # id of the current entry
    my $ac;     # accession number(s) of the current entry
    $count++;
    ($id)=$flat=~/^ID\s\s\s(\w+)/ or next;
    $TMPINDEX{$id}=$curpos; 
    $flat=~s/^[^\n]+\n//;
    ($ac)=$flat=~/^AC\s\s\s(\w+)/ or next;
    $TMPINDEX{$ac}=$curpos;
    
    # my submission for the totally obfuscated perl code contest:
    if ($flat=~/^(AC.*\n)+(\*\*\s\s\s[OPQ]\d.*\n)*/m){
      $_ = $&; s/AC\s+//mg; s/\*\*\s+//mg; s/\s//mg;
      my @acs = split(';',$_); shift @acs; 
      @TMPINDEX{@acs} = ($curpos) x @acs if @acs;
    } # actually, the secondary accession numbers are stored as well
  }
  untie %TMPINDEX;
  $/=$save;

  `mv $temp_name.dir $index_name.dir`;
  `mv $temp_name.pag $index_name.pag`;

  unless (-e "$index_name.dir" && -e "$index_name.pag"){
    die "$0: couldnt built the indexes\n";
  }
  chmod $PERMISSION, "$index_name.dir", "$index_name.pag";
  carp "Build index '$index_name' ($count entries).\n" if $main::opt_debug;
}

# * debuggin

sub _dump_index {
  my $self = shift;
  while (my ($key,$value) = each %{$self->{INDEX}}){
    print "$key $value\n";
  }
}



1;
