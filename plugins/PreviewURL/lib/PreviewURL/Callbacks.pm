package PreviewURL::Callbacks;

use strict;
use warnings;

use MT::Util qw( perl_sha1_digest_hex caturl );

our $plugin = MT->component( 'PreviewURL' );

sub _cb_template_param_edit_entry {
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

    return if $obj->status == MT->model( $type )->RELEASE();

    my $preview_url = preview_url( $obj );
    my $pointer_field = $tmpl->getElementById( 'permalink' );
    my $nodeset = $tmpl->createElement('app:setting',
                                       {
                                           id => 'previewurl',
                                           required => 0,
                                           class => 'field-no-header' });
    my $innerHTML = <<"HTML";
<label>@{[ $plugin->translate( 'Preview URL' ) ]}</label>
<div class="input-group">
    <input type="text" readonly="readonly" onclick="this.select();" class="form-control text med" value="$preview_url" />
    <div class="input-group-append">
        <a class="button btn btn-default" href="$preview_url" target="_blank"><__trans phrase="View"></a>
    </div>
</div>
HTML
    $nodeset->innerHTML($innerHTML);
    $tmpl->insertAfter($nodeset, $pointer_field);
}

sub _cb_cms_filtered_list_param_entry {
    my $cb = shift;
    my ( $app, $res, $objs ) = @_;
    # $res->{ columns } = 'title,title-link,...'; idは入っていない
    # $res->{ objects } = [
    #   [1列目データ, 2列目データ, ...],
    #   [1列目データ, 2列目データ, ...],
    # ]
    my $columns     = $res->{ columns } or return;
    my $rows        = $res->{ objects } or return;
    my @columns     = split ',', $columns;
    my $preview_link = sub {
        my ( $obj ) = @_;
        my $class           = $obj->class;
        my $class_label     = $obj->class_label;
        my $preview_icon    = MT->static_path . 'images/status_icons/view.gif';
        qq{
            <span class="preview-link">
                <a href="@{[ preview_url( $obj ) ]}" target="_blank">
                    <img alt="Preview $class_label" src="$preview_icon" />
                </a>
            </span>
        };
    };
    for ( my $i=0; $i<@columns; $i++ ) {
        if ( $columns[$i] eq 'title' ) {
            for ( my $row_idx=0; $row_idx<@$rows; $row_idx++ ) {
                my $row = $rows->[$row_idx];
                my $obj = $objs->[$row_idx];
                if ( $obj->status != MT->model( $obj->class_type )->RELEASE() ) {
                    my $link = $preview_link->( $obj );
                    $row->[$i+1] =~ s|(<span class="title">.+?</span>)|$1$link|s;
                }
            }
        }
    }
}

sub preview_url {
    my ( $obj ) = @_;
    return unless defined $obj->id;
    my $app = MT->instance;
    my $key = $obj->previewurl_key;
    unless ( $key ) {
        $key = perl_sha1_digest_hex( sprintf( "%s:%05d:%011d", $obj->class_type, $obj->id, rand( time ) ) );
        $obj->previewurl_key( $key );
        $obj->save() or die;
    }
    my $uri = $app->mt_uri(
        mode => 'view_preview',
        args => {
            _type   => $obj->class_type,
            key     => $key,
            blog_id => $obj->blog_id,
        }
    );
    my $cfg = $app->config;
    my $url_base = $cfg->AdminCGIPath || $cfg->CGIPath;
    if ($url_base !~ m!^https://!) {
        $url_base = $app->{query}->url;
    }
    $url_base = $url_base =~ m!^(https?://[^/]+/?).*$!i ? $1 : '/';
    return caturl( $url_base, $uri );
}

1;
