use eXpanda;
use eXpanda::Util;
use eXpanda::Structure::Component;

$e = eXpanda->new("ko04012.xml", -filetype=>"kgml");
eXpanda::Util::extend 'eXpanda', 'eXpanda::Structure::Component', 'add_component';

$e->Apply( -object => 'node:graphics:w' , -value => '20');
$e->Apply( -object => 'node:graphics:font-size' , -value => '13');

$e->add_component('K05083', (label => 'hogehoge'));
$e->add_component('K05083', (label => 'hoge1'   ));
$e->add_component('K05083', (label => 'hoge2'   ));


$e->out("egfr.svg",
	-no_node => 0 ,
	-no_edge => 1,
	-no_node_label => 1,
	-no_edge_label => 1
);
