#!perl
use strict;
use warnings;

eXpanda::Test->runtests;

package eXpanda::Test;

use base qw/Test::Class/;
use Test::More;

use eXpanda;

sub setup_test : Test(setup){
    my $self = shift;
    $self->{obj} = eXpanda->new('t/data/biopax-level2/biopax-example-short-pathway.owl',
				-filetype => 'owl');
}

sub test_sif : Test {
  # sif
  my $sif = eXpanda->new('t/data/test.sif',
			 -filetype => 'sif');

  is( ref($sif), 'eXpanda', 'sif format loaded' );
}

sub test_gml : Test {
  # gml
  my $gml = eXpanda->new('t/data/cytoscape.gml',
			 -filetype => 'gml' );

  is( ref($gml), 'eXpanda', 'gml format loaded' );
}
use Data::Dumper;
sub test_owl : Test {
  # owl
  my $owl = eXpanda->new('t/data/biopax-level2/biopax-example-ecocyc-glycolysis.owl',
			 -filetype => 'owl',
			);
  is( ref($owl), 'eXpanda', 'biopax format loaded' );
}

=k
sub test_mif : Test(2) {

  # mif
  my $mif = eXpanda->new('t/data/Ito_compact.xml',
			 -filetype => 'xml',
			);

  is( ref($mif), 'eXpanda', 'psi-mi ver 1.0 format loaded' );
}
=cut

sub test_str : Test {

  # str
  my  $hash = {
	       a => {
		     b => 1,
		     d => 1,
		    },
	       e => {
		     f => 1,
		     u => 1,
		    },
	      };

  my $str = eXpanda->new( $hash,
			  -filetype => 'str');

  is( ref($str), 'eXpanda', 'str loaded' );
}

sub test_kgml : Test {

  # kgml
  my $kgml = eXpanda->new('t/data/test.xml',
			  -filetype => 'kgml');

  is( ref($kgml), 'eXpanda', 'kgml format loaded' );
}

1;
