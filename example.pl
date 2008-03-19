#!/usr/bin/perl
use strict;
use warnings;

package MyServer;

use lib qw(./lib);
use base 'HTTP::Server::Simple::CGI';
use HTTP::Server::Simple::Static;

my $webroot = '/tmp';

sub handle_request {
    my ($self,$cgi) = @_;
    return $self->serve_static($cgi,$webroot);
}

package main;

my $server = MyServer->new();
$server->run();


