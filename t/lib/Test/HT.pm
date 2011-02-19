package t::lib::Test::HT;
use strict;
use warnings;

use HTTP::Throwable::Factory;
use Scalar::Util qw(reftype);
use Test::Deep qw(cmp_deeply bag);
use Test::Fatal;
use Test::Moose;
use Test::More;

use Sub::Exporter -setup => {
  exports => [ qw(ht_test) ],
  groups  => [ default => [ '-all' ] ],
};

sub ht_test {
  my ($identifier, $arg);

  ($identifier, $arg) = ref $_[0] ? (undef, shift) : (shift, shift || {});

  my $comment    = (defined $_[0] and ! ref $_[0])
                 ? shift(@_)
                 : sprintf("ht_test at %s, line %s", (caller)[1, 2]);

  my $extra      = (! defined $_[0])         ? {}
                 : (! reftype $_[0])         ? confess("bogus extra value")
                 : (reftype $_[0] eq 'CODE') ? { assert => $_[0] }
                 : (reftype $_[0] eq 'HASH') ? $_[0]
                 :                             confess("bogus extra value");

  subtest $comment => sub {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $exception = exception { 
      HTTP::Throwable::Factory->throw($identifier, $arg);
    };

    does_ok($exception, 'HTTP::Throwable');
    does_ok($exception, 'Throwable');

    if (my $code = $extra->{code}) {
      is($exception->status_code, $code, "got expected status code");

      $code =~ /^3/
        ? ok(   $exception->is_redirect, "it's a redirect" )
        : ok( ! $exception->is_redirect, "it's not a redirect" );

      $code =~ /^4/
        ? ok(   $exception->is_client_error, "it's a client error")
        : ok( ! $exception->is_client_error, "it's a not client error");

      $code =~ /^5/
        ? ok(   $exception->is_server_error, "it's a server error" )
        : ok( ! $exception->is_server_error, "it's not a server error" );
    }

    if (defined $extra->{reason}) {
      is($exception->reason, $extra->{reason}, "got expected reason");
    }

    if (defined $extra->{code} and defined $extra->{reason}) {
      my $body = $extra->{body} || join q{ }, @$extra{ qw(code reason) };

      cmp_deeply($exception->as_string, $body, "got the expected body");

      my $length = $extra->{length} // length $body;

      unless (defined $extra->{body}) {
        cmp_deeply(
            $exception->as_psgi,
            [
                $extra->{code},
                bag(
                    'Content-Type'   => 'text/plain',
                    'Content-Length' => $length,
                    @{ $extra->{headers} || [] },
                ),
                [ $body ]
            ],
            '... got the right PSGI transformation'
        );
      }
    }

    if ($extra->{assert}) {
      local $_ = $exception;
      $extra->{assert}->($exception);
    }
  };
}

1;
