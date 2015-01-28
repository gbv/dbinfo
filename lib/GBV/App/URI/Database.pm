use strict;
use warnings;
package GBV::App::URI::Database;
#ABSTRACT: Linked Data endpoint for http://uri.gbv.de/database

use Log::Contextual::Easy::Default;

# Required TemplateToolkit plugins
use Template::Plugin::Number::Format;
use Template::Plugin::JSON::Escape;

use Plack::Middleware::TemplateToolkit qw(0.21);
use Plack::Middleware::Cached;
use RDF::Lazy qw(0.061);
use Plack::Middleware::RDF::Flow qw(0.170);
use Plack::Middleware::Rewrite;
use RDF::Flow qw(0.175 :all);
use RDF::Flow::LinkedData qw(0.16);
use Plack::Builder;
use Plack::Request;
use URI::Escape;
use CHI;

use RDF::Dumper;
use RDF::Trine qw(iri);
use RDF::Trine::Model;
use RDF::Trine::Parser;

use RDF::NS;
use constant NS => RDF::NS->new('20130926');

use GBV::RDF::Source::DBInfo;

use Plack::Builder;

use parent 'Plack::Component', 'Exporter';
use Plack::Util::Accessor qw(source base rewrite_uri formats htdocs);

use CHI;

sub prepare_app {
    my $self = shift;
    return if $self->{app};

    $self->{htdocs} = 'root';
    my $base = ref($self);
    if ( $base =~ /^GBV::App::URI::(.+)$/ and $1 ne 'Base' ) {
        $base = "http://uri.gbv.de/" . lc($1) . '/';
        $base =~ s/::/\//g;
        $self->base( $base );
    } else {
        $self->base('http://uri.gbv.de/');
    }

    $self->formats([qw(ttl json rdfxml)])
        unless $self->formats;
    push @{$self->formats}, 'dbinfo';


    my $gbv_dbinfo = GBV::RDF::Source::DBInfo->new;

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

        mount '/api/suggest-dbkey' => sub {
            my $id = Plack::Request->new($_[0])->param('id') // '';
            my $result = $gbv_dbinfo->suggest_dbkey( $id );
            my $json = JSON->new->encode( $result );
            return [ 200, [ "Content-Type" => "text/javascript" ], [ $json ] ];
        };

        mount '/' => builder {

            enable 'RDF::Flow',
                base         => $self->base,
                empty_base   => 1,
                rewrite      => $self->rewrite_uri,
                source       => $self->source,
                namespaces   => NS,
                formats      => {
                    nt   => 'ntriples', 
                    rdf  => 'rdfxml', 
                    xml  => 'rdfxml',
                    ttl  => 'turtle',
                    json => 'rdfjson',
                },
                pass_through => 1;

            # core driver
            enable sub { 
                my $app = shift;
                sub { 
                    my $env = shift;
                    $self->core($app, $env);
                    $app->($env);
                }
            };
        
            Plack::Middleware::TemplateToolkit->new( 
                INCLUDE_PATH => $self->htdocs,
                RELATIVE     => 1,
                INTERPOLATE  => 1, 
                pass_through => 0,
                vars => { base => '.' }, # request.base.remove('/$')
                404 => '404.html', 
                500 => '500.html'
            );

        };
    };
}

sub call { 
    my $self = shift;
    $self->{app}->( @_ );
}

sub core {
    my ($self, $app, $env) = @_;

    my $req = Plack::Request->new($env);

    my $uri = $env->{'rdflow.uri'};
    my $rdf = $env->{'rdflow.data'};

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
}

1;
