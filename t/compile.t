use v5.14.1;
use Test::More;

# test before deployment only
plan skip_all => 1 if $ENV{TEST_DEPLOYED};

foreach (`find lib/ -iname "*.pm"`) {
    chomp;
    s{^lib/|\.pm$}{}g;
    s{/}{::}g;
    use_ok "$_";
}

done_testing;
