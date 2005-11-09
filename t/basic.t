#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::MockObject;
use Test::MockObject::Extends;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session::State::Cookie" ) }

my $cookie = Test::MockObject->new;
$cookie->set_always( value => "the session id" );

my $req = Test::MockObject->new;
my %req_cookies;
$req->set_always( cookies => \%req_cookies );

my $res = Test::MockObject->new;
my %res_cookies;
$res->set_always( cookies => \%res_cookies );

my $cxt =
  Test::MockObject::Extends->new("Catalyst::Plugin::Session::State::Cookie");

$cxt->set_always( config   => {} );
$cxt->set_always( request  => $req );
$cxt->set_always( response => $res );
$cxt->set_always( session  => { __expires => 123 } );
$cxt->set_false("debug");
my $sessionid;
$cxt->mock( sessionid => sub { shift; $sessionid = shift if @_; $sessionid } );

can_ok( $m, "setup_session" );

$cxt->setup_session;

is( $cxt->config->{session}{cookie_name},
    "session", "default cookie name is set" );

can_ok( $m, "prepare_cookies" );

$cxt->prepare_cookies;
ok( !$cxt->called("sessionid"),
    "didn't try setting session ID when there was nothing to set it by" );

$cxt->clear;

%req_cookies = ( session => $cookie );

ok( !$cxt->sessionid, "no session ID yet" );
$cxt->prepare_cookies;
is( $cxt->sessionid, "the session id", "session ID was restored from cookie" );

$cxt->clear;
$res->clear;

can_ok( $m, "finalize_cookies" );
$cxt->finalize_cookies;
{ local $TODO = "This check is a pain to write, should be done by catalyst itself";
ok( !$res->called("cookies"),
    "response cookie was not set since res cookie is already there" );
}

$cxt->clear;
$sessionid = undef;
$res->clear;

$cxt->finalize_cookies;
ok( !$res->called("cookies"),
"response cookie was not set when sessionid was deleted, even if req cookie is still there"
);

$sessionid = "some other ID";
$cxt->clear;
$res->clear;

$cxt->finalize_cookies;
$res->called_ok( "cookies", "response cookie was set when sessionid changed" );
is_deeply(
    \%res_cookies,
    { session => { value => $sessionid, expires => 123 } },
    "cookie was set correctly"
);

$cxt->clear;
$res->clear;
%req_cookies = ();
%res_cookies = ();
$sessionid   = undef;

$cxt->finalize_cookies;
ok( !$res->called("cookies"),
    "response cookie was not set when there is no sessionid or request cookie"
);

$cxt->clear;
$sessionid   = "123";
%res_cookies = ();
$res->clear;

$cxt->finalize_cookies;

$res->called_ok( "cookies",
    "response cookie was set when session was created" );
is_deeply(
    \%res_cookies,
    { session => { value => $sessionid, expires => 123 } },
    "cookie was set correctly"
);

