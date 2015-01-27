use v5.14.1;
use Test::More;
use HTTP::Tiny;

# only test on ci server
plan skip_all => 1 unless $ENV{CI};

# read default configuration
my $config = "/etc/default/dbinfo";
my %conf = do { 
    local(@ARGV) = $config; 
    map { /^\s*([^=\s#]+)\s*=\s*([^#\n]*)/ ? ($1 => $2) : () } <>;
};
note $config, ": ", explain \%conf;

# run test
my $url = "http://localhost:$conf{PORT}";
my $res = HTTP::Tiny->new->get($url);
ok $res->{success}, $url;

done_testing;
