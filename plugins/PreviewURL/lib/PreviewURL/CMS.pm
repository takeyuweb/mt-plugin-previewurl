package PreviewURL::CMS;

use strict;
use warnings;

use File::Spec;
use FindBin;
use File::Basename;

sub _view_preview {
    my $app = shift;
    
    my $key = $app->param( 'key' );
    my $blog_id = $app->param( 'blog_id' );
    my $type = $app->param( '_type' ) || 'entry';

    my $blog = MT->model( 'blog' )->load( $blog_id )
      or return $app->errtrans( "Invalid request." );

    my $obj = MT->model( 'entry' )->load(
        {
            previewurl_key => $key,
            blog_id => $blog->id,
            class => $type
        },
        {
            limit => 1
        }) or return $app->errtrans( "Invalid request." );

    my $author = _load_sysadmin();

    $app->param( 'id', $obj->id );
    $obj->authored_on =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/;
    $app->param( 'authored_on_date', sprintf( "%04d:%02d:%02d", $1, $2, $3 ) );
    $app->param( 'authored_on_time', sprintf( "%02d-%02d-%02d", $4, $5, $6 ) );
    my @category_ids = do {
        my %wk;
        grep{ !$wk{$_}++ } ($obj->category ? ($obj->category->id) : (), map{ $_->id } @{$obj->categories})
    };
    $app->param( 'category_ids', join ',', @category_ids );

    $app->param( 'basename', '' );

    $app->user( $author );
    $app->permissions( $author->permissions($blog_id) );
    
    without_preview_in_new_window( $app, sub {
        $app->preview_entry; # プレビューファイル生成
    } );

    $obj = MT->model( $type )->load( $obj->id );
    my $preview_basename = $app->preview_object_basename;
    $obj->basename( $preview_basename );

    my $archive_file = $obj->archive_file();

    require File::Basename;
    my $file_ext;
    my ($orig_file, $path) = File::Basename::fileparse($archive_file);
    my $archive_file_ext = (File::Basename::fileparse($orig_file, qr/\.[^\.]+$/))[2];
    if ($archive_file_ext) {
        $file_ext = $archive_file_ext;
    } else {
        if ( $blog->file_extension ) {
            $file_ext = '.' . $blog->file_extension;
        }
    }
    $archive_file = File::Spec->catfile($path, $preview_basename . $file_ext);
    
    my $blog_url
      = $type eq 'page'
        ? $blog->site_url
          : ( $blog->archive_url || $blog->site_url );
    my $archive_url = $blog_url . $archive_file;

    $app->redirect( $archive_url );
}

sub _load_sysadmin {
    require MT::Author;
    MT->model('author')->load(
        {
            type => MT::Author::AUTHOR()
        },
        {   join => MT::Permission->join_on(
                'author_id',
                {   permissions => "\%'administer'\%",
                    blog_id     => '0',
                },
                { 'like' => { 'permissions' => 1 } }
            ),
            limit => 1
        }
    );
}

sub without_preview_in_new_window {
    my ( $app, $closure ) = @_;
    my $preview_in_new_window = $app->config( 'PreviewInNewWindow' );
    my $retval;
    if ( defined $preview_in_new_window ) {
        $app->config( 'PreviewInNewWindow', 0 );
        eval {
            $retval = $closure->();
        };
        if ( my $errmsg = $@ ) {
            $app->config( 'PreviewInNewWindow', $preview_in_new_window );
            die $errmsg;
        }
        $app->config( 'PreviewInNewWindow', $preview_in_new_window );
    } else {
        $retval = $closure->();
    }
    return $retval;
}

1;
