PreviewURL プラグイン
===========

* Author:: Yuichi Takeuchi <uzuki05@takeyu-web.com>
* Website:: http://takeyu-web.com/
* Copyright:: Copyright 2013 Yuichi Takeuchi
* License:: MIT License

下書き状態のブログ記事及びウェブページのプレビュー用URLを提供します。

![利用イメージ](https://raw.github.com/uzuki05/mt-plugin-previewurl/master/PreviewURL1.png)

* インストールすると、公開状態以外のブログ記事について、プレビュー用URLが提供されます。
  * 記事一覧に「プレビュー」表示項目が追加され、有効にすると公開状態以外の記事タイトルの横にプレビューリンクのが付きます（v1.2～ MT5.1以降）
  * ブログ記事編集画面のパーマリンクの下にプレビュー用URLが表示されます
* プレビュー用URLはMTにログインしなくても利用できます。
* プレビュー用URLは記事を削除するまで有効です。（編集者がログアウト後も利用できます）

「一般公開はできない、社外の人に確認して貰う必要がある。でもID/PASSは渡せない。」こんな時に役立ちます…というかその為に作ったので、せっかくなので公開します。

動作要件
-----------

* MT(MTOS) 5.0 / 5.1 / 5.2 / 6.0 / 6.1
* CGI / PSGI対応

インストール
-----------

plugins/PreviewURL を MT_DIR/plugins/ にコピーして下さい。

設定
-----------

不要。

なお、プレビューURLの組み立てに、mt-config.cgiの CGIPath または AdminCGIPath を使用する為、これらの設定は http: あるいは https: から記述して下さい。

利用方法
-----------

インストールすると、下書き状態の記事の記事編集ページにプレビューURLが表示されるようになりますのでコピーしてご利用下さい。

お約束
-----------

ご利用は自己責任で。
