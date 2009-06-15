
package FlickrAssets::FlickrAsset;

use strict;
use base qw( MT::Asset );

__PACKAGE__->install_properties(
    {
        class_type  => 'flickr',
        column_defs => {
            photo_id => 'integer indexed meta',
            server  => 'integer meta',
            farm    => 'integer meta',
            license => 'integer indexed meta',
            owner   => 'string indexed meta'
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

sub thumbnail_url {
    my $obj = shift;
    my (%params) = @_;

    my $size = 's';

    $size = 'm' if ( $params{Height} == 240 );

    return
        'http://farm'
      . $obj->farm
      . '.static.flickr.com/'
      . $obj->server . '/'
      . $obj->photo_id . '_'
      . $obj->photo_secret . '_'
      . $size . '.jpg';
}

sub photo_secret {
    shift->file_name(@_);
}

sub photo_title {
    shift->label(@_);
}

1;
