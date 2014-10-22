package HTTP::Server::Simple::Static;
use strict;
use warnings;

use File::LibMagic ();
use File::Spec::Functions qw(canonpath);
use HTTP::Date ();
use IO::File     ();
use URI::Escape  ();

use base qw(Exporter);
our @EXPORT = qw(serve_static);

our $VERSION = '0.09';

my $line_end = "\015\012";

my $magic = File::LibMagic->new();

sub serve_static {
    my ( $self, $cgi, $base ) = @_;
    my $path = $cgi->url( -absolute => 1, -path_info => 1 );

    # Internet Explorer provides the full URI in the GET section
    # of the request header, so remove the protocol, domain name,
    # and port if they exist.
    $path =~ s{^https?://([^/:]+)(:\d+)?/}{/};

    # Sanitize the path and try it.
    $path = $base . canonpath( URI::Escape::uri_unescape($path) );

    my $fh = IO::File->new();
    if ( -f $path && $fh->open($path) ) {
        my $mtime = ( stat $path )[9];
        my $now = time;

        # RFC-2616 Section 14.25 "If-Modified-Since":

	my $if_modified_since = $cgi->http('If-Modified-Since');
	if ($if_modified_since) {
	    $if_modified_since = HTTP::Date::str2time($if_modified_since);

	    if ( defined $if_modified_since &&     # parsed ok
		 $if_modified_since <= $now &&     # not in future
		 $mtime <= $if_modified_since ) {  # not changed

		print 'HTTP/1.1 304 Not Modified' . $line_end;
		print $line_end;

		return 1;
	    }
	}

	# Read the file contents and get the length in bytes

        binmode $fh;
        binmode $self->stdout_handle;

        my $content;
        {
            local $/;
            $content = <$fh>;
        }
        $fh->close;

        my $content_length;
        if ( defined $content ) {
            use bytes;    # Content-Length in bytes, not characters
            $content_length = length $content;
        }
        else {
            $content_length = 0;
            $content        = q{};
        }

	# Find MIME type

        my $mimetype = $magic->checktype_filename($path);

        # RFC-2616 Section 14.29 "Last-Modified":
        #
        # An origin server MUST NOT send a Last-Modified date which is
        # later than the server's time of message origination. In such
        # cases, where the resource's last modification would indicate
        # some time in the future, the server MUST replace that date
        # with the message origination date.

        if ( $mtime > $now ) {
            $mtime = $now;
        }

        my $last_modified = HTTP::Date::time2str($mtime);
        my $date = HTTP::Date::time2str($now);

        print 'HTTP/1.1 200 OK' . $line_end;
        print 'Date: ' . $date . $line_end;
        print 'Last-Modified: ' . $last_modified . $line_end;
        print 'Content-type: ' . $mimetype . $line_end;
        print 'Content-length: ' . $content_length . $line_end;
        print $line_end;

	if ( $cgi->request_method() ne 'HEAD' ) {
	    print $content;
	}

        return 1;
    }
    return 0;
}

1;
__END__

=head1 NAME

HTTP::Server::Simple::Static - Serve static files with HTTP::Server::Simple

=head1 VERSION

This documentation refers to HTTP::Server::Simple::Static version 0.07

=head1 SYNOPSIS

    package MyServer;

    use base qw(HTTP::Server::Simple::CGI);
    use HTTP::Server::Simple::Static;

    my $webroot = '/var/www';

    sub handle_request {
	my ( $self, $cgi ) = @_;

        if ( !$self->serve_static( $cgi, $webroot ) ) {
            print "HTTP/1.0 404 Not found\r\n";
            print $cgi->header, 
                  $cgi->start_html('Not found'),
                  $cgi->h1('Not found'),
                  $cgi->end_html;
        }
    } 

    package main;

    my $server = MyServer->new();
    $server->run();

=head1 DESCRIPTION

this mixin adds a method to serve static files from your HTTP::Server::Simple
subclass.


=head1 SUBROUTINES/METHODS

=over 4

=item serve_static( $cgi, $base )

Takes a reference to the CGI object and a document root path, and
tries to serve a static file. Returns 0 if the file does not exist,
returns 1 on success.

This method sets the C<Date> and C<Last-Modified> HTTP headers when
sending a response for a valid file. Further to this, the method
supports clients which send an C<If-Modified-Since> HTTP header in the
request, it will return a 304 C<Not Modified> response if the file is
unchanged. See RFC-2616 for full details.

If the client makes a C<HEAD> request then no message body will be
returned in the response.

=back

=head1 BUGS AND LIMITATIONS

Bugs or wishlist requests should be submitted via http://rt.cpan.org/

=head1 DEPENDENCIES

The L<File::LibMagic> module is used to detect the MIME-type of
a file. The L<URI::Escape> module is used for URI handling. The
L<HTTP::Date> module is used to format the timestamp in the
Last-Modified HTTP header.

=head1 SEE ALSO

L<HTTP::Server::Simple>, L<HTTP::Server::Simple::CGI>

=head1 AUTHOR

Stephen Quinney C<sjq-perl@jadevine.org.uk>

Thanks to Marcus Ramberg C<marcus@thefeed.no> and Simon Cozens for
initial implementation.

=head1 LICENSE AND COPYRIGHT

Copyright 2006 - 2013. Stephen Quinney C<sjq-perl@jadevine.org.uk>

You may distribute this code under the same terms as Perl itself.

=cut
