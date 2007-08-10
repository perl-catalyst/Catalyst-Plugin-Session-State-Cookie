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

    sub deleteme : Local {
        my ( $self, $c ) = @_;
        my $id = $c->get_session_id;
        $c->delete_session;
        my $id2 = $c->get_session_id;
        $c->res->body( $id ne ( $id2 || '' ) );
    }

    __PACKAGE__->setup;
}

use Test::WWW::Mechanize::Catalyst qw/CookieTestApp/;

my $m = Test::WWW::Mechanize::Catalyst->new;

$m->get_ok( "http://localhost/stream", "get page" );
$m->content_contains( "hit number 1", "session data created" );

my $expired;
$m->cookie_jar->scan( sub { $expired = $_[8]; warn join":",@_; } );

$m->get_ok( "http://localhost/page", "get page" );
$m->content_contains( "hit number 2", "session data restored" );

$m->get_ok( "http://localhost/stream", "get stream" );
$m->content_contains( "hit number 3", "session data restored" );

sleep 1;

$m->get_ok( "http://localhost/page", "get stream" );
$m->content_contains( "hit number 4", "session data restored" );

my $updated_expired;
$m->cookie_jar->scan( sub { $updated_expired = $_[8]; warn join":",@_; } );

cmp_ok( $expired, "<", $updated_expired, "cookie expiration was extended" );

$m->get_ok( "http://localhost/deleteme", "get page" );
$m->content_is( 1, 'session id changed' );
