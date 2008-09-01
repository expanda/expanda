package eXpanda;

$VERSION = '1.0.7';

use strict;
use warnings;
use Carp;
use 5.6.1;
use Data::Dumper;
# bases
use base qw{
	     eXpanda::Output
	     eXpanda::Operator
	     eXpanda::StrMod
	 };

#require eXpanda;
use eXpanda::Data qw/open_file/;
# use eXpanda::Service qw{get_data}; # TODO
use eXpanda::Structure::Index;
use eXpanda::Util;

#import routine. (not for normal uses)
sub import {
  return if scalar(@_) < 2;
  for (@_) {
    if ( $_ eq 'debug' ) {
      our $DEBUG = 1;
      my ( $package, $filename, $line ) = caller(1);
      print STDERR "[debug] pkg:$package file:$filename line:$line\n";
    }
  }
}

# eXpanda constractor.
sub new {
  my $pkg = shift;
  my $str;
  my $args = {
	      filepath  => shift,
	      -db     => undef,
	      -filetype => undef,
	      @_,
	     };

  if ( defined($args->{-db}) ) {
    $str = download($args);
  }
  elsif (defined($args->{filepath})) {
    $str = eXpanda::Data::open_file($args);
  }
  else {
    croak "[fatal] Invalid argument. You have to input filepath or accession number.";
  }

  if ( defined($str->{node})
       && defined($str->{edge}) ) {

    # Pre-processing
    bless $str, $pkg;

    $str = eXpanda::Structure::Index->mkindex($str);

    eXpanda::Util::extend 'eXpanda', 'eXpanda::Structure::Index' , ['label2id', 'is_indexed'];

    return $str;
  }
  else {
    croak "[fatal] new: Node and edge is undefined. May be parse error.";
  }
}

sub filetype
  {
    my $self = shift;
    $self->{-filetype} = shift if @_;
    return $self->{-filetype}
  }

sub filepath
  {
    my $self = shift;
    $self->{filepath} = shift if @_;
    return $self->{filepath}
  }

sub kegg
  {
    my $self = shift;
    $self->{kegg} = shift if @_;
    return $self->{kegg}
  }

sub get_node { $_[0]->{node} or "no nodes.\n"; }
sub get_edge { $_[0]->{edge} or "no edges.\n"; }
sub get_desc { $_[0]->{description} or "no description.\n"; }
#this is internal method. for $prestr
sub get_method { $_[0]->{method} }

1;


__END__

=head1 NAME

eXpanda - [an Integrated Platform for Network Analyzing and Visualization]


=head1 VERSION

This document describes eXpanda version 1.0.4


=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use eXpanda;
  
  # Make Constructor
  my $str = eXpanda->new('ribosome.sif');
  
  # Analyze network in 'degree' method
  $str->Analyze(
                -method => 'degree',
                );
  
  # Design node which suffuse '$label =~ /rps/', with "fill" into red.
  $str->Apply(
              -limit => [{
                  -object => 'node:label',
                  -operator => '=~',
                  -identifier => 'rps'
              }],
              -object => 'node:graphics:fill',
              -value => 'red',
              );
  
  # Design node which suffuse '$label =~ /rrn/', with "fill" into gradation
  # from #00FF00 to #FFFFFF, using 'degree' scores.
  $str->Apply(
              -limit => [{
                  -object => 'node:label',
                  -operator => '=~',
                  -identifier => 'rrn'
                  }],
              -from => 'node:score:degree',
              -object => 'node:graphics:fill',
              -value => {"#00FF00" => "#FFFFFF"},
              );
  
  # Design all nodes with 'w' (which means 'width') into 24 pixels.
  $str->Apply(
              -object => 'node:graphics:w',
              -value => '24',
              );
  
  
  # Design node which suffuse '$label =~ /rpl/', with "fill" into blue.
  # This step overwrite with "fill" in earlier steps.
  $str->Apply(
              -limit => [{
                  -object => 'node:label',
                  -operator => '=~',
                  -identifier => 'rpl'
              }],
              -object => 'node:graphics:fill',
              -value => 'blue',
              );
  
  # Design all nodes with 'font-size' (which defining font-size of label).
  $str->Apply(
              -object => 'node:graphics:font-size',
              -value => '8',
              );
  
  # Design node which suffuse '$label eq 'rplV'', with all designs using
  # file whose file path is './ribosome.style'.
  $str->Apply(
              -limit => [{
                  -object => "node:label",
                  -operator => "eq",
                  -identifier => "rplV"
              }],
              -object => "node:graphics",
              -file => './riobosome.style',
              );
  
  # Return list as sub graph which contains nodes which suffuse 
  # '$label =~ 'rpl'', and copy into $str2.
  my $str2 = $str->Return(
                          -limit => [{
                              -object => 'node:label',
                              -operator => '=~',
                              -identifier => 'rpl',
                          }],
                          -object => 'as_network',
                          );
  
  # Divide $str2 networks into each independent networks and 
  # save as "in$i.svg"($i is incremental number).
  my $i = 1;
  for my $in (@{$str2->Return(
                              -network =>{
                                  -operator => 'independent',
                              },
                              )}){
      $in->out("in$i\.svg",
               -object_size => 3,
               );
      $i++;
  }
  
  # Design node which join in list, as smiling in pink
  my $hoge = undef;
  for(qw(rpsB rplX rpsP rpmH rpsN)){
      push @{$hoge->{node}}, $_;
  }
  $str->Apply(
              -limit => [{
                  -list => $hoge,
              }],
              -object => 'node:graphics:smile',
              -value => 'pink',
              );
  
  # Save network in 4x object size with no label, as 'ribosome.svg'. 
  $str->out('ribosome.svg',
            -object_size => 4,
            -l => 1,
            );


=head1 DESCRIPTION

eXpanda helps to observe interactome networks.

=head1 INTERFACE 

eXpanda have 5 modules in the user interface which is named 'B<new>', 'B<Apply>', 'B<Return>', 'B<Analyze>' and 'B<out>'. 
The following texts are detailed commentary on these interfaces.


=head2 B<new(> I<filepath>, I<%Options>, B<)>

"new" is the module to make a constructor. 
Acceptable file-types are 'SIF', 'Cytoscape GML', 'Two dimensioned hash reference', 'Database Flat Data'. 
File format rules are described in "supplementary.txt".
If you choose hash reference, the structure formation is as follows:
c.f) {a => {b => 1, c => 1,} c => {d => 1}}
To make this hash, additionaly code the following:

  my $hash = undef;
  $hash->{a}->{b} = 1;
  $hash->{a}->{c} = 1;
  $hash->{c}->{d} = 1;

Following are the options.


=over

=item  -filetype => I<String>

This option defines the filetype to input string as 'sif', 'gml', 'str' and 'xml'.

Default value is 'sif'.

B<Example:>
  my $str->new('ribosome.sif', -filetype => 'sif')

=back

=head2 B<Apply(> I<%Options>, B<)>

"Apply" is the module to modify network. 

Options are as follows.

=over

=item -limit => [{ I<%Options> }, {}, ... ]

"-limit" is the option for limiting the applying objects in the network.

Limitations are multiply definable as array references as ¡ÈEXAMPLE¡É that is described as follows.

Options are as follows.

  -object => I<String>,
  -operator => I<String>,
  -identifier => I<Float, Integer or String>,

or

  -object => I<String>,
  -list => I<Hash reference>,

"-object", "-operator" and "-identifier" are the set. These 3 terms evaluates to limit objects. If you put "node:label", "eq", "lacZ", then the module will select the only nodes whose label is lacZ.

Description about "-object" is written below.

"-operator" is the operator. Acceptable strings is as follows. "eq", "ne", "=~", "!~"(regular expressions!), "==", "!=", ">=", "<=", ">", "<".

"-identifier" defines the identifying terms. It usually uses I<Float>, but I<String> "average" or "center" are acceptable, too. eXpanda will determine the value of "average" and "center" as a statistical value and is able to be used with "-limit" option 

If the object has Float or Integer data, then you can put "-operator" and "-identifier" in the following words:

"top", "I<Integer>" returns top Integer objects scored.

"bottom", "I<Integer>" returns bottom Integer objects scored. 


"-list" takes list matching with the object label. You can input here as I<eXpanda blessed structure>, I<filepath> or I<hash reference>.

If you want to query eXpanda structure, you may just put the constructed structure here.

Rules of the file format for eXpanda are also described in the "supplementary.txt". 

Definition of the hash reference are as follows.

If you want to include nodes labeled "lacZ" and "lacY", then code as: 

  $list->{node}->{lacZ} = 1;

Also you can put the edge of lacZ to lacY:

  $list->{edge}->{lacZ}->{lacY} = 1;

B<Note:
If you limit only for the nodes, the edges between the limited nodes will be applied to Apply().>

B<Example:>

  $str->Apply(
              -limit => [{
                  -object => 'node:label',
                  -operator => '=~',
                  -identifier => 'rpl'
              },
              {
                  -list => $list_hash,
              },
              {
                  -list => './list.limit',
              }
              ],
              -object => 'node:graphics:fill',
              -value => 'blue',
              );

=item -object => I<String>

"-object" option defines the object information layered with ":" for the following  3 methods. If you want to manipulate objects to apply in degree score of nodes, then you may put "node:score:degree" into "-object". Also you can put "node:information:GI", "node:graphics:fill", etc. Originally, the constructed network has no data except "node:label" and "edge:label" when you constructed network with sif, gml or svg data. If you have constructed network from the public databases, some information are put in "I<object>:information:*". If you want data that have been inputted in each object, please check "supplementary.txt": The supplementary text file.

You have to put information or scores using "Apply" method or "Analyze" method after constructing the data structure.

In this colon separated description format, the last term in "I<object>:graphics:*" is acceptable with the limited strings such as the following listed:

[node attributes]

node:graphics:w  I<Float>

node:graphics:stroke-width  I<Float>

node:graphics:stroke-dash  I<List of Float> ( c.f) "2" or "5,10")

node:graphics:font-size  I<Float>

node:graphics:opacity  I<Float> (0 to 1)

node:graphics:stroke-opacity  I<Float> (0 to 1)

node:graphics:font-opacity  I<Float> (0 to 1)

node:graphics:fill  I<Color>

node:graphics:stroke  I<Color>

node:graphics:smile  I<Color>

node:graphics:font-color  I<Color>

node:graphics:font-family  I<Installed font name>

node:graphics:type  I<'oval', 'diamond', 'star' or 'heart'>



[edge attributes]

edge:graphics:stroke-width  I<Float>

edge:graphics:stroke-dash  I<List of Float> ( c.f) "2" or "5,10")

edge:graphics:opacity  I<Float> (0 to 1)

edge:graphics:stroke  I<Color>

edge:graphics:font-size  I<Float>

edge:graphics:font-opacity I<Float> (0 to 1)

edge:graphics:font-family  I<Installed font name>

edge:graphics:font-color  I<Color>




Details are described in "supplementary.txt".


=item -value => I<String> | I<Hash reference> # when using "-from" option

Input value.

If you change the design of objects, the value of the option must be under the rule. This rule is also described in "supplementary.txt". When "-from" option is set, it is described in the section from "-from" option. "-value" is basically defined as I<Hash Reference>.


=item -file => I<Filepath>

This handles 3 types of files. score data, design data, and information data.

When you are using this option, "-object" option must be set to "node:graphics", "edge:graphics", "all:graphics", "node:score", "edge:score", "all:score", "node:information", "edge:information" or  "all:information".

The file rule is also described in "supplementary.txt".

B<Example:>
  $str->Apply(
              -limit => [{
                  -object => "node:label",
                  -operator => "eq",
                  -identifier => "rplV"
              }],
              -object => "node:graphics",
              -file => './riobosome.style',
              );


=item -from => I<String>,

eXpanda is able to change the design of objects from the scored information. For example, if you finished calculating the degree scoring, you can apply the results to the 'node:score:degree' option.

The applying object for this option must be a design attributes. Using this option, you have to fill "-object" option with "node:graphics:I<detail String>" or "edge:graphics:I<detail String>". When you apply I<detailString> as Float data ( c.f) w, stroke-width..) the "-value" option should be {"I<Float>" => "I<float>"}. These values define the minimum  value and the maximum value from the applying object which are determined from "-from" scores. The "-value" options are defined as {"I<Color>" => "I<Color>"} when you set color data in "-object".

The list of object, which can put in to '-object' option when '-from' option is activated, are as follows:

[node attributes]

node:graphics:w  I<Float>

node:graphics:stroke-width  I<Float>

node:graphics:opacity  I<Float> (0 to 1)

node:graphics:stroke-opacity  I<Float> (0 to 1)

node:graphics:font-opacity  I<Float> (0 to 1)

node:graphics:font-size  I<Float>

node:graphics:fill  I<Color>

node:graphics:stroke  I<Color>

node:graphics:smile  I<Color>

node:graphics:font-color  I<Color>

[edge attributes]

edge:graphics:stroke-width  I<Float>

edge:graphics:opacity  I<Float>

edge:graphics:font-size  I<Float>

edge:graphics:font-opacity  I<Float> (0 to 1)

edge:graphics:stroke  I<Color>

edge:graphics:font-color  I<Color>


B<Example:>
  $str->Apply(
              -from => 'node:score:degree',
              -object => 'node:graphics:fill',
              -value => {"#00FF00" => "#FFFFFF"},
              );

=item -apply_information => { I<%Options>}

This option defines applying information using networks.

 -object => I<String>, -from => I<String>, -to => I<String>, -organism => I<String> },

"-object" option defines resources of apply_information. You may input here as "node:label" or "node:information:I<String>".

"-from" option is the default label name type, such as "GI", "Uniprot", etc.

"-to" option defines conversion target type. 

"-organism" defines the organism which the network joins. Sometimes this option should be use. c.f) The network described in gene name ("-from" option should be the "name").

The acceptable options are also defined in "supplementary.txt".

B<Example:>
  $str->Apply(
              -apply_information => {
                  -object => 'node:information:GI',
                  -from => 'GI',
                  -to => 'PIR'
                  },
              -object => 'node:label',
              );

=item -reset => I<String>,

This option removes the specified data inside the eXpanda data structure.

You can input same strings with "-object", or "all", "node:all", "edge:all", and "except_xy".

"except_xy" is developed mainly for GML format files. This value remove others except the coordinates.

B<Example:>
  $str->Apply(
              -reset => 'except_xy',
              );

=item -label => I<String>,

This option applies object label from other existing information. I<String> format is completely same with "-object".

B<Example:>
  $str->Apply(
              -label => 'node:information:GO',
              );

=back


=head2 B<Return(> I<%Options>, B<)>

"Return" is the module to return information of object, object as is, or sometime also returns eXpanda blessed subgraph. Options are as follows.

B<NOTE:>

If you only want to receive the network structure, simply code as follows.

  my $network_structure = $str->Return();

$network_structure may have second order hash reference.

=over

=item -limit => [{ I<%Options> }, {}, ... ],

Same as "-limit" options in Apply().

=item -object => I<String>, 

Almost the same as "-object" options in Apply() except for the following: 

This input accept the string "as_network". In this case, you may set "-network" option.
In details, see the "-network" section.

If you input "1|true" into the option "-hash", this option should be the hash reference. After that procedure, "Return()" will return values as a hash reference. In details, see "-hash" section.
B<NOTE:
If you input "-object" as "as_network", input something in "-limit", and not input to the "-network", you will get subgraphs with limited objects.>

B<Example 1:>
  $str->Return(
               -limit => [{
                           -object => "node:information:name",
                           -operator => "=~",
                           -identifier => "^lac"
                           }],
               -object => 'node:label',
               );

B<Example 2:>
  $str->Return(
               -limit => [{
                           -list => './list.limit',
                           }],
               -object => 'as_network',
               );

B<Example 3:>
  $str->Return(
               -limit => [{
                           -object => "node:score:degree",
                           -operator => ">=",
                           -identifier => "average"
                           }],
               -hash => 1,
               -object => {'node:label' => 'node:information:GO'}
               );


=item -network => { I<%Option>},

Further options are are listed below:

  -operator => I<String>,
  -with => I<eXpanda Blessed structure>,
  -threshold => I<Integer>

This option defines and returns networks operation.

"-operator" is acceptable with strings of "cap", "cup", "independent" and "clique".

In order to use "cap" and "cup", "-with" is necessary. This operation will search for the cap or cup network with the applied network that is set in "-with".

If you choose "independent", "Return" returns each independent subgraphs in the network as a blessed structure.

"Return" also returns each complete subgraphs if you choose "clique". Then you may set '-threshold' which determines threshold of node numbers of subgraphs. Default:4.

B<Example:> 
  my $i = 1;
  for my $in (@{$str2->Return(
                              -network =>{
                                  -operator => 'independent',
                              },
                              )}){
      $in->out("in$i\.svg",
               -debug_size => 3,
               );
      $i++;
  }

=item -hash => I<Boolean>

Default: 0

If you do not set "as_network" in "-object", "Return" module always return the values as array reference in default. If you change this option to "1", you can receive hash reference.

B<Example 1:>
  @list = @{$str->Return(
                         -limit => [{
                             -object => 'node:score:degree',
                             -operator => '>=',
                             -identifier => 'average',
                             }],
                         -object => 'node:label',
                         )};

B<Example 2:>
  %index = %{$str->Return(
                          -limit => [{
                              -object => 'node:score:degree',
                              -operator => '>=',
                              -identifier => 'average',
                              }],
                          -hash => 1,
                          -object => {'node:label' => 'node:information:GO'}
                          )};


=item -get_information => { I<%Option> }

Further options are as follows:

  -object => I<String>,
  -from => I<String>,
  -to => I<String>,

Definition of the option is basically same with "-apply_information" in "Apply()".

This options get data using web services. If you use this option, you do not have to set "-object" option into "Return()". If you check "-hash" option, then it returns hash reference as {"-object in -get_information" => "translated information", ...}. If not, then it returns list of translated information as array reference.

B<Example:>
  %function_list = %{$str->Return(
                       -limit => [{
                                   -object => 'node:score:degree',
                                   -operator => 'top',
                                   -identifier => '10',
                                   }],
                       -get_information => {
                                            -object => 'node:information:GI',
                                            -from => 'GI',
                                            -to => 'protein_function',
                                            },
                       -hash => '1',
                       )};

=back


=head2 B<Analyze(> I<%Options>, B<)>

"Analyze()" is a module for topological analysis on the network. 

=over

=item -method => I<String>,

This option defines what method applies to network. Currently this method supports the following names as:

"degree", "normalized_degree", "clique", "connectivity", "accuracy", "coverage", "count_nodes" and "count_edges".

These data are stored in "node:score:I<method_name>" or "edge:score:I<method_name>". It have return value when you set the specific method name.

In detail, see "supplementary.txt".

=item -option => I<hash reference>,

This is an method options for each method. This input may alters in each method.

What should be inputted for each methods are also described in "supplementary.txt".

=item -object => I<String>

If you want to reflect scores as soon as possible, you can fill design object here. c.f) "node:graphics:fill".

=item -value => I<Hash reference>

Input value for "-object". String rules are same as "-from" inputted "Apply()". See "supplementary.txt" in detail.

B<Example:>
  $str->Analyze(
                -method => 'accuracy',
                -option => {
                            -object => "node:label",
                            -with => $str2,
                            -with_object => "node:information:GI",
                            }
                );


=back


=head2 B<out(> I<filepath>, I<%Options>, B<)>

"out()" method is for outputting network data.

=over

=item -filetype => I<String>

This option defines the type of output file. "Scalable Vector Graphics", "Graphics Markup Language" and "Simple Interaction File" are supported. You can input string type value such as "svg", "gml" or "sif".


=item B<Following  4 options are for Graph::Layout::Aesthetic module which determines coordinates of the objects. In detail, see Graph::Layout::Aesthetic document on CPAN or simply type "perldoc Graph::Layout::Aesthetic" on command line.>

=item knr => I<Float>

This option defines node repulsion on spring graph draw algorithm. Default: 1.

=item kmel => I<Float>

This option defines minimum edge length. Default: 1.

=item kner => I<Float>

This option defines node edge repulsion. Default: 1.

=item kmei2 => I<Float>

This option defines minimum edge intersection. Default: 0.


=item B<Following 3 options defines the graphical output of the sizing attributes.>

=item -width => I<Float>

This option defines the graphics width. Default: 1000.

=item -height => I<Float>

This option defines the graphics height. Default: 1000.

=item -margin => I<Float>

This option defines the graphics object margin from the border of the field. Default: 100.


=item B<Following are the general options for graphical output.>

=item -no_direction => I<Boolean>

This option defines the drawing of the graph network as directional or not. Default: 1 (No direction.)

=item -no_node_label => I<Boolean>

This option defines whether to display the nodes labels or not. Default: 0 (Display node labels.)

=item -no_edge_label => I<Boolean>

This option defines whether to display the edges labels or not. Default: 0 (Display edge labels.)

=item -dual_arrow_spreads => I<Float>

This option defines the width between dual directed edges. The applied value will determine the width size between the 2 arrows. Default: 2.

=item -rotation => I<Float>

This option defines rotation angle of the network. Default: 0.

=item -object_size => I<Float>

This option change each object size magnification ratio. You can use this when the object size is too large for the network. This option changes node width, stroke-width and edge stroke-width at once. Default: 1.

=item -label_size => I<Float>

This option defines the label size which is similar to -object_size. Default: 1.

B<Example:>
  $str->out('ribosome.svg',
            -object_size => 4,
            -label_size => 3,
            -no_edge_label => 1,
            );


=back



=head1 CONFIGURATION AND ENVIRONMENT

eXpanda requires no configuration files or environment variables.


=head1 DEPENDENCIES

=list 4

=item Carp

=item Graph::Topology::Aesthetic

=item SVG

=item LWP::UserAgent;

=item SOAP::Lite;

=item XML::Twig;

=back

=head1 INCOMPATIBILITIES


None reported.


=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<t04632hn@sfc.keio.ac.jp>, or through the web interface at
L<http://medcd.iab.keio.ac.jp/expanda/>.


=head1 AUTHOR

Yoshiteru Negishi  C<< <po@sfc.keio.ac.jp> >>
Current maintenance (including this release) by Hiroyuki Nakamura C<<t04632hn@sfc.keio.ac.jp>>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Yoshiteru Negishi C<< <po@sfc.keio.ac.jp> >>.
Copyright (c) 2008, Hiroyuki Nakakura C<< <t04632hn@sfc.keio.ac.jp> >>.

This module is a free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perlartistic.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
