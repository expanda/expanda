package eXpanda::Analysis::Comparative;

use strict;
use Carp;
use Data::Dumper;
use Storable;

sub Accuracy
  {
    my $self = shift;
    my $arg_ref = shift;
    my %args = (
		-object      => $$arg_ref{-object}         || 'node:label',
	        -with_object => $$arg_ref{-with_object}    || 'node:label',
		-with        => $$arg_ref{-with}           || undef,
	       );

    croak 'No -with option.' unless $args{-with};

    my @obj = split(/:/, $args{-object});
    my @with_obj = split(/:/, $args{-with_object});
    my $count;
    $count = $self->Calc( $args{-with}, (pop @obj), (pop @with_obj) , 'accuracy');
    return $$count{match_edge} / $$count{true_edge};
  }

sub Coverage
  {
    my $self = shift;
    my $arg_ref = shift;
    my %args = (
		-object      => $$arg_ref{-object}         || 'node:label',
	        -with_object => $$arg_ref{-with_object}    || 'node:label',
		-with        => $$arg_ref{-with}           || undef,
	       );

    croak 'No -with option.' unless $args{-with};
    
    my @obj = split(/:/, $args{-object});
    my @with_obj = split(/:/, $args{-with_object});
    my $count;
    ( $self, $count ) = &Calc( $self, $args{-with}, (pop @obj), (pop @with_obj) , 'accuracy');

    return ( $self, $$count{match_edge} / $$count{sample_edge} );
  }

sub Calc
  {
    my ( $self , $with ,$opt_self, $opt_with, $method ) = @_;
    my $count = ();
    my $ret_self = Storable::dclone($self);
    my ( $mtrx_self, $label_edge_with ) = ();
    my %score_self;

    while( my ( $node_id, $str ) = each %{$$self{node}} )
      {
	$$mtrx_self{$node_id} = $$str{label};
      }

    while( my ( $s_id, $str ) = each %{$$with{edge}} )
      {
	while( my ( $t_id, $str1) = each %{$str} )
	  {
	    $$label_edge_with{$$with{node}{$s_id}{label}}{$$with{node}{$t_id}{label}} = 1;
	  }
      }

    while( my ( $source, $ref1 ) = each %{$$ret_self{edge}} )
      {
	while( my ( $target, $ref2 ) = each %{$ref1} )
	  {
	    $score_self{$source}{all}++;
	    $score_self{$target}{all}++;
	    $$count{'true_edge'}++;
	    if($$label_edge_with{$$mtrx_self{$source}}{$$mtrx_self{$target}} or
	       $$label_edge_with{$$mtrx_self{$target}}{$$mtrx_self{$source}})
	      {
		print "$$mtrx_self{$source}\t$$mtrx_self{$target}\t$method\n";
		print "$source\t$target\n";
		$$count{'match_edge'}++;
		$score_self{$source}{match}++;
		$score_self{$target}{match}++;
		$$self{edge}{$source}{$target}{score}{$method} = 1;
	      }
	    else
	      {
		$$self{edge}{$source}{$target}{score}{$method} = 0;
	      }
	  }
      }

    $$count{'sample_edge'} = scalar( keys %{$$with{node}} );

    while( my ( $n_id, $refs ) = each %score_self )
      {
	$$self{node}{$n_id}{score}{$method} = $$refs{match}/$$refs{all};
      }

    #*insert result into $self.  $self is true set. result are
    # {node}->{label}->{score}->{$option} = 0..1
    # {edge}->{label}->{label}->{score}->{$option} = 0 or 1

    return $count;
  }



1;
