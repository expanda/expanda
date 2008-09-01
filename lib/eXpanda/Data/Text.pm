package eXpanda::Data::Text;

use strict;
use warnings;
use Carp;

=head1 NAME

  eXpanda::Data::Text

=head1 DESCRIPTION

eXpanda::Data::Text is text file parser (sif,perl, tab, csv..) module for eXpanda.

=head1 FUNCTIONS

=over 4

=item Sif2Str

Sif2Str($str, $filepath);

str is graphics structure.

=cut

sub Sif2Str{
  my $file = shift;
  my $str = {};
  my %checkn = ();
  my $checke = undef;
  my %nodename2num = ();
  my $num = 0;
  my $source = '';
  my $target = '';

  open my $f, "$file";

  while(<$f>){
    chomp;
    $source = '';
    $target = '';
    if(/^(.+?) pp (.+)$/){
      ($source, $target) = ($1, $2);
    }elsif(/^(.+?) pd (.+)$/){
      ($source, $target) = ($1, $2);
    }
    if($source ne '' && $target ne ''){
      unless(defined($checkn{$source})){
		$nodename2num{$source} = $num;
		$str->{node}->{$nodename2num{$source}}->{id} = $nodename2num{$source};
		$str->{node}->{$nodename2num{$source}}->{label} = "$source";
		$checkn{$source} = 1;
		$num++;
	      }
      unless(defined($checkn{$target})){
	$nodename2num{$target} = $num;
	$str->{node}->{$nodename2num{$target}}->{id} = $nodename2num{$target};
	$str->{node}->{$nodename2num{$target}}->{label} = "$target";
	$checkn{$target} = 1;
	$num++;
      }

      unless(defined($checke->{$source}->{$target}) && $source ne '' && $target ne ''){
	$str->{edge}->{$nodename2num{$source}}->{$nodename2num{$target}}->{source} = $source;
	$str->{edge}->{$nodename2num{$source}}->{$nodename2num{$target}}->{target} = $target;
	$str->{edge}->{$nodename2num{$source}}->{$nodename2num{$target}}->{label} = "pp";
	$checke->{$source}->{$target} = 1;
      }
    }
  }

  close $f;

  my @edgekey = keys %{$str->{edge}};

  croak qq{[fatal] No network imported from "$file" for sif format. Check input file} if ($#edgekey == -1);

  $str->{filetype} = 'sif';

  return $str;
}

=item Dump2Str

Dump2Str($str, $filepath);

Data::Dumper output file parser.

=cut

sub Dump2Str {
  my $str  = shift;
  $str = do $str unless (ref $str eq 'HASH');
  my $ret_str = undef;
  my %checkn = ();
  my $checke = undef;
  my %nodename2num = ();
  my $num = 0;

  for my $source (keys %{$str}){
    for my $target (keys %{$str->{$source}}){
	    unless(defined($checkn{$source})){
		$ret_str->{node}->{$source}->{id} = $source;
		$ret_str->{node}->{$source}->{label} = "$source";
#		$ret_str->{graphviz}->{node}->{$num} = 1;
#		$ret_str->{graphviz}->{num2nodename}->{$num} = $source;
		$nodename2num{$source} = $num;
		$checkn{$source} = 1;
		$num++;
	    }

	    unless(defined($checkn{$target})){
		$ret_str->{node}->{$target}->{id} = $target;
#		$ret_str->{node}->{$target}->{label} = "\"$target\"";
		$ret_str->{node}->{$target}->{label} = "$target";
#		$ret_str->{graphviz}->{node}->{$num} = 1;
#		$ret_str->{graphviz}->{num2nodename}->{$num} = $target;
		$nodename2num{$target} = $num;
		$checkn{$target} = 1;
		$num++;
	    }

	    unless(defined($checke->{$source}->{$target}) && $source ne '' && $target ne ''){
		$ret_str->{edge}->{$source}->{$target}->{source} = $source;
		$ret_str->{edge}->{$source}->{$target}->{target} = $target;
		$ret_str->{edge}->{$source}->{$target}->{label} = "pp";
#		$ret_str->{graphviz}->{edge}->{$nodename2num{$source}}->{$nodename2num{$target}} = 1;
		$checke->{$source}->{$target} = 1;
	    }
	}
    }

    my @edgekey = keys %{$ret_str->{edge}};
  croak qq{No network imported from Perl structure format. check import} if ($#edgekey == -1);

  $ret_str->{filetype} = 'str';
  return $ret_str;
}


1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
