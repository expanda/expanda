#!/usr/bin/perl
package eXpanda::Data::DbSupport;

use warnings;
use strict;
use Carp;
use XML::Twig;
use Data::Dumper; #To debug.
use SOAP::Lite;

sub _check_file
  {
    my $self = shift;
    my $db_spec = (IsPsimi($self->{filepath})) ?
      WhatDb( $self->{filepath} ) : IsSif($self->{filepath});

    $self->{method} = $db_spec;

    return $self;
  }

sub IsPsimi {
    my $filepath = shift;
    my $xmlns;
    my $is_xml;
    open FILE, $filepath or croak "cannot open file. $filepath";
    while(<FILE>){
	$_ =~ /xmlns="(.+?)"/;
	$xmlns = $1;
	if( $_ =~ /<?xml.+/i ){
	    $is_xml = 1;
	}
	last if $xmlns;
    }
    close FILE;
    return 1 if ($xmlns and $xmlns =~ /net:sf:psidev:mi/) or $is_xml == 1;
}

sub IsSif {
    my $filepath = shift;
    my $flag;
    open FILE, $filepath;
    while(<FILE>){
	return 'sif' if $_ =~ /^(?:.+?)\s..\s(?:.+?)$/ and close FILE;
    }
    close FILE;
}

sub WhatDb {
    my $filepath = shift;
    my $xin;
    my $biopax = 0;

    open FILE, $filepath;
    while(<FILE>){
	$_ =~ /xmlns:xin="(.+?)"/;
	$xin = $1;
	$biopax = 'Biopax1' if $_ =~ /http\:\/\/www\.biopax\.org\/release\/biopax-level1.owl/; 
	$biopax = 'Biopax2' if $_ =~ /http\:\/\/www\.biopax\.org\/release\/biopax-level2.owl/; 
    }
    close FILE;

    return 'dip' if $xin and $xin =~ /dip/;

    return $biopax if $biopax;

    my $Path = "entrySet/entry/source/names/shortLabel";
    my $entryset = "entrySet";

    our $db_spec;
    our $xmlns_and_version;

    my $twig = new XML::Twig(
			     TwigRoots => { "entrySet/entry/source" => 1},
			     TwigHandlers => {
					      $entryset => \&entryset,
					      $Path     => \&part,
					     });

    $twig->parsefile($filepath);
    $twig->purge;

    if ( $db_spec ) {
      return "MINT" if $db_spec =~ /mint/i;
      return "IntAct" if $db_spec =~ /European Bioinformatics Institute/i;
    }

    if ( $xmlns_and_version ) {
      if ( $xmlns_and_version->{xmlns} =~ /net:sf:psidev:mi/ ) {
	$db_spec = 'psimi_'.$xmlns_and_version->{'version'};
      }
      else {
	$db_spec = 'unsupported';
      }
      return $db_spec;
    }

    sub part {
	my ($tree, $elem) = @_;
	$db_spec = $elem->text;
	$tree->purge;
    }

    sub entryset {
      my ($tree, $elem) = @_;

      $xmlns_and_version->{'xmlns'} = $elem->att('xmlns');
      $xmlns_and_version->{'version'} = $elem->att('level')."_".$elem->att('version');
    }

}

### DataFromKegg('HASH Ref of arguments')
sub DataFromKegg {
    my $args = shift;
    my $org = $$args{'-kegg'};
    my $prestr;
    my $entry_id;
    my $carp_list;

    croak "Organization Name is undefined." if !$org;

    my $serv = InstallKeggApi();

    my $org_arr = $serv->list_organisms();

    if ($org =~ /^\d+$/){
	my $tmp = GetFromNcbi($org, 'taxonomy');
	print $tmp;
	$tmp =~ /\<ScientificName\>(.+)\<\/ScientificName\>/;
	$org = $1;
    }elsif( $org =~ /^[a-z]{3,5}$/ ){
      for( @{$org_arr} )
	{
	  print "Query Find in Kegg.\n" if $org eq $$_{entry_id};
	  return KeggDataSet($org , $serv) if $org eq $$_{entry_id};
	}
    }

    foreach( @{$org_arr} ){
	$entry_id = $$_{entry_id} if $$_{definition} =~ /$org/i;
	$carp_list .= $$_{definition}.",";
    }

    croak "Your request doesn't exist on KEGG. organisms allowed by KEGG are".$carp_list."\n" unless $entry_id;

    return $prestr = KeggDataSet($entry_id, $serv);
}

### KeggDataSet('organism', 'soap handlar')
sub KeggDataSet {
    my ($org, $serv) = @_;
    my $ListPath = $serv->list_pathways($org);
    my ( $path, $prestr );
    my $path_def;

    foreach(@{$ListPath}){
      $$path_def{$$_{entry_id}} = $$_{definition};
    }

    while(my ($path_id, $def) = each(%{$path_def})){
      my $ListGene = $serv->get_genes_by_pathway($path_id);
      my $Information;
      $Information = {
		      'Pathway' => $path_id,
		      'PathwayDefinition' => $def,
		      'Part' => undef,
		     };

      for(@{$ListGene}){
	$$prestr{node}{$_}{'information'}{KEGG}{$_} = 1;
	$$prestr{node}{$_}{'information'}{'pathway'}{$path_id} = 1;
	$$prestr{node}{$_}{'label'} = $_;
      }

      $$prestr{edge} = eXpanda::Data::Parse::List2BinaryInteraction( $ListGene, $Information, $$prestr{edge});
    }

    $prestr = MakeDescription($prestr);

    return $prestr;
}

sub InstallKeggApi
  {
    my $wsdl = 'http://soap.genome.jp/KEGG.wsdl';
    my $serv = SOAP::Lite->service($wsdl);

    return $serv;
  }

sub GetFromNcbi
  {
    my ( $query , $db) = @_;
    my $utils = 'http://www.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?';
    my $retmode = 'xml';
    $db = 'protein' if !$db;
    my $Params = $utils.'db='.$db.'&'.'id='.$query.'&'.'retmode='.$retmode;
    my $req = HTTP::Request->new( 'GET', $Params );
    my $ua = LWP::UserAgent->new;
    $ua->from('interactome@gmail.com');
    $ua->timeout(60);
    $ua->agent('Mozilla/5.0');

    my $result = $ua->request($req);

    if($result->is_success){
        return $result->content;
      }else{
	return ();
      }
  }

sub MakeDescription
  {
    return 0 if $#_ == -1;

    my $str = shift;
    my ( $count, $index);

    while(my ($entry, $one) = each %{$$str{node}})
      {
	while(my ($id_spec, $vals) = each %{$$one{index}})
	  {
	    $$str{desc}{index}{$id_spec} = 1;
	  }
	while(my ($info_id, $vals2) = each %{$$one{information}})
	  {
	    $$str{desc}{information}{$info_id} = 1;
	  }
      }

    while(my ($source, $un) = each %{$$str{edge}})
      {
      while(my ($target, $info) = each %{$un})
	{
        while( my ($info_spec, $vals) = each %{$$info{information}} )
	  {
	    $$str{desc}{information}{$info_spec} = 1 if $info_spec ne $target and $info_spec ne $source;
	  }
      }
    }
    return $str;
  }




1;
