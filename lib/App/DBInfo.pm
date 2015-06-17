package App::DBInfo;
use v5.14;

#ABSTRACT: Linked Data endpoint for http://uri.gbv.de/database

use Log::Contextual::Easy::Default;

# Required TemplateToolkit plugins
use Template::Plugin::Number::Format;
use Template::Plugin::JSON::Escape;

use Plack::Middleware::TemplateToolkit qw(0.21);
use Plack::Middleware::Cached;
use RDF::Lazy qw(0.061);
use Plack::Middleware::Rewrite;
use RDF::Flow qw(0.175 :all);
use Plack::Builder;
use Plack::Request;
use URI::Escape;
use CHI;

use RDF::Trine qw(iri);
use RDF::Trine::Model;
use RDF::Trine::Parser;

use RDF::NS;
use constant NS => RDF::NS->new('20130930');

use App::DBInfo::Source;

use Plack::Builder;

use parent 'Plack::Component', 'Exporter';
use Plack::Util::Accessor qw(source base formats htdocs);

use CHI;
use Plack::Middleware::Negotiate;
use Encode qw(encode); 

my $NEGOTIATE = Plack::Middleware::Negotiate->new(
    parameter => 'format',
    extension => 0,
    formats => {
        nt   => { type => 'text/plain' },
        rdf  => { type => 'application/rdf+xml' },
        xml  => { type => 'application/rdf+xml' },
        rdfxml => { type => 'application/rdf+xml' },
        ttl  => { type => 'text/turtle' },
        json => { type => 'application/rdf+json' },
        html => { type => 'text/html' },
        _    => { charset => 'utf-8', }
    }
);


sub prepare_app {
    my $self = shift;
    return if $self->{app};

    $self->{htdocs} = 'public';
    $self->base('http://uri.gbv.de/database/'); 

    $self->formats([qw(ttl json rdfxml)])
        unless $self->formats;
    push @{$self->formats}, 'dbinfo';

    # TODO: get rid of RDF::Flow
    my $gbv_dbinfo = App::DBInfo::Source->new;
    my $enrich = rdflow( from => $self->htdocs, name => 'Additional RDF files' );
    $self->source( 
        RDF::Flow::Cached->new(
            union( $gbv_dbinfo, $enrich ),
            CHI->new( driver => 'Memory', global => 1, expires_in => '1 hour' )
        )
    );

    $self->{app} = builder {

        enable 'Static', 
            root => $self->htdocs, 
            path => qr{\.(css|png|gif|js|ico)$};

        # cache everything else for 10 seconds. TODO: set cache time
        enable 'Cached',
                cache => CHI->new( 
                    driver => 'Memory', global => 1, 
                    expires_in => '10 seconds' 
                );

        enable 'JSONP';

        mount '/api/dbkey' => sub {
            my $id = Plack::Request->new($_[0])->param('id') // '';
            my $result = $gbv_dbinfo->suggest_dbkey( $id );
            my $json = JSON->new->encode( $result );
            return [ 200, [ "Content-Type" => "text/javascript" ], [ $json ] ];
        };

        mount '/' => 
            $NEGOTIATE->wrap(
                sub { $self->core(@_) }
            );
    };
}

sub call { 
    my $self = shift;
    $self->{app}->(@_);
}

sub core {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    # construct request URI
    my $base = defined $self->base ? $self->base : $req->base;

    my $path = $req->path;
    $path =~ s/^\///;
    my $uri = $base.$path;

    # retrieve RDF
    $env->{'rdflow.uri'} = $uri;
    my $rdf = $self->source->retrieve($env);

    my $format = $env->{'negotiate.format'} // 'html';

    # serialize and return RDF data
    if ($format ne 'html') {
        if ( $env->{'rdflow.error'} ) {
            return [ 500, [ 'Content-Type' => 'text/plain' ], [ $env->{'rdflow.error'} ] ];
        }
 
        my $ser = {
            nt     => 'NTriples',
            rdf    => 'RDFXML',
            xml    => 'RDFXML',
            rdfxml => 'RDFXML',
            ttl    => 'Turtle',
            json   => 'RDFJSON',
        };
        my $serializer = RDF::Trine::Serializer->new($ser->{$format});

        my $rdf_data;
 
        if ( UNIVERSAL::isa( $rdf, 'RDF::Trine::Model' ) ) {
            $rdf_data = $serializer->serialize_model_to_string( $rdf );
        } elsif ( UNIVERSAL::isa( $rdf, 'RDF::Trine::Iterator' ) ) {
            $rdf_data = $serializer->serialize_iterator_to_string( $rdf );
        }
        if ( $rdf_data ) {
            $rdf_data = encode('utf8',$rdf_data);
            my $headers = [];
            $NEGOTIATE->add_headers($headers, $format);
            return [ 200, $headers, [ $rdf_data ] ];
        }
    }

    # initialize HTML format via Template
    my $vars = $env->{'tt.vars'} || { };

    $vars->{'formats'} = [ @{$self->formats} ];

    my $lazy = RDF::Lazy->new( $rdf, namespaces => NS );

    if ( $rdf and $rdf->size ) {
        if ( ($req->param('format')||'') eq 'dbinfo' ) {
            $vars->{'JSON_TRUE'} = JSON::true;
            $vars->{'JSON_FALSE'} = JSON::false;
            $env->{'tt.path'} = '/dbinfo.json';
        } elsif ( $uri eq $self->base ) {
            # ...
        } elsif ( $lazy->resource($uri)->type('skos:Concept') ) {
            # show database group/prefix
            $env->{'tt.path'} = '/prefix.html';
        } else {
            # show database
            $env->{'tt.path'} = '/database.html';
        }
    } 

    $vars->{uri} = $lazy->resource($uri);

    $vars->{apptitle}  = 'GBV Datenbankverzeichnis';

    $vars->{error}     = $env->{'rdflow.error'};
    $vars->{timestamp} = $env->{'rdflow.timestamp'};
    $vars->{cached} = 1 if $env->{'rdflow.cached'};

    $env->{'tt.vars'} = $vars;

    state $app = Plack::Middleware::TemplateToolkit->new( 
        INCLUDE_PATH => $self->htdocs,
        RELATIVE     => 1,
        INTERPOLATE  => 1, 
        pass_through => 0,
        vars => { base => '.' }, # request.base.remove('/$')
        404 => '404.html', 
        500 => '500.html'
    )->to_app;
    return $app->($env);
}

1;
