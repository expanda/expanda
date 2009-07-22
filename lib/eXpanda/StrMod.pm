package eXpanda::StrMod;

use Data::Dumper;
use Carp;
use Storable qw(dclone);
use eXpanda::Graphics::Color;
use base qw/Exporter/;
our @EXPORT_OK = qw{ApplyGraphics};

sub ApplyAttributesFromFile{
  my $str = shift;
  my $file = shift;
  my %attribute = (
    -limit => undef,
    -object => undef,
    @_,
  );
  my $limit = $attribute{-limit};
  my $object = $attribute{-object};
  my $limit_flag = 0;
  $limit_flag = 1 if(!defined $limit);
  my $base = undef;
  my $att = undef;
  if(defined $object && $object =~ /:/){
    ($base, $att) = split /:/, $object;
  }else{
    carp "Subroutin Apply() must be set option \'-object\'. Such as 'all:graphics'\n";
    exit;
  }

  my %l2id = ();
  for my $nid (keys %{$str->{node}}){
    $l2id{$str->{node}->{$nid}->{label}} = $nid;
  }
  open(F,$file);
  while(<F>){
    chomp;
    if(($base eq 'all' || $base eq 'node') && 
      /^node\t(.+?)\t(.+?)\t(.+)$/){
      next if(!defined $l2id{$1});
      my $label = $l2id{$1};
      my $style = $2;
      my $value = $3;
      if(defined $str->{node}->{$label}->{label}){

        if($limit_flag || defined $limit->{node}->{$label}){
          $str->{node}->{$label}->{$att}->{$style} = $value;
        }else{
          delete $limit->{node}->{$label}
          if(defined $limit->{node}->{$label});
        }
      }else{
        delete $str->{node}->{$label};
      }
    }elsif(($base eq 'all' || $base eq 'edge')&& 
      $_=~/^edge\t(.+?)\t(.+?)\t(.+?)\t(.+)$/){
      my $labelS = $l2id{$1};
      my $labelT = $l2id{$2};

      my $labelKey = "$labelS\|$labelT";

      my $style = $3;
      my $value = $4;
      if(defined $str->{edge}->{$labelS}->{$labelT}->{label}){
        if($limit_flag || #|| 
          defined $limit->{edge}->{$labelS}->{$labelT} 
#		   || defined $limit->{edge}->{$labelT}->{$labelS}
        ){
          $str->{edge}->{$labelS}->{$labelT}->{$att}->{$style} = $value;
        }else{
          delete $str->{edge}->{$labelS}->{$labelT}
          if(defined $limit->{edge}->{$labelS}->{$labelT} ||
            defined $limit->{edge}->{$labelT}->{$labelS});
        }
      }else{
        delete $str->{edge}->{$labelS}->{$labelT};
      }
    }
  }
  close F;
}

sub ApplyNodeScore{
  my $str = shift;
  my $ret_str = $str;
  my $label = shift;
  my %attribute = (
    -value => undef,
    -score_name => undef,
    @_,
  );
  my $value = $attribute{-value};

  my $score_name = $attribute{-score_name};
  if(! defined $score_name){
    my ($tmplabel, $nodestr) = each %{$ret_str->{node}};
    my %score_names_index = ();
    map{$score_names_index{$_} = 1} keys %{$nodestr->{score}};
    for(my $i = 0;$i++;){
      if(!defined $score_names_index{$i}){
        $score_name = $i;
        last;
      }
    }
  }

  if(defined $ret_str->{node}->{$label}){
    $str->{node}->{$label}->{score}->{$score_name} = $value;
  }else{
    croak "Node $label does not exist in ReturnNodeScore";
  }
}


sub ApplyEdgeScore{
  my $str = shift;
  my $ret_str = $str;
  my $source = shift;
  my $target = shift;
  my %attribute = (
    -value =>undef,
    -score_name => undef,
    @_,
  );
  my $value = $attribute{-value};

  my $score_name = $attribute{-score_name};
  if(! defined $score_name){
    my ($tmpsource, $edgestr1) = each %{$ret_str->{edge}};
    my ($tmptarget, $edgestr2) = each %{$edgestr1};
    my %score_names_index = ();
    map{$score_names_index{$_} = 1} keys %{$edgestr2->{score}};
    for(my $i = 0;$i++;){
      if(!defined $score_names_index{$i}){
        $score_name = $i;
        last;
      }
    }
  }

  if(defined $ret_str->{edge}->{$source}->{$target}){
    $ret_str->{edge}->{$source}->{$target}->{score}->{$score_name} = $value;
  }else{
    croak "Edge $source tp $target does not exist in ReturnNodeScore";
  }
}

sub ApplyNodeInformation{
  my $str = shift;
  my $ret_str = $str;
  my $label = shift;
  my %attribute = (
    -value => undef,
    -information_name => undef,
    @_,
  );
  my $value = $attribute{-value};

  my $information_name = $attribute{-information_name};
  if(! defined $information_name){
    my ($tmplabel, $nodestr) = each %{$ret_str->{node}};
    my %information_names_index = ();
    map{$information_names_index{$_} = 1} keys %{$nodestr->{information}};
    for(my $i = 0;$i++;){
      if(!defined $information_names_index{$i}){
        $information_name = $i;
        last;
      }
    }
  }


  if(defined $ret_str->{node}->{$label}){
    $str->{node}->{$label}->{information}->{$information_name} = $value;
  }else{
    croak "Node $label does not exist in ReturnNodeInformation";
  }
}


sub ApplyEdgeInformation{
  my $str = shift;
  my $ret_str = $str;
  my $source = shift;
  my $target = shift;
  my %attribute = (
    -value =>undef,
    -information_name => undef,
    @_,
  );
  my $value = $attribute{-value};
  my $information_name = $attribute{-information_name};
  if(! defined $information_name){
    my ($tmpsource, $edgestr1) = each %{$ret_str->{edge}};
    my ($tmptarget, $edgestr2) = each %{$edgestr1};
    my %information_names_index = ();
    map{$information_names_index{$_} = 1} keys %{$edgestr2->{information}};
    for(my $i = 0;$i++;){
      if(!defined $information_names_index{$i}){
        $information_name = $i;
        last;
      }
    }
  }

  if(defined $ret_str->{edge}->{$source}->{$target}){
    $ret_str->{edge}->{$source}->{$target}->{information}->{$information_name} = $value;
  }else{
    croak "Edge $source tp $target does not exist in ReturnNodeInformation";
  }
}


sub ApplyNodeLabel{
  my $str = shift;
  my $label = shift;
  my %attribute = (
    -label => undef,
    @_,
  );
  my $new_label = $attribute{-label};
  croak "node $label is not defined in ApplyNodeLabel"
  unless(defined $str->{node}->{$label});
  $str->{node}->{$label}->{label} = $new_label;
}

sub ApplyEdgeLabel{
  my $str = shift;
  my $source = shift;
  my $target = shift;
  my %attribute = (
    -label => undef,
    @_,
  );
  my $new_label = $attribute{-label};
  croak "edge $source - $target is not defined in ApplyEdgeLabel" 
  unless(defined $str->{edge}->{$source}->{$target}->{label});

  $str->{edge}->{$source}->{$target}->{label} = $new_label;
}

sub ApplyNodeGraphics{
  my $str = shift;
  my $label = shift;
  my %attribute = (
    -attribute => undef,
    @_,
  );
  my %graphics_attribute = %{$attribute{-attribute}};
  my $ret_str = $str;

  croak "node $label is not defined in ApplyNodeGraphics" 
  unless(defined $ret_str->{node}->{$label});

  my @atts = qw(start fill stroke stroke-width w type opacity stroke-opacity smile smilepo font-size font-family font-color font-opacity stroke-dash);
  my %checkatts=();
  map{$checkatts{$_} = 1} @atts;
  for my $att (keys %graphics_attribute){
    croak "$att is invalid attribute in ApplyNodeGraphics"
    unless(defined $checkatts{$att});
  }

  for my $att (@atts){
    $ret_str->{node}->{$label}->{graphics}->{$att} = $graphics_attribute{$att}
    if(defined $graphics_attribute{$att});
  }

  $str = $ret_str;
}

sub ApplyEdgeGraphics{
  my $str = shift;
  my $source = shift;
  my $target = shift;
  my %attribute = (
    -attribute => undef,
    @_,
  );
  my %graphics_attribute = %{$attribute{-attribute}};
  my $ret_str = $str;

  croak "edge $source to $target is not defined in ApplyNodeGraphics" 
  unless(defined $ret_str->{edge}->{$source}->{$target});

  my @atts = qw(stroke-width stroke opacity font-size font-family font-color font-opacity stroke-dash type);
  my %checkatts=();
  map{$checkatts{$_} = 1} @atts;
  for my $att (keys %graphics_attribute){
    croak "$att is invalid attribute in ApplyEdgeGraphics"
    unless(defined $checkatts{$att});
  }

  for my $att (@atts){
    $ret_str->{edge}->{$source}->{$target}->{graphics}->{$att} = $graphics_attribute{$att}
    if(defined $graphics_attribute{$att});

  }

  $str = $ret_str;
}


# void subroutin
sub ChangeNodeAvailable{
  my $str = shift;
  my $label = shift;
  my %attribute = (
    -available => 'disable', # disable enable
    @_,
  );
  my $value = 1;
  $value = 0 if($attribute{-available} eq 'enable');

  $str->{node}->{$label}->{disable} = $value;
  for my $source (keys %{$str->{edge}}){
    for my $target (keys %{$str->{edge}->{$source}}){
      if($source eq $label || $target eq $label){
        if($attribute{-available} eq 'enable'){
          $str->{edge}->{$source}->{$target}->{disable} = 0 
          if($str->{edge}->{$source}->{$target}->{disable} != 1);
        }elsif($attribute{-available} eq 'disable'){
          $str->{edge}->{$source}->{$target}->{disable} = 1;
        }
      }
    }
  }
}


# void subroutin
sub ChangeEdgeAvailable{
  my $str = shift;
  my $source = shift;
  my $target = shift;
  my %attribute = (
    -available => 'disable', # disable enable
    @_,
  );
  my $value = 1;
  $value = 0 if($attribute{-available} eq 'enable');

  $str->{edge}->{$source}->{$target}->{disable} = $value;
}


sub ApplyGraphics{
  my $str = shift;
  my %attribute = (
    -object_size => 1,
    -label_size => 1,
    %{shift(@_)},
  );

  my $object_size = $attribute{'-object_size'};
  my $label_size = $attribute{'-label_size'};
  my $temp_str = dclone($str);
  my $gstr = bless {}, 'eXpanda';

  if (defined($str->{background})) {
    $gstr->{background} = $str->{background};
  }

  for my $label (keys %{$temp_str->{node}}){ 
    $gstr->{node}->{$label}->{graphics} =
    $temp_str->{node}->{$label}->{graphics};
    $gstr->{node}->{$label}->{label} =
    $temp_str->{node}->{$label}->{label};
    $gstr->{node}->{$label}->{id} =
    $temp_str->{node}->{$label}->{id};
    $gstr->{node}->{$label}->{component} =
    $temp_str->{node}->{$label}->{component};
  }

  for my $source (keys %{$temp_str->{edge}}){
    for my $target (keys %{$temp_str->{edge}->{$source}}){
      $gstr->{edge}->{$source}->{$target}->{graphics} =
      $temp_str->{edge}->{$source}->{$target}->{graphics};
      $gstr->{edge}->{$source}->{$target}->{source} =
      $temp_str->{edge}->{$source}->{$target}->{source};
      $gstr->{edge}->{$source}->{$target}->{target} =
      $temp_str->{edge}->{$source}->{$target}->{target};
      $gstr->{edge}->{$source}->{$target}->{label} =
      $temp_str->{edge}->{$source}->{$target}->{label};

    }
  }

  $gstr->{graphed} = 1 if (defined $temp_str->{graphed} && $temp_str->{graphed} == 1);

  my %def_node_graphics = (
    w => 6,
    'stroke-width' => 1,
    opacity => 1,
    'stroke-opacity' => 1,
    'font-opacity' => 1,
    'font-size' => 1,
    fill => '#FFFFFF',
    stroke => '#000000',
    'font-color' => '#000000',
    'font-family' => 'Arial',
    type => 'oval',
    'stroke-dash' => 'none',
  );

  for my $label (keys %{$gstr->{node}}){
    my %graphics = (defined $gstr->{node}->{$label}->{graphics}) 
    ? %{$gstr->{node}->{$label}->{graphics}} : ();

    %graphics = (
      %def_node_graphics,
      %graphics,
    );

    for my $att (keys %graphics){
      if($att eq 'w' ||
        $att eq 'stroke-width'
      ){
        $graphics{$att} *= $object_size;
      }elsif($att eq 'font-size'){
        $graphics{$att} *= $label_size;
      }
      if($att eq 'stroke-dash' && $graphics{$att} ne 'none'){
        my @list = split /,\s*/, $graphics{$att};
        my @ret_list = ();
        for my $val (@list){
          push @ret_list, $val * $object_size;
        }
        $graphics{$att} = join ',', @ret_list;
      }
    }
    %{$gstr->{node}->{$label}->{graphics}} = (
      %graphics,
    );

  }

  my %def_edge_graphics = (
    'stroke-width' => 1,
    stroke => '#000000',
    opacity => 1,
    'font-size' => 1,
    'font-family' => 'Arial',
    'font-opacity' => 1,
    'font-color' => '#000000',
    'stroke-dash' => 'none',
  );

  for my $source (keys %{$gstr->{edge}}){
    for my $target (keys %{$gstr->{edge}->{$source}}){
      my %graphics = (defined $gstr->{edge}->{$source}->{$target}->{graphics}) 
      ? %{$gstr->{edge}->{$source}->{$target}->{graphics}} : ();

      %graphics = (
        %def_edge_graphics,
        %graphics,
      );
      for my $att (keys %graphics){
        if($att eq 'stroke-width'){
          $graphics{$att} *= $object_size;
        }elsif($att eq 'font-size'){
          $graphics{$att} *= $label_size;
        }
        if($att eq 'stroke-dash' && $graphics{$att} ne 'none'){
          my @list = split /,\s*/, $graphics{$att};
          my @ret_list = ();
          for my $val (@list){
            push @ret_list, $val * $object_size;
          }
          $graphics{$att} = join ',', @ret_list;
        }
      }
      %{$gstr->{edge}->{$source}->{$target}->{graphics}} = (
        %graphics,
      );

    }
  }

  return $gstr;
}


sub ApplyMethod2Graphics{
  my $str = shift;
  my %attribute = (
    -method => undef,
    -apply => undef,
    -value => undef,
    -limit => undef,
    @_,
  );

  my $score_name = $attribute{-method};
  my $gradient = $attribute{-value};
  my $value = $attribute{-value};
  my $limit = $attribute{-limit};
  my $overwrite = 1;

  my @node_graphics_list_def = qw(w fill stroke opacity 'stroke-width');
  my @node_graphics_list = ();
  my %nodegraphicsreserved =();

  if ($overwrite) {
    @node_graphics_list = @node_graphics_list_def;
  }
  else {
    for my $label (keys %{$str->{node}}){
      for my $graphics (keys %{$str->{node}->{$label}->{graphics}}){
        $nodegraphicsreserved{$graphics} = 1;# if(!defined $nodedesingreserved{$graphics});
      }
    }
    for(@node_graphics_list_def){
      push @node_graphics_list, $_ if(!defined $nodegraphicsreserved{$_});
    }
  }

  my @edge_graphics_list_def = qw(width fill opacity);
  my @edge_graphics_list = ();
  my %edgegraphicsreserved =();

  if($overwrite){
    @edge_graphics_list = @edge_graphics_list_def;
  }else{
    for my $source (keys %{$str->{edge}}){
      for my $target (keys %{$str->{edge}->{$source}}){
        for my $graphics (keys %{$str->{edge}->{$source}->{$target}->{graphics}}){
          $edgegraphicsreserved{$graphics} = 1;# if(!defined $nodedesingreserved{$graphics});
        }
      }
    }
    for ( @edge_graphics_list_def ) {
      push @edge_graphics_list, $_ if(!defined $edgegraphicsreserved{$_});
    }
  }

  if($score_name eq 'hub_weight' ||
    $score_name eq 'connectivity' ||
    $score_name eq 'centrity'){
    if($attribute{-apply} eq ''){
      $attribute{-apply} = 'node:graphics:' . $node_graphics_list[0];
    }
  }elsif(0){
    if($attribute{-apply} eq ''){
      $attribute{-apply} = 'edge:graphics:' . $edge_graphics_list[0];
    }

  }

  if($attribute{-apply} =~ /^node\:.*?\:(.*?)$/){
    my $score_obj = $1;
    my $nodemax = undef;
    my $nodemin = undef;
    my $nodeflag = 1;
    my $heat_flag = 0;

    for my $label (keys %{$str->{node}}){
      if(
        (
          (!defined $str->{node}->{$label}->{disable}) ||
          (defined $str->{node}->{$label}->{disable} &&
            $str->{node}->{$label}->{disable} == 0)
        ) &&
        !defined $str->{node}->{$label}->{score}->{$score_name}){
        delete $str->{node}->{$label}->{score}->{$score_name};
        croak "Score \"$score_name\": undefined node exist in ApplyMethod2Graphics().\n";
      }else{

        if(defined $nodemax){
          $nodemax = ($str->{node}->{$label}->{score}->{$score_name} > $nodemax)
          ? $str->{node}->{$label}->{score}->{$score_name} : $nodemax;
        }else{
          $nodemax = $str->{node}->{$label}->{score}->{$score_name};
        }

        if(defined $nodemin){
          $nodemin = ($str->{node}->{$label}->{score}->{$score_name} < $nodemin)
          ? $str->{node}->{$label}->{score}->{$score_name} : $nodemin;
        }else{
          $nodemin = $str->{node}->{$label}->{score}->{$score_name};
        }
      }
    }

    if($nodeflag){
      my @rgb_from = ();
      my @rgb_bi = ();
      my $value_from = undef;
      my $value_to = undef;
      my $value_bi = undef;
      my $value_type = "color";

      if( $score_obj eq 'fill' ||
        $score_obj eq 'stroke' ||
        $score_obj eq 'smile' ||
        $score_obj eq 'smilepo' ||
        $score_obj eq 'font-color' ){

        my $grad_from = undef;
        my $grad_to = undef;
        my $grad_flag = 0;

        if(ref $gradient){
          my @void = each %{$gradient};
          if($void[0] =~ /^\#/ && $void[1] =~ /^\#/){
            ($grad_from, $grad_to) = @void;
          }else{
            $grad_flag = 1;
          }
        }
        elsif ($gradient eq 'heat' || $gradient eq 'heatcolor') {
          print "[debug] Heat flag is on..\n";
          $heat_flag = 1;
        }
        else {
          $grad_flag = 1;
        }

        ($grad_from, $grad_to) = ('#FFFFFF', '#000000') if ($grad_flag);

        $grad_from =~ /\#*(..)(..)(..)/;
        my @rgb_from_tmp =($1, $2, $3);
        $grad_to =~ /\#*(..)(..)(..)/;
        my @rgb_to_tmp =($1, $2, $3);
        for my $i (0..2){
          $rgb_from[$i] = hex($rgb_from_tmp[$i]);
          $rgb_bi[$i] = hex($rgb_to_tmp[$i]) - hex($rgb_from_tmp[$i]);
        }

      } elsif ($score_obj eq 'w' || 
        $score_obj eq 'opacity' || 
        $score_obj eq 'stroke-width' || 
        $score_obj eq 'stroke-opacity' ||
        $score_obj eq 'font-size' ||
        $score_obj eq 'font-opacity'){

        $value_type = 'float';

        my $val_flag = 0;
        if(ref $value){
          my @void = each %{$value};
          if($void[0] =~ /^\d+\.?\d*/ && $void[1] =~ /^\d+\.?\d*/){
            ($value_from, $value_to) = @void;
          }else{
            $val_flag = 1;
          }
        }else{
          $val_flag = 1;
        }

        if($val_flag){
          if($score_obj eq 'w'){
            ($value_from, $value_to) = (
              3,
              9
            );
          }elsif($score_obj eq 'opacity'){
            ($value_from, $value_to) = (
              0.3,
              1
            );
          }elsif($score_obj eq 'stroke-opacity'){
            ($value_from, $value_to) = (
              0.3,
              1
            );
          }elsif($score_obj eq 'stroke-width'){
            ($value_from, $value_to) = (
              0.5,
              1.5
            );
          }elsif($score_obj eq 'font-size'){
            ($value_from, $value_to) = (
              0.5,
              1.5
            );
          }elsif($score_obj eq 'font-opacity'){
            ($value_from, $value_to) = (
              0.3,
              1
            );
          }
        }

        $value_bi = $value_to - $value_from;

      }
      else{
        croak qq{Invalid graphics object "$score_obj" has been set at Apply(-object)};
      }
      my $nodearea = $nodemax - $nodemin;
      $nodearea = 1 if ($nodearea == 0);

      for my $label (keys %{$str->{node}}) {
        my $optimized = ($str->{node}->{$label}->{score}->{$score_name} - $nodemin) / $nodearea;

        if ($value_type eq 'color') {
          my $color = '';

          if ( $heat_flag == 1 ) {
            $color = eXpanda::Graphics::Color::hexHeat($str->{node}->{$label}->{score}->{$score_name},
              $nodemin, $nodemax);
          }
          else {
            for my $i (0..2) {
              my $color_tmp = sprintf "%X", int($rgb_from[$i] + $optimized * $rgb_bi[$i]);
              $color_tmp = '0'.$color_tmp if(length $color_tmp == 1);
              $color .= $color_tmp;
            }
          }
          $color = '#' . $color;

          $str->{node}->{$label}->{graphics}->{$score_obj} = $color
          unless ((! $overwrite && defined $str->{node}->{$label}->{graphics}->{$score_obj}) ||
            !defined $limit->{node}->{$label}
          );
        } elsif ($value_type eq 'float') {
          my $input_value = $value_from + $optimized * $value_bi;
          $str->{node}->{$label}->{graphics}->{$score_obj} = $input_value
          unless ((! $overwrite && defined $str->{node}->{$label}->{graphics}->{$score_obj} &&
              $str->{node}->{$label}->{graphics}->{$score_obj} ne '' ) ||
            !defined $limit->{node}->{$label}
          );
        }
      }
    }
  }elsif($attribute{-apply} =~ /^edge\:.*?\:(.*?)$/){
    my $score_obj = $1;
    my $edgemax = undef;
    my $edgemin = undef;
    my $edgeflag = 1;
    for my $source (keys %{$str->{edge}}){
      for my $target (keys %{$str->{edge}->{$source}}){
        unless(defined $str->{edge}->{$source}->{$target}->{score}->{$score_name}){
          delete $str->{edge}->{$source}->{$target}->{score}->{$score_name};
          $edgeflag = 0;
          next;
        }else{
          if(defined $edgemax){
            $edgemax = ($str->{edge}->{$source}->{$target}->{score}->{$score_name} > $edgemax)? 
            $str->{edge}->{$source}->{$target}->{score}->{$score_name} : $edgemax if(defined $edgemax);
          }else{
            $edgemax = $str->{edge}->{$source}->{$target}->{score}->{$score_name};
          }
          if(defined $edgemin){
            $edgemin = ($str->{edge}->{$source}->{$target}->{score}->{$score_name} < $edgemin)? 
            $str->{edge}->{$source}->{$target}->{score}->{$score_name} : $edgemin if(defined $edgemin);
          }else{
            $edgemin = $str->{edge}->{$source}->{$target}->{score}->{$score_name};
          }
        }
      }
    }

    if($edgeflag){
      my @rgb_from = ();
      my @rgb_bi = ();
      my $value_from = undef;
      my $value_to = undef;
      my $value_bi = undef;
      my $value_type = "color";
      if($score_obj eq 'stroke' || 
        $score_obj eq 'font-color'){
        my $grad_from = undef;
        my $grad_to = undef;
        my $grad_flag = 0;

        if(ref $gradient){
          my @void = each %{$gradient};
          if($void[0] =~ /^\#/ && $void[1] =~ /^\#/){
            ($grad_from, $grad_to) = @void;
          }else{
            $grad_flag = 1;
          }
        }else{
          $grad_flag = 1;
        }
        ($grad_from, $grad_to) = ('#FFFFFF', '#000000') if($grad_flag);


        $grad_from =~ /\#*(..)(..)(..)/;
        my @rgb_from_tmp =($1, $2, $3);
        $grad_to =~ /\#*(..)(..)(..)/;
        my @rgb_to_tmp =($1, $2, $3);
        for my $i (0..2){
          $rgb_from[$i] = hex($rgb_from_tmp[$i]);
          $rgb_bi[$i] = hex($rgb_to_tmp[$i]) - hex($rgb_from_tmp[$i]);
        }
      }elsif($score_obj eq 'stroke-width' || 
        $score_obj eq 'stroke-opacity' ||
        $score_obj eq 'font-size' ||
        $score_obj eq 'font-opacity'){
        $value_type = 'float';

        my $val_flag = 0;
        if(ref $value){
          my @void = each %{$value};
          if($void[0] =~ /^\d+\.?\d*/ && $void[1] =~ /^\d+\.?\d*/){
            ($value_from, $value_to) = @void;
          }else{
            $val_flag = 1;
          }
        }else{
          $val_flag = 1;
        }

        if($val_flag){
          if($score_obj eq 'stroke-opacity'){
            ($value_from, $value_to) = (
              0.3,
              1
            );
          }elsif($score_obj eq 'stroke-width'){
            ($value_from, $value_to) = (
              0.5,
              1.5
            );
          }elsif($score_obj eq 'font-size'){
            ($value_from, $value_to) = (
              0.5,
              1.5
            );
          }elsif($score_obj eq 'font-opacity'){
            ($value_from, $value_to) = (
              0.3,
              1
            );
          }
        }
        $value_bi = $value_to - $value_from;

      }else{
        croak qq{Invalid graphics object "$score_obj" has been set at Apply(-object)};
      }

      my $edgearea= $edgemax - $edgemin;
      for my $source (keys %{$str->{edge}}){
        for my $target (keys %{$str->{edge}->{$source}}){
          my $optimized = ($str->{edge}->{$source}->{$target}->{score}->{$score_name} - $edgemin) / $edgearea;
          if($value_type eq 'color'){
            my $color = '';
            for my $i (0..2){
              my $color_tmp = sprintf "%X", int($rgb_from[$i] + $optimized * $rgb_bi[$i]);
              $color_tmp = '0'.$color_tmp if(length $color_tmp == 1);
              $color .= $color_tmp;
            }
            $color = '#' . $color;
            $str->{edge}->{$source}->{$target}->{graphics}->{$score_obj} = $color
            unless((! $overwrite && defined $str->{edge}->{$source}->{$target}->{graphics}->{$score_obj}) ||
              ! defined $limit->{edge}->{$source}->{$target}
            );
          }elsif($value_type eq 'float'){
            my $input_value = $value_from + $optimized * $value_bi;
            $str->{edge}->{$source}->{$target}->{graphics}->{$score_obj} = $input_value
            unless((! $overwrite && defined $str->{edge}->{$source}->{$target}->{graphics}->{$score_obj}) ||
              ! defined $limit->{edge}->{$source}->{$target}
            );
          }
        }
      }
    }
  }
  return $str;
}

sub ChangeLabel{
  my $str = shift;
  my $object = shift;

  my $base = undef;
  my $att = undef;
  my $detail = undef;
  if($object !~ /:/){
    croak "Cannnot change label: object style $object not supported.";
  }
  ($base, $att, $detail) = split /:/, $object;


  if($base eq 'node'){
    for my $label (keys %{$str->{node}}){
      if ( defined($str->{node}->{$label}->{$att}->{$detail}) ) {
        $str->{node}->{$label}->{label} = 
        $str->{node}->{$label}->{$att}->{$detail};
      }
    }
  }elsif($base eq 'edge'){
    for my $source (keys %{$str->{edge}}){
      for my $target (keys %{$str->{edge}->{$source}}){
        $str->{edge}->{$source}->{$target}->{label} = 
        $str->{edge}->{$source}->{$target}->{$att}->{$detail};
      }
    }
  }

  return $str;
}

sub ResetAllGraphics{
  my $str = shift;
=c
    my %attribute = (
         -exception => undef, # disable enable
         @_,
         );
    my $nodeex = undef;
    my $edgeex = undef;

    if(ref $attribute->{-exception}){
  map{$nodeex->{$_} = 1} @{$attribute->{-exception}->{node}};
  map{$edgeex->{$_} = 1} @{$attribute->{-exception}->{edge}};
    }
=cut
#debug code
  my $nodeex = undef;
  my $edgeex = undef;
  $nodeex->{x} = 1;
  $nodeex->{y} = 1;
#EOD
  for my $label (keys %{$str->{node}}){
    for my $graphics (keys %{$str->{node}->{$label}->{graphics}}){
      unless(defined $nodeex->{$graphics}){
        delete $str->{node}->{$label}->{graphics}->{$graphics};
        delete $nodeex->{$graphics};
      }else{
      }
    }
  }

  for my $source (keys %{$str->{edge}}){
    for my $target (keys %{$str->{edge}->{$source}}){
      for my $graphics (keys %{$str->{edge}->{$source}->{$target}->{graphics}}){
        unless(defined $edgeex->{$graphics}){
          delete $str->{edge}->{$source}->{$target}->{graphics}->{$graphics};
          delete $edgeex->{$graphics};
        }
      }
    }
  }
  unless(defined $nodeex->{x} || defined $nodeex->{y}){
    delete $str->{graphed};
  }

}



1;
