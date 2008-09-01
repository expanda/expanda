# *************************************************************
#
# Package:    SWISS/knife
#
# Purpose:    Fast access to SPTR entries via NDBM indexes
#             flat files.
#
# Usage:      use SWISS::EntryStore::SPTR qw(%SPTR);
#             my $entry1 = $SPTR{'E1184836'};
#
# $Revision: 1.1 $
# $State: Exp $
# $Date: 2002/11/11 16:37:51 $
# $Author: gatt $
# $Locker:  $
#
# *************************************************************

package SWISS::EntryStore::SPTR;

use vars qw(@ISA @EXPORT_OK %SPTR);
use Env qw(INDEXES OSTYPE);
use Exporter;
use Fcntl;
use Carp;
use strict;

use SWISS::Entry;
use SWISS::EntryStore::Index;

BEGIN {
  @EXPORT_OK = qw(%SPTR);
  @ISA       = qw(Exporter);
}
  die "Environment variable 'OSTYPE' is not defined.\n".
    "It should contain the name of the operating system.\n"
    unless $OSTYPE;
  die "Environment variable 'INDEXES' is not defined.\n".
    "It should point to the directory where all indexes live.\n"
    unless $INDEXES;

tie %SPTR, 'SWISS::EntryStore::Index',
  {File   => '/net/nfs0/vol2/swissprot/projects/sptr/data/sptr.txl',
   Index  => $INDEXES."sptr.ac.$OSTYPE",
   Access => O_RDWR|O_CREAT,
  };
