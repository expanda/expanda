#!perl
use strict;
use warnings;

eXpanda::Test->runtests;

package eXpanda::Test;
use base qw/Test::Class/;
use Test::More;

###### Test File for Analysis.pm ######
use eXpanda;

sub setup : Test(setup) {
  my $str1 = bless {
		    node => {
			     'hoge1' => { index => 4, label => 'a', information => undef },
			     'hoge2' => { index => 3, label => 'b', information => undef },
			     'hoge3' => { index => 1, label => 'c', information => undef },
			     'hoge4' => { index => 1, label => 'd', information => undef },
			    },
		    edge => {
			     'hoge1' => {
					 'hoge2' => { information => undef },
					 'hoge4' => { information => undef },
					},
			     'hoge2' => {
					 'hoge3' => { information => undef },
					 'hoge4' => { information => undef },
					},
			    },
		   }, 'eXpanda';

  my $str2 = bless {
		    node => {
			     'hoge1'  => { index => 4, label => 'a',information => undef },
			     'hoge2'  => { index => 3, label => 'b',information => undef },
			     'hoge5' => { index => 'popopo', label => 'p',information => undef },
			     'hoge4'  => { index => 1, label => 'd',information => undef},
			    },
		    edge => {
			     'hoge1' => {
					 'hoge2' => { information => undef },
					 'hoge4' => { information => undef },
					},
			     'hoge5' => {
					  'hoge1' => { information => undef },
					},
			    },
		   }, 'eXpanda';

  my $self = shift;

  $self->{sample} = {
		     'sample1' => $str1,
		     'sample2' => $str2,
		    };
}

sub test_calc : Tests( 1 ) {
  my $str_ref = shift->{'sample'};
  my $count;

#  ok $count = $$str_ref{sample1}->Accuracy( -with => $$str_ref{sample2} );
  my $return = $$str_ref{sample1}->Return(
					  -network => { -operator => "cap",
							-with => $$str_ref{sample2},
						      }
					 );
  is ref $return , 'eXpanda';
}

sub test_methods_load : Test(1) {
  my $str_ref = shift->{'sample'};

  can_ok ( $$str_ref{sample1}, qw(Apply Return Analyze out) );
}


1;
