use strict;
use warnings;
package GBV::RDF::Source::DBInfo; 

use Log::Contextual::Easy::Default;

use parent 'RDF::Flow::Source';

use Carp qw(carp);

use Try::Tiny;
use RDF::Trine::Model;
use RDF::Trine qw(iri statement literal blank);

use LWP::Simple qw(get);
use JSON;
use Digest::MD5 qw(md5_hex);
use Scalar::Util qw(blessed);

use CHI;
our $CACHE = CHI->new( driver => 'Memory', global => 1, expires_in => '1 day' );

use RDF::NS;
use constant NS => RDF::NS->new('20130926');

sub retrieve_rdf {
    my ($self, $env) = @_;
    my $uri = $env->{'rdflow.uri'};

    log_trace { "retrieve_rdf: $uri" };

    my $model = RDF::Trine::Model->new;

    if ( $uri =~ qr{^http://lobid\.org/organisation/(.+)} ) {
        # Infos zur Datenbank einer Einrichtung
        
        my $isil = $1;
        return unless $isil =~ /^[a-z]+-[a-z0-9-]+$/i;

        log_info { "retrieve ISIL $isil" };
        try {
            my $key = 'opac-'.lc($isil);
            $self->load_dblist;

            my @triples;
            $self->db2rdf( $key, \@triples );
            if (@triples) {
                my $dburi = $self->db2uri($key);
                push @triples,
                    [ iri($uri), NS->uri('gbv:opac'), $dburi ],
                    [ $dburi, NS->uri('dcterms:creator'), iri($uri) ];
            }
            add_statements($model, \@triples);

        } catch {
            log_error { "Failed to get GBV databases: $_" };
        };
    } elsif ( $uri =~ qr{^http://uri.gbv.de/database/(.+)} ) {
        # Infos zu einer Datenbank

        my $key = $1;
        return unless $key =~ /^[a-z][a-z0-9_-]+$/;
        log_info { "retrieve dbkey $key" };

        $self->load_dblist;

        my @triples;
        $self->db2rdf( $key, \@triples );

        if (@triples) {
            if ( $key =~ /^([^-]+)-/ ) {
                my $prefix = $1;
                if ( $self->prefixonly2rdf( $prefix, \@triples ) ) {
                    my $prefixuri = "http://uri.gbv.de/database/$prefix";
                    my $dburi = $self->db2uri($key);
                    push @triples, [ $dburi, NS->uri('dc:subject'), iri($prefixuri) ];
                }
            }
        } else {
            # Wenn keine spezielle Datenbank, dann Datenbankgruppe
            $self->prefix2rdf( $key, \@triples );
        }

        add_statements($model, \@triples);

    } elsif ( $uri eq 'http://uri.gbv.de/database/' ) {
        $model = $self->retrieve_base;
    }

    log_info {"retrieved: $model"};

    return $model;
}

sub retrieve_base {
    my $self = shift;

    $self->load_dblist;

    my @triples;

    my $scheme = iri('http://uri.gbv.de/database/');
    push @triples, [ $scheme, NS->uri('rdf:type'), NS->uri('skos:ConceptScheme') ];
    foreach my $prefix (keys %{ $self->{prefixes} }) {
        if ( $self->prefixonly2rdf( $prefix, \@triples ) ) {
            my $uri = iri("http://uri.gbv.de/database/$prefix");
            push @triples, [ $scheme, NS->uri('skos:hasTopConcept'), $uri ];
        }
    }

    # databases without prefix
    foreach my $key (keys %{ $self->{dblist} }) {
        next if $key =~ /-/;
        my $db = $self->{dblist}->{$key};
    
        my $dburi = $self->db2uri($key);
        push @triples, [ $dburi, NS->uri('dc:subject'), $scheme ];
        $self->db2rdf( $key, \@triples );
    }

    my $model = RDF::Trine::Model->new;
    add_statements($model, \@triples);

    $model;
}

sub db2uri {
    my ($self, $key) = @_;
    my $db = $self->{dblist}->{$key};

    if ($db) {    
        return iri("http://uri.gbv.de/database/$key");
    } else {
        log_debug { "database $key not found." };
        return;
    }
}

sub prefixonly2rdf {
    my ($self, $key, $triples) = @_;
    my $prefix = $self->{prefixes}->{$key} || return;

    my $uri = "http://uri.gbv.de/database/$key";
    my $title = $prefix->{title} || 'unnamed database type';

    log_debug { "database prefix found for $key: $title" };

    push @$triples,
        [ iri($uri), NS->uri('rdf:type'), NS->uri('skos:Concept') ],
        [ iri($uri), NS->uri('skos:prefLabel'), literal($title) ];

    return 1;
}

sub prefix2rdf {
    my ($self, $key, $triples, @dbkeys) = @_;
    my $uri = "http://uri.gbv.de/database/$key";

    prefixonly2rdf( $self, $key, $triples ) || return;
   
    # Alle oder ausgewählte Datenbanken dieser Gruppe hinzufügen
    @dbkeys = keys %{$self->{dblist}};
    foreach my $dbkey (@dbkeys) {
        if ( $dbkey =~ /^$key-/ ) {
            my $dburi = $self->db2uri($dbkey);
            push @$triples, [ $dburi, NS->uri('dc:subject'), iri($uri) ];
            $self->db2rdf( $dbkey, $triples );
        }
    }
}

sub add_statements {
    my ($model, $statements) = @_;

    $model->begin_bulk_ops;
    foreach (@$statements) {
        $_->[1] = iri($_->[1]) unless blessed $_->[1];
        $_->[2] = iri($_->[2]) unless blessed $_->[2];
        $_ = statement( @$_ ); # if ref $_ eq 'ARRAY';
        $model->add_statement( $_ );
    }
    $model->end_bulk_ops;
    return $model;
}

sub db2rdf {
    my ($self, $key, $triples) = @_;
    my $db = $self->{dblist}->{$key};

    my $dburi = $self->db2uri($key) || return;

    my $model = RDF::Trine::Model->new;

    my ($host,$dbsid,$title,$restricted) = ($db->{host}, $db->{dbsid}, $db->{title});
    log_debug { "database found for $key $host, $title" };

    if ( $host && $dbsid ) {
        $host =~ s/gsoapi/gso/; # HACK
        my $url = "http://$host/DB=$dbsid/";
        
        my $srubase = "http://sru.gbv.de/$key";
        push @$triples, [ $dburi, NS->uri('gbv:srubase'), iri($srubase) ] if $srubase;

        push @$triples, 
            [ $dburi, NS->uri('gbv:picabase'), iri($url) ],
            [ $dburi, NS->uri('gbv:dbkey'), literal($key) ],
            [ $dburi, NS->uri('foaf:homepage'), iri($url) ]
        ;

=head1 COUNT
        my $counturl = $url.'XML=Y/CMD?ACT=SRCHA&IKT=1016&TRM=ppn[%23]%3F';
        #log_trace { $counturl };
        my $count = $CACHE->get( $url );
        unless ( defined $count ) {
            $count = try {
                my $xml = ''; # get($counturl); # TODO: put in another source and cache from file
                if ( $xml =~ /hits=\"([0-9]+)\"/m ) {
                    $1;
                } else {
                    '?';
                }
            } catch { '?' };
            $CACHE->set( $url, $count );
        }
        if ( $count ne '?' ) {

#            my $statItem = blank(md5_hex($counturl));
#            $model->add_statement(statement(
#                $dburi, NS->uri('void:statItem'), $statItem
#            ));
#            $model->add_statement(statement(
#               $statItem, NS->uri('scovo:dimension'), NS->uri('void:numberOfResources')
#            ));
#            $model->add_statement(statement(
#                $statItem, NS->uri('rdf:value'), literal($count) # TODO: xs:int
#            ));
        
            push @$triples, 
                [ $dburi, NS->uri('dcterms:extent'), literal($count) ]; # TODO: xs:int

            log_info { "Got current number of titles: $count" };
        } else {
            log_error { 'Failed to get number of titles: '.$@ };
        }
=cut
    }

    if (defined $db->{'restricted'} and not $db->{'restricted'}) {
        push @$triples, [ $dburi, NS->uri('rdf:type'), NS->uri('daiaserv:Openaccess') ];
    }

    # Spezielle Links je nach Datenbank-Typ
    if ( $key =~ /^opac-([a-zA-Z]+)-(.+)$/ ) {
        my $org = "http://uri.gbv.de/organization/isil/".uc($1)."-".ucfirst($2);
        push @$triples, [ iri($org), NS->uri('gbv:opac'), $dburi ];

    } elsif ( $key =~ /^fachopac-(.+)$/ ) {
        # TODO: daten der anderen DB auch hinzu
        if ( $self->{dblist}->{"fachopacplus-$1"} ) {
            push @$triples, [ $dburi, NS->uri('rdfs:seeAlso'), $self->db2uri("fachopacplus-$1") ];
        }
    } elsif ( $key =~ /^fachopacplus-(.+)$/ ) {
        if ( $self->{dblist}->{"fachopac-$1"} ) {
            push @$triples, [ $dburi, NS->uri('rdfs:seeAlso'), $self->db2uri("fachopac-$1") ];
        }
    }

    if ( $title ) {
        push @$triples, [ $dburi, NS->uri('dcterms:title'), literal($title) ];
    }

    foreach my $type (qw(daia:Service http://purl.org/cld/cdtype/CatalogueOrIndex void:Dataset)) {
       push @$triples, [ $dburi, NS->uri('rdf:type'), NS->uri($type) ];
    }
    
    # void:uriRegexPattern "http://uri.gbv.de/record/opac-de-18:ppn:[0-9]+[0-9xX]"  ?

    log_debug { "added database $dburi" };
}

sub isil2db {
    my ($self, $isil) = @_;
    return unless $self->{dblist};

    return unless $isil =~ /^[a-z]+-[a-z0-9-]+$/i;
    my $key = 'opac-'.lc($isil);

    return $self->{dblist}->{$key};
}

sub load_dblist {
    my $self = shift;

    my $dbs = try {
        my $json = get('http://gsoapiwww.gbv.de/unapi/databases');
        $json = JSON->new->utf8->decode($json);
        log_debug { "retrieved GBV list of databases" };
        $json;
    };

    if ($dbs) {
        $self->{dblist} = $dbs;
    } else {
        log_error { "failed to get GBV list of databases" };
        $self->{dblist} = { }
    }

    $self->{prefixes} = try {
        my $json = get('http://gsoapiwww.gbv.de/unapi/prefixes');
        $json = JSON->new->utf8->decode($json);
        log_debug { "retrieved GBV list of database prefixes" };
        $json;
    };
}

1;
