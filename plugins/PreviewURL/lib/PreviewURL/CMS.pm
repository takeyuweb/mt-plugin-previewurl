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

    $app->user($author);
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

sub _create_temp_entry {
    my $app         = shift;
    my $type        = $app->param('_type') || 'entry';
    my $entry_class = $app->model($type);
    my $blog_id     = $app->param('blog_id');
    my $blog        = $app->blog;
    my $id          = $app->param('id');
    my $entry;
    my $user_id = $app->user->id;

    if ($id) {
        $entry = $entry_class->load( { id => $id, blog_id => $blog_id } )
            or return $app->errtrans("Invalid request.");
        $user_id = $entry->author_id;
    }
    else {
        $entry = $entry_class->new;
        $entry->author_id($user_id);
        $entry->id(-1);    # fake out things like MT::Taggable::__load_tags
        $entry->blog_id($blog_id);
    }

    my $names = $entry->column_names;
    my %values = map { $_ => scalar $app->param($_) } @$names;
    delete $values{'id'} unless $app->param('id');
    ## Strip linefeed characters.
    for my $col (qw( text excerpt text_more keywords )) {
        $values{$col} =~ tr/\r//d if $values{$col};
    }
    $values{allow_comments} = 0
        if !defined( $values{allow_comments} )
            || $app->param('allow_comments') eq '';
    $values{allow_pings} = 0
        if !defined( $values{allow_pings} )
            || $app->param('allow_pings') eq '';
    $entry->set_values( \%values );

    return $entry;
}


1;
