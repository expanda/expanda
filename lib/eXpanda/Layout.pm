package eXpanda::Layout;

use Data::Dumper;
use strict;
use warnings;

use autouse 'eXpanda::Layout::Default'  => 'CalCoord_default';
use autouse 'eXpanda::Layout::Phospho'  => 'CalCoord_phospho';
use autouse 'eXpanda::Layout::GraphViz' => 'CalCoord_dot';
use autouse 'eXpanda::Layout::Oracle'   => 'CalCoord_oracle';

sub _dispacher {
  print "[debug] Layout::_dispatcher.\n" if $eXpanda::DEBUG;
  return {
    'Graph::Layout::Aesthetic' => \&CalCoord_default,
    'Phospho'  => \&CalCoord_phospho,
    'GraphViz' => \&CalCoord_dot,
    'Oracle' => \&CalCoord_oracle,
  };
}

sub CalCoord {
  print "[debug] CalCoord.\n" if $eXpanda::DEBUG;
  my ( $gstr, $attribute , $str) = @_;

  unless ( defined( $gstr->{graphed} ) ) {
    $gstr = _dispacher()->{$attribute->{-engine}}($gstr, $attribute, $str);
  }

  return $gstr;
}

1;
