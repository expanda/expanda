package eXpanda::Services::EMBL;

use strict;
use warnings;
use Carp;
use eXpanda::Data::EMBL;
use LWP::Simple;

sub dbfetch {
  my ( $db, $acc ) = @_;
  my $source = dbfetch_row($db,$acc);

  unless ($source) {
    carp "[dbfetch:error] Entry not found.";
    return;
  }

  return eXpanda::Data::EMBL::parse_embl($source);
}

sub dbfetch_row {
  my ( $db, $acc ) = @_;
  unless ( $db || $acc ) {
    carp "[dbfetch:error] Not enough argument.";
    return;
  }

  my $base_url = "http://www.ebi.ac.uk/Tools/webservices/rest/dbfetch/";
  my $url = qq{$base_url/$db/$acc};

  return get($url);
}


1;

