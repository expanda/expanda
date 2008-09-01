package eXpanda::ReturnElement;

use Data::Dumper;
use Carp;
use Storable qw(dclone);

sub ReturnAllNodes {
    my $str = shift;
    my $ret_str = $str;

    my @ret = keys %{$str->{node}};
#    return [keys %{$ret_str->{node}}];
    return \@ret;
}

sub ReturnAllEdges{
    my $str = shift;
    my $ret_str = $str;
    
    my $ret_edges = undef;
    for my $source (keys %{$ret_str->{edge}}){
	for my $target (keys %{$ret_str->{edge}->{$source}}){
	    $ret_edges->{$source}->{$target} = 1;
	}
    }

    return $ret_edges;
}

sub ReturnNodesByNodeName{
    my $str = shift;
    my $label = shift;

    my  $ret_str = $str;
    our %ret_node = ();
    our $ret_edges = undef;
    for my $source (keys %{$ret_str->{edge}}){
	for my $target (keys %{$ret_str->{edge}->{$source}}){
	    $ret_edges->{$source}->{$target} = 1;
	    $ret_edges->{$target}->{$source} = 1;
	}
    }
	
    
    
    
    &ReturnNodesByNodeRec($label);
    
    return [keys %ret_node];
    
    
    sub ReturnNodesByNodeRec(){
	my $label = shift;
	for my $target (keys %{$ret_edges->{$label}}){
	    if(defined $ret_node{$target}){
		next;
	    }else{
		delete $ret_node{$target};
	    }
	    $ret_node{$target} = 1;
	    &ReturnNodesByNodeRec($target);
	}
	
    }
}

sub ReturnEdgesByNodeName{
    my $str = shift;
    my $label = shift;

    my  $ret_str = $str;
    our $ret_edge = undef;
    our $ret_edges = undef;
    for my $source (keys %{$ret_str->{edge}}){
	for my $target (keys %{$ret_str->{edge}->{$source}}){
	    $ret_edges->{$source}->{$target} = 1;
	    $ret_edges->{$target}->{$source} = 1;
	}
    }
    &ReturnEdgesByNodeRec($label);

    for my $source (keys %{$ret_edge}){
	for my $target (keys %{$ret_edge->{$source}}){
	    unless(defined $ret_str->{edge}->{$source}->{$target}){
		delete $ret_edge->{edge}->{$source}->{$target};
		delete $ret_edge->{$source}->{$target};
	    }
	}
    }
    return $ret_edge;
    
    
    sub ReturnEdgesByNodeRec(){
	my $label = shift;
	for my $target (keys %{$ret_edges->{$label}}){
	    if(defined $ret_edge->{$label}->{$target}){
		next;
	    }else{
		delete $ret_edge->{$label}->{$target};
	    }
	    $ret_edge->{$label}->{$target} = 1;
	    $ret_edge->{$target}->{$label} = 1;
	    &ReturnNodesByNodeRec($target);
	}
    }
}


sub ReturnTopNodesByScore{
    my $str = shift;
    my $ret_str = $str;
    my %attribute = (
		     -num => 10,
		     -ranking => 'top', # top bottom
		     -score_name => undef, # c.f. hub_weight
		     @_,
		     );

    if(!defined $attribute{-score_name}){
	my ($label, $nodestr) = each %{$ret_str->{node}};
	my ($score_name_tmp, $score_banes) = each %{$nodestr->{score}};
	$attribute{-score_name} = $score_name_tmp;
    }
    my $score_name = $attribute{-score_name};
    my $num = $attribute{-num};
    
    my @sort_labels = ();
    if($attribute{-ranking} eq 'top'){
	@sort_labels  = sort {$ret_str->{node}->{$b}->{score}->{$score_name} 
			      <=> $ret_str->{node}->{$a}->{score}->{$score_name}} 
	keys %{$ret_str->{node}};
    }elsif($attribute{-ranking} eq 'bottom'){
	@sort_labels  = sort {$ret_str->{node}->{$a}->{score}->{$score_name} 
			      <=> $ret_str->{node}->{$b}->{score}->{$score_name}} 
	keys %{$ret_str->{node}};
    }

    my $threshold = $ret_str->{node}->{$sort_labels[$num]}->{score}->{$score_name};
    my @ret_nodes = ();
    for my $label (keys %{$ret_str->{node}}){
	push @ret_nodes, $label if($ret_str->{node}->{$label}->{score}->{$score_name} >= $threshold 
	       && $attribute{-ranking} eq 'top');
	push @ret_nodes, $label if($ret_str->{node}->{$label}->{score}->{$score_name} <= $threshold 
				   && $attribute{-ranking} eq 'bottom');
    }
    return [@ret_nodes];
}


sub ReturnTopEdgesByScore{
    my $str = shift;
    my $ret_str = $str;
    my %attribute = (
		     -num => 10,
		     -ranking => 'top', # top bottom
		     -score_name => undef, # c.f. hub_weight
		     @_,
		     );
    my $score_name = $attribute{-score_name};
    my $num = $attribute{-num};

    if(!defined $attribute{-score_name}){
	my ($source, $edgestr1) = each %{$ret_str->{edge}};
	my ($target, $edgestr2) = each %{$edgestr1};
	my ($score_name_tmp, $score_banes) = each %{$edgestr2->{score}};
	$attribute{-score_name} = $score_name_tmp;
    }
    
    
    my @edge_scores = ();
    my @sort_edge_scores = ();
    for my $source (keys %{$ret_str->{edge}}){
	for my $target (keys %{$ret_str->{edge}->{$source}}){
	    push @edge_scores, $ret_str->{edge}->{$source}->{$target}->{score}->{$score_name};
	}
    }
    
    if($attribute{-ranking} eq 'top'){
	@sort_edge_scores = sort {$b <=> $a} @edge_scores;
    }elsif($attribute{-ranking} eq 'bottom'){
	@sort_edge_scores = sort {$a <=> $b} @edge_scores;
    }


    my $threshold = $sort_edge_scores[$num];
    my $ret_edges = undef;
    for my $source (keys %{$ret_str->{edge}}){
	for my $target (keys %{$ret_str->{edge}->{$source}}){
	    $ret_edges->{$source}->{$target} = 1
		if($ret_str->{edge}->{$source}->{$target}->{score}->{$score_name} >= $threshold 
		   && $attribute{-ranking} eq 'top');
	    $ret_edges->{$source}->{$target} = 1
		if($ret_str->{edge}->{$source}->{$target}->{score}->{$score_name} <= $threshold 
		   && $attribute{-ranking} eq 'bottom');
	}
    }    
    return $ret_edge;
}


sub ReturnNodesByScore{
    my $str = shift;
    my $ret_str = $str;
    my %attribute = (
		     -threshold => 0,
		     -operator => 'above', # above below above_or_equal below_or_equal equal
		     -statistic => undef, # average median
		     -statistic_threshold => undef, # uncoded
		     -score_name => undef, # c.f. hub_weight
		     @_,
		     );
    
    if(!defined $attribute{-score_name}){
	my ($label, $nodestr) = each %{$ret_str->{node}};
	my ($score_name_tmp, $score_banes) = each %{$nodestr->{score}};
	$attribute{-score_name} = $score_name_tmp;
    }
    
    my $threshold = $attribute{-threshold};
    my $operator = $attribute{-operator};
    my $statistic = $attribute{-statistic};
    my $score_name = $attribute{-score_name};
    if($statistic){
	my @score_array = ();
	for my $label (keys %{$ret_str->{node}}){
	    push @score_array, $ret_str->{node}->{$label}->{score}->{$score_name};
	}
	
	if($statistic eq 'average'){
	    my $sum = 0;
	    for(@score_array){
		$sum += $_;
	    }
	    $threshold = $sum / ($#score_array + 1);
	}elsif($statistic eq 'median'){
	    my @sort_array = sort {$a <=> $b} @score_array;
	    if(($#sort_array + 1) % 2 == 1){
		$threshold = $sort_array[int($#sort_array/2)-1];
	    }else{
		$threshold = 
		    ($sort_array[int(($#sort_array-1)/2)-1] + $sort_array[int(($#sort_array+1)/2)-1]) / 2;
	    }
	}
    }
    
    
    my @ret_node = ();
    
    for my $label (keys %{$ret_str->{node}}){
	if($operator eq 'above' || $operator eq '>'){
	    push @ret_node, $label if($ret_str->{node}->{$label}->{score}->{$score_name} > $threshold);
	    next;
	}elsif($operator eq 'below' || $operator eq '<'){
	    push @ret_node, $label if($ret_str->{node}->{$label}->{score}->{$score_name} < $threshold);
	    next;
	}elsif($operator eq 'above_or_equal' || $operator eq '>='){
	    push @ret_node, $label if($ret_str->{node}->{$label}->{score}->{$score_name} >= $threshold);
	    next;
	}elsif($operator eq 'below_or_equal' || $operator eq '<='){
	    push @ret_node, $label if($ret_str->{node}->{$label}->{score}->{$score_name} <= $threshold);
	    next;
	}elsif($operator eq 'equal' || $operator eq '=='){
	    push @ret_node, $label if($ret_str->{node}->{$label}->{score}->{$score_name} == $threshold);
	    next;
	}elsif($operator eq 'not_equal' || $operator eq '!='){
	    push @ret_node, $label if($ret_str->{node}->{$label}->{score}->{$score_name} != $threshold);
	    next;
	}

    }
    return [@ret_node];
}

sub ReturnEdgesByScore{
    my $str = shift;
    my $ret_str = $str;
    my %attribute = (
		     -threshold => 0,
		     -operator => 'above', # above below above_or_equal below_or_equal equal
		     -statistic => undef, # average median
		     -statistic_threshold => undef, # uncoded
		     -score_name => undef, # c.f. hub_weight
		     @_,
		     );
    
    if(!defined $attribute{-score_name}){
	my @sources = keys %{$ret_str->{edge}};
	my @targets = keys %{$ret_str->{edge}->{$sources[0]}};
	my @score_names = keys %{$ret_str->{edge}->{$sources[0]}->{$targets[0]}};
	$attribute{-score_name} = $score_names[0];
    }

    my $threshold = $attribute{-threshold};
    my $operator = $attribute{-operator};
    my $statistic = $attribute{-statistic};
    my $score_name = $attribute{-score_name};
    
    if($statistic){
	my @score_array = ();
	for my $source (keys %{$ret_str->{edge}}){
	    for my $target (keys %{$ret_str->{edge}->{$source}}){
		push @score_array, $ret_str->{edge}->{$source}->{$target}->{score}->{$score_name};
		
	    }
	}
	
	if($statistic eq 'average'){
	    my $sum = 0;
	    for(@score_array){
		$sum += $_;
	    }
	    $threshold = $sum / ($#score_array + 1);
	}elsif($statistic eq 'median'){
	    my @sort_array = sort {$a <=> $b} @score_array;
	    if(($#sort_array + 1) % 2 == 1){
		$threshold = $sort_array[int($#sort_array/2)-1];
	    }else{
		$threshold = 
		    ($sort_array[int(($#sort_array-1)/2)-1] + $sort_array[int(($#sort_array+1)/2)-1]) / 2;
	    }
	}
    }
    
    my $ret_edge = undef;
    
    for my $source (keys %{$ret_str->{edge}}){
	for my $target (keys %{$ret_str->{edge}->{$source}}){
	    if($operator eq 'above' || $operator eq '>'){
		$ret_edge->{$source}->{$target} = 1
		    if($ret_str->{edge}->{$source}->{$target}->{score}->{$score_name} > $threshold);
		next;
	    }
	    if($operator eq 'below' || $operator eq '<'){
		$ret_edge->{$source}->{$target} = 1
		    if($ret_str->{edge}->{$source}->{$target}->{score}->{$score_name} < $threshold);
		next;
	    }
	    if($operator eq 'above_or_equal' || $operator eq '>='){
		$ret_edge->{$source}->{$target} = 1
		    if($ret_str->{edge}->{$source}->{$target}->{score}->{$score_name} >= $threshold);
		next;
	    }
	    if($operator eq 'below_or_equal' || $operator eq '<='){
		$ret_edge->{$source}->{$target} = 1
		    if($ret_str->{edge}->{$source}->{$target}->{score}->{$score_name} <= $threshold);
		next;
	    }
	    if($operator eq 'equal' || $operator eq '=='){
		$ret_edge->{$source}->{$target} = 1
		    if($ret_str->{edge}->{$source}->{$target}->{score}->{$score_name} == $threshold);
		next;
	    }
	    if($operator eq 'not_equal' || $operator eq '!='){
		$ret_edge->{$source}->{$target} = 1
		    if($ret_str->{edge}->{$source}->{$target}->{score}->{$score_name} != $threshold);
		next;
	    }
	}
    }
    return $ret_edge;
}

sub ReturnIndependentNetworks{
    my $str = shift;
    my $limit_str = shift;
    my $ret_str = $str;
    my %attribute = (
		     -as_hash_ref => undef, # if defined, return networks as hash refs 
		     @_,
		     );

    for my $label (keys %{$ret_str->{node}}){
        if(! defined $limit_str->{node}->{$label}){
            delete $ret_str->{node}->{$label};
        }
    }
    for my $source (keys %{$ret_str->{edge}}){
        for my $target (keys %{$ret_str->{edge}->{$source}}){
            if(! defined $limit_str->{edge}->{$source}->{$target}){
                delete $ret_str->{edge}->{$source}->{$target};
            }
        }
    }
    


    our %label2nid = ();
    for my $label (keys %{$ret_str->{node}}){
	if(!defined $ret_str->{node}->{$label}->{disable} ||
	   $ret_str->{node}->{$label}->{disable} == 0){
	    $label2nid{$label} = 0;
	}else{
	    delete $ret_str->{node}->{$label}->{disable};
	}
    }
    
    our $edgestr = undef;
    our $edge2nid = undef;
    for my $source (keys %{$ret_str->{edge}}){
	for my $target (keys %{$ret_str->{edge}->{$source}}){
	    if(!defined $ret_str->{edge}->{$source}->{$target}->{disable} ||
	       $ret_str->{edge}->{$source}->{$target}->{disable} == 0){
		$edge2nid->{$source}->{$target} = 0;
		$edgestr->{$source}->{$target} = 1;
		$edgestr->{$target}->{$source} = 1;
	    }else{
		delete $ret_str->{edge}->{$source}->{$target}->{disable};
	    }
	}
    }
    
    my $nid = 1;
    our $nid2edge = undef;
    for my $label (keys %label2nid){
	next if($label2nid{$label} != 0);
	&ReturnIndependentNetworksCal($label, $nid);
	$nid++;
    }
    
    my @ret_edges = ();
    for my $nid_tmp (keys %{$nid2edge}){
	push @ret_edges, $nid2edge->{$nid_tmp};
    }
    
    if(defined $attribute{-as_hash_ref}){
	return [@ret_edges];
    }else{
	my @ret_networks = ();

	for my $ret_edge (@ret_edges){
	    my $ret_node = undef;
	    for my $source (keys %{$ret_edge}){
		for my $target (keys %{$ret_edge->{$source}}){
		    $ret_node->{$source} = 1;
		    $ret_node->{$target} = 1;
		}
	    }
	    
	    my $limit_str = undef;
	    $limit_str->{node} = $ret_node;
	    $limit_str->{edge} = $ret_edge;
	    push @ret_networks, &ReturnLimitedNetwork(
						      $str,
						      $limit_str,
						      );
	}

	return [@ret_networks];
    }



    sub ReturnIndependentNetworksCal{
	my $label = shift;
	my $nid = shift;
	
	$label2nid{$label} = $nid;
	for my $target (keys %{$edgestr->{$label}}){
	    if(defined $edge2nid->{$label}->{$target} && $edge2nid->{$label}->{$target} == 0){
		$nid2edge->{$nid}->{$label}->{$target} = 1;
	    }elsif(defined $edge2nid->{$target}->{$label} && $edge2nid->{$target}->{$label} == 0){
		$nid2edge->{$nid}->{$target}->{$label} = 1;
	    }
	    if($label2nid{$target} == 0){
		&ReturnIndependentNetworksCal($target, $nid);
	    }
	}
    }
}

sub ReturnCliques{
    my $str = shift;
    my $limit_str = shift;
    my $threshold = shift; # default 4 is imputed in Return() No exception required.

    if($threshold < 3){
        carp "Analyzing method ReturnCliques() unaccept option \'-threshold\' cause -threshold < 3";
        exit;
    }

    my $ret_str = $str;
    for my $label (keys %{$ret_str->{node}}){
        if(! defined $limit_str->{node}->{$label}){
            delete $ret_str->{node}->{$label};
        }
    }
    for my $source (keys %{$ret_str->{edge}}){
        for my $target (keys %{$ret_str->{edge}->{$source}}){
            if(! defined $limit_str->{edge}->{$source}->{$target}){
                delete $ret_str->{edge}->{$source}->{$target};
            }
        }
    }

    our $estr = undef;
    our $cstr = undef;
    for my $source (keys %{$str->{edge}}){
        for my $target (keys %{$str->{edge}->{$source}}){
	    if($source eq $target){
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
        last if (!&FindCliquesInReturn($i));
    }


    my @ret_networks = ();
    my $i = $threshold;
    for(;;){
        if(defined $cstr->{$i} && scalar @{$cstr->{$i}}){
            for my $node_hash (@{$cstr->{$i}}){
                my $ret_network_limit = undef;
		$ret_network_limit->{node} = $node_hash;

		push @ret_networks, &ReturnLimitedNetwork(
							  $ret_str,
							  $ret_network_limit,
							  );
	    }
	}else{
            last;
        }
        $i++;
    }
    return [@ret_networks];

    sub FindCliquesInReturn{
	my $object_num = shift;
	my $flag = 0;
	for my $os_hash (@{$cstr->{$object_num-1}}){ # os hash
	    for my $os_hash2 (@{$cstr->{$object_num-1}}){
		my @no_match = grep{!$os_hash2->{$_}} keys %{$os_hash};
		if($#no_match == 0){
		    my @no_match2 = grep{!$os_hash->{$_}} keys %{$os_hash2};
		    if($estr->{$no_match[0]}->{$no_match2[0]}){
			my %node_hash = map{$_, 1} keys %{$os_hash}, keys %{$os_hash2};
			unless(&FindOldCliqueInReturn($object_num, \%node_hash)){
			    push @{$cstr->{$object_num}}, \%node_hash;
			    $flag = 1 if($flag == 0);
			}
		    }
		}
	    }
	}
	return $flag;
    }

    sub FindOldCliqueInReturn{
	my $object_num = shift;
	my %node_hash = %{shift(@_)};
	for my $os_hash (@{$cstr->{$object_num}}){
	    next if(scalar(grep{!$node_hash{$_}} keys %{$os_hash}) != 0);
	    return 1;
	}
	
	return 0;
    }
    
}


sub ReturnLimitedNetwork{
    my $ori_str = shift;
    my $limit_str = shift;
 
    my $str = dclone($ori_str);
    
    my $able_nodes = undef;
    my $able_edges = undef;
    
    my $ret_str = \%{$str};
    
    for my $label (keys %{$str->{node}}){
	$able_nodes->{$label} = 0;
    }
#    for my $label (@{$attribute{-node}}){
    for my $label (keys %{$limit_str->{node}}){
	$able_nodes->{$label} = 1;
    }
    
    for my $label (keys %{$str->{node}}){
	delete $ret_str->{node}->{$label} if(! $able_nodes->{$label});
    }

    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$ret_str->{edge}->{$source}}){
	    $able_edges->{$source}->{$target} = 0;
	}
    }
    
    my @edgearray = keys %{$limit_str->{edge}};
    if($#edgearray == -1){
	for my $source (keys %{$str->{edge}}){
	    for my $target (keys %{$str->{edge}->{$source}}){

		$able_edges->{$source}->{$target} = 1 
		    if($able_nodes->{$source} && $able_nodes->{$target});
	    }
	}
    }else{
	for my $source (keys %{$limit_str->{edge}}){
	    for my $target (keys %{$limit_str->{edge}->{$source}}){
		$able_edges->{$source}->{$target} = 1
		    if($able_nodes->{$source} && $able_nodes->{$target});
	    }
	}
    }
    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	    delete $ret_str->{edge}->{$source}->{$target} if(!$able_edges->{$source}->{$target});
	}
	delete $ret_str->{edge}->{$source} if(scalar(keys %{$ret_str->{edge}->{$source}}) == 0);
    }
    return $ret_str;
}

=c
sub ReturnLimitedNetwork{
    my $str = shift;
    my $limit_str = shift;
    
    my $able_nodes = undef;
    my $able_edges = undef;
    
    my $ret_str = undef;
    
    $ret_str->{graphed} = 1 if(defined $str->{graphed} && $str->{graphed} == 1);
    
    for my $label (keys %{$str->{node}}){
	$able_nodes->{$label} = 0;
    }
#    for my $label (@{$attribute{-node}}){
    for my $label (keys %{$limit_str->{node}}){
	$able_nodes->{$label} = 1;
    }
    
    for my $label (keys %{$str->{node}}){
	if($able_nodes->{$label}){
	    $ret_str->{node}->{$label} =  $str->{node}->{$label};
	}
    }
    
    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	    $able_edges->{$source}->{$target} = 0;
	}
    }
    
    my @edgearray = keys %{$limit_str->{edge}};
    if($#edgearray == -1){
	for my $source (keys %{$str->{edge}}){
	    for my $target (keys %{$str->{edge}->{$source}}){

		$able_edges->{$source}->{$target} = 1 
		    if($able_nodes->{$source} && $able_nodes->{$target});
	    }
	}
    }else{
	for my $source (keys %{$limit_str->{edge}}){
	    for my $target (keys %{$limit_str->{edge}->{$source}}){
		$able_edges->{$source}->{$target} = 1
		    if($able_nodes->{$source} && $able_nodes->{$target});
	    }
	}
    }
    for my $source (keys %{$str->{edge}}){
	for my $target (keys %{$str->{edge}->{$source}}){
	    $ret_str->{edge}->{$source}->{$target} = $str->{edge}->{$source}->{$target}
	    if($able_edges->{$source}->{$target});
	}

#	$ret_str->{edge}->{$source} = $ret_str->{edge}->{$source} 
#	if(scalar(keys %{$ret_str->{edge}->{$source}}) == 0);
    }

    my $blessed_ret_str = eXpanda->new($ret_str);
    return $blessed_ret_str;
}
=cut


1;
