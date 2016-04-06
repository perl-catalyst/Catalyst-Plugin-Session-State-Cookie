package # PAUSE HIDE
    CookieTestApp::Controller::Root;
use strict;
use warnings;

use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

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

sub set_session_cookie_expire : Local {
    my ( $self, $c, $val ) = @_;
    $val = undef if $val eq 'undef';
    $c->set_session_cookie_expire($val);
    $c->res->body('expire_with_browser_session');
}

sub deleteme : Local {
    my ( $self, $c ) = @_;
    my $id = $c->get_session_id;
    $c->delete_session;
    my $id2 = $c->get_session_id;
    $c->res->body( $id ne ( $id2 || '' ) );
}

1;
