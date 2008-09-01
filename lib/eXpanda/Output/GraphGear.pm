package eXpanda::Output::GraphGear;

use strict;
use warnings;
use XML::Twig;
#use base qw{Exporter};
#our @EXPORT_OK = qw{Str2GraphGear};

=head1 NAME

  eXpanda::Out::GraphGear

=head1 DESCRIPTION

eXpanda::Output::GraphGear is GraphGear-XML output module for eXpanda.
export function is Str2GraphGear.
Graph Gear is an open platform for graph visualization (the mathematical kind, not the bar chart kind),
developed by CreativeSynthesis L<http://www.creativesynthesis.net>.

About GraphGear, See L<http://www.creativesynthesis.net/blog/projects/graph-gear/>

=head2 GraphGearXML

<?xml version="1.0"?>
<graph title="Sample Graph" bgcolor="ffffff" linecolor="cccccc" viewmode="display" width="725" height="400">
     <node id="n1" text="Some Text" image="Some Image Link" link="Some Link" scale="100" color="0000ff" textcolor="0000ff"/>
     <node id="n2" text="Some Text" image="Some Image Link" link="Some Link" scale="100" color="0000ff" textcolor="0000ff"/>
     <node id="n3" text="Some Text" image="Some Image Link" link="Some Link" scale="100" color="0000ff" textcolor="0000ff"/>
     <edge sourceNode="n1" targetNode="n2" label="Some Label" textcolor="555555"/>
     <edge sourceNode="n1" targetNode="n3" label="Some Label" textcolor="555555"/>
</graph>

=head1 FUNCTIONS

=over 4

=item Str2Svg

Str2GraphGear($gstr);

str is expanda structure.

=cut

sub Str2GraphGear{
    my $str = shift;
    my %attribute = %{shift(@_)};

#     my $xmlflame = qq{<?xml version="1.0"?>
# <graph title="My graph title" bgcolor="0xffffff" linecolor="0xcccccc">
# <node id="n1" text="node1" color="0x6000ff" textcolor="0xffffff"/>
# <edge sourceNode="n1" targetNode="n2" label="" textcolor="0x555555"/>
# </graph>};

    my $xmlflame = qq{<?xml version="1.0"?>
<graph title="My graph title" bgcolor="0xffffff" linecolor="0xcccccc"></graph>};

    my $twig= new XML::Twig(twig_handlers => {
					      graph => \&graph
					    }
			   );

    my $node = $str->{node};
    my $edge = $str->{edge};

    sub graph {
      my( $twig, $elem) = @_;

      $elem->set_att('linecolor' => '0x000000');

      while (my ($labelS,$Target) = each(%{$edge})){
        while (my ($labelT,$e) = each(%{$Target})){
	  my $elt2= XML::Twig::Elt->new('edge');
	  $elt2->set_att('sourceNode' => $labelS);
	  $elt2->set_att('targetNode' => $labelT);
	  $elt2->set_att('text' => $e->{label});
	  $elt2->set_att('textcolor' => '0x555555');
	  $elt2->paste( first_child => $elem);
	}}


      while (my ($label,$n) = each (%{$node}) ){
	my $elt= XML::Twig::Elt->new('node');
	$elt->set_att('text' => $n->{label});
	$elt->set_att('id' => $n->{id});
	$elt->set_att('color' => '0x6000ff');
	$elt->set_att('textcolor' => '0xffffff');
	$elt->paste( first_child => $elem);
      }
    }

    $twig->parsestring($xmlflame);

    $twig->print_to_file($attribute{-o},
			 pretty_print => 'indented'
			);
}

1;
