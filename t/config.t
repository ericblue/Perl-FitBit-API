#! perl

use Test::More;
use Test::Exception;
use WWW::Fitbit::API;

dies_ok { WWW::Fitbit::API->new() } 'new() without config throws exception';

done_testing(1);
