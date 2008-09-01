#!/usr/bin/perl -w
use strict;
use eXpanda;


# eXpanda Sample Script No6
# "Return Cap Network and extruct larger independent file from cap network."
# This script generate "sample06.svg"


# parse gml and sif file. reset coorddinate of gml network.
my $str = eXpanda->new('./sampledata/cytoscape.gml',
		      -filetype => 'gml',);

$str->Apply(-reset => 'all' );


my $str_kegg = eXpanda->new('./sampledata/kegg_sce2.sif');


# return cap network to new object.
my $cap_network = $str->Return(
			       -network => {
					    -operator => 'cap',
					    -with => $str_kegg,
					   },
			      );
my $count = 0;
my $independent;

# return largest independent network from cap network.
for my $in (@{$cap_network->Return(
			    -network => {
					 -operator => 'independent',
					},
			   )}){
  if( $count < scalar(keys %{$$in{node}}) )
     {
       $independent = $in;
     }
    $count =  scalar(keys %{$$independent{node}});
}


print "analyze connectivity\t";

# caluculate connectivity with option 'depth 2'.
$independent->Analyze(
		      -method => 'connectivity',
		      -option =>{
				 -depth => 2,
				},
		     );
# initialize network design
$independent->Apply(
		    -object => 'node:graphics:stroke-width',
		    -value => 2,
		   );

$str->Apply(
	    -object => 'node:graphics:fill',
	    -value => "#FFFFFF",
	   );


$independent->Apply(
		    -object => 'node:graphics:font-family',
		    -value => 'Gill Sans',
		   );

$independent->Apply(
		    -object => 'edge:graphics:stroke-width',
		    -value => '3',
		   );

# apply score of connectivity to node design.
$independent->Apply(
		    -object => 'node:graphics:font-size',
                    -from => 'node:score:connectivity',
		    -value => { 15 => 30},
		   );


$independent->Apply(
		    -from => 'node:score:connectivity',
		    -object => 'node:graphics:w',
		    -value => {20 => 45},
		   );


$independent->Apply(
		    -from => 'node:score:connectivity',
		    -object => 'node:graphics:font-color',
		    -value => {'#316745' => '#eb6101'},
		   );



$independent->Apply(
		    -limit => [{
				-object => 'edge:label',
				-operator => 'eq',
				-identifier => 'pd'
			       }],
		    -object => 'edge:graphics:stroke-dash',
		    -value => '2',
		   );

print "END\n";

# output as svg with option "no edge label"
$independent->out('sample06.svg',
		  -no_edge_label => 1,
		 );

__END__

