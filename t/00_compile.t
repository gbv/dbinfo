use strict;
use Test::More;

foreach (`find lib/ -iname "*.pm"`) {
    s{^lib/|\.pm$}{}g;
    s{/}{::}g;
    use_ok "$_";
}

done_testing;
