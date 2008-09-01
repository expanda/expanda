#!perl
use strict;
use warnings;

eXpanda::TestIdConv->runtests;

package eXpanda::TestIdConv;
use base qw/Test::Class/;
use Test::More;
use eXpanda::Services::IdConvert;

sub test_constlucter : Test(setup){
  my $self = shift;
  $self->{obj} = eXpanda::Services::IdConvert->new()->init(
							   -id => 'Q03047',
							   -from => 'uniprot',
							   -to => 'pir',
							  );

}

sub test_FindResult_retinfo : Test(3) {
  my $self = shift->{obj};
  my @index = ({ database => 'pir', primary => 'sample_pir_entry' },
	       { database => 'embl',primary => 'bbbb' } );

  my $res = $self->ReturnInformation()->result();
  is $res , 'S30900';

  $self->index(\@index);
  $self->FindResult();

  is $self->result(), 'sample_pir_entry';

  $self->init( -id => 'Q03047',
	       -from => 'uniprot',
	       -to => 'name',
	      );

  $self->parsed({
		 'date' => 'dummy',
		 'name' => 'sample_name',
		});

  $self->FindResult();

  is $self->result(), 'sample_name';
}

sub test_IdSpecDetect : Test {
  my $self = shift->{obj};

  $self->init(-id => 'Q03047',
	      -to => 'pir');

  $self->IdSpecDetect();

  is $self->from() , 'up';
}

sub test_UpParse : Test(2) {
  my $self = shift->{obj};

  $self->GetKEGG($self->query());

  ok ( $self->UpParse(), 'parsing data...' );
  ok ( defined $self->parsed(), 'parse data ok.');
}

sub test_PirParse : Test(2) {
  my $self = shift->{obj};

  $self->init( -id => 'HAFQG',
	       -from => 'pir',
	       -to => 'up',
	       );

  $self->GetKEGG($self->query());

  ok $self->PirParse(), 'parsing data...';
  ok defined $self->parsed(), 'parse data ok.';
}

sub test_General : Test(2) {
  my $sampletxt = qq{\nPANDA hogehogehogehoge
		     \nINTARACTOME piyopiyo
		     \nREFERENCE hogepiyohogepiyo};
  my $str = eXpanda::Services::IdConvert::General($sampletxt);

  is ref $str, 'HASH';
 is $$str{PANDA}, 'hogehogehogehoge';
}

sub test_GbParse : Test(2) {
  my $self = shift->{obj};

  $self->init( -id => 'AAX16503',
	       -from => 'ncbi',
	       -to => 'up',
	       );

  $self->GetNCBI($self->query());

  ok $self->GbParse(), 'parsing data...';
  ok defined $self->parsed(), 'parse data ok.';
}

sub test_GetKEGG : Test {
  my $self = shift->{obj};

  $self->GetKEGG($self->query());

  ok defined $self->rawdata(), 'check getting from kegg api';
}

sub test_GetNCBI : Test {
  my $self = shift->{obj};
  $self->init(
	      -id => 'AAX16503',
	      -from => 'ncbi',
	      -to => 'up',
	     );
  $self->GetNCBI($self->query());

  ok defined $self->rawdata(), 'check getting from ncbi api';
}

sub test_Loopget : Test {
  my $self = shift->{obj};
  my @stack;

  for my $id ('Q03047', 'P18548', 'P11935') {
    $self->init( -id => $id,
		 -from => 'ncbi',
		 -to => 'uniprot',
	       );

    $self->GetKEGG($self->query());
    push @stack, $self->rawdata();
  }

  is scalar(@stack), '3', 'using get method in loop check';
}

1;
