package GBV::App::DBInfo;
use v5.14.1;
use Plack::Builder;
use parent 'Plack::Component';

use GBV::App::URI::Database;
my $app = GBV::App::URI::Database->new->to_app;

my $debug = ($ENV{PLACK_ENV} // '') =~ /^(development|debug)$/;

builder {
    enable_if { $debug } 'Debug';
    enable_if { $debug } 'Debug::TemplateToolkit';

    enable 'Plack::Middleware::XForwardedFor',
        trust => ['127.0.0.1','193.174.240.0/24','195.37.139.0/24'];

    enable 'SimpleLogger';
    enable_if { $debug }  'Log::Contextual', level => 'trace';
    enable_if { !$debug } 'Log::Contextual', level => 'warn';

    $app;
};

1;
