package Mojo::Promise::Role::Merge;

use Mojo::Base -role;
use Mojo::Util qw/dumper/;

use Hash::Merge;
use JSON::Path;

sub flatten {
    my $self = shift;
    $self->then(sub {
		    Mojo::Promise->resolve(map { $_->[0] } @_)
		  })
}

sub merge {
    my $self = shift;
    # my $cb = shift;

    # print STDERR $_[0];

    my $cb = _make_cb( shift() );

    # printf "this should be %s\n", ref $cb;

    $self->then(sub {
		    my @r = map { $cb->($_) } @_;
		    @r = (_merge(@r));
		    Mojo::Promise->resolve(@r)
		  })
}

sub _make_cb {
    my $cb;

    if (ref $_[-1] eq 'CODE') {
	$cb = pop;
    } elsif (ref $_[-1] eq 'SCALAR') {
	my $query = ${pop()};
	my $jpath = JSON::Path->new($query);

	if ($query =~ /\[\*\]/) {
	    $cb = sub { [ $jpath->values(shift()->res->json) ] };
	} else {
	    $cb = sub { $jpath->value(shift()->res->json) };
	}
    } else {
	$cb = sub { return shift()->res->json }
    }
    return $cb;
};

sub _merge {
    my $b = {};
    for (@_) { $b = Hash::Merge::merge($b, $_) }
    return $b;
}

1;
