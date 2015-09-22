#!/usr/bin/perl
use v5.14;
use lib 'local/lib/perl5';
use Pandoc::Filter;
use Pandoc::Elements;

pandoc_filter sub {
    my $e = shift;
    for ($e->name) {
        # move headers one level up
        if ($_ eq 'Header') {
            return Header $e->level+1, $e->attr, $e->content;
        }  
        # remove all SVG images
        elsif ($_ eq 'Image') {
           return [] if $e->url =~ /\.svg$/;
        }
    }
    return;
};
