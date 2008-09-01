#!/usr/bin/perl
use strict;
use warnings;

use eXpanda;


# eXpanda Sample Script No 20 (1)
#
# [NOTICE]
# "demonstration of converting file format XML to sif, and output SVG from GML file  which modified & generate by Cytoscape."
# Footage file is Ecoli interaction file from DIP database ('http://dip.doe-mbi.ucla.edu/')
#
# this script generate "sample20.sif"

my $str = eXpanda->new('Ecoli20060402.mif',
		      -filetype => 'xml',);


my $n_str = $str->Return(
                         -limit => [{
                                     -object => 'node:information:fullName',
                                     -operator => '=~',
                                     -identifier => 'Hypothetical',
                                    }],
                         -object => 'as_network',
                        );



$n_str->out('sample20.sif',
	 -filetype => 'sif');

# Next, you open this sif file with cytoscape, modify & generate gml file. then ran script 2.
