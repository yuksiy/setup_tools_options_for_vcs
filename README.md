# setup_tools_options_for_vcs

## 概要

システムセットアップツール VCS オプション

本ツールは、[setup_tools](https://github.com/yuksiy/setup_tools)を使用し、かつ
VCSを使用するディレクトリ構造を採用する際に、VCSの操作を支援・効率化します。

想定ディレクトリ構造は以下の通りですが、
[setup_fil_vcs.sh 用の変数定義ファイル](https://github.com/yuksiy/setup_tools_options_for_vcs/tree/master/examples)
を編集することによって、ある程度カスタマイズすることができます。

    ${HOME}/VCS/
      setup/
        旧OS名(例：DebianY.Y)/
          (中略)
        OS名(例：DebianX.X)/
          list/
            file_list_remote.txt (=ファイルリスト)
          files/
            ホスト名.orig/
              any_dir/any_file (=オリジナル設定ファイル)
            ホスト名/
              any_dir/any_file (=設定ファイル)

## 使用方法

### setup_fil_vcs_list.sh

ファイルリスト中のパッケージグループフィールドの値が「apache」であり、
fil_import フィールドの値が「1」であり、
ホストフィールドの値が「1」である設定ファイルを、
VCS管理下の
「旧OS名/files/ホスト名.orig」ディレクトリから
「OS名/files/ホスト名.orig」ディレクトリにコピーします。

    $ cd ${HOME}/VCS/setup
    $ setup_fil_vcs_list.sh copy -C ~/.setup_fil_vcs_list.OS名.conf ./OS名/list/file_list_remote.txt -g apache --fil_import="1" -h ホストフィールド名 --hd=ホスト名 --hds=".orig"

ファイルリスト中のパッケージグループフィールドの値が「apache」であり、
ホストフィールドの値が「1」である設定ファイルを、
VCS管理下の
「旧OS名/files/ホスト名」ディレクトリから
「OS名/files/ホスト名」ディレクトリにコピーします。

    $ setup_fil_vcs_list.sh copy -C ~/.setup_fil_vcs_list.OS名.conf ./OS名/list/file_list_remote.txt -g apache -h ホストフィールド名 --hd=ホスト名

#### ファイルリストの書式

ファイルリストの書式に関しては、以下のファイルを参照してください。

* [README_file_list.md](https://github.com/yuksiy/setup_tools/blob/master/README_file_list.md)

### その他

* 上記で紹介したツール、および本パッケージに含まれるその他のツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Linux
* Cygwin

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* subversion
* [common_sh](https://github.com/yuksiy/common_sh)
* [dos_tools](https://github.com/yuksiy/dos_tools)
* [setup_tools](https://github.com/yuksiy/setup_tools)

## インストール

ソースからインストールする場合:

    (Linux, Cygwin の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

必要に応じて、
[examples/README.md ファイル](https://github.com/yuksiy/setup_tools_options_for_vcs/blob/master/examples/README.md)
を参照して変数定義ファイルをインストールしてください。

## 最新版の入手先

<https://github.com/yuksiy/setup_tools_options_for_vcs>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/setup_tools_options_for_vcs/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2011-2017 Yukio Shiiya
