package Catalyst::Plugin::Session::State::Cookie;
use base qw/Catalyst::Plugin::Session::State/;

use strict;
use warnings;

use NEXT;
use Catalyst::Utils ();

our $VERSION = "0.06";

sub setup_session {
    my $c = shift;

    $c->NEXT::setup_session(@_);

    $c->config->{session}{cookie_name}
        ||= Catalyst::Utils::appprefix($c) . '_session';
}

sub extend_session_id {
    my ( $c, $sid, $expires ) = @_;

    if ( my $cookie = $c->get_session_cookie ) {
        $c->update_session_cookie( $c->make_session_cookie( $sid ) );
    }

    $c->NEXT::extend_session_id( $sid, $expires );
}

sub set_session_id {
    my ( $c, $sid ) = @_;

    $c->update_session_cookie( $c->make_session_cookie( $sid ) );

    return $c->NEXT::set_session_id($sid);
}

sub update_session_cookie {
    my ( $c, $updated ) = @_;
    
    unless ( $c->cookie_is_rejecting( $updated ) ) {
        my $cookie_name = $c->config->{session}{cookie_name};
        $c->response->cookies->{$cookie_name} = $updated;
    }
}

sub cookie_is_rejecting {
    my ( $c, $cookie ) = @_;
    
    if ( $cookie->{path} ) {
        return 1 if index '/'.$c->request->path, $cookie->{path};
    }
    
    return 0;
}

sub make_session_cookie {
    my ( $c, $sid, %attrs ) = @_;

    my $cfg    = $c->config->{session};
    my $cookie = {
        value => $sid,
        ( $cfg->{cookie_domain} ? ( domain => $cfg->{cookie_domain} ) : () ),
        ( $cfg->{cookie_path} ? ( path => $cfg->{cookie_path} ) : () ),
        %attrs,
    };

    unless ( exists $cookie->{expires} ) {
        $cookie->{expires} = $c->calculate_session_cookie_expires();
    }

    $cookie->{secure} = 1 if $cfg->{cookie_secure};

    return $cookie;
}

sub calc_expiry { # compat
    my $c = shift;
    $c->NEXT::calc_expiry( @_ ) || $c->calculate_session_cookie_expires( @_ );
}

sub calculate_session_cookie_expires {
    my $c   = shift;
    my $cfg = $c->config->{session};

    my $value = $c->NEXT::calculate_session_cookie_expires(@_);
    return $value if $value;

    if ( exists $cfg->{cookie_expires} ) {
        if ( $cfg->{cookie_expires} > 0 ) {
            return time() + $cfg->{cookie_expires};
        }
        else {
            return undef;
        }
    }
    else {
        return $c->session_expires;
    }
}

sub get_session_cookie {
    my $c = shift;

    my $cookie_name = $c->config->{session}{cookie_name};

    return $c->request->cookies->{$cookie_name};
}

sub get_session_id {
    my $c = shift;

    if ( my $cookie = $c->get_session_cookie  ) { 
        my $sid = $cookie->value;
        $c->log->debug(qq/Found sessionid "$sid" in cookie/) if $c->debug;
        return $sid if $sid;
    }

    $c->NEXT::get_session_id(@_);
}

sub delete_session_id {
    my ( $c, $sid ) = @_;

    $c->update_session_cookie( $c->make_session_cookie( $sid, expires => 0 ) );

    $c->NEXT::delete_session_id($sid);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::State::Cookie - Maintain session IDs using cookies.

=head1 SYNOPSIS

    use Catalyst qw/Session Session::State::Cookie Session::Store::Foo/;

=head1 DESCRIPTION

In order for L<Catalyst::Plugin::Session> to work the session ID needs to be
stored on the client, and the session data needs to be stored on the server.

This plugin stores the session ID on the client using the cookie mechanism.

=head1 METHODS

=over 4

=item make_session_cookie

Returns a hash reference with the default values for new cookies.

=item update_session_cookie $hash_ref

Sets the cookie based on C<cookie_name> in the response object.

=back

=head1 EXTENDED METHODS

=over 4

=item prepare_cookies

Will restore if an appropriate cookie is found.

=item finalize_cookies

Will set a cookie called C<session> if it doesn't exist or if it's value is not
the current session id.

=item setup_session

Will set the C<cookie_name> parameter to it's default value if it isn't set.

=back

=head1 CONFIGURATION

=over 4

=item cookie_name

The name of the cookie to store (defaults to C<Catalyst::Utils::apprefix($c) . '_session'>).

=item cookie_domain

The name of the domain to store in the cookie (defaults to current host)

=item cookie_expires

Number of seconds from now you want to elapse before cookie will expire. 
Set to 0 to create a session cookie, ie one which will die when the 
user's browser is shut down.

=item cookie_secure

If this attribute set true, the cookie will only be sent via HTTPS.

=item cookie_path

The path of the request url where cookie should be baked.

=back

=head1 CAVEATS

Sessions have to be created before the first write to be saved. For example:

	sub action : Local {
		my ( $self, $c ) = @_;
		$c->res->write("foo");
		$c->session( ... );
		...
	}

Will cause a session ID to not be set, because by the time a session is
actually created the headers have already been sent to the client.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>.

=head1 AUTHORS

This module is derived from L<Catalyst::Plugin::Session::FastMmap> code, and
has been heavily modified since.

Andrew Ford
Andy Grundman
Christian Hansen
Yuval Kogman, C<nothingmuch@woobling.org>
Marcus Ramberg
Sebastian Riedel

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
