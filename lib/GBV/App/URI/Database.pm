use strict;
use warnings;
package GBV::App::URI::Database;
#ABSTRACT: Linked Data endpoint for http://uri.gbv.de/database
#VERSION

use Log::Contextual::Easy::Default;

# Required TemplateToolkit plugins
use Template::Plugin::Number::Format;
use Template::Plugin::JSON::Escape;

use Plack::Middleware::TemplateToolkit qw(0.21);
use Plack::Middleware::Cached;
use RDF::Lazy qw(0.061);
use Plack::Middleware::RDF::Flow qw(0.161);
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

#----------

# RDF source
use GBV::RDF::Source::DBInfo;
use CHI;

use GBV::App::URI::Base; # qw(0.112);

use parent 'GBV::App::URI::Base';


sub init {
    my $self = shift;

    my $gbv_dbinfo = GBV::RDF::Source::DBInfo->new;

    my $enrich = rdflow( from => $self->htdocs, name => 'Additional RDF files' );
    $gbv_dbinfo = union( $gbv_dbinfo, $enrich );

    push @{$self->formats}, 'dbinfo';

    my $source = RDF::Flow::Cached->new(
        $gbv_dbinfo,
        CHI->new( driver => 'Memory', global => 1, expires_in => '1 hour' )
    );

    $self->source( $source );
}

sub core {
    my ($self, $app, $env) = @_;

    my $req = Plack::Request->new($env);

    my $uri = $env->{'rdflow.uri'};
    my $rdf = $env->{'rdflow.data'};

    if ( $rdf and $rdf->size ) {
        my $lazy = RDF::Lazy->new( $rdf, namespaces => NS );
        $env->{'tt.vars'}->{uri} = $lazy->resource($uri);

        if ( $uri eq $self->base ) {

            # main page (TODO)
            
        } elsif ( ($req->param('format')||'') eq 'dbinfo' ) {
            $env->{'tt.vars'}->{'JSON_TRUE'} = JSON::true;
            $env->{'tt.vars'}->{'JSON_FALSE'} = JSON::false;
            $env->{'tt.path'} = '/dbinfo.json';
        } elsif ( $lazy->resource($uri)->type('skos:Concept') ) {
            # show database group/prefix
            $env->{'tt.path'} = '/prefix.html';
        } else {
            # show database
            $env->{'tt.path'} = '/database.html';
        }
    }

    $env->{'tt.vars'}->{apptitle}  = 'Datenbanken';
    $env->{'tt.vars'}->{error}     = $env->{'rdflow.error'};
    $env->{'tt.vars'}->{timestamp} = $env->{'rdflow.timestamp'};
    $env->{'tt.vars'}->{cached} = 1 if $env->{'rdflow.cached'};
}

1;
