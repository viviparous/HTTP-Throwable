#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('HTTP::Throwable::RequestTimeout');
}

isa_ok(exception {
    HTTP::Throwable::RequestTimeout->throw();
}, 'HTTP::Throwable');

does_ok(exception {
    HTTP::Throwable::RequestTimeout->throw();
}, 'Throwable');

my $e = HTTP::Throwable::RequestTimeout->new();

my $body = '408 Request Timeout';

is($e->as_string, $body, '... got the right string transformation');
is_deeply(
    $e->as_psgi,
    [
        408,
        [
            'Content-Type'   => 'text/plain',
            'Content-Length' => length $body,
        ],
        [ $body ]
    ],
    '... got the right PSGI transformation'
);


done_testing;