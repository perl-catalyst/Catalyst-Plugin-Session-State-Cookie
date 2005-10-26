package Catalyst::Plugin::Session::State::Cookie;
use base qw/Catalyst::Plugin::Session::State/;

use strict;
use warnings;

use NEXT;

sub finalize {
    my $c = shift;

    if ( my $sid = $c->sessionid ) {
        my $cookie = $c->request->cookies->{session};
        if ( !$cookie or $cookie->value ne $sid ) {
            $c->response->cookies->{session} = { value => $sid };
            $c->log->debug(qq/A cookie with the session id "$sid" was saved/)
              if $c->debug;
        }
    }

    return $c->NEXT::finalize(@_);
}

sub prepare_cookies {
    my $c = shift;

    if ( my $cookie = $c->request->cookies->{session} ) {
        my $sid = $cookie->value;
        $c->sessionid($sid);
        $c->log->debug(qq/Found sessionid "$sid" in cookie/) if $c->debug;
    }

    $c->NEXT::prepare_cookies(@_);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::State::Cookie - A session ID 

=head1 SYNOPSIS

	use Catalyst qw/Session Session::State::Cookie Session::Store::Foo/;

=head1 DESCRIPTION

In order for L<Catalyst::Plugin::Session> to work the session ID needs to be
stored on the client, and the session data needs to be stored on the server.

This plugin stores the session ID on the client using the cookie mechanism.

=head1 EXTENDED METHODS

=over 4

=item prepare_cookies

Will restore if an appropriate cookie is found.

=item finalize

Will set a cookie called C<session> if it doesn't exist or if it's value is not the current session id.

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>.

=head1 AUTHOR

Sebastian Riedel E<lt>C<sri@cpan.org>E<gt>,
Marcus Ramberg E<lt>C<mramberg@cpan.org>E<gt>,
Andrew Ford E<lt>C<andrewf@cpan.org>E<gt>,
Yuval Kogman E<lt>C<nothingmuch@woobling.org>E<gt>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
