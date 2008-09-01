use inc::Module::Install;
use ExtUtils::Installed;
use Carp;

BEGIN {
  $^W = 1;
}

name             'eXpanda';
perl_version     '5.006';
license          'perl';
all_from         'lib/eXpanda.pm';
include          'Module::AutoInstall';

build_requires 'Test::Class'   => '0';
build_requires 'Test::Harness' => '2.03';
build_requires 'Test::More'    => '0.42';
build_requires 'Test::Pod'     => '0';

requires         'Class::Struct'            => '0';
requires         'XML::Twig'                => '3.260';
requires         'LWP::UserAgent'           => '0';
requires         'SOAP::Lite'               => '0';
requires         'Graph::Layout::Aesthetic' => '0.12';
requires         'SVG'                      => '2.33';

if ( is_admin() )
  {
    requires 'YAML' => 0.35;
  }
elsif ( can_cc() )
  {
    requires('YAML::Syck' => '0.27') unless can_use('YAML'       => 0.35);
  } else {
    requires('YAML'       => '0.35') unless can_use('YAML::Syck' => 0.27);
  }

no_index
  directory => 'example';

if ( $ARGV[0] =~ /PREFIX=(.+?)/i ) {
auto_install(
             makepl_arg => $ARGV[0],
             prerequisites_policy => 'follow',
            );
}
else {
auto_install(
             prerequisites_policy => 'follow',
            );
}

if (can_use("eXpanda")) {
  my $inst = ExtUtils::Installed->new();
  my @files = $inst->files("eXpanda");
  print "Delete current version of eXpanda\n";
  # Delete current version #
  for ( @files ) {
    print "Delete Current Module : $_\n";
    my $chk = unlink($_);
    carp "[Error] File unlink failed : $_ " unless  $chk;
  }

  my $all_dirs = $inst->directories("eXpanda", 'prog');

  for (@{$all_dirs}) {
    if (/eXpanda/) {
      print "Delete Directory: $_\n";
      rmdir $_;
    }
  }
}

auto_provides;

WriteAll;
