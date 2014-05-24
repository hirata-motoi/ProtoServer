package Test::ProtoServer::Schema::Test;
use strict;
use warnings;
use parent qw/Test::ProtoServer::Reader/;
sub read { $_[0]->SUPER::read }
1;
__DATA__
CREATE TABLE `test_table` (
  `id` int(10) unsigned NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  `updated_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
