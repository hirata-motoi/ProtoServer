use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use Test::ProtoServer::Loader;
use ProtoServer::Logic;

my $loader = Test::ProtoServer::Loader::factory('db', [
    +{
        database => 'babyry_main',
        node     => [qw/TEST_W TEST_R/],
    }
])->load;


my $logic = ProtoServer::Logic->new;
my $dx = $logic->dx('TEST_R');
$dx->select(
    'test_table',
    'count(*)',
)->into(my $count);

is $count, 0;

done_testing;
