package # Hide from PAUSE
  CookieTestApp;
use Catalyst qw/
  Session
  Session::Store::Dummy
  Session::State::Cookie
  /;

__PACKAGE__->config->{session} = { cookie_secure => 2 };

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

1;

