package eXpanda::Structure::Component;

use strict;
use warnings;
use Carp;

use eXpanda::Util;
use eXpanda::Data::Tab;
use eXpanda::Structure::Index;

=head1 NAME

  eXpanda::Structure::Component

=head1 DESCRIPTION

Handling node component in eXpanda Structure.

=head1 FUNCTIONS

=over 4

=item add_components_from_file

C<<<
	$str->add_components_from_file($filepath,
											 format => 'tab',
											 component_label => NUMBER or String.
											 owner_label => NUMBER or String.
											 import => ( NUMBER or String ) or (ARRAY)
>>>

=over 4

=item format

You can use 'tab' or 'csv' (Not Implemented)

=item component_label

If you use String as component label identifier,
You have to write header in source file.

=item owner_label

Same as component_label.

=item import

import columns list.

=back

=cut

use Data::Dumper;

sub add_components_from_file {
	my $str = shift;
	my $source = shift;
	my $args = {
		format => 'tab',
		component_label => '',
		owner_label => 1,
		import => 'all',
		@_,
	};

	eXpanda::Util::extend 'eXpanda', 'eXpanda::Structure::Component', 'add_component';

	my ( $owner_flag , $comp_flag ) = (0,0);
	$owner_flag = 1 if ( $args->{owner_label} =~ m/[a-z]/i );
	$comp_flag = 1 if ( $args->{component_label} =~ m/[a-z]/i );

	my $header_switch = ( $owner_flag || $comp_flag ) ? 1 : 0;

	my $tab_resource = eXpanda::Data::Tab->new($source,
		header => $header_switch, # use header.
		comment => '#',
	);

	for my $line ( $tab_resource->rows ) {
		my $owner_l = $line->column($args->{owner_label});
		my $cmps_l = $line->column($args->{component_label});
		my $information;

		print STDERR "[debug] $owner_l\t$cmps_l\n" if $eXpanda::Debug;

		if ( $str->is_indexed($owner_l) ) {

			if ( $args->{import} eq 'all' ) {
				for my $colstr ( $line->columns_as_hash ) {
					$information->{$colstr->{name}} = $colstr->{value};
				}
			}
			elsif ( ref($args->{import}) eq 'ARRAY' ) {
				for my $cname ( @{$args->{import}} ) {
					$information->{$cname} = $line->column($cname);
				}
			}
			else {
				carp "[warn] add_component_from_file: 'import' argument must be ArrayRef or strings 'all' ";
				return 0;
			}

			if ( !$owner_l || !$cmps_l ) {
				carp "[warn] add_component_from_file: owner label or component label is null ";
			}
			else {
				$str->add_component($owner_l,
					label => $cmps_l,
					information => $information,
					graphics => { 'width-scale' => 1.2  }
				);
			}
		}
	}

	return $str;
}

sub add_component {
	my $str = shift;
	my $owner = shift;
	my $args = {
		label => $owner,
		information => {},
		graphics    => {
			'font-color' => '#000000',
			'fill'       => 'blue',
			'opacity'       => 0.5,
			'stroke-width'    => 0.5,
			'stroke'    => '#000000',
			'stroke-opacity'    => 1,
			'font-color'    => '#000000',
		},
		@_
	};
	my $owner_id = $str->label2id($owner);
	$str->{node}->{$owner_id}->{component}->{$args->{label}} = $args;
}

1;

=back

=head1 AUTHOR

  Hiroyuki Nakamura C<t04632hn@sfc.keio.ac.jp>

=cut
