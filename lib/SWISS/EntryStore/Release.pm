# *************************************************************
#
# Package:    SWISS/knife
#
# Purpose:    Fast access to SWISS-PROT entries via NDBM indexes
#             flat files.
#
# Usage:      use SWISS::EntryStore::Release qw(%WR);
#             my $entry1 = $WR{'P39000'};
#
# *************************************************************

package SWISS::EntryStore::Release;

use vars qw(@ISA @EXPORT_OK %WR);
use Env qw(WR INDEXES OSTYPE);
use Exporter;
use Fcntl;
use Carp;
use strict;

use SWISS::Entry;
use SWISS::EntryStore::Index;

BEGIN {
  @EXPORT_OK = qw(%WR);
  @ISA       = qw(Exporter);
}
  die "Environment variable 'WR' is not defined.\n".
    "It should point to the current SWISS-PROT workrelease.\n"
    unless $WR;
  die "Environment variable 'OSTYPE' is not defined.\n".
    "It should contain the name of the operating system.\n"
    unless $OSTYPE;
  die "Environment variable 'INDEXES' is not defined.\n".
    "It should point to the directory where all indexes live.\n"
    unless $INDEXES;

my ($wrname)=$WR=~m!/(\w+?)$!;
tie %WR, 'SWISS::EntryStore::Index',
  {File   => $WR,
   Index  => $INDEXES."$wrname.spac.$OSTYPE",
   Access => O_RDWR|O_CREAT,
  };
