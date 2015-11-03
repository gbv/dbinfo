package App::DBInfo::Stats; 
use v5.14;

use LWP::Simple qw(get);
use DateTime;

=head1 SYNOPSIS

  my $stat = App::DBInfo::Stats->new( picabase => $picabase );
  $stat->count;                             # this may take a while
  say $stat->time, ": ", $stat->extent;

=cut

sub new {
    my ($class, %args) = @_;
    $args{picabase} =~ s{/$}{};

    bless { picabase => $args{picabase} }, $class;
}

sub count {
    my $self = shift;
    my $url = $self->{picabase}.'/CMD?XML=ON&ACT=SRCHA&IKT=1016&TRM=ppn+.*';

    $self->{time}   = DateTime->now;
    $self->{extent} = eval { get($url) =~ /hits\s*=["'](\d+)["']/ ? $1 : undef };
}

sub extent { $_[0]->{extent} }
sub time   { $_[0]->{time}->iso8601 }

1;
