package eXpanda::Data::KGML;

use strict;
use warnings;
use Carp;
use XML::Twig;
use Storable qw{dclone};

sub _parse_kgml {
  my $filepath = shift;
  my $self;
  our ( $k_node, $k_edge, $pathway) = ();

  my $Path = {
	      pathway => '/pathway',
	     };

  my $twig = new XML::Twig(
			   TwigHandlers => {
					    $$Path{'pathway'} => \&path_kgml,
					   });

  $twig->parsefile($filepath) or croak "[fatal] Cannot open file $filepath.";
  $twig->purge;

  $self->{node} = $k_node;
  $self->{edge} = $k_edge;
  $self->{filetype} = 'kgml';
  $self->{pathway} = $pathway;
  $self->{background} = $pathway->{image};
  $self->{graphed} = 1;


  return $self;

  sub path_kgml {
    my ( $tree, $elem ) = @_;

    $pathway = {
		name   => $elem->att('name')   || 'NULL',
		org    => $elem->att('org')    || 'NULL',
		number => $elem->att('number') || 'NULL',
		title  => $elem->att('title')  || 'NULL',
		image  => $elem->att('image')  || 'NULL',
		link   => $elem->att('link')   || 'NULL',
	       };

    my @entrys = $elem->children('entry');
    my $name_id;

    for my $entry (@entrys) {

      $$k_node{$entry->att('id')}{information}{pathway_name}    = $$pathway{name};
      $$k_node{$entry->att('id')}{information}{pathway_org}     = $$pathway{org};
      $$k_node{$entry->att('id')}{information}{pathway_number}  = $$pathway{number};
      $$k_node{$entry->att('id')}{information}{pathway_title}   = $$pathway{title};
      $$k_node{$entry->att('id')}{information}{pathway_image}   = $$pathway{image};
      $$k_node{$entry->att('id')}{information}{pathway_link}    = $$pathway{link};
      $$k_node{$entry->att('id')}{information}{kegg_id}         =  $entry->att('name') or undef;
      $$k_node{$entry->att('id')}{information}{type}            =  $entry->att('type') or undef;
      $$k_node{$entry->att('id')}{information}{map}            =  $entry->att('map') or undef;
      $$k_node{$entry->att('id')}{graphics}{url}                = $entry->att('link') or undef;

      if ( $entry->att('map') ) {
	$$k_edge{$entry->att('id')}{$entry->att('map')}{label} = 'maplink';
      }

      if ($entry->first_child('graphics')) {
	$$k_node{$entry->att('id')}{information}{name} =  $entry->first_child('graphics')->att('name') or undef;
	$$k_node{$entry->att('id')}{graphics}{'x'} = $entry->first_child('graphics')->att('x') or undef;
	$$k_node{$entry->att('id')}{graphics}{y} = $entry->first_child('graphics')->att('y') or undef;
	$$k_node{$entry->att('id')}{label} = $entry->first_child('graphics')->att('name') or undef;
      }
      $$k_node{$entry->att('id')}{label} = $entry->att('name') if !$$k_node{$entry->att('id')}{label};
      $$name_id{$entry->att('name')} = $entry->att('id');

		if ($entry->att('type') eq 'group' ) {
			for my $cmp ( $entry->children('component') ){
			  	my $cmpid = $cmp->id;		
				$$k_node{$entry->att('id')}{component}{$cmpid} = dclone($$k_node{$cmpid});
				delete $$k_node{$cmpid};
			}	
		}
    }

    my @relations = $elem->children('relation');

    for my $relation (@relations) {
      $$k_edge{$relation->att('entry1')}{$relation->att('entry2')}{label} = $relation->att('type');
      if ( $relation->first_child('subtype') ) {
	$$k_edge{$relation->att('entry1')}{$relation->att('entry2')}{information}{name} = $relation->first_child('subtype')->att('name');
	$$k_edge{$relation->att('entry1')}{$relation->att('entry2')}{information}{value} = $relation->first_child('subtype')->att('value');
      }
    }
    my @reactions = $elem->children('reaction');

    for my $reaction (@reactions) {
      my @substrates = $reaction->children('substrate');
      my @products = $reaction->children('product');

      for my $substrate ( @substrates ) {
	for my $product ( @products ) {
	  if (!defined($$name_id{$substrate->att('name')})) {
	    my $entryid_substrate = ( shift @{([ sort {$b <=> $a} keys %{$k_node}])} ) + 1;
	    print "subs: ".$entryid_substrate."\n";
	    $$k_node{$entryid_substrate}{information}{name} =  $substrate->att('name');
	    $$k_node{$entryid_substrate}{label} = $substrate->att('name');
	    $$name_id{$substrate->att('name')} = $entryid_substrate;
	    print "No Id for \t".$substrate->att('name')."\n";
	  }

	  if (!defined($$name_id{$product->att('name')})) {
	    my $entryid_product = ( shift @{([sort {$b <=> $a} keys %{$k_node}])}) + 1;
	    $$k_node{$entryid_product}{information}{name} =  $product->att('name');
	    $$k_node{$entryid_product}{label} = $product->att('name');
	    $$name_id{$product->att('name')} = $entryid_product;
	    print "No Id for \t".$product->att('name')."\n";
	  }

	  $$k_edge{$$name_id{$substrate->att('name')}}{$$name_id{$product->att('name')}}{label} = $reaction->att('type');
	  $$k_edge{$$name_id{$substrate->att('name')}}{$$name_id{$product->att('name')}}{information}{name} = $reaction->att('name');

	}
      }
    }
  }
}

1;
