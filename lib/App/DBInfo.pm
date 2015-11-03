package App::DBInfo;
use v5.14;

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

use CHI;
use Plack::Middleware::Negotiate;
use Encode qw(encode); 

use List::Util qw(first);
use YAML ();

our $VERSION="0.8.0";

my $NEGOTIATE = Plack::Middleware::Negotiate->new(
    parameter => 'format',
    extension => 1,
    formats => {
        nt      => { type => 'text/plain' },
        rdf     => { type => 'application/rdf+xml' },
        xml     => { type => 'application/rdf+xml' },
        rdfxml  => { type => 'application/rdf+xml' },
        ttl     => { type => 'text/turtle' },
        json    => { type => 'application/rdf+json' },
        dbinfo  => { type => 'application/ld+json' },
        jsonld  => { type => 'application/ld+json' },
        html    => { type => 'text/html' },
        _       => { charset => 'utf-8', }
    }
);

sub new {
    my $self = bless { }, shift;

    # load config file and set default values
    $self->{etcdir} = first { -e "$_/config.yml" } '/etc/dbinfo', 'etc';
    $self->{config} = YAML::LoadFile( $self->{etcdir} . "/config.yml");

    $self->{config}{base} //= 'http://uri.gbv.de/database/';
    $self->{config}{stats} //= $self->{etcdir} . "/stats";

    # TODO: get rid of RDF::Flow
    $self->{source}    = App::DBInfo::Source->new;
    $self->{rdfsource} = RDF::Flow::Cached->new(
            $self->{source},
            CHI->new( driver => 'Memory', global => 1, expires_in => '1 hour' )
        );

    $self->{app} = builder {

        enable_if { $self->{config}{proxy} } 'Plack::Middleware::XForwardedFor',
            trust => $self->{config}{proxy};

        enable 'Static', 
            root         => $self->{config}{stats},
            path         => qr{\.(png)$},
            pass_through => 1;

        enable 'Static', 
            root         => 'public',
            path         => qr{\.(css|png|gif|js|ico|jsonld)$},
            pass_through => 0;
            
        # cache everything else for 10 seconds. TODO: set cache time
        enable 'Cached',
                cache => CHI->new( 
                    driver => 'Memory', global => 1, 
                    expires_in => '10 seconds' 
                );

        enable 'JSONP';

        mount '/api/dbkey' => sub {
            my $id = Plack::Request->new($_[0])->param('id') // '';
            my $result = $self->{source}->suggest_dbkey( $id );
            my $json = JSON->new->encode( $result );
            return [ 200, [ "Content-Type" => "text/javascript" ], [ $json ] ];
        };

        mount '/' => 
            $NEGOTIATE->wrap(
                sub { $self->core(@_) }
            );
    };

    return $self;
}

sub to_app {
    my $self = shift;
    return sub { $self->{app}->(@_) }
}

sub core {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    # construct request URI
    my $base = $self->{config}{base} || $req->base;

    my $path = $req->path;
    $path =~ s/^\///;
    my $uri = $base.$path;

    # retrieve RDF
    $env->{'rdflow.uri'} = $uri;
    my $rdf = $self->{rdfsource}->retrieve($env);

    my $format = $env->{'negotiate.format'} // 'html';

    # serialize and return RDF data
    unless (grep { $format eq $_ } qw(html dbinfo jsonld)) {
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

    $vars->{'formats'} = [qw(ttl json rdfxml jsonld)];

    my $lazy = RDF::Lazy->new( $rdf, namespaces => NS );

    if ( $rdf and $rdf->size ) {
        if ( $format =~ /^(dbinfo|jsonld)$/ ) {
            $vars->{'JSON_TRUE'} = JSON::true;
            $vars->{'JSON_FALSE'} = JSON::false;

            $env->{'tt.path'} = '/jsonld.json';

        } elsif ( $uri eq $self->{config}{base} ) {
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

    $vars->{error}     = $env->{'rdflow.error'};
    $vars->{timestamp} = $env->{'rdflow.timestamp'};
    $vars->{cached} = 1 if $env->{'rdflow.cached'};

    $env->{'tt.vars'} = $vars;

    state $app = Plack::Middleware::TemplateToolkit->new( 
        INCLUDE_PATH => 'public',
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
