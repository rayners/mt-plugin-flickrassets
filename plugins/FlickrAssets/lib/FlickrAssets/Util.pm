
package FlickrAssets::Util;

use strict;
use warnings;

use base qw( Exporter );

our @EXPORT_OK = qw( run_method get_user_id build_login_link run_auth_method authorize_blog_user );

use Digest::MD5 qw( md5_hex );
use XML::Simple;

sub build_api_sig {
    my (%params) = @_;
    my $sig_str = join( '',
        MT->config->FlickrAssetsAPISecret,
        map { ( $_, $params{$_} ) } sort keys %params );
    $sig_str = md5_hex($sig_str);
    return $sig_str;
}

sub build_login_link {
    my ($frob)   = @_;
    my $base_url = 'http://flickr.com/services/auth/';
    my $api_key  = MT->config->FlickrAssetsAPIKey;
    my $ua       = MT->new_ua;

    my %params = ( api_key => $api_key, frob => $frob, perms => 'read' );
    my $sig_str = build_api_sig(%params);
    $params{api_sig} = $sig_str;

    $base_url . '?' . join( '&', map { $_ . '=' . $params{$_} } keys %params );
}

sub authorize_blog_user {
    my (%params) = @_;

    my $blog = $params{Blog} || $params{blog};
    if ( !$blog && ( my $blog_id = $params{BlogID} || $params{blog_id} ) ) {
        require MT::Blog;
        $blog = MT::Blog->load($blog_id);
    }

    return if ( !$blog );

    my $p = MT->component('flickrassets');
    my $username;
    if ( $username = $params{Username} || $params{username} ) {
        my $auth_users = $p->get_config_value('authenticated_users');
        if ( !$auth_users->{$username} || !$auth_users->{$username}->{token} ) {
            print "No token for $username\n";
            return;
        }
    }
    elsif ( my $author = $params{Author} || $params{author} ) {
        my $auth_users = $p->get_config_value('authenticated_users');
        foreach my $u ( keys %$auth_users ) {
            if (   $auth_users->{$u}->{id}
                && $auth_users->{$u}->{id} == $author->id )
            {
                $username = $u;
                last;
            }
        }
    }

    return unless $username;

    my $blog_auth_users =
      $p->get_config_value( 'authorized_blog_users', 'blog:' . $blog->id );
    $blog_auth_users->{$username} = 1;
    $p->set_config_value( 'authorized_blog_users', $blog_auth_users,
        'blog:' . $blog->id );

    1;
}

sub run_auth_method {
    my (%params) = @_;

    my $method = $params{Method} || $params{method};
    return unless $method;

    my $blog = $params{Blog} || $params{blog};
    if ( !$blog && ( my $blog_id = $params{BlogID} || $params{blog_id} ) ) {
        require MT::Blog;
        $blog = MT::Blog->load($blog_id);
    }

    return unless $blog;

    my $username   = $params{Username} || $params{username};
    my $p          = MT->component('flickrassets');
    my $auth_users = $p->get_config_value('authenticated_users');
    if ( !$auth_users->{$username} || !$auth_users->{$username}->{token} ) {
        print "No token for $username\n";
        return;
    }

    my $blog_auth_users =
      $p->get_config_value( 'authorized_blog_users', 'blog:' . $blog->id );
    return unless $blog_auth_users->{$username};

    my $params = $params{Params} || $params{params};
    _run_auth_method(
        $method,
        auth_token => $auth_users->{$username}->{token},
        ( $params ? %$params : () )
    );
}

sub _run_auth_method {
    my ( $method, %params ) = @_;

    my $base_url = 'http://api.flickr.com/services/rest/';
    my $api_key  = MT->config->FlickrAssetsAPIKey;
    my $ua       = MT->new_ua;

    $params{api_key} = $api_key;
    $params{method}  = $method;

    my $sig_str = build_api_sig(%params);
    my $res = $ua->post( $base_url, [ %params, api_sig => $sig_str ] );

    return $res->content;
}

sub run_method {
    my ( $method, %params ) = @_;

    my $base_url = 'http://api.flickr.com/services/rest/';
    my $api_key  = MT->config->FlickrAssetsAPIKey;
    my $ua       = MT->new_ua;
    my $res =
      $ua->post( $base_url,
        [ method => $method, api_key => $api_key, %params ] );

    return $res->content;
}

sub get_user_id {
    my ($username) = @_;
    my $out =
      run_method( 'flickr.people.findByUsername', username => 'rayners' );
    my $xml_ref = XMLin($out);

    return $xml_ref->{user}->{nsid};
}

1;
