package eXpanda::Operator;

#use strict;
#use warnings;
use Carp;
use Data::Dumper;
use autouse 'eXpanda::Util' => qw{extend};
use autouse 'eXpanda::Structure::Component' => qw{add_components_from_file};
use base qw{eXpanda::ReturnElement eXpanda::Analysis eXpanda::ReturnValue};

sub Apply {
  my $str = shift;
  my %attribute = (
		   -limit => [{ # object limitation
			       -object => undef,
			       -operator => undef,
			       -identifier => undef, # or
			       -list => undef,
			      }],
		   -object => undef,  # object c.f) node:graphics:fill
		   -value => undef,   # input object value
		   -file => undef,    # filename
		   -from => undef, # integure data input for graphics
		   -apply_information => {
					  -object => undef,
					  -from => undef,
					  -to => undef,
					  -organism => undef,
					 },
		   -label => undef,
		   -reset => undef,
		   -component_label  => undef,
		   -owner_label  => undef,
		   -import_information => undef,
		   @_,
		  );

  if ($#_ == -1) {
    carp "WARNING: No options are inputed in Apply(). Nothing applies;";
    return;
  }

  my %option_index = ();
  map{$option_index{$_} = 1} qw(
				 -limit -object -value -file -from -apply_information -label -reset
				 -component_label -owner_label -import_information
			      );

  my $i = 0;
  for my $option (@_) {
    if ($i % 2 == 0) {
      croak qq{Invalid option "$option" on Apply();} if(!$option_index{$option});
    }
    $i++;
  }


  my $limit  = $attribute{-limit};
  my $object = $attribute{-object};
  my $value  = $attribute{-value};
  my $file   = $attribute{-file};
  my $from   = $attribute{-from};
  my $apply_information = $attribute{-apply_information};
  my $label_change      = $attribute{-label};
  my $reset  = $attribute{-reset};

  if ( $limit ) {
    for my $tmp_lstr (@{$limit}) {
      my %loption_index = ();
      map{$loption_index{$_} = 1} qw(-object -operator -identifier -list);
      my $i = 0;
      for my $option (keys %{$tmp_lstr}) {
	croak qq{Invalid option "$option" on Apply(-limit=>{});} if(!$loption_index{$option});
      }
    }
  }

  if ($apply_information) {
    my %aoption_index = ();
    map{$aoption_index{$_} = 1} qw(-object -from -to -organism);
    my $i = 0;
    for my $option (keys %{$apply_information}) {
      croak qq{Invalid option "$option" on Apply(-apply_information=>{});} if(!$aoption_index{$option});
    }
  }

  my $limit_str = $str->MultiSort( $limit);
  my $base = undef;
  my $att = undef;
  my $detail = undef;

  if (defined $object) {
    ($base, $att, $detail) = split /:/, $object;
  } elsif (defined $label_change) {
    $str->ChangeLabel($label_change);
    return;
  } elsif (!defined $reset) {
    carp "Subroutin Apply() must be set option \'-object\'.\n";
    exit;
  }

  if ( $att eq 'component' ) {
    extend 'eXpanda', 'eXpanda::Structure::Component', 'add_components_from_file';
    $str->add_components_from_file($file,
				   format => $attribute{-format} || 'tab',
				   component_label => $attribute{-component_label} || '',
				   owner_label =>  $attribute{-owner_label} || '',
				   import => $attribute{-import_information} || 'all',
				  );
    return;
  }

  if (defined $reset) {
    ($base, $att, $detail) = split /:/, $reset;
    if ($base eq 'all' || ($base eq 'node' && $att eq 'all')) {
      delete $str->{graphed} if(defined $str->{graphed});
    }

    if ($base eq 'node' || $base eq 'all' || $base eq 'except_xy') {
      $att = 'all' if(!defined $att);
      for my $nid (keys %{$str->{node}}) {
	my $x = undef;
	my $y = undef;
	if (defined $str->{node}->{$nid}->{graphics}->{x}) {
	  ($x, $y) = (
		      $str->{node}->{$nid}->{graphics}->{x},
		      $str->{node}->{$nid}->{graphics}->{y},
		     );
	}
	if (!defined $detail) {
	  delete $str->{node}->{$nid}->{graphics}
	    if ($att eq 'all' || $att eq 'graphics');
	  delete $str->{node}->{$nid}->{score}
	    if ($att eq 'all' || $att eq 'score');
	} else {
	  delete $str->{node}->{$nid}->{$att}->{$detail};
	}
	if ($base eq 'except_xy') {
	  $str->{'node'}->{$nid}->{'graphics'}->{'x'} = $x;
	  $str->{'node'}->{$nid}->{'graphics'}->{'y'} = $y;
	}
      }
    }

    if ($base eq 'node' || $base eq 'all' || $base eq 'except_xy') {
      $att = 'all' if(!defined $att);
      for my $source (keys %{$str->{edge}}) {
	for my $target (keys %{$str->{edge}->{$source}}) {
	  if (!defined $detail) {
	    delete $str->{edge}->{$source}->{$target}->{graphics} if ($att eq 'all' || $att eq 'graphics');
	    delete $str->{edge}->{$source}->{$target}->{score} if ($att eq 'all' || $att eq 'score');
	  } else {
	    delete $str->{edge}->{$source}->{$att}->{$detail};
	  }
	}
      }
    }

    return;
  }

  if (defined $file) {
    $str->ApplyAttributesFromFile($file,
				  -object => $object,
				  -limit => $limit_str,
				 );
  } elsif (defined $from) {
    my $score_base = undef;
    my $score_att = undef;
    my $score_detail = undef;

    if ($from =~ /:/) {
      ( $score_base, $score_att, $score_detail ) = split /:/, $from;
    } else {
      ( $score_base, $score_att, $score_detail ) = ($base, 'score', $from);
    }

    my %detail_index = ();
    if ($score_base eq 'node') {
      my @nlist = keys %{$str->{$score_base}};
      map{$detail_index{$_} = 1} keys %{$str->{$score_base}->{$nlist[0]}->{$score_att}};

      croak qq{Invalid score name "$score_detail" has been referenced;} if(!$detail_index{$score_detail});
    } elsif ($score_base eq 'edge') {
      my @nlist = keys %{$str->{edge}};
      my @nlist2 = keys %{$str->{edge}->{$nlist[0]}};
      map{$detail_index{$_} = 1} keys %{$str->{$score_base}->{$nlist[0]}->{$nlist2[0]}->{$score_att}};

      croak qq{Invalid score name "$score_detail" has been referenced;} if(!$detail_index{$score_detail});
    } else {
      croak qq{Invalid base name of -object or -from: "$score_base";};
    }

    $str->ApplyMethod2Graphics(
			       -method => $score_detail,
			       -apply => $object,
			       -value => $value,
			       -limit => $limit_str,
			      );
  } elsif (defined $apply_information->{-object}) {
    my $from = $apply_information->{-from};
    my $to = $apply_information->{-to};
    my $from_object = $apply_information->{-object};
    my $organism = $apply_information->{-organism};

    $str->ApplyInformationFromDB(
				 -limit => $limit,
				 -from_object => $from_object,
				 -from => $from,
				 -to => $to,
				 -to_object => $object,
				 -organism => $organism,
				);
  } else {
    my $code = undef;
    if ($base eq 'node') {
      if ($att eq 'label') {
	$code = '$str->ApplyNodeLabel($nid,
-label =>"' . $value .'");';
      } elsif ($att eq 'score') {
	$code = '$str->ApplyNodeScore($nid,
-score_name =>"' . $detail .'",
-value =>"' . $value .'");';
      } elsif ($att eq 'graphics') {
	$code = '$str->ApplyNodeGraphics($nid,-attribute => {"' . $detail .'"=>"' . $value . '"});';
      } elsif ($att eq 'information') {
	$code = '$str->ApplyNodeInformation($nid, -information_name =>"' . $detail .'", -value =>"' . $value .'");';
      } elsif ($att eq 'disable') {
	if (!defined $value) {
	  $value = 'disable';
	}
	$code = '$str->ChangeNodeAvailable($nid, 
-available =>"' . $value .'");';
      }
    } elsif ($base eq 'edge') {
      if ($att eq 'label') {
	$code = '$str->ApplyEdgeLabel($source, $target,
-label =>"' . $value .'");';
      } elsif ($att eq 'score') {
	$code = '$str->ApplyEdgeScore($source, $target, 
-score_name =>"' . $detail .'",
-value =>"' . $value .'");';
      } elsif ($att eq 'graphics') {
	$code = '$str->ApplyEdgeGraphics($source, $target, -attribute => {"' . $detail .'"=>"' . $value . '"});',
      } elsif ($att eq 'information') {
	$code = '$str->ApplyEdgeInformation($source, $target, 
-information_name =>"' . $detail .'",
-value =>"' . $value .'");';
      } elsif ($att eq 'disable') {
	if (!defined $value) {
	  $value = 'disable';
	}
	$code = '$str->ChangeEdgeAvailable($source, $target, 
-available =>"' . $value .'");', 
}
    }

    $str = &ExeInLimit(
		       -str => $str,
		       -limit => $limit_str,
		       -object => $base,
		       -code => $code,
		      );
  }
}


sub Return{
  my $str = shift;
  my %attribute = (
		   -limit => [{ # object limitation
			       -object => undef,
			       -operator => undef,
			       -identifier => undef, # or
			       -list => undef,
			      }],
		   -network => { # use if -object eq 'as_network'
				-operator => undef,
				-with => undef,
			       },
		   -object => undef, # object c.f) node:graphics:fill
		   -hash => 0,	     # return as hash. boolean
		   -get_information => {
					-object => undef,
					-from => undef,
					-to => undef,
					-organism => undef,
				       },
		   @_,
		  );

  my %option_index = ();
  map{$option_index{$_} = 1} qw(-limit -network -object -hash -get_information);

  my $i = 0;
  for my $option (@_) {
    if ($i % 2 == 0) {
      croak qq{Invalid option "$option" on Return();} if(!$option_index{$option});
    }
    $i++;
  }

  my $limit = $attribute{-limit};
  my $network = $attribute{-network};
  my $object = $attribute{-object};
  my $as_hash = $attribute{-hash};
  my $get_information = $attribute{-get_information};

  my $limit_str = &MultiSort($str, $limit);
  my $ret_str = undef;

  if ((defined $object && $object eq 'as_network') || defined $network->{-operator}) {
    if (defined $network->{-operator}) {
      my %noption_index = ();
      map{$noption_index{$_} = 1} qw(-operator -with -threshold);
	    
      my $i = 0;
      for my $option (keys %{$network}) {
	croak qq{Invalid option "$option" on Return(-network=>{});} if(!$noption_index{$option});
	$i++;
      }

      $network = {
		  -operator => undef,
		  -with => undef,
		  -threshold => 4,
		  %{$network},
		 };
	    
	    
	    
      my $operator = $network->{-operator};
      my $with = $network->{-with};
      my $threshold = $network->{-threshold};
	    
      if (defined $with) {
	if ($operator eq 'cap') {
	  return $str->CapNetwork($limit_str, $with);
	} elsif ($operator eq 'cup') {
	  return $str->CupNetwork($limit_str,$with);
	}
      } else {
	if ($operator eq 'independent') {
	  return $str->ReturnIndependentNetworks($limit_str);
	} elsif ($operator eq 'clique') {
	  return $str->ReturnCliques($limit_str,$threshold);
	}
      }
    } else {
      return $str->ReturnLimitedNetwork($limit_str);
    }
  } elsif (defined $get_information->{-from}) {
    my $from = $get_information->{-from};
    my $to = $get_information->{-to};
    my $from_object = $get_information->{-object};
    my $organism = $get_information->{-organism};
	
    return  $str->ReturnInformationFromDB(
					  -limit => $limit,
					  -from_object => $from_object,
					  -from => $from,
					  -to => $to,
					  -organism => $organism,
					  -hash => $as_hash
					 );
  } else {

    my $base = undef;
    my $att = undef;
    my $detail = undef;

    if (!$object) {
      return $str->ReturnAllEdges();
    }

    if ($object =~ /^(.*?):(.*?):(.*)$/) {
      $base = $1;
      $att = $2;
      $detail = $3;
    } elsif ($object =~ /(.*?):(.*)$/) {
      $base = $1;
      $att = $2;
    } elsif ($object =~ /^(.*)$/) {
      $base = $1;
      $att = "all";
    }

    if ($base eq 'node') {
      if ($att eq 'label') {
	$ret_str = &ReturnInLimit(
				  -str => $str,
				  -limit => $limit_str,
				  -object => $object,
				  -hash => $as_hash,
				  -code => '$ret_value = $str->ReturnNodeLabel($nid);'
				 );
      } elsif ($att eq 'score') {
	$ret_str = &ReturnInLimit(
				  -str => $str,
				  -limit => $limit_str,
				  -object => $object,
				  -hash => $as_hash,
				  -code => '$ret_value = $str->ReturnNodeScore($nid,
-score_name => "'. $detail. '");'
				 );
      } elsif ($att eq 'information') {
	$ret_str = &ReturnInLimit(
				  -str => $str,
				  -limit => $limit_str,
				  -object => $object,
				  -hash => $as_hash,
				  -code => '$ret_value = $str->ReturnNodeInformation($nid,
-information_name => "' . $detail. '");'
				 );
      } else {
	croak qq{-object option "$object" may be invalid in Return(). c.f) "node:graphics";};
      }

    } elsif ($base eq 'edge') {
      if ($att eq 'label') {
	$ret_str = &ReturnInLimit(
				  -str => $str,
				  -limit => $limit_str,
				  -object => $object,
				  -hash => $as_hash,
				  -code => '$ret_value = $str->ReturnEdgeLabel($source, $target);'
				 );
      } elsif ($att eq 'score') {
	$ret_str = &ReturnInLimit(
				  -str => $str,
				  -limit => $limit_str,
				  -object => $object,
				  -hash => $as_hash,
				  -code => '$ret_value = $str->ReturnEdgeScore($source, $target,
-score_name => "' . $detail . '");'
				 );
      } elsif ($att eq 'information') {
	$ret_str = &ReturnInLimit(
				  -str => $str,
				  -limit => $limit_str,
				  -object => $object,
				  -hash => $as_hash,
				  -code => '$ret_value = $str->ReturnEdgeInformation($source, $target,
-information_name => "' . $detail . '");'
				 );
      } else {
	croak qq{-object option "$object" may be invalid in Return(). c.f) "node:graphics";};
      }
    }
  }
  return $ret_str;
}



sub Analyze{
  my $str = shift;
  my %attribute = (
		   -method => '',
		   -option => {},
		   -object => '',
		   -value => '',
		   @_,
		  );

  my $method = $attribute{-method};
  my $object = $attribute{-object};
  my $gradient = $attribute{-gradient};
  my $option = $attribute{-option};
  my $value = $attribute{-value};

  if ($#_ == -1) {
    carp "WARNING: No options are inputed in Analyze(). Nothing analyzes;";
    return;
  }

  my %option_index = ();
  map{$option_index{$_} = 1} qw(-method -option -object -value);

  my $i = 0;
  for my $option (@_) {
    if ($i % 2 == 0) {
      croak qq{Invalid option "$option" on Return();} if(!$option_index{$option});
    }
    $i++;
  }

  my %method_index = ();

  # TODO: MCL is under construction.
  map{$method_index{$_} = 1} qw(degree normalized_degree clique connectivity cenrality accuracy coverage count_nodes count_edges);
  croak qq{Invalid method "$method" was called;} if(!$method_index{$method});

  my $ret_value = undef;

  # Add return *num 
  if ($method eq 'degree') {
    $str->Degree;
  } elsif ( $method eq 'MCL' ) {
    $str->MCL($option);
  } elsif ($method eq 'normalized_degree') {
    $str->NormalizedDegree;
  } elsif ($method eq 'clique') {
    $str->Clique($option);
  } elsif ($method eq 'connectivity') {
    $str->Connectivity($option);
  } elsif ($method eq 'centrality') {
    $str->Centrality($option);
  } elsif ($method eq 'accuracy') {
    if (!defined $option->{-with}) {
      carp "Invalid value of \'-option\' at Analyze. Please input \'-with\' into options.\n";
      exit;
    }
    ($str, $ret_value) = $str->Accuracy($option);
  } elsif ($method eq 'coverage') {
    if (!defined $option->{-with}) {
      carp "Invalid value of \'-option\' at Analyze. Please input \'-with\' into options.\n";
      exit;
    }
    #	($str, $ret_value) = &Coverage($str, $option);
    ($str, $ret_value) = $str->Coverage($option);
  } elsif ($method eq 'count_nodes') {
    return $str->ReturnNodeNum();
  } elsif ($method eq 'count_edges') {
    return $str->ReturnEdgeNum();
  }
    
  if ( $object ) {
    #      print ref($str)."\n";
    $str->ApplyMethod2Graphics(
			       -method => $method,
			       -apply => $object,
			       -value => $value,
			      );
  }
}


sub MultiSort{
  my $str = shift;
  my $limits = shift;
  my @objects = ();

  bless( $str, 'eXpanda' ) if ref($str) ne 'eXpanda';

  my $ret_object = undef;

  for my $nid (@{$str->ReturnAllNodes()}) {
    $ret_object->{node}->{$nid} = 1;
  }

  $ret_object->{edge} = $str->ReturnAllEdges;

  if ($#{$limits} != -1 && (defined $limits->[0]->{-object} || $limits->[0]->{-list})) {
    for my $limit (@{$limits}) {

      my $object = &Sort(
			 $str,
			 -limit => $limit
			);

      for my $object_name (keys %{$object}) {

	if ($object_name eq 'node') {
	  for my $nid (keys %{$ret_object->{node}}) {
	    if (!defined $object->{node}->{$nid}) {
	      delete $ret_object->{node}->{$nid};
	    }
	  }
	} elsif ($object_name eq 'edge') {
	  for my $source (keys %{$ret_object->{edge}}) {
	    for my $target (keys %{$ret_object->{edge}->{$source}}) {
	      if (!defined $object->{edge}->{$source}->{$target}) {
		delete $ret_object->{edge}->{$source}->{$target};
	      }
	    }
	  }
	}
      }
    }

    for my $object (@objects) {
      for my $base (keys %{$ret_object}) {
	if ($base eq 'node') {
	  for my $nid (keys %{$ret_object->{node}}) {
	    delete $ret_object->{node}->{$nid} 
	      if (!defined $object->{node}->{$nid});
	  }
	} elsif ($base eq 'edge') {
	  for my $source (keys %{$ret_object->{edge}}) {
	    for my $target (keys %{$ret_object->{edge}->{$source}}) {
	      delete $ret_object->{edge}->{$source}->{$target} 
		if (! defined $object->{edge}->{$source}->{$target});
	    }
	  }
	}
      }
    }
    return $ret_object;
  } else {
    return $ret_object;
  }
}

sub Sort{
  my $str = shift;
  my %attribute = (
		   -limit => {
			      -object => undef,
			      -operator => undef,
			      -identifier => undef, # or
			      -list => undef,
			     },
		   @_
		  );

  my $limit = $attribute{-limit};
    
  if (defined $limit->{-list}) {
    my $list = $limit->{-list};
    my $ret_str = undef;
	
    my %l2id = ();
    for my $nid (keys %{$str->{node}}) {
      my $label = $str->{node}->{$nid}->{label};
      $l2id{$label} = $nid;
    }

    if (ref $list) {
      if (defined $list->{node}) {
	for my $nid (keys %{$list->{node}}) {
	  $ret_str->{node}->{$l2id{$nid}} = 1;
	}
      }
	    
      if (defined $list->{edge}) {
	for my $source (keys %{$list->{edge}}) {
	  for my $target (keys %{$list->{edge}->{$source}}) {
	    $ret_str->{edge}->{$l2id{$source}}->{$l2id{$target}} = 1;
	  }
	}
      }
    } else {
      $ret_str = &ReturnListFromFile($str,$list);
    }
	
    return $ret_str;
  } else {
    my $ret_object = undef;
    my $ret_list = undef;
    my $object = $limit->{-object};
    my $operator = $limit->{-operator};
    my $identifier = $limit->{-identifier};
	
    if ($object =~ /^node\:/ || $object eq 'label') {
      $object =~ s/^node\://g;
      $ret_object = 'node';
	    
      unless($object =~ /^score/){
	for my $nid (@{$str->ReturnAllNodes}) {
	  my $value = '';
	  if ($object =~ /label/) {
	    $value = $str->ReturnNodeLabel($nid);
	  } elsif ($object =~ /^information\:(.*)/) {
	    $value = $str->ReturnNodeInformation($nid,
						 -information_name => $1,
						);
	  }
	  if ($operator eq 'eq') {
	    $ret_list->{$nid} = 1 if($value eq $identifier);
	  } elsif ($operator eq '=~') {
	    $ret_list->{$nid} = 1 if($value =~ /$identifier/);
	  } elsif ($operator eq 'ne') {
	    $ret_list->{$nid} = 1 if($value ne $identifier);
	  } elsif ($operator eq '!~') {
	    $ret_list->{$nid} = 1 if($value !~ /$identifier/);
	  } elsif ($operator eq '==') {
	    $ret_list->{$nid} = 1 if($value == $identifier);
	  } elsif ($operator eq '!=') {
	    $ret_list->{$nid} = 1 if($value != $identifier);
	  } elsif ($operator eq '>=') {
	    $ret_list->{$nid} = 1 if($value >= $identifier);
	  } elsif ($operator eq '<=') {
	    $ret_list->{$nid} = 1 if($value <= $identifier);
	  } elsif ($operator eq '>') {
	    $ret_list->{$nid} = 1 if($value > $identifier);
	  } elsif ($operator eq '<') {
	    $ret_list->{$nid} = 1 if($value < $identifier);
	  } else {
	    carp qq{-operator "$operator" in -limit may be invalid for value in -identifier. check document of -limit option;};
	  }
	}
		
      } elsif ($object =~ /^score\:(.*)/) {
	my $detail = $1;
	if ($operator eq 'top' || $operator eq 'bottom') {
	  for my $nid (@{$str->ReturnTopNodesByScore(
						     -num => $identifier,
						     -ranking => $operator,
						     -score_name => $detail
						    )}) {
	    $ret_list->{$nid} = 1;
	  }
	} else {
	  if ($identifier =~ /\d/) {
	    for my $nid (@{$str->ReturnNodesByScore(
						    -threshold => $identifier,
						    -operator => $operator,
						    -score_name => $detail
						   )}) {
	      $ret_list->{$nid} = 1;
	    }
	  } else {
	    for my $nid (@{$str->ReturnNodesByScore(
						    -static => $identifier,
						    -operator => $operator,
						    -score_name => $detail
						   )}) {
	      $ret_list->{$nid} = 1;
	    }
	  }
	}
      }
    } elsif ($object =~ /^edge\:/) {
      $object =~ s/^edge\://g;
      $ret_object = 'edge';
      #	     $obj_term =~ s/^[\"\'\/]|[\"\'\/]$//g;
      unless($object =~ /^score/){
	my $edges = $str->ReturnAllEdges;

	for my $source (keys %{$edges}) {
	  for my $target (keys %{$edges->{$source}}) {
	    my $value = '';
	    if ($object =~ /label/) {
	      $value = $str->ReturnEdgeLabel($source, $target);
	    } elsif ($object =~ /^information\:(.*)/) {
	      $value = $str->ReturnEdgeInformation($source,$target,
						   -information_name => $1,
						  );
	    }

	    if ($operator eq 'eq') {
	      $ret_list->{$source}->{$target} = 1 if($value eq $identifier);
	    } elsif ($operator eq '=~') {
	      $ret_list->{$source}->{$target} = 1 if($value =~ /$identifier/);
	    } elsif ($operator eq 'ne') {
	      $ret_list->{$source}->{$target} = 1 if($value ne $identifier);
	    } elsif ($operator eq '!~') {
	      $ret_list->{$source}->{$target} = 1 if($value !~ /$identifier/);
	    } elsif ($operator eq '==') {
	      $ret_list->{$source}->{$target} = 1 if($value == $identifier);
	    } elsif ($operator eq '!=') {
	      $ret_list->{$source}->{$target} = 1 if($value != $identifier);
	    } elsif ($operator eq '>=') {
	      $ret_list->{$source}->{$target} = 1 if($value >= $identifier);
	    } elsif ($operator eq '<=') {
	      $ret_list->{$source}->{$target} = 1 if($value <= $identifier);
	    } elsif ($operator eq '>') {
	      $ret_list->{$source}->{$target} = 1 if($value > $identifier);
	    } elsif ($operator eq '<') {
	      $ret_list->{$source}->{$target} = 1 if($value < $identifier);
	    } else {
	      carp qq{-operator "$operator" in -limit may be invalid for value in -identifier. check document of -limit option;};
	    }
	  }
	}
      } elsif ( $object =~ /^score\:(.*)/ ) {
	my $detail = $1;
	if ($operator eq 'top' || $operator eq 'bottom') {
	  my $edgesOA = $str->ReturnTopEdgesByScore(
						    -num => $identifier,
						    -ranking => $operator,
						    -score_name => $detail
						   );
	  for my $source (keys %{$edges}) {
	    for my $target (keys %{$edges->{$source}}) {
	      $ret_list->{$source}->{$target} = 1;
	    }
	  }
	} else {
	  if ($identifier =~ /\d/) {
	    my $edges = $str->ReturnEdgesByScore(
						 -threshold => $identifier,
						 -operator => $operator,
						 -score_name => $detail
						);
	    for my $source (keys %{$edges}) {
	      for my $target (keys %{$edges->{$source}}) {
		$ret_list->{$source}->{$target} = 1;
	      }
	    }
	  } else {
	    my $edges = $str->ReturnEdgesByScore(
						 -static => $identifier,
						 -operator => $operator,
						 -score_name => $detail
						);
	    for my $source (keys %{$edges}) {
	      for my $target (keys %{$edges->{$source}}) {
		$ret_list->{$source}->{$target} = 1;
	      }
	    }
	  }
	}
      }
    }

    my $ret_str = undef;
    $ret_str->{$ret_object} = $ret_list;
    my @return_list = keys %{$ret_list};
    carp qq{WARNING: -limit returns no objects. the limit may be invalid or too strict;} if(scalar(@return_list) == 0);
	
    return $ret_str;
  }
}

# Use this in name by name applying methods
sub ExeInLimit{
  my %attribute = (
		   -str => undef,
		   -limit => undef,
		   -object => undef,
		   -code => undef,
		   @_,
		  );
    
  my $str = $attribute{-str};
  my $limit_str = $attribute{-limit};
  my $object = $attribute{-object}; # node | edge
  my $code = $attribute{-code};
    
  if ($object eq 'node') {
    for my $nid (keys %{$limit_str->{node}}) {
      eval($code);
    }
  } elsif ($object eq 'edge') {
    for my $source (keys %{$limit_str->{edge}}) {
      for my $target (keys %{$limit_str->{edge}->{$source}}) {
	eval($code);
      }
    }
  }
  return $str;
}

# Use this in totally applying methods
sub CutInLimit{
  my %attribute = (
		   -str => undef,
		   -limit => undef,
		   -object => undef,
		   @_,
		  );
    
  my $str = $attribute{-str};
  my $limit_str = $attribute{-limit};
  my $object_term = $attribute{-object}; # node:graphics:fill etc..
    
  my ($base, $object, $detail) = split /:/, $object_term;
  if ($base eq 'node' || $base eq 'all') {
    my $i = 0;
    my @detail_list = ();
    for my $nid (keys %{$str->{node}}) {
      if ($detail eq 'all') {
	if ($i == 0) {
	  @detail_list = keys %{$str->{node}->{$nid}->{$object}};
	  $i++;
	}
	for my $detail_i ($detail_list) {
	  delete $str->{node}->{$nid}->{$object}->{$detail}
	    if (!$limit_str->{node}->{$nid});
	}
      }
      delete $str->{node}->{$nid}->{$object}->{$detail}
	if (!$limit_str->{node}->{$nid});
    }
  }
  if ($base eq 'edge' || $base eq 'all') {
    my $i = 0;
    my @detail_list = ();
    for my $source (keys %{$limit_str->{edge}}) {
      for my $target (keys %{$limit_str->{edge}->{$source}}) {
	if ($detail eq 'all') {
	  if ($i == 0) {
	    @detail_list = keys %{$str->{edge}->{$source}->{$target}->{$object}};
	    $i++;
	  }
	  for my $detail_i ($detail_list) {
	    delete $str->{edge}->{$source}->{$target}->{$object}->{$detail}
	      if (!$limit_str->{edge}->{$source}->{$target});
	  }
	}
	delete $str->{edge}->{$source}->{$target}->{$object}->{$detail}
	  if (!$limit_str->{edge}->{$source}->{$target});
      }
    }
  }
  return $str;
}

sub ReturnInLimit{
  my %attribute = (
		   -str => undef,
		   -limit => undef,
		   -object => undef,
		   -hash => 0,
		   -code => undef,
		   @_,
		  );
    
  my $str = $attribute{-str};
  my $limit_str = $attribute{-limit};
  my $object_term = $attribute{-object}; # node:graphics:fill etc..
  my $hash = $attribute{-hash};		 # return as hash ref
  my $code = $attribute{-code};
  my $ret_str = undef;
    
  my ($base, $object, $detail) = split /:/, $object_term;
    
  if ($base eq 'node') {
    for my $nid (keys %{$str->{node}}) {
      next if(!$limit_str->{node}->{$nid});

      my $ret_value = undef;
      eval($code);
      if ($hash) {
	$ret_str->{$nid} = $ret_value;
      } else {
	push @{$ret_str}, $ret_value;
      }
    }
  } elsif ($base eq 'edge') {
    for my $source (keys %{$limit_str->{edge}}) {
      for my $target (keys %{$limit_str->{edge}->{$source}}) {
	next if(!$limit_str->{edge}->{$source}->{$target});

	my $ret_value = undef;
	eval($code);
	if ($hash) {
	  $ret_str->{$source}->{$target} = $ret_value;
	} else {
	  push @{$ret_str}, $ret_value;
	}
      }
    }
  }

  return $ret_str;

}

sub ReturnListFromFile{
  my $str = shift;
  my $file = shift;
  my $ret_str = undef;
  my %l2id = ();
    
  for my $nid (keys %{$str->{node}}) {
    my $label = $str->{node}->{$nid}->{label};
    $l2id{$label} = $nid;
  }
    
  open(LIMIT, $file);
  while (<LIMIT>) {
    chomp;
    if ($_ =~ /^node\t(.+?)$/) {
      $ret_str->{node}->{$l2id{$1}} = 1;
    } elsif ($_ =~ /^edge\t(.+?)\t(.+?)$/) {
      $ret_str->{edge}->{$l2id{$1}}->{$l2id{$2}} = 1;
      $ret_str->{edge}->{$l2id{$2}}->{$l2id{$1}} = 1;
      $ret_str->{node}->{$l2id{$1}} = 1;
      $ret_str->{node}->{$l2id{$2}} = 1;
    } elsif ($_ =~ /^(.*?) pp (.*?)/) {
      $ret_str->{edge}->{$l2id{$1}}->{$l2id{$2}} = 1;
      $ret_str->{edge}->{$l2id{$2}}->{$l2id{$1}} = 1;
      $ret_str->{node}->{$l2id{$1}} = 1;
      $ret_str->{node}->{$l2id{$2}} = 1;
    }
  }
  close LIMIT;
  return $ret_str;
}

sub ApplyInformationFromDB {
  require eXpanda::Services::IdConvert;
  my $str = shift;
  my %attribute = (
		   -limit => undef,
		   -from_object => undef,
		   -from => undef,
		   -to => undef,
		   -to_object => undef,
		   -organism => undef,
		   @_,
		  );
  my $limit = $attribute{-limit};
  my $f_term = $attribute{-from_object};
  my $from = $attribute{-from};
  my $to = $attribute{-to};
  my $t_term = $attribute{-to_object};
  my $organism = $attribute{-organism};

  my $ret_str = $str;

  my ($f_base, $f_object, $f_detail) = split /:/, $f_term;
  my ($t_base, $t_object, $t_detail) = split /:/, $t_term;
    
  my $db_str = eXpanda::Services::IdConvert->new();
    
  if ($f_base ne $t_base) {
    carp "No match: \'-object\' with \'-apply_information\' and \'Apply()\' must be on same object. $f_base not equal to $t_base.\n";
    exit;
  }

  #    my $limit_str = &MultiSort($str, $limit);
  my $limit_str = $str->MultiSort($limit);

  if ($f_base eq 'node') {
    for my $nid (keys %{$str->{node}}) {
      next if(!$limit_str->{node}->{$nid});

      my $in_value = undef;
      my $ret_value = undef;
      if ($f_object eq 'label') {
	$in_value = $str->{node}->{$nid}->{label};
      } else {
	$in_value = $str->{node}->{$nid}->{$f_att}->{$f_detail};
      }
      $db_str->init(
		    id => $in_value,
		    from => $from,
		    to => $to,
		    organism => $organism,
		   );

      $ret_value = $db_str->ReturnInformation()->result();

      if ($t_object eq 'label') {
	$ret_str->{node}->{$nid}->{label} = $ret_value;
      } else {
	$ret_str->{node}->{$nid}->{$t_att}->{$t_detail} = $ret_value;
      }
	    
    }
  } elsif ($f_base eq 'edge') {
    for my $source (keys %{$limit_str->{edge}}) {
      for my $target (keys %{$limit_str->{edge}->{$source}}) {
	next if(!$limit_str->{edge}->{$source}->{$target});
	my $in_value = undef;
	my $ret_value = undef;

	if ($f_object eq 'label') {
	  $in_value = $str->{edge}->{$source}->{$target}->{label};
	} else {
	  $in_value = $str->{edge}->{$source}->{$target}->{$f_att}->{$f_detail};
	}
		
	$db_str->init(
		      id => $in_value,
		      from => $from,
		      to => $to,
		      organism => $organism,
		     );
		
	$ret_value = $db_str->ReturnInformation()->result();

		
	if ($t_object eq 'label') {
	  $ret_str->{edge}->{$source}->{$target}->{label} = $ret_value;
	} else {
	  $ret_str->{edge}->{$source}->{$target}->{$t_att}->{$t_detail} = $ret_value;
	}
      }
    }
  }
  return $ret_str;
}


sub ReturnInformationFromDB{
  require eXpanda::Services::IdConvert;
  my $str = shift;
  my %attribute = (
		   -limit => undef,
		   -from_object => undef,
		   -from => undef,
		   -to => undef,
		   -organism => undef,
		   -hash => undef,
		   @_,
		  );
  my $limit = $attribute{-limit};
  my $f_term = $attribute{-from_object};
  my $from = $attribute{-from};
  my $to = $attribute{-to};
  my $organism = $attribute{-organism};
  my $hash = $attribute{-hash};

  my $ret_str = undef;

  my ($f_base, $f_object, $f_detail) = split /:/, $f_term;
    
  my $limit_str = $str->MultiSort($limit);

  my $db_str = eXpanda::Services::IdConvert->new();
    
  if ($f_base eq 'node') {
    for my $nid (keys %{$str->{node}}) {
      next if(!$limit_str->{node}->{$nid});

      my $in_value = undef;
      my $ret_value = undef;
      if ($f_object eq 'label') {
	$in_value = $str->{node}->{$nid}->{label};
      } else {
	$in_value = $str->{node}->{$nid}->{$f_att}->{$f_detail};
      }
	    
      $db_str->init(
		    -id => $in_value,
		    -from => $from,
		    -to => $to,
		    -organism => $organism,
		   );

      $ret_value = $db_str->ReturnInformation()->result();

      if ($hash) {
	$ret_str->{$str->{node}->{$nid}->{label}} = $ret_value;
      } else {
	push @{$ret_str}, $ret_value;
      }
    }
  } elsif ($f_base eq 'edge') {
    for my $source (keys %{$limit_str->{edge}}) {
      for my $target (keys %{$limit_str->{edge}->{$source}}) {
	next if(!$limit_str->{edge}->{$source}->{$target});
	my $in_value = undef;
	my $ret_value = undef;

	if ($f_object eq 'label') {
	  $in_value = $str->{edge}->{$source}->{$target}->{label};
	} else {
	  $in_value = $str->{edge}->{$source}->{$target}->{$f_att}->{$f_detail};
	}

	$db_str->init(
		      -id => $in_value,
		      -from => $from,
		      -to => $to,
		      -organism => $organism,
		     );

	$ret_value = $db_str->ReturnInformation()->result();

	if ($hash) {
	  $ret_str->{$str->{node}->{$source}->{label}}->{$str->{node}->{$target}->{label}} = $ret_value;
	} else {
	  push @{$ret_str}, $ret_value;
	}
      }
    }
  }
  return $ret_str;
}

1;
