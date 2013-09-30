use strict;
use Test::More;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;

use GBV::App::URI::Database;

my $app = GBV::App::URI::Database->new( htdocs => "htdocs" );

test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/gvk");
        use Data::Dumper;
        is $res->code, '200', 'gvk found';
#        like $res->content, qr/Pharmazie/m, 'Pharmazie';
    };

done_testing;
