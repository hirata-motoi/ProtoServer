package ProtoServer::Web;
use strict;
use warnings;
use utf8;
use parent qw/ProtoServer Amon2::Web/;
use File::Spec;
use Log::Minimal;
use Carp;
use ProtoServer::Web::Root;
use ProtoServer::Config;

use Data::Dumper;

# load plugins
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::JSON',
    '+ProtoServer::Web::Plugin::Session',
    'Web::Stash' => +{
       autorender => 1,
    },
);

# dispatcher
use ProtoServer::Web::Dispatcher;
sub dispatch {
    return ( ProtoServer::Web::Dispatcher->dispatch($_[0]) or __exception("response is not generated") );
}

sub __exception {
    my $msg = shift;
    critff($msg);
    croak($msg);
}


# setup view
use ProtoServer::Web::View;
{
    sub create_view {
        my $view = ProtoServer::Web::View->make_instance(__PACKAGE__);
        no warnings 'redefine';
        *ProtoServer::Web::create_view = sub { $view }; # Class cache.
        $view
    }
}

sub render_json_validation_error {
    my ($c, $validator) = @_;

    my $messages = $validator->get_messages();
    my $res = $c->render_json( +{ error_messages => $messages } );
    $res->status(400);
    return $res;
}


# for your security
__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ($c, $res) = @_;

        # set domain
        $c->stash->{domain} = $c->req->env->{'HTTP_HOST'};

        # to https
        $c->req->env->{"psgi.url_scheme"} = "https";

        my $session_id = $c->session->get('session_id');

        my $session_not_required_paths = ProtoServer::Common->config->{session_not_required_paths} || [];

        my $path = $c->req->env->{PATH_INFO};
        if ( ! $session_id  ) {
            if ( ! grep { $path =~ m{^$_} } @$session_not_required_paths ) {
                infof('redirect to landing page');
                return;
            }
            return;
        }

        my $base_info = ProtoServer::Web::Root->new->certify($session_id);
        for my $key (keys %$base_info) {
            $c->stash->{$key} = $base_info->{$key};
        }

        # update session_id
        if ($c->stash->{session_have_to_update}) {
            infof("update session_id.");
            my $new_session_id = ProtoServer::Web::Root->new->update_session($c->stash->{user_id});
            $c->session->set('session_id', $new_session_id);
            $c->session->session_cookie->{expires} = time + 31*24*60*60 + 9*60*60;
        }

        # clear session when session is invalid
        if ( ! $c->stash->{user_id} ) {
            $c->session->remove('session_id');
            infof('redirect to login page');
            return;
        }

    },

    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );
    },
);

1;
