package PreviewURL::CMS;

use strict;
use warnings;

use File::Spec;
use FindBin;
use File::Basename;

sub hdlr_view_preview {
    my $app = shift;
    
    my $key = $app->param( 'key' );
    my $blog_id = $app->param( 'blog_id' );
    my $type = $app->param( '_type' ) || 'entry';

    my $blog = MT->model( 'blog' )->load( $blog_id )
      or return $app->errtrans( "Invalid request." );

    my $obj = MT->model( 'entry.previewurl' )->load(
        {
            previewurl_key => $key,
            blog_id => $blog->id,
            class => $type
        },
        {
            limit => 1
        }) or return $app->errtrans( "Invalid request." );

    my $author = MT->model( 'author' )->load( $obj->author_id );
    
    $app->param( 'id', $obj->id );
    $obj->authored_on =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/;
    $app->param( 'authored_on_date', sprintf( "%04d:%02d:%02d", $1, $2, $3 ) );
    $app->param( 'authored_on_time', sprintf( "%02d-%02d-%02d", $4, $5, $6 ) );

    $app->param( 'basename', '' );

    $app->user( $author );
    $app->permissions( $author->permissions($blog_id) );
    $app->preview_entry; # プレビューファイル生成

    # 生成されたファイルの内容を読込
    $obj = MT->model( $type )->load( $obj->id );
    my $preview_basename = $app->preview_object_basename;
    $obj->basename( $preview_basename );

    my $file_ext     = $blog->file_extension || '';
    my $archive_file = $obj->archive_file();

    my $blog_path
      = $type eq 'page'
        ? $blog->site_path
          : ( $blog->archive_path || $blog->site_path );
    $archive_file = File::Spec->catfile( $blog_path, $archive_file );
    require File::Basename;
    my ( $orig_file, $path ) = File::Basename::fileparse($archive_file);
    $file_ext = '.' . $file_ext if $file_ext ne '';
    $archive_file
      = File::Spec->catfile( $path, $app->preview_object_basename . $file_ext );

    my $fmgr = $blog->file_mgr;
    return $fmgr->get_data( $archive_file );
}

1;