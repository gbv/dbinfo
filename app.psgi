use v5.14;


### 1. instantiate

use Cwd;
use File::Basename qw(dirname);
my $root = Cwd::realpath( dirname($0) );

use GBV::App::URI::Database;

my $app = GBV::App::URI::Database->new(
    htdocs => "$root/root" 
)->to_app;


### 2. run

use Plack::Builder;

my $debug = ($ENV{PLACK_ENV} // '') =~ /^(development|debug)$/;

builder {
    enable_if { $debug } 'Debug';
    enable_if { $debug } 'Debug::TemplateToolkit';

    enable 'SimpleLogger';
    enable_if { $debug }  'Log::Contextual', level => 'trace';
    enable_if { !$debug } 'Log::Contextual', level => 'warn';

    $app;
};

