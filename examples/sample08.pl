#!/usr/bin/perl
use warnings;
use strict;

use eXpanda;

# eXpanda Demo Script No 8
#
# "Visualizing Social network."


my $str = do './sampledata/sns_net.str';
bless $str, 'eXpanda';


### Analysis ####

$str->Analyze(
	      -method =>"clique",
	     );

$str->Analyze(
	      -method =>"degree",
	     );

### Initialize design ####
$str->Apply(
	    -object => 'node:graphics:fill',
	    -value  => '#d39800',
	   );

$str->Apply(
	    -object => 'node:graphics:w',
	    -value  => '15',
	   );

$str->Apply(
	    -object => 'edge:graphics:stroke',
	    -value  => '#c3d825',
	   );

$str->Apply(
	    -object => 'edge:graphics:width-stroke',
	    -value  => '#c3d825',
	   );

### Apply Score to Design ###
$str->Apply(
	    -object => 'node:graphics:fill',
	    -from => 'node:score:degree',
	    -value => {'#f39800' => '#e2041b'},
	   );

$str->Apply(
	    -object => 'node:graphics:w',
	    -from => 'node:score:degree',
	    -value => {'15' => '40'},
	   );
=kk
$str->Apply(
	    -object => 'edge:graphics:stroke',
	    -from => 'edge:score:clique',
	    -value => {'#c3d825' => '#007b43'},
	   );
=cut

my $limit3 = [{
              -object => 'edge:score:clique',
              -operator => '==',
              -identifier => '4',
             }];

$str->Apply(
            -limit => $limit3,
            -object => 'edge:graphics:stroke',
            -value => '#004d25',
           );

### Output ###
$str->out("sample08.svg",-no_node_label=>1,);

