#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Test::WWW::Mechanize::Catalyst };
    plan skip_all =>
      "This test requires Test::WWW::Mechanize::Catalyst in order to run"
      if $@;
    plan 'no_plan';
}

{

    package CookieTestApp;
    use Catalyst qw/
      Session
      Session::Store::Dummy
      Session::State::Cookie
      /;

    sub page : Local {
        my ( $self, $c ) = @_;
        $c->res->body( "Hi! hit number " . ++$c->session->{counter} );
    }

    sub stream : Local {
        my ( $self, $c ) = @_;
        my $count = ++$c->session->{counter};
        $c->res->write("hit number ");
        $c->res->write($count);
    }

    __PACKAGE__->setup;
}

use Test::WWW::Mechanize::Catalyst qw/CookieTestApp/;

my $m = Test::WWW::Mechanize::Catalyst->new;

$m->get_ok( "http://foo.com/stream", "get page" );
$m->content_contains( "hit number 1", "session data created" );

my $expired;
$m->cookie_jar->scan( sub { $expired = $_[8] } );

$m->get_ok( "http://foo.com/page", "get page" );
$m->content_contains( "hit number 2", "session data restored" );

$m->get_ok( "http://foo.com/stream", "get stream" );
$m->content_contains( "hit number 3", "session data restored" );

sleep 2;

$m->get_ok( "http://foo.com/page", "get stream" );
$m->content_contains( "hit number 4", "session data restored" );

my $updated_expired;
$m->cookie_jar->scan( sub { $updated_expired = $_[8] } );

cmp_ok( $expired, "<", $updated_expired, "cookie expiration was extended" );
