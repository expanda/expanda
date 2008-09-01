use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'eXpanda',
    license             => 'perl',
    dist_author         => 'Yoshiteru Negishi <po@sfc.keio.ac.jp>',
    dist_version_from   => 'lib/eXpanda.pm',
    requires => {
		 'Test::More'  => 0,
		 'version'     => 0,
		 'Test::Class' => 0,
		 'SVG'         => 0,
		 'SOAP::Lite'  => 0,
		 'XML::Twig'   => 0,
		 'Graph::Layout::Aesthetic' => 0,
		},
    add_to_cleanup      => [ 'eXpanda-*' ],
);

$builder->create_build_script();
