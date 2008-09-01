package eXpanda::Analysis::Topology;

use warnings;
use strict;
use Carp;
use Storable qw(dclone);

sub MCL {
  my ( $str ) = shift;
  my ( $G, $N );
  my ($na, $an) = {};
  my $i = 0;
  #my ( %height , %width, %W);
  my %attribute = (
		   -r => 2,  # parameter 'r'.
		   -d => 0,	 # debug option.
		   -t => 10, # top n cluster coloring.
		   -limit => 10000,
		   %{shift(@_)},
		  );

  my $r = $attribute{-r};

  # 1 #  Dclone(edge) For Temporaly G.
  my $G_G = dclone( $str->{edge} );

  # 2 # Self Looping

  while ( my ( $source, $ref1 ) = each %{ $G_G } ) {
    while ( my ( $target, $val ) = each %{ $ref1 } ) {

      if ( $source ne $target ) {
	$G->{$source}->{$source} = 1;
	$G->{$target}->{$target} = 1;
	# 3 # Make Non-Directed Graph.
	$G->{$source}->{$target} = 1;
	$G->{$target}->{$source} = 1;
      }
      else {
	$G->{$source}->{$target} = 1;
      }
    }
  }
  # 4 # ? Node no syurui wo shiraberu
  my @all;
  my $order = 0;

  while ( my ( $firstkey, $ref1 ) = each( %{$G}) ) {
    push @all, $firstkey;
    $order++;
  }

  # 5 # Make Markov Matrix [LOOP]
  my @brunch = ();

  while ( my ( $firstkey, $ref1 ) = each %{$G} ) {
    @brunch = keys %{$ref1};

    ## 6 ## Calculate Transition Rate.
    my $n = keys %{ $G->{$firstkey} };
    my $transition_rate = 1 / $n;

    ## 7 ## Make Graph Matrix.
    my $diff = &_compare( \@all, \@brunch );

    for my $val ( @{$diff} ) {
      $G->{ $firstkey }->{ $val } = 0;
    }
    ## 8 ## Make Markov Matrix.
    for my $ref_edge ( values( %{ $ref1 } ) ) {
      $ref_edge *= $transition_rate;
    }
  }

  foreach (keys%{$G}){
    $an->{$_}= $i;
    $na->{$i}=$_;
    $i++;
  }

  while (my ($key1, $val1) = each(%{$G})){
    while (my ($key2, $val2) = each(%{$val1})){
      $N->{$$an{$key1}}{$$an{$key2}}=$val2;
    }
  }

  $G = $N;

  # 9 # Yoko gata matrix(%W) -> Internal Subroutine _yoko_mtrx() -> appeared 3 times

  my $Q;                    # <- Tate.
  my $count = 0;

  # 10 # LOOP start.
  while ('until idempotent..') {
    print "D > $count\n" if $attribute{-d} == 1;

    ## 11 ## EXPANTION ( %Q is multiplied MTRX )

    $Q = &multiple( $G, $order);

    ### 12 ### Make Tate Matrix.

    print "D > finish expantion\n" if $attribute{-d} == 1;

    ## 13 ## INFLATION
    while ( my ( $firstkey, $value1 ) = each %$Q ) {
      my ( $one, $two, $three ) = 0;

      ## 14 ## Calc..
      for $one ( values( %{$value1} ) ) {
	$one**= $r;
	$two += $one;
      }
      for $three ( values( %{$value1} ) ) {
	$three /= $two;
      }
      $two = 0;
    }
    print "D > finish inflation \n"if $attribute{-d} == 1;

    ## 15 ## Yoko Matrix. from Tate Matrix.
   
    print "D > finish yoko \n"if $attribute{-d} == 1;

    ## 16 ## Doubly Idempotent.

    my $answer = &_idempotent( $Q, $G );
    print "D > finish idempotent \n" if $attribute{-d} == 1;
    print "D > $answer\n"if $attribute{-d} == 1;

    # limit is experimentaly.
    if ( $answer eq "y" or $attribute{-limit} == $count  ) {
      last;
    }
    elsif ( $answer eq "n" ) {
      $G = dclone($Q);
    }
    
    $count ++;
  } # /LOOP END/

  $N = $G;
  $G = ();

  while (my ($key1, $val1) = each(%{$N})){
    while (my ($key2, $val2) = each(%{$val1})){
      $G->{$$na{$key1}}{$$na{$key2}}=$val2;
    }
  }
  
  # Test Test
  # Generate Result as ARRAY Ref.
  my $R;
  my @array;
  
  while ( my ( $key, $val ) = each(%{$G}) ) {
    while ( my ( $key2, $val2 ) = each( %{$val} ) ) {
      $R->{$key2}->{$key} = $val2;
    }
  }
  
  while ( my ( $key, $val ) = each(%{$R}) ) {
    
    my @s_array;
    
    while ( my ( $key2, $val2 ) = each( %{$val} ) ) {
      if ( $val2 > 0 ) {
	push( @s_array, $key2 );
      }
    }
    
    map {
      my ( %a );
      my $count = 0;
      for my $mem( @s_array ) {
	$a{$mem} = 1;
      }
      
      for my $mem_b ( @{$_} ) {
	if( $a{$mem_b} ) {
	  $count++;
	}
      }
      @s_array = () if  $count == scalar(@s_array);

    } @array;

    if ( scalar @s_array != 0 ) {
      push( @array, \@s_array );
    }
  }

  # grep Top n Cluters.
  return @array if $attribute{-t} eq 'all';

  my %count;

  my (@list, @part, @new_array, @order);

  foreach my $hoge (@array){
    my $part = join(",",@$hoge);
    $count{$part} = 0;
  }

  foreach ( keys (%count) ) {
    my @list = split(/,/, $_);
    push ( @new_array, \@list );
  }

  my $sort_array = qsort_array(\@new_array, 0, (scalar(@new_array) -1 ));

  for (my $i = 0; $i <= $attribute{-t}; $i++){

    push (@order, $$sort_array[$i]);

  }

  # Return ARRAY and Node:Score:
  &_apply_to_str( $str, \@order );

  return $sort_array;
}

# SubRoutines For MCL.
sub qsort_array() {
  my $array = shift;
  my $left  = shift;
  my $right = shift;
  my ($i, $j, $pivot, $tmp, $sp);
  my @left_stack;
  my @right_stack;
  $left_stack[0]  = 0;
  $right_stack[0] = $right;
  $sp = 1;
  while( $sp > 0 ) {
    ## Stack Pop
    $sp--;
    $left  = $left_stack[$sp];
    $right = $right_stack[$sp];
    
    if ( $left < $right ) {
      $i = $left;
      $j = $right;
      $pivot = scalar(@{$array->[($left+$right)/2]});

      while (1) {
        while (scalar(@{$array->[$i]}) > $pivot && $i < $right ) { $i++; }
        while (scalar(@{$array->[$j]}) <= $pivot && $left < $j ) { $j--; }
        if( $i >= $j ){ last; }
        $tmp = $array->[$i];
        $array->[$i] = $array->[$j];
        $array->[$j] = $tmp;
      }

      ### Stack Push
      if ($i - $left < $right - $i) {
        $left_stack[$sp]    = $i + 1;
        $right_stack[$sp++] = $right;
        $left_stack[$sp]    = $left;
        $right_stack[$sp++] = $i - 1;
      } else {
        $left_stack[$sp]    = $left;
        $right_stack[$sp++] = $i - 1;
        $left_stack[$sp]    = $i + 1;
        $right_stack[$sp++] = $right;
      }
    }
  }
  return $array;
}

sub _apply_to_str {
  my ( $str, $result_arr ) = @_;
  my $cluster_number = 0;
  my $score = _color_gen(scalar(@{$result_arr}));

  for my $cluster ( @{$result_arr} ) {
    for my $member ( @{$cluster} ) {
      $str->{node}->{$member}->{graphics}->{fill} = $$score[$cluster_number];
      $str->{node}->{$member}->{score}->{MCL} = $cluster_number;
    }
    $cluster_number++;
  }
}

sub _color_gen {
  my ( $number ) = shift;
  my @colors = ();

  for( my $i = 1; $i <= $number; $i++ ) {
    my $deci = int(rand(16777216));
    my $hex = sprintf("%06x", $deci);
    push @colors, "#".$hex;
  }
  return \@colors;
}

# Store Difference.
sub _compare {
  my ( $a_aref, $b_aref ) = @_;
  my @diff;

  foreach my $var ( @{$a_aref} ) {
    unless ( grep( /^$var$/, @{$b_aref} ) ) {
      push @diff, $var;
    }
  }
  return \@diff;
}


# Multiple Matrix.
sub multiple {
  my ($G,$order) = @_;
  my ($i,$k);
  my $sum = 0;
  my $Q = {};
  my $u = 1;
  my $total;

   for(my$a=0; $a<$order; $a++){
    for(my$g=0; $g<$order; $g++){
      for(my$t=0; $t<$order; $t++){
	$sum = $$G{$a}{$t} * $$G{$t}{$g};
	$total += $sum;      
      }
      $$Q{"$a"}{"$g"}=$total;
      $total = 0;
    }
  }

  return $Q;
}

# This sub was sub last.
sub _idempotent {
  my ( $c, $d ) = @_;
  my %changed  = %$c;
  my %original = %$d;
  my ( @origin, @change, @result ) = ();
  my $nu = 0;

  while ( my ( $firstkey, $value1 ) = each(%changed) ) {

    while ( my ( $secondkey, $value ) = each( %{$value1} ) ) {

      if ( $value != $original{$firstkey}{$secondkey} ) {
	$nu = 1;
      }

    }
  }

  if ( $nu == 0 ) {
    return "y";
  }
  elsif ( $nu == 1 ) {
    return "n";
  }

}

# END Subroutines.


sub Degree {
    my $str = shift;

    my %countedge = ();
    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	    $countedge{$source}++;
	    $countedge{$target}++;
	}
    }
    for my $label (keys %countedge){
	$str->{node}->{$label}->{score}->{degree} = $countedge{$label};
    }
    return $str;
}

sub NormalizedDegree {
    my $str = shift;
    my $eindex = undef;

    my %score = ();
    map{$score{$_} = 0} keys %{$str->{node}};
    
    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	    $eindex->{$source}->{$target} = 1;
	    $eindex->{$target}->{$source} = 1;
	}
    }

    for my $source (keys %{$eindex}){
	my $index = undef;
	for my $target (keys %{$eindex->{$source}}){
	    my $t_flag = 0;
	    $t_flag = 1 if(defined $index->{$target} && $index->{$target} == 1);
	    for my $t_target (keys %{$eindex->{$target}}){
		if(defined $index->{$t_target} && 
		   $index->{$t_target} == 1 &&
		   $t_target ne $source){
		    $t_flag = 1;
		}
		$index->{$t_target} = 1;
	    }
	    $score{$source}++ if($t_flag == 0);

	  }
    }

    for my $label (keys %{$str->{node}}){
	$str->{node}->{$label}->{score}->{normalized_degree} = $score{$label};
    }
    return $str;
}

sub Clique{
    my $str = shift;
    my %attribute = (
		     %{shift(@_)},
		     );

    our $estr = undef;
    our $cstr = undef;

    for my $nid (keys %{$str->{node}}){
	$str->{node}->{$nid}->{score}->{clique} = 1;
    }

    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	  if($source eq $target){
	    $str->{edge}->{$source}->{$target}->{score}->{clique} = 2;
	    $str->{node}->{$source}->{score}->{clique} = 2;
	    $str->{node}->{$target}->{score}->{clique} = 2;
	    next;
	  }
	    my %node_hash = ($source => 1, $target => 1);
	    push @{$cstr->{2}}, \%node_hash;

	    unless(defined $estr->{$source}->{$target}){
		$estr->{$source}->{$target} = 1;
	    }
	    unless(defined $estr->{$target}->{$source}){
		$estr->{$target}->{$source} = 1;
	    }

	}
    }

    for(my $i = 3 ; ; $i++){
	last if (!&FindCliques($i));
    }
    
    my $i = 2;
    for(;;){
	if(defined $cstr->{$i} && scalar @{$cstr->{$i}}){
	    for my $node_hash (@{$cstr->{$i}}){
		my @nids = keys %{$node_hash};
		for my $nid (@nids){
		    $str->{node}->{$nid}->{score}->{clique} = $i;
		    for my $nid2 (@nids){
			if($nid ne $nid2){
			    if(exists $str->{edge}->{$nid}->{$nid2}){
				$str->{edge}->{$nid}->{$nid2}->{score}->{clique} = $i;
			    }elsif(exists $str->{edge}->{$nid2}->{$nid}){
				$str->{edge}->{$nid2}->{$nid}->{score}->{clique} = $i;
			    }else{
				carp "something wrong in clique..";
			    }
			}
		    }
		}
	    }
	}else{
	    last;
	}
	$i++;
    }
    
    while( my ($source, $sstr) = each %{$str->{edge}}){
      while( my ($target, $tstr) = each %{$sstr}){
	unless(defined $tstr->{score}->{clique}){
	  delete $str->{edge}->{$source}->{$target};
	}
      }
      if(scalar(keys %{$sstr}) == 0){
	delete $str->{edge}->{$source};
      }  
    }
    
    
    return $str;
    
    sub FindCliques{
	my $object_num = shift;
	my $flag = 0;
	for my $os_hash (@{$cstr->{$object_num-1}}){ # os hash
	    for my $os_hash2 (@{$cstr->{$object_num-1}}){
		my @no_match = grep{!$os_hash2->{$_}} keys %{$os_hash};
		if($#no_match == 0){
		    my @no_match2 = grep{!$os_hash->{$_}} keys %{$os_hash2};
		    if($estr->{$no_match[0]}->{$no_match2[0]}){
		      my %node_hash = map{$_, 1} keys %{$os_hash}, keys %{$os_hash2};
		      unless(&FindOldClique($object_num, \%node_hash)){
			push @{$cstr->{$object_num}}, \%node_hash;
			$flag = 1 if($flag == 0);
		      }
		    }
		}
	    }
	}
	return $flag;
    }

    sub FindOldClique{
	my $object_num = shift;
	my %node_hash = %{shift(@_)};
	for my $os_hash (@{$cstr->{$object_num}}){
	    next if(scalar(grep{!$node_hash{$_}} keys %{$os_hash}) != 0);
	    return 1;
	}

	return 0;
    }

    return $str;
}

sub Connectivity{
    my $str = shift;
    my %attribute = (
		     -depth => 3,
		     %{shift(@_)},
		     );
    my $depth = $attribute{-depth};
    our $dualdir = undef;
    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	    $dualdir->{$source}->{$target} = 1;
	    $dualdir->{$target}->{$source} = 1;
	}
    }
    
    our %c_index = ();
    for my $label (keys %{$str->{node}}){
	%c_index = ();
	$c_index{$label} = 1;
	$str->{node}->{$label}->{score}->{connectivity} = &ConnectivityCal($label, $depth) - 1;
    }
    
    return $str;

    sub ConnectivityCal{
	my $label = shift;
	my $depth = shift;
	my $score = 1;
	if($depth == 0){
	    $c_index{$label} = 1;
	    return $score;
	}
	
	for my $target (keys %{$dualdir->{$label}}){
	    $c_index{$label} = 1;
	    $score += &ConnectivityCal($target, $depth - 1) if(!$c_index{$target});
	}
	
	return $score;
    }
}

=c
sub Centrality{
    my $str = shift;
    my %attribute = (
		     -bary => 1,
		     @_,
		     );
    our $bary = $attribute{-bary};
    
    our $dualdir = ();
    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	    $dualdir->{$source}->{$target} = 1;
	    $dualdir->{$target}->{$source} = 1;
	}
    }

    our %check = ();
    for my $label (keys %{$str->{node}}){
	%check = ();
	my $depth = 0;
 v$str->{node}->{$label}->{score}->{centrality} = &CentralityCal($label, $depth);
    }

    return $str;
    
    sub CentralityCal{
	my $label = shift;
	my $depth = shift;
	my @able = ();
	
	$check{$label} = 1;
	
	for my $target (keys %{$dualdir->{$label}}){
	    push @able, $target unless exists $check{$target};
	}
	
	$depth++ if($bary == 0);
	
	for my $target (@able){
	    my $tmpdepth = &CentralityCal($target, $depth);
	    $depth = $tmpdepth if($tmpdepth > $depth && $bary == 0);
	    $depth++ if($bary == 1);
	}
	
	$check{$depth} = $depth;
	return $depth;
    }
}
=cut


sub CapNetwork {
    my $str = shift;
    my $limit_str = shift;
    my $obj_str = shift;
    my $ret_str = dclone($str);

    my %attribute = (
                     -object => 'node', # node edge
                     -datatype => 'network', # network nodearray
		    );


    my $l_index = undef;
    my $obj_l_index = undef;
    my %l2id = ();
    my %obj_l2id = ();
    my %id2l = ();
    my %obj_id2l = ();

    while(my ($id, $ref) = each %{$$str{node}}){
	$l2id{$ref->{label}} = $id;
	$id2l{$id} = $ref->{label};
	$l_index->{node}->{$ref->{label}} = 1;
    }

    while(my ($id, $ref) = each %{$$obj_str{node}}){
	$obj_l2id{$ref->{label}} = $id;
	$obj_id2l{$id} = $ref->{label};
	$obj_l_index->{node}->{$ref->{label}} = 1;
    }
    
    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	    $l_index->{edge}->{$id2l{$source}}->{$id2l{$target}} = 1;
	    $l_index->{edge}->{$id2l{$target}}->{$id2l{$source}} = 1;
	}
    }
    for my $source (keys %{$obj_str->{edge}}){
	for my $target (keys %{$obj_str->{edge}->{$source}}){
	    $obj_l_index->{edge}->{$obj_id2l{$source}}->{$obj_id2l{$target}} = 1;
	    $obj_l_index->{edge}->{$obj_id2l{$target}}->{$obj_id2l{$source}} = 1;
	}
    }
    
    for my $label (keys %{$l_index->{node}}){
	delete $l_index->{node}->{$label} if(! $obj_l_index->{node}->{$label});
    }
    for my $source (keys %{$l_index->{edge}}){
	for my $target (keys %{$l_index->{edge}->{$source}}){
	    delete $l_index->{edge}->{$source}->{$target}
	    if(!$obj_l_index->{edge}->{$source}->{$target} ||
	       !$obj_l_index->{node}->{$source} ||
	       !$obj_l_index->{node}->{$target});
	}
    }
    for my $label (keys %{$limit_str->{node}}){
	delete $limit_str->{node}->{$label}
	if(!$l_index->{node}->{$id2l{$label}});
    }
    
    for my $source (keys %{$limit_str->{edge}}){
	for my $target (keys %{$limit_str->{edge}->{$source}}){
	    delete $limit_str->{edge}->{$id2l{$source}}->{$id2l{$target}}
	    if(!$l_index->{edge}->{$id2l{$source}}->{$id2l{$target}} ||
	       !$l_index->{node}->{$id2l{$source}} ||
	       !$l_index->{node}->{$id2l{$target}});
	}
    }

    $ret_str = eXpanda::ReturnElement::ReturnLimitedNetwork($ret_str, $limit_str);

#    $ret_str->ReturnLimitedNetwork( $limit_str);

    delete $ret_str->{graphed} if(defined $ret_str->{graphed});
    return $ret_str;
}


# notice!!! have to apply with  label <=> id no match structure
## ID remake
## label_index (see capnetwork)

sub CupNetwork{
    my $str = shift;
    my $limit_str = shift;
    my $obj_str = shift;
    my $ret_str = dclone($str);
    
    my $l_index = undef;
    my $obj_l_index = undef;
    my %l2id = ();
    my %obj_l2id = ();
    my %id2l = ();
    my %obj_id2l = ();
    
    my $l_str = undef;
    
    while(my ($id, $ref) = each %{$$obj_str{node}}){
	$obj_l2id{$ref->{label}} = $id;
	$obj_id2l{$id} = $ref->{label};
	$obj_l_index->{node}->{$ref->{label}} = 1;
	$l_str->{node}->{$ref->{label}} = $ref;
    }

    while(my ($id, $ref) = each %{$$str{node}}){
	$l2id{$ref->{label}} = $id;
	$id2l{$id} = $ref->{label};
	$l_index->{node}->{$ref->{label}} = 1;
	$l_str->{node}->{$ref->{label}} = $ref;
    }
    
    for my $source (keys %{$obj_str->{edge}}){
	for my $target (keys %{$obj_str->{edge}->{$source}}){
	    $l_str->{edge}->{$obj_id2l{$source}}->{$obj_id2l{$target}} = 
		$obj_str->{edge}->{$source}->{$target};
	}
    }
    
    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	    $l_str->{edge}->{$id2l{$source}}->{$id2l{$target}} = 
		$str->{edge}->{$source}->{$target};
	    delete $l_str->{edge}->{$id2l{$target}}->{$id2l{$source}}
	    if(defined $l_str->{edge}->{$id2l{$target}}->{$id2l{$source}});
	}
    }


    delete $ret_str->{node};
    delete $ret_str->{edge};
    $ret_str->{node} = $l_str->{node};
    $ret_str->{edge} = $l_str->{edge};

    delete $ret_str->{graphed} if(defined $ret_str->{graphed});
    return $ret_str;
}


1;
