package PreviewURL::Entry;

use strict;
use warnings;

use base 'MT::Entry';

__PACKAGE__->install_properties({
    column_defs => {
        previewurl_key => 'string(255) default null'
    },
    indexes => {
        previewurl_key => {
            columns => [ 'previewurl_key' ],
            unique => 1
        }
    }
});

1;
