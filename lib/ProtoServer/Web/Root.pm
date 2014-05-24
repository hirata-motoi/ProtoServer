package ProtoServer::Web::Root;
use strict;
use warnings;
use utf8;
use Log::Minimal;
use parent qw/ProtoServer/;

use ProtoServer::Logic::Session;
use ProtoServer::Logic::Register;

sub certify {
    my ($self, $session_id) = @_;

    my $session = ProtoServer::Logic::Session->new->get($session_id);

    if( $session->{user_id} ) {
        if( $session->{expired_at} > time() ) {
            return { user_id => $session->{user_id} };
        } else {
            return { user_id => $session->{user_id}, session_have_to_update => '1' };
        }
    } else {
        return {};
    }
}

sub update_session {
    my ($self, $user_id) = @_;

    my $session_id = ProtoServer::Logic::Session->new->set($user_id);

    return $session_id;
}

sub is_verified {
    my ($self, $user_id) = @_;

    return ProtoServer::Logic::Register->new->is_verified($user_id);
}

1;

