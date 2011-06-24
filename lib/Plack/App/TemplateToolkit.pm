package Plack::App::TemplateToolkit;

use strict;
use warnings;
use 5.008_001;

use parent qw( Plack::Component );
use Plack::Request 0.9901;
use Plack::MIME;
use Template 2;

use Plack::Util::Accessor
    qw( root interpolate post_chomp dir_index path extension content_type
    default_type tt eval_perl pre_process process);

sub prepare_app {
    my ($self) = @_;

    die "No root supplied" unless $self->root();

    $self->dir_index('index.html')   unless $self->dir_index();
    $self->default_type('text/html') unless $self->default_type();
    $self->interpolate(0)            unless defined $self->interpolate();
    $self->eval_perl(0)              unless defined $self->eval_perl();
    $self->post_chomp(1)             unless defined $self->post_chomp();

    my $config = {
        INCLUDE_PATH => $self->root(),           # or list ref
        INTERPOLATE  => $self->interpolate(),    # expand "$var" in plain text
        POST_CHOMP   => $self->post_chomp(),     # cleanup whitespace
        EVAL_PERL    => $self->eval_perl(),      # evaluate Perl code blocks
    };

    $config->{PRE_PROCESS} = $self->pre_process() if $self->pre_process();
    $config->{PROCESS}     = $self->process()     if $self->process();

    # create Template object
    $self->tt( Template->new($config) );

}

sub call {
    my $self = shift;
    my $env  = shift;

    if ( my $res = $self->_handle_tt($env) ) {
        return $res;
    }
    return [ 404, [ 'Content-Type' => 'text/html' ], ['404 Not Found'] ];
}

sub _handle_tt {
    my $self = shift;
    my $req  = Plack::Request->new(shift);

    my $path = $req->path;
    $path .= $self->dir_index if $path =~ /\/$/;

    if ( my $extension = $self->extension() ) {
        return 0 unless $path =~ /${extension}$/;
    }

    my $tt = $self->tt();

    my $vars = { params => $req->query_parameters(), };

    my $content;
    $path =~ s{^/}{};    # Do not want to enable absolute paths

    if ( $tt->process( $path, $vars, \$content ) ) {
        my $type = $self->content_type || do {
            Plack::MIME->mime_type($1) if $path =~ /(\.\w{1,6})$/;
            }
            || $self->default_type;
        return [ 200, [ 'Content-Type' => $type ], [$content] ];
    } else {
        my $error = $tt->error->as_string();
        my $type = $self->content_type || $self->default_type;

        if ( $error =~ /file error .+ not found/ ) {
            return [ '404', [ 'Content-Type' => $type ], [$error] ];
        } else {
            warn $error;
            return [ '500', [ 'Content-Type' => $type ], [$error] ];

        }
    }
}

1;

__END__

=head1 NAME

Plack::App::TemplateToolkit DEPRECIATED use Plack::Middleware::TemplateToolkit

=head1 DESCRIPTION

Plack::App::TemplateToolkit DEPRECIATED use Plack::Middleware::TemplateToolkit

=head1 SEE ALSO

L<Plack::Middleware::TemplateToolkit>

=cut
