package HTTP::Server::Simple::Static;
use strict;
use warnings;
use File::MMagic;
use MIME::Types;
use URI::Escape;
use File::Spec::Functions qw(canonpath);
require Exporter;
our $VERSION = '0.02';
our @ISA = qw(Exporter);
our @EXPORT = qw(serve_static);

my $mime=MIME::Types->new();
my $magic = File::MMagic->new();

sub serve_static { 
    my ($self,$cgi,$base) = @_;
    my $path = $cgi->url( -absolute => 1, -path_info => 1 );

    # Sanitize the path and try it.
    $path = $base.canonpath(uri_unescape($path));

    if (-e $path and open FILE, $path) {
	local $/;
	my $content=<FILE>;
	close FILE;
        my $mimeobj= $mime->mimeTypeOf($path);
        my $mime = ($mimeobj ? $mimeobj->type :
    			$magic->checktype_contents($content));
        print "HTTP/1.1 200 OK\n"; 
        print "Content-type: ", $mime, "\n";
        print "Content-length: ", length($content), "\n\n";
        print $content;
        return 1 ;
    } 
    return 0;
}

1;

=head1 NAME 

HTTP::Server::Simple::Static - Serve static files with HTTP::Server::Simple

=head1 SYNOPSIS

    use base 'HTTP::Server::Simple';
    use HTTP::Server::Simple::Static;

    sub handle_request {
	my ($self,$cgi) = @_;
	return $self->serve_static($cgi,$webroot);
    }

=head1 DESCRIPTION

this mixin adds a method to serve static files from your HTTP::Server::Simple
subclass.


=head1 METHODS

=over 4
 
=item  serve_static

Takes a base directory and a web path, and tries to serve a static file.

=back

=head1 SEE ALSO

=head1 AUTHOR

Marcus Ramberg C<marcus@thefeed.no>
Thanks to Simon Cozens for initial implementation.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
