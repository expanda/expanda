package eXpanda::Output::Text;

use strict;
use warnings;
use Carp;
#use base qw{Exporter};
#our @EXPORT_OK = qw{Str2Sif};

=head1 NAME

  eXpanda::Out::Text

=head1 DESCRIPTION

eXpanda::Output::Text is text output (sif, tab, csv..) module for eXpanda.
export function is Str2Sif.

=head1 FUNCTIONS

=over 4

=item Str2Svg

Str2Sif($gstr);

str is graphics structure.

=cut

sub Str2Sif{
    my $str = shift;
    my %attribute = %{shift(@_)};

    my $out = '';
    my %countedge = ();

    for my $source (keys %{$str->{edge}}){
        for my $target (keys %{$str->{edge}->{$source}}){
	    unless(defined $str->{edge}->{$source}->{$target}->{disable} 
		   && $str->{edge}->{$source}->{$target}->{disable} == 1){
		$out .= "$str->{node}->{$source}->{label} pp $str->{node}->{$target}->{label}\n";
	    }
	}
    }

    open F, ">$attribute{-o}";
    print F $out;
    close F;
}

1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
