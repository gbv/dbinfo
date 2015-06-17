use v5.14.1;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Util::Load;
my $app = load_app( $ENV{TEST_URL} || 'GBV::App::DBInfo', verbose => 1 );

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->code, '200', 'base';

    my $res = $cb->(GET "/gvk");
    is $res->code, '200', 'gvk found';
};

done_testing;
