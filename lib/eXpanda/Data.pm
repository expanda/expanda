package eXpanda::Data;

use strict;
use warnings;
use Carp;
use File::Spec;
use base qw{Exporter};
our @EXPORT_OK = qw/open_file/;

# Parser Modules
use autouse 'eXpanda::Data::Text'   => qw(Sif2Str Dump2Str);
use autouse 'eXpanda::Data::GML'    => qw(Gml2Str);
# use autouse 'eXpanda::Data::XGMML'    => qw(_parse_xgmml);
use autouse 'eXpanda::Data::KGML'   => qw(_parse_kgml);
use autouse 'eXpanda::Data::EntryPoint' => qw(_parse_file);
# use autouse 'eXpanda::Data::BioPax' => qw(_parse_biopax);
# use autouse 'eXpanda::Data::PSIMI'  => qw(_parse_psimi);

### eXpanda::Data::EntryPoint is OLD & DIRTY. rewrite as soon as possible. ###

{
  my $map = {
	     'sif' => \&Sif2Str,
	     'str' => \&Dump2Str,
	     'gml' => \&Gml2Str,
	     'kgml'=> \&_parse_kgml,
	     'xml' => sub { return _parse_file({filepath => $_[0]}); },
	     'owl' => sub { return _parse_file({filepath => $_[0]}); },
	     'mif' => sub { return _parse_file({filepath => $_[0]}); },
	    };

  sub _dispatcher {
    my $key = shift;
    if ( defined($map->{$key}) ) {
      print STDERR "[debug] $key found. in dispatcher\n" if $eXpanda::DEBUG;
      return $map->{$key};
    }
    else {
      croak "[fatal] eXpanda cannot read this file, filetype is $key.";
    }
  }
}

### Main Routine.

sub open_file {
  my $args = shift;
  my ( $str , $filetype );
  my $abs = File::Spec->rel2abs($args->{filepath});

  unless (-e $abs ) {
    if ( ref($args->{filepath}) eq 'HASH' ) {
      $args->{-filetype} = 'str';
    }
    else {
      croak "[fatal] Cannot access '$abs' : no such file or directory.";
    }
  }

  # guess filetype.
  if ( defined $args->{-filetype} ) {
    $filetype = $args->{-filetype};
    delete $args->{-filetype};
  }
  else{
    $args->{filepath} =~ m/\.(.{2,5})$/;
    $filetype = $1;
  }

  print STDERR "[debug] _dispatcher($filetype)\n" if $eXpanda::DEBUG;

  $str = _dispatcher($filetype)->($args->{filepath});

  return $str;
}

1;

__END__
