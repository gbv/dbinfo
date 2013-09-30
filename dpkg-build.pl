#!/usr/bin/perl

# Dpkg::Build::CartonStarman

# Creates a debian package
# code based on parts of Dist::Zilla::Plugin::Dpkg and Dist::Zilla::Plugin::Dpkg::PerlbrewStarman

use v5.14;

# core modules
use File::Path qw(make_path remove_tree);
use File::Basename;

# non-core modules
use lib 'dpkg/lib/';
use Text::Template qw(fill_in_file);
use YAML::Tiny qw(Dump);

my $VERBOSE = grep { $_ =~ /^-?-v/ } @ARGV;

my $conf = read_config('dpkg.yml');
my $vars = template_vars($conf);

## cleanup
remove_tree($conf->{target});

my $path = $conf->{target}.'/source';
make_path("$path/debian");

## no critic
foreach my $template (<dpkg/*>) {
    next unless -f $template;

    my $filename = "$path/debian/".basename($template);

    open my $fh, ">", $filename;
    print $fh fill_in_file($template, HASH => $vars);
    close $fh;

    say $filename if $VERBOSE;
}

foreach (@{ $conf->{before_build} || [ ] }) {
    `$_`;
    die "failed to run $_\n" if $?;
}

foreach (@{ $conf->{source} || [ ] }) {
    `cp -r $_ $path/$_`;
    die "failed to copy $_\n" if $?;
}

system("cd debuild/source && debuild -uc -us");


## functions

sub read_config {
    my $file = shift;

    my $conf = YAML::Tiny->read($file) or die $YAML::Tiny::errstr."\n";
    $conf = $conf->[0];

    expand_config($conf);

    $conf->{target} //= 'debuild';

    print Dump($conf) if $VERBOSE;

    $conf;
}

sub expand_config {
    return if (ref $_[0] || "") ne 'HASH';
    foreach (keys %{$_[0]}) {
        my $v = $_[0]->{$_};
        if ( !ref $v and $v =~ /^`(.+)`$/ ) {
            $_[0]->{$_} = `$1`;
            die "`$v` died with ".($?>>8)."!\n" if $?;
            chomp $_[0]->{$_};
        } else {
            expand_config($v);
        }
    }
}

sub template_vars {
    my $conf = shift;
    my $vars = { };

    foreach ( keys %{ $conf->{package} // { } } ) {
        $vars->{"package_$_"} = $conf->{package}->{$_};
    }

    foreach ( keys %{ $conf->{about} // { } } ) {
        $vars->{$_} = $conf->{about}->{$_} unless ref $conf->{about}->{$_};
    }

    print Dump($vars) if $VERBOSE;
    
    $vars;
}


