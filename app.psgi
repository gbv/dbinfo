use v5.14;
use Plack::Builder;
use App::DBInfo;
use List::Util qw(first);
use YAML ();

my $app = App::DBInfo->new->to_app;
my $debug = ($ENV{PLACK_ENV} // '') =~ /^(development|debug)$/;

my $config = first { -e $_ } '/etc/dbinfo/config.yml','etc/config.yml';
$config = $config ? YAML::LoadFile($config) : { };

builder {
    enable_if { $debug } 'Debug';
    enable_if { $debug } 'Debug::TemplateToolkit';

    enable_if { $config->{proxy} } 'Plack::Middleware::XForwardedFor',
        trust => $config->{proxy};

    enable 'SimpleLogger';
    enable_if { $debug }  'Log::Contextual', level => 'trace';
    enable_if { !$debug } 'Log::Contextual', level => 'warn';

    $app;
}
