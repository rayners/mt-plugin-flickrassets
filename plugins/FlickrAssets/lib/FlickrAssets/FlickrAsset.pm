
package FlickrAssets::FlickrAsset;

use strict;
use base qw( MT::Asset );

__PACKAGE__->install_properties(
    {
        class_type  => 'flickr',
        column_defs => {
            photo_id => 'string indexed meta',
            server   => 'integer meta',
            farm     => 'integer meta',
            license  => 'integer indexed meta',
            owner    => 'string indexed meta'
        },
    }
);

sub class_label {
    MT->translate('Flickr Image');
}

sub class_label_plural {
    MT->translate("Flickr Images");
}

sub has_thumbnail { 1 }

# s small square 75x75
# t thumbnail, 100 on longest side
# m small, 240 on longest side
# - medium, 500 on longest side
# b large, 1024 on longest side (only exists for very large original images)
# o original image, either a jpg, gif or png, depending on source format

sub thumbnail_url {
    my $obj = shift;
    my (%params) = @_;

    my $size = 's';

    if ( $params{size} ) {
        $size = $params{size};
    }
    else {
        $size = 'm' if ( $params{Height} == 240 );
    }

    if ($size) {
        return
            'http://farm'
          . $obj->farm
          . '.static.flickr.com/'
          . $obj->server . '/'
          . $obj->photo_id . '_'
          . $obj->photo_secret . '_'
          . $size . '.jpg'
          if ( $size ne 'o' );
    }
    else {
        return
            'http://farm'
          . $obj->farm
          . '.static.flickr.com/'
          . $obj->server . '/'
          . $obj->photo_id . '_'
          . $obj->photo_secret . '.jpg';

    }
}

sub photo_secret {
    shift->file_name(@_);
}

sub photo_title {
    shift->label(@_);
}

sub as_html {
    my $asset = shift;
    my ($params) = @_;

    my $wrap_style = '';
    if ( $params->{align} ) {
        $wrap_style = 'class="mt-image-' . $params->{align} . '" ';
        if ( $params->{align} eq 'none' ) {
            $wrap_style .= q{style=""};
        }
        elsif ( $params->{align} eq 'left' ) {
            $wrap_style .= q{style="float: left; margin: 0 20px 20px 0;"};
        }
        elsif ( $params->{align} eq 'right' ) {
            $wrap_style .= q{style="float: right; margin: 0 0 20px 20px;"};
        }
        elsif ( $params->{align} eq 'center' ) {
            $wrap_style .=
q{style="text-align: center; display: block; margin: 0 auto 20px;"};
        }

    }
    my $text = sprintf '<a href="%s"><img src="%s" title="%s" %s /></a>',
      MT::Util::encode_html( $asset->url ),
      MT::Util::encode_html( $asset->thumbnail_url(%$params) ),
      MT::Util::encode_html( $asset->label ),
      $wrap_style;
    return $asset->enclose($text);
}

sub insert_options {
    my $asset = shift;
    my ($param) = @_;

    my $app = MT->instance;
    my $plugin = MT->component('flickrassets');
    my $tmpl = $plugin->load_tmpl( 'dialog/insert_options.tmpl', $param )
      or MT->log( $plugin->errstr );
    my $html = $app->build_page( $tmpl, $param );
    if ( !$html ) {
        MT->log( $app->errstr );
    }
    return $html;

}

1;
