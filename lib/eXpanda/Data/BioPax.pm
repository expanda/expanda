package eXpanda::Data::BioPax;

use warnings;
use strict;
use Data::Dumper;
use XML::Twig;
use Carp;

#-----------------------------#
my ( $entity,
     $unif,
     $step,
     $Int ,
     $Interaction,
     $path,
   ) = ();
#-----------------------------#

sub _parse_biopax
  {
    my $self = shift;
    my $option = shift || 'level2';
    my $filepath = $$self{'-filepath'};

    my $Path = {
		'unif' => "/rdf:RDF/bp:unificationXref",
		'rela' => "/rdf:RDF/bp:relationshipXref",
		'publ' => "/rdf:RDF/bp:publicationXref",
		'node' => "/rdf:RDF/bp:physicalEntityParticipant",
		'edge' => "/rdf:RDF/bp:pathwayStep",
		'path' => "/rdf:RDF/bp:pathway",
	       };

    my $twig = new XML::Twig(
			     TwigHandlers => {
					      $$Path{'rela'} => \&unify,
					      $$Path{'unif'} => \&unify,
					      $$Path{'publ'} => \&unify,
					      $$Path{'node'} => \&entity,
					      $$Path{'edge'} => \&step,
					      $$Path{'path'} => \&pathway,
					     });

    $twig->parsefile($self->filepath()) or croak "Wrong FilePath";
    $twig->purge;

    my $new_entity = ReMakeEnt( $entity, $unif );
    $entity = ();
    my $new_step = ReMakeStep( $step );
    $step = ();

    $Interaction = Converter( $unif, $new_entity, $new_step, $path, $option );
    $$self{node} = $$Interaction{node};
    $$self{edge} = $$Interaction{edge};

    return $self;
}
#Below is Subs.

sub Converter
  {
    my ( $unif, $entity, $step, $path, $option ) = @_;
    $option = 'level2' unless $option;
    my $int;
    ## option ( level1, level2, level3, level4 ) do not use LEVEL1;
    ##CONVINE 3 Str.
    $$int{'node'} = $entity;

    my ( $control, $conversion, $path_hash ) = DevideStep($step, $path);

    if( $option eq 'level1' )
      {
	$$int{edge} = level1( $step );
      }
    elsif( $option eq 'level2' )
      {
	$$int{edge} = level2( $step, $control, $conversion, $path_hash, $unif );
      }
    elsif( $option eq 'level3' )
      {
	$$int{edge} = level3( $step );
      }
    elsif( $option eq 'level4' )
      {
	$$int{edge} = level4( $step, $path );
      }

    return $int;
  }

sub level1
  {
    my ( $step_org ) = @_;
    my $edge_set = ();
    my $interaction_set = ();
    my $catalysis_set = ();

    while(  my ( $key1, $str0 ) = each %{$step_org} )
      {
	while( my ( $key2, $str1) = each %{$str0} )
	  {
	    if( $key2 ne 'NEXT-STEP' and $key2 ne 'STEP-INTERACTIONS')
	      {
		$$interaction_set{$key2} = $str1;
		if( $key2 =~ /catalysis/ )
		  {
		    $$catalysis_set{$key2} = $str1;
		    my ( $BR ) = keys %{$$str1{CONTROLLED}};
		    $BR =~ s/^\#//g if $BR;
		    $$catalysis_set{$key2}{CONTROLLED} = $$str0{$BR} if $BR;
		  }
	      }
	  }
      }

    while( my ( $key1, $str0 ) = each %{$interaction_set} )
      {
	if( $key1 =~ /^biochemicalReaction/ or
	    $key1 =~ /transportWithBiochemicalReaction/ or
	    $key1 =~ /transport/ or $key1 =~ /complexAssembly/ )
	  {
	my @right = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$str0{'RIGHT'}};
	my @left = map{(my $x = $_ )  =~ s/^\#//g; $x } keys %{$$str0{'LEFT'}};
	    for my $l (@left)
	      {
		for my $r (@right)
		  {
		    $$edge_set{$r}{$l}{information} = 1 if $r and $l;
		  }
	      }
	  }
	elsif( $key1 =~ /^catalysis/ )
	  {
	    my @ctrler = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$str0{'CONTROLLER'}};
	    my @ctrled = map{(my $x = $_ )  =~ s/^\#//g; $x } keys %{$$str0{'CONTROLLED'}};
	    my ( @mod_ctrled_r, @mod_ctrled_l);
	    for my $ed (@ctrled)
	      {
		@mod_ctrled_r = map{(my $x = $_) =~ s/^\#//g; $x} keys %{$$interaction_set{$ed}{RIGHT}};
		@mod_ctrled_l = map{(my $x = $_) =~ s/^\#//g; $x} keys %{$$interaction_set{$ed}{LEFT}};
	      }
	    for my $er (@ctrler)
	      {
		for my $r (@mod_ctrled_r)
		  {
		    $$edge_set{$er}{$r}{information} = '1';
		  }
		for my $l (@mod_ctrled_l)
		  {
		    $$edge_set{$er}{$l}{information} = '1';
		  }
	      }
	  }
	elsif( $key1 =~ /^modulation/ )
	  {
	    my @ctrler = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$str0{'CONTROLLER'}};
	    my @ctrled = map{(my $x = $_ )  =~ s/^\#//g; $x } keys %{$$str0{'CONTROLLED'}};
	    my ( @mod_ctrled_r, @mod_ctrled_l, @mod_ctrl);
	    for my $ed (@ctrled)
	      {
		@mod_ctrl =  map{(my $x = $_) =~ s/^\#//g; $x} keys %{$$catalysis_set{$ed}{CONTROLLER}};
		@mod_ctrled_r = map{(my $x = $_) =~ s/^\#//g; $x} keys %{$$catalysis_set{$ed}{CONTROLLED}{RIGHT}};
		@mod_ctrled_l = map{(my $x = $_) =~ s/^\#//g; $x} keys %{$$catalysis_set{$ed}{CONTROLLED}{LEFT}};
	      }
	    for my $er (@ctrler)
	      {
		for my $r (@mod_ctrled_r)
		  {
		    $$edge_set{$er}{$r}{information} = '1';
		  }
		for my $l (@mod_ctrled_l)
		  {
		    $$edge_set{$er}{$l}{information} = '1';
		  }
		for my $fuck ( @mod_ctrl )
		  {
		    $$edge_set{$er}{$fuck}{information} = '1';
		  }
	      }
	  }
      }
    return $edge_set;
  }

sub DevideStep
  {
    my $step = shift;
    my $path = shift;
    my ( $control, $conversion ) = ();
    my $tmp_str;

    while( my ( $stp_id, $str ) = each %{$step} )
      {
	while( my ($p_id, $ref) = each %{$str} )
	  {
	    $$tmp_str{$p_id} = $ref unless $p_id eq 'NEXT-STEP' or $p_id eq 'STEP-INTERACTION';
	  }
      }

    while( my ( $step_id, $str0 ) = each %{$step} )
      {
	while( my ( $process_id, $str1 ) = each %{$str0})
	  {
	    if( $process_id =~ /biochemicalReaction/ or
	        $process_id =~ /transport/ or
	        $process_id =~ /complexAssembly/ or
		$process_id =~ /transportWithBiochemicalReaction/ )
	      {
		$$conversion{$process_id} = $str1;
	      }
	    elsif( $process_id =~ /catalysis/ or
		   $process_id =~ /modulation/ )
	      {
		my $newstr;
		my @ctrld = keys %{$$str1{CONTROLLED}};
		my ( @ctrld_r, @ctrld_l , @ctrlr_c );
		for(@ctrld)
		  {
		    $_ =~ s/^\#//g;
		    if( $_ =~ /biochemicalReaction/ or
		        $_ =~ /transport/ or
		        $_ =~ /complexAssembly/ )
		      {
			@ctrld_l = keys %{$$tmp_str{$_}{LEFT}};
			@ctrld_r = keys %{$$tmp_str{$_}{RIGHT}};
		      }
		    elsif( $_ =~ /catalysis/ )
		      {
			@ctrlr_c = keys %{$$tmp_str{$_}{CONTROLLER}};
			my @catalysis = keys %{$$tmp_str{$_}{CONTROLLED}};
			for my $c (@catalysis)
			  {
			    if( $c !~ /^\#/)
			      {
				@ctrld_l = $c;
				@ctrld_r = $c;
			      }
			    else
			      {
				$c =~ s/^\#//g;
				@ctrld_l = keys %{$$tmp_str{$c}{LEFT}};
				@ctrld_r = keys %{$$tmp_str{$c}{RIGHT}};
			      }
			  }
		      }
		    else
		      {
			@ctrld_l = $_;
			@ctrld_r = $_;
		      }
		  }
		$$control{$process_id} = $str1;
		$$control{$process_id}{"CTRLR-CATARYSIS"} = \@ctrlr_c if @ctrlr_c;
		$$control{$process_id}{"CTRL-RIGHT"} = \@ctrld_r;
		$$control{$process_id}{"CTRL-LEFT"} = \@ctrld_l;
		print "##ERROR## $process_id\n" unless @ctrld_l or @ctrld_r;
	      }
	  }
      }

    my $path_hash;

    while( my ( $path_id, $str00 ) = each %{$path} )
      {
	for my $cmp( @{$$str00{'PATHWAY-COMPONENTS'}} )
	  {
	    $$path_hash{$cmp} = $path_id;
	  }
      }
    return ( $control ,$conversion, $path_hash );
  }


sub level2
  {
    my ( $step,  $control, $conversion, $path, $unif ) = @_;
    my $edge_set = ();

    while( my ( $step_id, $str0 ) = each %{$step} )
      {
	while( my ( $process_id, $str1 ) = each %{$str0} )
	  {
	    my $information;

	    if( $process_id ne 'NEXT-STEP' and $process_id ne 'STEP-INTERACTIONS' )
	      {
		while ( my ( $key, $ref ) = each %{$str1} )
		  {
		    my @tmp_inf = ();
		    @tmp_inf = keys %{$ref} unless $key eq 'RIGHT' or $key eq 'LEFT' or $key eq 'CONTROLLER' or $key eq 'CONTROLLED' or $key =~ /CTRL||pathwayStep/;
		    if( $key eq 'XREF' )
		      {
			for(@tmp_inf){
			  s/^\#//g;
			  $$information{$$unif{$_}{'DB'}} = $$unif{$_}{'ID'} if $$unif{$_}{DB};
			}
		      }
		    else
		      {
			( $$information{$key} ) = $tmp_inf[0] if scalar( @tmp_inf ) == 1;
			$$information{$key}  = \@tmp_inf if scalar( @tmp_inf ) > 1;
		      }
		  }

	      }
	    $$information{'PATHWAY-STEP'} = $step_id;
	    $$information{'PATHWAY'} = $$path{$step_id};

	    if( $process_id eq 'NEXT-STEP' )
	      {
		my @steps;
		if( scalar( keys %{$$str1{'STEP-INTERACTIONS'}}) > 1 ){
		  @steps = keys %{$$str1{'STEP-INTERACTIONS'}};
		  for( @steps )
		    {
		      $_ =~ s/^\#//g;
		      if( /biochemicalReaction/ or /transport/ or /complexAssembly/)
			{
			  $$information{'INTERACTION'} = $_;
			  my @r = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$conversion{$_}{'RIGHT'}};
			  my @l = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$conversion{$_}{'LEFT'}};

			  for my $right (@r)
			    {
			      for my $left (@l)
				{
				  $$edge_set{$right}{$left} = $information;
				}
			    }
			}
		      elsif( /catalysis/ or /modulation/)
			{
			  $$information{'INTERACTION'} = $_;
			  my @ctrlr   = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$control{$process_id}{'CONTROLLER'}};
			  my @ctrld_r = map{(my $x = $_ ) =~ s/^\#//g; $x } @{$$control{$process_id}{'CTRL-RIGHT'}};
			  my @ctrld_l = map{(my $x = $_ ) =~ s/^\#//g; $x } @{$$control{$process_id}{'CTRL-LEFT'}};
			  my @ctrld_c = map{(my $x = $_ ) =~ s/^\#//g; $x } @{$$control{$process_id}{'CTRLR-CATARYSIS'}};
			  for my $er ( @ctrlr )
			    {
			      for my $c ( @ctrld_c )
				{
				  $$edge_set{$er}{$c} = $information;
				}
			      for my $r ( @ctrld_r )
				{
				  $$edge_set{$er}{$r} = $information;
				}
			      for my $l ( @ctrld_l )
				{
				  $$edge_set{$er}{$l} = $information;
				}
			    }
			  ( @ctrlr, @ctrld_r, @ctrld_l, @ctrld_c ) = ();
			}
		    }
		}
	      }
	    elsif( $process_id eq 'STEP-INTERACTIONS' )
	      {
		my @steps = keys %{$str1};
		  for( @steps )
		    {
		      $_ =~ s/^\#//g;
		      if( /biochemicalReaction/ or /transport/ or /complexAssembly/)
			{
			  $$information{'INTERACTION'} = $_;
			  my @r = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$conversion{$_}{'RIGHT'}};
			  my @l = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$conversion{$_}{'LEFT'}};

			  for my $right (@r)
			    {
			      for my $left (@l)
				{
				  $$edge_set{$right}{$left} = $information;
				}
			    }
			}
		      elsif( /catalysis/ or /modulation/)
			{
			  $$information{'INTERACTION'} = $_;
			  my @ctrlr   = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$control{$process_id}{'CONTROLLER'}};
			  my @ctrld_r = map{(my $x = $_ ) =~ s/^\#//g; $x } @{$$control{$process_id}{'CTRL-RIGHT'}};
			  my @ctrld_l = map{(my $x = $_ ) =~ s/^\#//g; $x } @{$$control{$process_id}{'CTRL-LEFT'}};
			  my @ctrld_c = map{(my $x = $_ ) =~ s/^\#//g; $x } @{$$control{$process_id}{'CTRLR-CATARYSIS'}};
			  for my $er ( @ctrlr )
			    {
			      for my $c ( @ctrld_c )
				{
				  $$edge_set{$er}{$c} = $information;
				}
			      for my $r ( @ctrld_r )
				{
				  $$edge_set{$er}{$r} = $information;
				}
			      for my $l ( @ctrld_l )
				{
				  $$edge_set{$er}{$l} = $information;
				}
			    }
			  ( @ctrlr, @ctrld_r, @ctrld_l, @ctrld_c ) = ();
			}
		    }
	      }
	    elsif( $process_id =~ /biochemicalReaction/ or
		   $process_id =~ /transport/)
	      {
		my @right = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$str0{'RIGHT'}};
		my @left = map{(my $x = $_ )  =~ s/^\#//g; $x } keys %{$$str0{'LEFT'}};
		$$information{'INTERACTION'} = $process_id;
		for my $l (@left)
		  {
		    for my $r (@right)
		      {
			$$edge_set{$r}{$l} = $information if $r and $l;
		      }
		  }
	      }
	    elsif( $process_id =~ /catalysis/ or
		   $process_id =~ /modulation/)
	      {
		$$information{'INTERACTION'} = $process_id;
		my @ctrlr   = map{(my $x = $_ ) =~ s/^\#//g; $x } keys %{$$control{$process_id}{'CONTROLLER'}};
		my @ctrld_r = map{(my $x = $_ ) =~ s/^\#//g; $x } @{$$control{$process_id}{'CTRL-RIGHT'}};
		my @ctrld_l = map{(my $x = $_ ) =~ s/^\#//g; $x } @{$$control{$process_id}{'CTRL-LEFT'}};
		my @ctrld_c = map{(my $x = $_ ) =~ s/^\#//g; $x } @{$$control{$process_id}{'CTRLR-CATARYSIS'}};

		for my $er ( @ctrlr )
		  {
		    for my $c ( @ctrld_c )
		      {
			$$edge_set{$er}{$c} = $information;
		      }
		    for my $r ( @ctrld_r )
		      {
			$$edge_set{$er}{$r} = $information;
		      }
		    for my $l ( @ctrld_l )
		      {
			$$edge_set{$er}{$l} = $information;
		      }
		  }
	      }
	    #NEXT-STEP lator reading.
	  }
      }

    return $edge_set;
  }

sub ReMakeEnt
  {
    my ( $ent, $unif, $switch ) = @_;
    $switch = 0 if !$switch;
    my $node_set = ();
    my $ent_set = ();

    while( my ( $ent_id, $str ) = each %{$ent} )
      {
	while( my ( $key, $val ) = each %{$str} )
	  {
	    if( $key eq 'CELLULAR-LOCATION' )
	      {
		if( $$val{'openControlledVocabulary'} )
		  {
		    my ( $tmp_id, $term, $xref ) = ();

		    while( my ( $local, $str0 ) = each %{$val} )
		      {
			while( my ( $value, $one ) = each %{$str0} )
			  {
			    $tmp_id = $value if $local eq 'openControlledVocabulary';
			    $term = $value if $local eq 'TERM';
			    push @{$xref}, $value if $local eq 'XREF';
			  }
		      }
		    $$ent_set{$tmp_id}{TERM} = $term;
		    if( scalar(@{$xref}) == 1 )
		      {
			$$ent_set{$tmp_id}{XREF} = $$xref[0];
		      }
		    else
		      {
			$$ent_set{$tmp_id} = \@{$xref};
		      }
		    $$node_set{$ent_id}{information}{$key} = $term;
		    for( @{$xref} )
		      {
			s/^\#//g;
			$$node_set{$ent_id}{information}{$$unif{$_}{DB}} = $$unif{$_}{ID} if $$unif{$_};
		      }
		    ( $tmp_id, $term, $xref ) = ();
		  }
		else
		  {
		    while( my ( $ref, $one ) = each %{$$val{'CELLULAR-LOCATION'}} )
		      {
			$$node_set{$ent_id}{information}{$key} = $ref;
		      }
		  }
	      }
	    elsif( $key eq 'STOICHIOMETRIC-COEFFICIENT' )
	      {
		while( my ( $ref, $one ) = each %{$$val{'STOICHIOMETRIC-COEFFICIENT'}} )
		  {
		    $$node_set{$ent_id}{information}{$key} = $ref;
		  }
	      }
	    elsif( $key eq 'PHYSICAL-ENTITY' )
	      {
		if( $$val{'STRUCTURE-DATA'} and $$val{'STRUCTURE-FORMAT'} )
		  {
		    my ( $tmp_id , $tmp_type);
		    while( my ( $val2, $zero ) = each %{$$val{'STRUCTURE-FORMAT'}} )
		      {
			if( $val2 =~ /^\w.+\d{5}$/ )
			  {
			    $$ent_set{$val2}{'STRUCTURE-DATA'} = ();
			    $tmp_id = $val2;
			  }
			else
			  {
			    $$node_set{$ent_id}{'information'}{'STRUCTURE-FORMAT'} = $val2;
			    $tmp_type = $val2;
			  }
		      }

		    while( my ( $val3, $zero ) = each %{$$val{'STRUCTURE-DATA'}} )
		      {
			$$ent_set{$tmp_id}{'STRUCTURE-DATA'} = $val3;
			$$ent_set{$tmp_id}{'STRUCTURE-FORMAT'} = $tmp_type;
		      }
		  }
		### PHISICAL-ENTITY SECTION. ###
		while( my ( $key2, $str3 ) = each %{$val} )
		  {
		    if( $key2 eq 'XREF' )
		      {
			while( my ( $xref, $one ) = each %{$str3} )
			  {
			    if( $xref ne $ent_id )
			      {
				$xref =~ s/^\#//g;
				$$node_set{$ent_id}{'information'}{$$unif{$xref}{'DB'}} = $$unif{$xref}{'ID'} if $$unif{$xref};
			      }
			  }
		      }
		    elsif($key2 eq 'NAME')
		      {
			while( my ( $name, $one ) = each %{$str3} )
			  {
			    if( $name ne $ent_id )
			      {
				if( $name =~ /^\w.+\d{5}$/ )
				  {
				    $$ent_set{$name}{'PHYSICAL-ENTITY'} = $val;
				  }
				else
				  {
				    $$node_set{$ent_id}{'information'}{$key2} = $name;
				    $$node_set{$ent_id}{'label'} = $name;              ######## SET LABEL ########
				  }
			      }
			  }
		      }
		    elsif( $key2 eq 'PHYSICAL-ENTITY' )
		      {
			while( my ( $tmp_ref, $one ) = each %{$str3} )
			  {
			    if( $tmp_ref ne $ent_id )
			      {
				$$node_set{$ent_id} = $tmp_ref;
			      }
			  }
		      }
		    else
		      {
			my $key_val;
			while( my ( $vals, $one ) = each %{$str3} )
			  {
			    push @{$key_val}, $vals;
			  }
			$$node_set{$ent_id}{'information'}{$key2} = $$key_val[0] if scalar(@{$key_val}) == 1;
			$$node_set{$ent_id}{'information'}{$key2} = $key_val if scalar(@{$key_val}) > 1;
		      }
		  }
	      }
	  }
      }

    return $node_set if $switch == '1';

    while( my ( $ent_id, $one ) = each %{$node_set} )
      {
	if( ref($one) ne 'HASH' )
	  {
	    $one =~ s/^\#//g;
	    my $tmp_ref;
	    $$tmp_ref{$one} = $$ent_set{$one};
	    $$node_set{$ent_id} = ReMakeEnt($tmp_ref, $unif, '1');
	  }
      }

    return $node_set;
  }

sub ReMakeStep
  {
    my ( $step ) = @_;

    while( my ( $step_id, $ref1 ) = each %{$step} )
      {

	delete $$ref1{$step_id} if $$ref1{$step_id};
	$ref1 = ReMakeStep( $ref1 ) if $step_id =~ /\w+?\d{5}$/;
	
	while( my ( $key, $ref2 ) = each %{$ref1} )
	  {
	    if( $key eq 'NEXT-STEP')
	      {
		delete $$ref2{$step_id} if $$ref2{$step_id};
		if( $$ref2{'STEP-INTERACTIONS'}{$step_id} )
		  {
		    delete $$ref2{'STEP-INTERACTIONS'}{$step_id};
		  }
	      }
	  }
      }
    return $step;
  }

sub pathway
  {
    my ( $tree, $elem ) = @_;
    my @components = $elem->children('bp:PATHWAY-COMPONENTS');
    my $path_id = $elem->att('rdf:ID');
    for(@components)
      {
	if($_->first_child('bp:pathwayStep'))
	  {
	    my $step_temp = SearchChild($_->first_child('bp:pathwayStep'));
	    my $step_id =  $_->first_child('bp:pathwayStep')->att('rdf:ID');
	    $$step{$step_id} = MakeStpStr_LE( $step_temp );
	    push @{$$path{$path_id}{'PATHWAY-COMPONENTS'}}, $step_id;
	  }
	else
	  {
	    my $step_id = $_->att('rdf:resource');
	    $step_id =~ s/^\#//g;
	    push @{$$path{$path_id}{'PATHWAY-COMPONENTS'}}, $step_id;
	  }
      }
  }

sub unify
  {
    my ($tree, $elem) = @_;
    eval{
      $$unif{$elem->att('rdf:ID')}{ID} = $elem->first_child('bp:ID')->text;
      $$unif{$elem->att('rdf:ID')}{DB} = $elem->first_child('bp:DB')->text;
    };
    $tree->purge();
  }

sub entity
  {
    my ($tree, $elem ) = @_;
    my ($entity_temp, $ent_id, $entity_second ) = ();
    $ent_id =  $elem->att('rdf:ID');
    $entity_temp = SearchChild($elem);
    $$entity{$ent_id} = MakeEntStr( $entity_temp );
    $tree->purge();
  }

sub step
  {
    my ($tree, $elem) = @_;
    my $step_temp = SearchChild($elem);
    my $stp_id =  $elem->att('rdf:ID');
    $$step{$stp_id} = MakeStpStr_LE( $step_temp );
    $tree->purge();
  }

sub MakeEntStr
  {
    my ($tmp, $cashe, $str ) = @_;
    if( ref $tmp eq 'HASH' ){
      while( my ( $key1, $str1 ) = each %{$tmp} ){
	$cashe = () if $key1 eq 'bp:CELLULAR-LOCATION' or $key1 eq 'bp:PHYSICAL-ENTITY' or $key1 eq 'bp:STOICHIOMETRIC-COEFFICIENT';
	if( $key1 eq 'att' ){
	  $$str{ "$$cashe[0]" }{ "$$cashe[$#{$cashe}]" }{$$str1{'val'}} = 1 if $$str1{'val'} and $$str1{val} !~ /^http/;
	}elsif( $key1 eq 'text' ){
	  $$str{ "$$cashe[0]" }{ "$$cashe[$#{$cashe}]" }{$str1} = 1 if $str1;
	}elsif( $key1 =~ /^bp:(.+)/ ){
	  push @{$cashe}, $1;
	  $str = MakeEntStr( $str1, $cashe, $str );
	}elsif( $key1 =~ /\d+/ ){
	  $str = MakeEntStr( $str1, $cashe, $str );
	}
      }
    }
    return $str;
  }

sub MakeStpStr_LE
  {
    my ($tmp, $cashe, $str ) = @_;
    if( ref $tmp eq 'HASH' )
      {
	while( my ( $key1, $str1 ) = each %{$tmp} )
	  {
	    #	$cashe = () if $key1 eq 'bp:NEXT-STEP' or $key1 eq 'bp:STEP-INTERACTIONS';
	    $cashe = () if
	      $key1 eq 'bp:biochemicalReaction' or
		$key1 eq 'bp:catalysis'          or
		  $key1 eq 'bp:modulation'         or
		    $key1 eq 'bp:complexAssembly'   or
		      $key1 eq 'bp:transport'        or
			$key1 eq 'bp:transportWithBiochemicalReaction';


	    if( $key1 eq 'att' )
	      {
		if( $$str1{val} and $cashe and $$str1{'val'} !~ /^http/ and $$cashe[$#{$cashe}] ne $$cashe[0] )
		  {
		    $$str{ "$$cashe[0]" }{ "$$cashe[$#{$cashe}]" }{$$str1{'val'}} = 1;
		  }
		elsif( $$str1{val} and $cashe and $$str1{'val'} !~ /^http/ and $$cashe[$#{$cashe}] eq $$cashe[0])
		  {
		    $$str{ "$$cashe[0]" }{$$str1{'val'}} = 1;
		  }

	      }
	    elsif( $key1 eq 'text' )
	      {
		$$str{ "$$cashe[0]" }{ "$$cashe[$#{$cashe}]" }{$str1} = 1 if $str1 and $$cashe[0] ne $$cashe[$#{$cashe}];
	      }
	    elsif( $key1 eq 'bp:pathwayStep' )
	      {
		$$step{$$str1{att}{val}} = MakeStpStr_LE( $str1, $cashe );
		$$str{"NEXT-STEP"}{"#".$$str1{att}{val}} = 1;
	      }
	    elsif( $key1 =~ /^bp:(.+)/ )
	      {
		if($1 eq 'modulation' or
		   $1 eq 'catalysis'  or
		   $1 eq 'biochemicalReaction' or
		   $1 eq 'complexAssembly' or
		   $1 eq 'transport' or
		   $1 eq 'transportWithBiochemicalReaction')
		  {
		    push @{$cashe}, $$str1{att}{val};
		    $str = MakeStpStr_LE( $str1, $cashe, $str );
		  }
		elsif($1 eq 'CONTROLLED')
		  {
		    for( 1..10 )
		      {
			if( $$str1{$_}{"bp:biochemicalReaction"} ){
#			  push @{$cashe}, $$str1{$_}{'bp:biochemicalReaction'}{att}{val};
#			  $$str{ "$$cashe[0]" }{ "$$cashe[$#{$cashe}]" }{'CONTROLLED'}{$$str1{$_}{'bp:biochemicalReaction'}{att}{val}} = 1;
			  $$str1{att}{val} = "#".$$str1{$_}{'bp:biochemicalReaction'}{att}{val};
			}
		      }
		    push @{$cashe}, $1;
		    $str = MakeStpStr_LE( $str1, $cashe, $str );
		  }
		else
		  {
		    push @{$cashe}, $1;
		    $str = MakeStpStr_LE( $str1, $cashe, $str );
		  }
	      }
	    elsif( $key1 =~ /\d+/ )
	      {
		$str = MakeStpStr_LE( $str1, $cashe,  $str );
	      }
	    
	  }

      }

    return $str;
  }

sub SearchChild
  {
    my ( $elem ) = @_;
    my @children = ();
    my ( $name, $att, $return ) = ();
    my $inclement = 0;
    eval{
      @children = $elem->children;
      $name = $elem->name();
    };
    carp $@."\n" if $@;
    eval{
      while(my ($name, $val) = each %{$elem->atts}){
	$$att{key} = $name;
	$$att{val} = $val;
      }
    };
    if(@children){
      foreach my $child (@children){
	if( $child->name() eq "#PCDATA"){
	  $return = SearchChild( $child );
	}else{
	  if($#children == 0){
	    $$return{$child->name()} = SearchChild( $child );
	  }else{
	    $$return{$child->name()}{$inclement} = SearchChild( $child );
	    $inclement++;
	  }
	}
      }
      $$return{att} = { key => $$att{key},
		        val => $$att{val},};
      return $return;
    }else{
      my $text;
      eval{
	$text = $elem->text();
      };
      carp "$@" if $@;
      return { att => $att,
	       text => $text,};
    }
  }

1;
