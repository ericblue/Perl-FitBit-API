#! perl

use Test::More;

BEGIN {
  use_ok 'WWW::Fitbit::API'
    or BAIL_OUT( "main module can't compile?!" )
}

diag "Testing WWW::Fitbit::API version $WWW::Fitbit::API::VERSION";

done_testing(1);
