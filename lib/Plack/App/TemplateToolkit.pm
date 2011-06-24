package Plack::App::TemplateToolkit;
use strict;
use warnings;

use parent qw( Plack::Component );
use Plack::Request 0.9901;
use Template 2;

use Plack::Util::Accessor
    qw( root interpolate post_chomp dir_index path extension content_type tt eval_perl pre_process process);

sub prepare_app {
    my ($self) = @_;

    die "No root supplied" unless $self->root();

    $self->dir_index('index.html')   unless $self->dir_index();
    $self->content_type('text/html') unless $self->content_type();
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
    my ( $self, $env ) = @_;

    my $path = $env->{PATH_INFO};

    if ( $path !~ /\.\w{1,6}$/ ) {

        # Use this regex instead of -e as $self->root can be a list ref
        # TT will sort it out,

        # No file extension
        $path .= $self->dir_index;
    }

    if ( my $extension = $self->extension() ) {
        return 0 unless $path =~ /${extension}$/;
    }

    my $tt = $self->tt();

    my $req = Plack::Request->new($env);

    my $vars = { params => $req->query_parameters(), };

    my $content;
    $path =~ s{^/}{};    # Do not want to enable absolute paths

    if ( $tt->process( $path, $vars, \$content ) ) {
        return [
            '200', [ 'Content-Type' => $self->content_type() ],
            [$content]
        ];
    } else {
        my $error = $tt->error->as_string();
        if ( $error =~ /not found/ ) {
            return [
                '404', [ 'Content-Type' => $self->content_type() ],
                [$error]
            ];
        } else {
            return [
                '500', [ 'Content-Type' => $self->content_type() ],
                [$error]
            ];
        }
    }
}

1;

# ABSTRACT: DEPRECIATED use Plack::Middleware::TemplateToolkit

__END__

=head1 NAME

Plack::App::TemplateToolkit DEPRECIATED use Plack::Middleware::TemplateToolkit

=head1 SYNOPSIS

  Use Plack::Middleware::TemplateToolkit instead of this.

=head1 DESCRIPTION

Use Plack::Middleware::TemplateToolkit instead of this package.

=head1 SEE ALSO

L<Plack::Middleware::TemplateToolkit>

=cut
