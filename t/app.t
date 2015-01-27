use strict;
use Test::More;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;

use GBV::App::URI::Database;
my $app = GBV::App::URI::Database->new( htdocs => "root" );

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/gvk");
    is $res->code, '200', 'gvk found';
};

done_testing;
