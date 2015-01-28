use v5.14.1;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Util::Load;
use JSON;

my $app = load_app($ENV{TEST_URL} // 'app.psgi');

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->code, '200', 'base';

    $res = $cb->(GET "/gvk");
    is $res->code, '200', 'gvk found';

    foreach my $format (qw(ttl rdfxml dbinfo json)) {
        $res = $cb->(GET "/opac-de-ilm1?format=$format");
        is $res->code, '200', "opac-de-ilm1 found (format=$format)";
        #note $res->header('Content-Type');
    }

    is $res->header('Content-Type'),'application/rdf+json; charset=utf-8','RDF/JSON';
    my $rdf = decode_json($res->decoded_content);

    is_deeply $rdf->{'http://uri.gbv.de/database/opac-de-ilm1'}
            ->{'http://purl.org/dc/terms/title'}, [ {
                'type' => 'literal',
                'value' => "Katalog der Universit\x{e4}tsbibliothek Ilmenau"
           } ], 'got RDF/XML with Unicode';
};

done_testing;
