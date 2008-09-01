package eXpanda::ReturnValue;
use Data::Dumper;
use Carp;

sub ReturnNodeScore{
    my $str = shift;
    my $ret_str = $str;
    my $label = shift;
    my %attribute = (
                     -score_name => undef, # c.f. hub_weight
                     @_,
                     );
    if(!defined $attribute{-score_name}){
        my ($tmplabel, $nodestr) = each %{$ret_str->{node}};
	my @score_names = keys %{$nodestr->{score}};
        $attribute{-score_name} = $score_names[0];
    }
    my $score_name = $attribute{-score_name};

    if(defined $ret_str->{node}->{$label}->{score}->{$score_name}){
	return $ret_str->{node}->{$label}->{score}->{$score_name};
    }else{
	die "Node $label does not scored at $score_name in ReturnNodeScore";
    }
}

sub ReturnEdgeScore{
    my $str = shift;
    my $ret_str = $str;
    my $source = shift;
    my $target = shift;

    my %attribute = (
                     -score_name => undef, # c.f. hub_weight
                     @_,
                     );

    if(!defined $attribute{-score_name}){
        my ($source, $edgestr1) = each %{$ret_str->{edge}};
        my ($target, $edgestr2) = each %{$edgestr1};
	my @score_names = keys %{$edgestr2->{score}};
        $attribute{-score_name} = $score_names[0];
    }
    my $score_name = $attribute{-score_name};

    if(defined $ret_str->{edge}->{$source}->{$target}->{score}){
	return $ret_str->{edge}->{$source}->{$target}->{score};
    }else{
	die "Edge $source tp $target does not exist in ReturnNodeScore";
    }
}


sub ReturnNodeLabel{
    my $str = shift;
    my $label = shift;
    
    if(defined $str->{node}->{$label}->{label}){
	return $str->{node}->{$label}->{label};
    }else{
	die "Node $label does not exist in ReturnNodeLabel";
    }
}

sub ReturnEdgeLabel{
    my $str = shift;
    my $source = shift;
    my $target = shift;

    if(defined $str->{edge}->{$source}->{$target}->{label}){
	return $str->{edge}->{$source}->{$target}->{label};
    }else{
	die "Edge $source tp $target does not labeled in ReturnEdgeLabel";
    }
}

sub ReturnNodeInformation{
    my $str = shift;
    my $ret_str = $str;
    my $label = shift;
    my %attribute = (
                     -information_name => undef, # c.f. hub_weight
                     @_,
                     );

    if(!defined $attribute{-information_name}){
        my ($tmplabel, $nodestr) = each %{$ret_str->{node}};
        #my ($information_name_tmp, $information_str) = each %{$nodestr->{information}};
	my @information_names = keys %{$nodestr->{information}};
#        $attribute{-information_name} = $information_name_tmp;
        $attribute{-information_name} = $information_names[0];
    }
    my $information_name = $attribute{-information_name};

    if(defined $ret_str->{node}->{$label}->{information}->{$information_name}){
	return $ret_str->{node}->{$label}->{information}->{$information_name};
    }else{
	carp "Node $label does not informationd at $information_name in ReturnNodeInformation" and return 0;
    }
}


sub ReturnEdgeInformation{
    my $str = shift;
    my $ret_str = $str;
    my $source = shift;
    my $target = shift;

    my %attribute = (
                     -information_name => undef, # c.f. hub_weight
                     @_,
                     );

    if(!defined $attribute{-information_name}){
        my ($source, $edgestr1) = each %{$ret_str->{edge}};
        my ($target, $edgestr2) = each %{$edgestr1};
        #my ($information_name_tmp, $information_str) = each %{$nodestr->{information}};
	my @information_names = keys %{$edgestr2->{information}};
#        $attribute{-information_name} = $information_name_tmp;
        $attribute{-information_name} = $information_names[0];
    }
    my $information_name = $attribute{-information_name};

    if(defined $ret_str->{edge}->{$source}->{$target}->{information}){
	return $ret_str->{edge}->{$source}->{$target}->{information};
    }else{
	die "Edge $source tp $target does not exist in ReturnNodeInformation";
    }
}

sub ReturnNodeNum{
    my $str = shift;
    my @num = keys %{$str->{node}};
    return $#num + 1;
}

sub ReturnEdgeNum{
    my $str = shift;
    my $checkedge = undef;
    my $num = 0;
    for my $source (keys %{$str->{edge}}){
        for my $target (keys %{$str->{edge}->{$source}}){
            if(! defined $checkedge->{$source}->{$target} && ! defined $checkedge->{$target}->{$source}){
                $num++;
                $checkedge->{$source}->{$target} = 1;
            }
        }
    }
    return $num;
}


1;
