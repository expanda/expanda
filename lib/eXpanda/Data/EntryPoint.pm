package eXpanda::Data::EntryPoint;

# CPAN Module #
use strict;
use warnings;
use Carp;
use XML::Twig;
use Data::Dumper;

# eXpanda Module #
use eXpanda::Util;
use eXpanda::Data::DbSupport;
use eXpanda::Data::BioPax;
use eXpanda::Data::PSIMI;

sub _parse_file {
  no strict 'refs';
  eXpanda::Util::extend 'eXpanda', 'eXpanda::Data::EntryPoint';
  eXpanda::Util::extend 'eXpanda', 'eXpanda::Data::DbSupport', '_check_file';
  eXpanda::Util::extend 'eXpanda', 'eXpanda::Data::PSIMI' , ['psimi_2_5'];
  eXpanda::Util::extend 'eXpanda', 'eXpanda::Data::KGML', ['_parse_kgml'];

  my $self = shift;
  bless $self, 'eXpanda';

  $self->_check_file();
  my $method = $self->{method};
  print "[debug] $method\n" if $eXpanda::DEBUG;
  $self->$method();
  $self->MakeLabel();
  $self->Index2Info();

  return $self;
}

sub Index2Info
  {
    my $self = shift;
    my $newinfo = ();

    while( my ($node_id, $ref0) = each %{$$self{node}} )
      {
	while( my ($db, $ref1) = each %{$$ref0{index}})
	  {
	    my @ids = keys( %{$ref1} );
	    if( scalar(@ids) == 1 )
	      {
		$$newinfo{$node_id}{$db} = $ids[0];
	      }
	    else
	      {
		$$newinfo{$node_id}{$db} = \@ids;
	      }
	  }
	while( my ( $i_key, $ref2 ) = each %{$$ref0{information}} )
	  {
	    my @keys;
	    if(ref($ref2) eq "ARRAY")
	      {
		@keys = @{$ref2}; #if $ref2 is scalar...
		if(scalar(@keys) == 1)
		  {
		    $$newinfo{$node_id}{$i_key} = $keys[0];
		  }
		else
		  {
		    $$newinfo{$node_id}{$i_key} = \@keys;
		  }
	      }
	    else
	      {
		$$newinfo{$node_id}{$i_key} = $ref2;
	      }
	  }
      }
    while( my ($node_id, $ref0) = each %{$newinfo} )
      {
	while( my ($db, $ref1) = each %{$ref0} )
	  {
	    $$self{node}{$node_id}{information}{$db} = $ref1;
	  }
      }

    return $self;
  }


sub MakeLabel {
  my $self = shift;

  while( my ($entry, $one) = each %{$$self{node}} ){
    while(my ( $id_spec, $two ) = each %{$$one{index}}){
	    while(my ($id_val, $val) = each %{$two}){
		if($id_spec =~ /(?:SWP|Swiss-Prot|swissprot)/i){
		    $$self{node}{$entry}{index}{'SWISS-PROT'}{$id_val} = $val;
		    delete $$self{node}{$entry}{index}{$id_spec} if $id_spec ne 'SWISS-PROT';
		    $$self{desc}{database_index}{'SWISS-PROT'} = $val;
		    delete $$self{desc}{database_index}{$id_spec} if $id_spec ne 'SWISS-PROT';
		  }elsif($id_spec =~ /GI/i){
		    $$self{node}{$entry}{index}{GI}{$id_val} = $val;
		    delete $$self{node}{$entry}{index}{$id_spec} if $id_spec ne 'GI';
		  }elsif($id_spec =~ /PIR/i){
		    $$self{node}{$entry}{index}{PIR}{$id_val} = $val;
		    delete $$self{node}{$entry}{index}{$id_spec} if $id_spec ne 'PIR';
		  }elsif($id_spec =~ /(?:uniprot|uni-prot)/i){
		    $$self{node}{$entry}{index}{uniprot}{$id_val} = $val;
		    delete $$self{node}{$entry}{index}{$id_spec} if $id_spec ne 'uniprot';
		  }
	      }
	  }
    $$self{node}{$entry}{label} = $$self{node}{$entry}{information}{shortLabel} || $$self{node}{$entry}{information}{names}{shortLabel};
    $$self{node}{$entry}{label} = $$self{node}{$entry}{information}{fullName} unless $$self{node}{$entry}{label};
  }
  return $self;
}

### subroutines for Parsing Biopax Level 1 ###

sub Biopax1 {
  my $self = shift;

  eXpanda::Util::extend 'eXpanda', 'eXpanda::Data::BioPax' , ['_parse_biopax'];
  $self->_parse_biopax;
  return $self;
}

### subroutines for Parsing Biopax Level 2 ###

sub Biopax2 {
  my $self = shift;
  #  carp "[TODO] This version of eXpanda cannot import BioPax Level 2. Sorry.";
  eXpanda::Util::extend 'eXpanda', 'eXpanda::Data::BioPax' , '_parse_biopax';
  $self->_parse_biopax;
  return $self;
}

### subroutines for Parsing PSI-MI Level 1 ###
sub MakeHandler {
  my $prestr = shift;
  my $torPath = '/entrySet/entry/interactorList/proteinInteractor';
  my $tionPath = '/entrySet/entry/interactionList/interaction';
  my $sub_name_tor = "tor_".$prestr->get_method();
  my $sub_name_tion = "tion_".$prestr->get_method();
  my $twig = new XML::Twig(
			   TwigRoots => { 'entrySet/entry' => 1 },
			   TwigHandlers => {
					    $torPath => \&$sub_name_tor,
					    $tionPath => \&$sub_name_tion,
					   });
  return $twig;
}

sub dip {
    our $prestr = shift;
    my $twig = $prestr->MakeHandler();
    $twig->parsefile($$prestr{filepath});
    $twig->purge;
    return $prestr;

    sub tor_dip {
	my ( $tree, $elem ) = @_;
	$$prestr{desc}{n_of_node}++;

	my $proid = $elem->att('id');
	$$prestr{node}{$proid}{'information'}{'fullName'} = $elem->first_descendant('fullName')->text;
	$$prestr{node}{$proid}{'information'}{'ncbiTaxId'} = $elem->first_child('organism')->att('ncbiTaxId');
	my $ref = $elem->first_child('xref')->first_child('primaryRef');
	eval { 
	    $$prestr{node}{$elem->att('id')}{'index'}{$ref->att('db')}{$ref->att('id')} = 1; 
	    $$prestr{desc}{'database_index'}{$ref->att('db')} = 1;
	};
	my @s_ref;
	eval { @s_ref = $elem->descendants('secondaryRef');};
	foreach(@s_ref){
	    $$prestr{node}{$elem->att('id')}{'index'}{$_->att('db')}{$_->att('id')} = 2;
	    	    $$prestr{desc}{'database_index'}{$_->att('db')} = 2;
	}
	$tree->purge;
    }

    sub tion_dip {
	my ( $tree, $elem ) = @_;
	my ( $Participant,
	     @Participants,
	     $Intid,
	     $Partinfo,
	     ) = ();
	my $Information = {
	    'pubmedId' => undef,
	    'interactionDetection' => undef,
	    'InteractionId' => undef,
	};
	$$prestr{desc}{n_of_edge}++;

	$$Information{'InteractionId'} = $elem->first_child('xref')->first_child('primaryRef')->att('id');
	$$Information{'interactionDetection'} = $elem->first_descendant('interactionDetection')->first_descendant('shortLabel')->text;
	eval {$$Information{'pubmedId'} = $elem->first_descendant('bibref')->first_descendant('primaryRef')->att('id');};
	my @partList = $elem->descendants('proteinParticipant');
	foreach(@partList){
	    push @Participants, $_->first_child('proteinInteractorRef')->att('ref');
	}

	$$Information{'Part'} = undef;
	$$prestr{edge} = List2BinaryInteraction(\@Participants, $Information, $$prestr{edge});
	$tree->purge;
    }
}

sub MINT {
    our $prestr = shift;
    my $twig = $prestr->MakeHandler();
    $twig->parsefile($$prestr{filepath});
    $twig->purge;

    return $prestr;

    sub tor_MINT {
	my ( $tree, $elem ) = @_;
	$$prestr{desc}{n_of_node}++;
	$$prestr{node}{$elem->att('id')}{'information'}{'shortLabel'} = $elem->first_descendant('shortLabel')->text;
	$$prestr{node}{$elem->att('id')}{'information'}{'organismName'} = $elem->first_descendant('fullName')->text;
	$$prestr{node}{$elem->att('id')}{'information'}{'ncbiTaxId'} = $elem->first_child('organism')->att('ncbiTaxId');
	my $ref = $elem->first_child('xref')->first_child('primaryRef');
	eval { 
	    $$prestr{node}{$elem->att('id')}{'index'}{$ref->att('db')}{$ref->att('id')} = 1;
	    $$prestr{desc}{'database_index'}{$ref->att('db')} = 1;
	};
	my @s_ref;
	eval { @s_ref = $elem->descendants('secondaryRef'); };
	foreach(@s_ref){
	    $$prestr{node}{$elem->att('id')}{'index'}{$_->att('db')}{$_->att('id')} = 2;
	    $$prestr{desc}{'database_index'}{$_->att('db')} = 2;
	}
	$tree->purge;
    }

    sub tion_MINT {
      my ( $tree, $elem ) = @_;
      my ( $Participant,
	   @Participants,
	   $Intid,
	   $Partinfo,
	 ) = ();
      my $Information = {
			 'shortLabel' => undef,
			 'pubmedId' => undef,
			 'experimentRef' => undef,
			 'InteractionType' => undef,
			 'InteractionId' => undef,
			 'attribution' => undef,
			};
      $$prestr{desc}{n_of_edge}++;
      $$Information{'InteractionId'} = $elem->first_child('xref')->first_child('primaryRef')->att('id');
      eval {$$Information{'pubmedId'} = $elem->first_child('interacitonType')->first_descendant('secondaryref')->att('id');};
      eval {$$Information{'experimentRef'} = $elem->first_descendant('experimentRef')->att('ref');};
      eval {$$Information{'InteractionType'} = $elem->first_child('interactionType')->first_descendant('shortLabel')->text;};
      eval {$$Information{'shortLabel'} = $elem->first_descendant('shortLabel')->text;};
      my @partList = $elem->descendants('proteinParticipant');
      foreach(@partList){
	push @Participants, $_->first_child('proteinInteractorRef')->att('ref');
	$$Partinfo{$_->first_child('proteinInteractorRef')->att('ref')}{'Role'} = $_->first_child('role')->text;
	$$Partinfo{$_->first_child('proteinInteractorRef')->att('ref')}{'isTaggedProtein'} = $_->first_child('isTaggedProtein')->text;
	$$Partinfo{$_->first_child('proteinInteractorRef')->att('ref')}{'isOverexpressedProtein'} = $_->first_child('isOverexpressedProtein')->text;
      }

      $$Information{'Part'} = $Partinfo;
      $$prestr{edge} = List2BinaryInteraction(\@Participants, $Information, $$prestr{edge});
      $tree->purge;
    }
  }

sub HPRD {
    our $prestr = shift;
    my $twig = $prestr->MakeHandler();
    $twig->parsefile($$prestr{filepath});
    $twig->purge;
    return $prestr;

    sub tor_HPRD {
	my ( $tree, $elem ) = @_;
	$$prestr{desc}{n_of_node}++;
	$$prestr{node}{$elem->att('id')}{'information'}{'shortLabel'} = $elem->first_descendant('shortLabel')->text;
	$$prestr{node}{$elem->att('id')}{'information'}{'ncbiTaxId'} = $elem->first_child('organism')->att('ncbiTaxId');
	$$prestr{node}{$elem->att('id')}{'information'}{'organismName'} = $elem->first_descendant('fullName')->text;
	eval{$$prestr{node}{$elem->att('id')}{'information'}{'sequence'} = $elem->first_child('sequence')->text;};
	my $ref;
	eval{$ref = $elem->first_child('xref')->first_child('primaryRef');
	      $$prestr{node}{$elem->att('id')}{'index'}{$ref->att('db')}{$ref->att('id')} = 1;
	      $$prestr{desc}{'database_index'}{$ref->att('db')} = 1;};
	$$prestr{node}{$elem->att('id')}{'index'} = undef if $@; 
	my @s_ref;
	eval { @s_ref = $elem->descendants('secondaryRef'); };
	foreach(@s_ref){
	    $$prestr{node}{$elem->att('id')}{'index'}{$_->att('db')}{$_->att('id')} = 2;
	    $$prestr{desc}{'database_index'}{$_->att('db')} = 2;
	}
	$tree->purge;
    }
    
    sub tion_HPRD {
	my ( $tree, $elem ) = @_;
	my ( $Participant,
	     @Participants,
	     $Intid,
	     $Partinfo,
	     ) = ();
	my $Information = {
	    'pubmedId' => undef,
	    'interactionDetection' => undef,
	    'InteractionId' => undef,
	};
	$$prestr{desc}{n_of_edge}++;
	$$Information{'InteractionId'} = $elem->first_child('xref')->first_child('primaryRef')->att('id');
	eval {$$Information{'pubmedId'} = $elem->first_child('interacitonType')->first_descendant('secondaryref')->att('id');};
	eval {$$Information{'interactionDetection'} = $elem->first_descendant('experimentDescription')->first_child('interactionDetection')->first_descendant('fullName')->text;};
	my @partList = $elem->descendants('proteinParticipant');
	foreach(@partList){
	    push @Participants, $_->first_child('proteinInteractorRef')->att('ref');
	}

	$$Information{'Part'} = undef;
	$$prestr{edge} = List2BinaryInteraction(\@Participants, $Information, $$prestr{edge});
	$tree->purge;
    }
}

sub IntAct {
    our $prestr = shift;
    my $twig = $prestr->MakeHandler();
    $twig->parsefile($$prestr{filepath});
    $twig->purge;    
    return $prestr;

    sub tor_IntAct {
	my ( $tree, $elem ) = @_;
	$$prestr{desc}{n_of_node}++;
	$$prestr{node}{$elem->att('id')}{'information'}{'shortLabel'} = $elem->first_descendant('shortLabel')->text;
	$$prestr{node}{$elem->att('id')}{'information'}{'fullName'} = $elem->first_descendant('fullName')->text;
	$$prestr{node}{$elem->att('id')}{'information'}{'ncbiTaxId'} = $elem->first_child('organism')->att('ncbiTaxId');
	eval{$$prestr{node}{$elem->att('id')}{'information'}{'sequence'} = $elem->first_child('sequence')->text;};
	
	my $ref = $elem->first_child('xref')->first_child('primaryRef');
	eval {
	  $$prestr{node}{$elem->att('id')}{'index'}{$ref->att('db')}{$ref->att('id')} = 1;
	  $$prestr{desc}{'database_index'}{$ref->att('db')} = 1;
	};
	
	my @s_ref;
	eval { @s_ref = $elem->descendants('secondaryRef'); };
	foreach(@s_ref){
	    $$prestr{node}{$elem->att('id')}{'index'}{$_->att('db')}{$_->att('id')} = $_->att('secondary') if $_->att('secondary');
	    $$prestr{node}{$elem->att('id')}{'index'}{$_->att('db')}{$_->att('id')} = 2;
	    $$prestr{desc}{'database_index'}{$_->att('db')} = 2;
	}

	$tree->purge;
    }
    
    sub tion_IntAct {
	my ( $tree, $elem ) = @_;
	my ( $Participant,
	     @Participants,
	     $Intid,
	     $Partinfo,
	     ) = ();
	my $Information = {
	    'pubmedId' => undef,
	    'experimentRef' => undef,
	    'InteractionType' => undef,
	    'fullName' => undef,
	    'InteractionId' => undef,
	};
	$$prestr{desc}{n_of_edge}++;
	$$Information{'InteractionId'} = $elem->first_child('xref')->first_child('primaryRef')->att('id');
	eval {$$Information{'pubmedId'} = $elem->first_child('interacitonType')->first_descendant('secondaryref')->att('id');};
	eval {$$Information{'experimentRef'} = $elem->first_descendant('experimentRef')->att('ref');};
	$$Information{'InteractionType'} = $elem->first_child('interactionType')->first_descendant('fullName')->text;
	$$Information{'Name'} = $elem->first_descendant('fullName')->text;
	my @partList= $elem->descendants('proteinParticipant');
	@partList = $elem->children('proteinParticipant') unless $partList[0];
	foreach(@partList){
	    push @Participants, $_->first_child('proteinInteractorRef')->att('ref');
	    $$Partinfo{$_->first_child('proteinInteractorRef')->att('ref')}{'Role'} = $_->first_child('role')->text;
	}

	$$Information{'Part'} = $Partinfo;
	$$prestr{edge} = List2BinaryInteraction(\@Participants, $Information, $$prestr{edge});
	$tree->purge;
    }
}

{
  no warnings;
  
  sub List2BinaryInteraction
    {
      my ( $Parts, $Information, $str ) = @_;

      return $str if scalar(@{$Parts}) == 0;

      my $selected = shift @{$Parts};

      for(@{$Parts})
	{
	  while(my ($infoName, $val) = each %{$Information})
	    {
	      if( $infoName ne 'Part' )
		{
		  if( !$$str{$selected}{$_}{information}{$infoName} )
		    {
		      $$str{$selected}{$_}{information}{$infoName} = $val;
		    }
		  else
		    {
		      if( ref ($$str{$selected}{$_}{'information'}{$infoName}) eq 'ARRAY' )
			{
			  push @{$$str{$selected}{$_}{'information'}{$infoName}}, $val;
			}
		      else
			{
			  my $tmp = $$str{$selected}{$_}{'information'}{$infoName};
			  $$str{$selected}{$_}{'information'}{$infoName} = [];
			  push @{$$str{$selected}{$_}{'information'}{$infoName}}, $tmp;
			  push @{$$str{$selected}{$_}{'information'}{$infoName}}, $val;
			}
		    }
		}
	    }
	  while(my ($id, $one) = each %{$$Information{'Part'}})
	    {
	      while (my ($infoName, $val) = each %{$one})
		{
		  $$str{$selected}{$_}{'information'}{$infoName}{$selected} = $val if $id eq $selected;
		  $$str{$selected}{$_}{'information'}{$infoName}{$_} = $val if $id eq $_;
		}
	    }
	}
      List2BinaryInteraction( $Parts, $Information, $str );
    }
}



1;


__END__
