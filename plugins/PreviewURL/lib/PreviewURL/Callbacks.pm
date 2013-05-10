package PreviewURL::Callbacks;

use strict;
use warnings;

use MT::Util qw( perl_sha1_digest_hex caturl );

our $plugin = MT->component( 'PreviewURL' );

sub hdlr_template_param_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $id = $app->param( 'id' ) or return;
    my $blog_id = $app->param( 'blog_id' ) or return;
    my $type = $app->param( '_type' ) || 'entry';

    my $obj = MT->model( 'entry' )->load(
        {
            id => $id,
            blog_id => $blog_id,
            class => $type
        },
        {
            limit => 1
        });
    return unless defined $obj;

    return if $obj->status == MT::Entry::RELEASE();

    my $key = $obj->previewurl_key;
    unless ( $key ) {
        $key = perl_sha1_digest_hex( sprintf( "%s:%05d:%011d", $type, $id, rand( time ) ) );
        $obj->previewurl_key( $key );
        $obj->save() or die;
    }

    my $uri = $app->mt_uri(
        mode => 'view_preview',
        args => {
            _type => $type,
            key => $key,
            blog_id => $blog_id,
        }
    );
    my $cfg = $app->config;
    my $url_base = $cfg->AdminCGIPath || $cfg->CGIPath;
    $url_base = $url_base =~ m!^(https?://[^/]+/?).*$!i ? $1 : '/';
    my $preview_url = caturl( $url_base, $uri );
    
    my $pointer_field = $tmpl->getElementById( 'permalink' );
    my $nodeset = $tmpl->createElement('app:setting',
                                       {
                                           id => 'previewurl',
                                           required => 0,
                                           class => 'field-no-header' });
    my $innerHTML = <<"HTML";
<strong>@{[ $plugin->translate( 'Preview URL' ) ]}:</strong>
<input type="text" readonly="readonly" onclick="this.select();" style="width: 530px;" value="$preview_url" />
<a class="button" href="$preview_url" target="<__trans phrase="_external_link_target">"><__trans phrase="View"></a>
HTML
    $nodeset->innerHTML($innerHTML);
    $tmpl->insertAfter($nodeset, $pointer_field);
}

1;
