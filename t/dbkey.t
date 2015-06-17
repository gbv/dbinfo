use v5.14.1;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Util::Load;
use JSON;

my $app = load_app($ENV{TEST_URL} // 'app.psgi');

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/api/dbkey");
    is $res->code, '200', 'dbkey';
    is $res->header('Content-Type'),'text/javascript', 'JSON';

    my $res = $cb->(GET "/api/dbkey?id=opac-de-ilm");
    my $data = JSON->new->decode($res->decoded_content);
    is $data->[0], 'opac-de-ilm';
    is $data->[1][0],'opac-de-ilm1';
    is $data->[2][0],"Katalog der Universit\x{e4}tsbibliothek Ilmenau";
    is $data->[3][0],"http://uri.gbv.de/database/opac-de-ilm1";
};

done_testing;
