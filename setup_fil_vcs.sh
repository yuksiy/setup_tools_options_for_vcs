#!/bin/sh

# ==============================================================================
#   機能
#     VCSの操作を実行する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2011-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
trap "" 28				# TRAP SET
trap "POST_PROCESS;exit 1" 1 2 15	# TRAP SET

SCRIPT_NAME="`basename $0`"
PID=$$

######################################################################
# 変数定義
######################################################################
# ユーザ変数
HOSTNAME=`hostname`

SVN_OPTIONS=""

HOST_DIR_PARENT_PREV="${HOME}/files.prev"
HOST_DIR_PARENT="${HOME}/files"
HOST_DIR_SUFFIX=""

# システム環境 依存変数

# プログラム内部変数
HOST_DIR="${HOSTNAME}"
COPY_SRC_FILE=""						#初期状態が「空文字」でなければならない変数
VERBOSITY="1"
OVERWRITE_PROMPT="ask"
PAUSE_PER_DEST_FILE="no"
PAUSE_AT_LOOP_LAST="no"

CONFIG_FILE="${HOME}/.setup_fil_vcs.conf"
# # 変数定義ファイルの読み込み
# if [ -f "${CONFIG_FILE}" ];then
# 	. "${CONFIG_FILE}"
# fi

#DEBUG=TRUE

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	:
}

POST_PROCESS() {
	:
}

USAGE() {
	if [ "$1" = "" ];then
		cat <<- EOF 1>&2
			Usage:
			    setup_fil_vcs.sh copy [OPTIONS ...] [ARGUMENTS ...]
		EOF
	elif [ "$1" = "copy" ];then
		cat <<- EOF 1>&2
			Usage:
			    setup_fil_vcs.sh copy [OPTIONS ...] DEST_FILE...
			
			ARGUMENTS:
			    DEST_FILE : Specify destination file(full-path).
			
			OPTIONS:
			    --svn-options="SVN_OPTIONS ..."
			       Specify options which execute "svn copy" command with.
			       See also "svn help copy" for the further information on each option.
			    --hdpp=HOST_DIR_PARENT_PREV
			       Specify previous parent directory of host directory.
			    --hdp=HOST_DIR_PARENT
			       Specify parent directory of host directory.
			    --hd=HOST_DIR
			       Specify host directory.
			    --hds=HOST_DIR_SUFFIX
			       Specify suffix of host directory.
			    -C CONFIG_FILE
			       Specify a config file.
			    -s COPY_SRC_FILE
			       Specify copy source file(full-path) if it differs from the destination
			       file.
			    -v {0|1}
			       Specify output verbosity.
			    --overwrite-prompt={ask|yes|no}
			    --pause-per-dest-file={yes|no}
			    --pause-at-loop-last={yes|no}
			    --help
			       Display this help and exit.
		EOF
	fi
}

. yesno_function.sh

. setup_common_function.sh

# 変数定義
VAR_INIT() {
	dir=`dirname "${arg}"`
	file=`basename "${arg}"`
	case ${ACTION} in
	copy)
		if [ "${COPY_SRC_FILE}" = "" ];then
			src_file="${HOST_DIR_PARENT_PREV}/${HOST_DIR}${HOST_DIR_SUFFIX}${dir}/${file}"
		else
			src_file="${COPY_SRC_FILE}"
		fi
		dest_file="${HOST_DIR_PARENT}/${HOST_DIR}${HOST_DIR_SUFFIX}${dir}/${file}"
		;;
	esac
}

# コピー元ファイルの存在チェック
SRC_FILE_EXIST_CHECK() {
	cmd_line="test -f '${src_file}'"
	case ${ACTION} in
	copy)
		CMD "${cmd_line}"
		if [ $? -ne 0 ];then
			echo "-W \"${src_file}\" file not exist, or not a file, skipped" 1>&2
			# 宛先ファイル毎に一時停止
			PAUSE_PER_DEST_FILE
			return 1
		fi
		;;
	esac
}

# コピー元ファイルのファイル情報取得
SRC_FILE_INFO_GET() {
	cmd_line="ls -ald '${src_file}'"
	case ${ACTION} in
	copy)
		src_file_ll="$(CMD "${cmd_line}")"
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# コピー先ファイルの存在チェック
DEST_FILE_EXIST_CHECK() {
	cmd_line="test -f '${dest_file}'"
	case ${ACTION} in
	copy)
		CMD "${cmd_line}"
		;;
	esac
}

# コピー先ファイルのファイル情報取得 (コピー前)
DEST_FILE_INFO_GET_BEFORE() {
	cmd_line="ls -ald '${dest_file}'"
	case ${ACTION} in
	copy)
		dest_file_ll="$(CMD "${cmd_line}")"
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# コピー先ファイルの上書き確認
DEST_FILE_OVERWRITE_PROMPT() {
	echo "-I Following file exist in the ${ACTION} destination directory"
	echo "Dest: ${dest_file_ll}"
	echo "Src : ${src_file_ll}"
	case ${OVERWRITE_PROMPT} in
	ask)
		echo "-Q Overwrite?" 1>&2
		YESNO
		OVERWRITE_PROMPT_RC=$?
		;;
	yes)	OVERWRITE_PROMPT_RC=0;;
	no)	OVERWRITE_PROMPT_RC=1;;
	esac
	if [ ${OVERWRITE_PROMPT_RC} -ne 0 ];then
		echo "-I Skipping..."
		# 宛先ファイル毎に一時停止
		PAUSE_PER_DEST_FILE
		return 1
	else
		echo "-I Overwriting..."
	fi
}

# コピー元ファイルをコピー先ファイルにコピー
SRC_FILE_COPY_TO_DEST_FILE() {
	cmd_line="svn copy ${SVN_OPTIONS} '${src_file}' '${dest_file}'"
	case ${ACTION} in
	copy)
		CMD_V "${cmd_line}"
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# コピー先ファイルのファイル情報取得 (コピー後)
DEST_FILE_INFO_GET_AFTER() {
	cmd_line="ls -ald '${dest_file}'"
	case ${ACTION} in
	copy)
		dest_file_ll="$(CMD "${cmd_line}")"
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# コピー先ファイルのファイル情報表示
DEST_FILE_INFO_SHOW() {
	echo "-I Following file is copied"
	echo "${dest_file_ll}"
}

# 宛先ファイル毎に一時停止
PAUSE_PER_DEST_FILE() {
	if [ "${PAUSE_PER_DEST_FILE}" = "yes" ];then
		pause.sh
	fi
}

# ループの最後で一時停止
PAUSE_AT_LOOP_LAST() {
	if [ "${PAUSE_AT_LOOP_LAST}" = "yes" ];then
		pause.sh
	fi
}

######################################################################
# メインルーチン
######################################################################

# ACTIONのチェック
if [ "$1" = "" ];then
	echo "-E Missing ACTION" 1>&2
	USAGE;exit 1
else
	case "$1" in
	copy)
		ACTION="$1"
		;;
	*)
		echo "-E Invalid ACTION -- \"$1\"" 1>&2
		USAGE;exit 1
		;;
	esac
fi

# ACTIONをシフト
shift 1

# オプションのチェック
CMD_ARG="`getopt -o C:s:v: -l svn-options:,hdpp:,hdp:,hd:,hds:,overwrite-prompt:,pause-per-dest-file:,pause-at-loop-last:,help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE ${ACTION};exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	--svn-options)	SVN_OPTIONS="$2" ; shift 2;;
	--hdpp)	HOST_DIR_PARENT_PREV="$2" ; shift 2;;
	--hdp)	HOST_DIR_PARENT="$2" ; shift 2;;
	--hd)	HOST_DIR="$2" ; shift 2;;
	--hds)	HOST_DIR_SUFFIX="$2" ; shift 2;;
	-C)
		CONFIG_FILE="$2" ; shift 2
		# 変数定義ファイルの読み込み
		if [ ! -f "${CONFIG_FILE}" ];then
			echo "-E CONFIG_FILE not a file -- \"${CONFIG_FILE}\"" 1>&2
			USAGE ${ACTION};exit 1
		else
			. "${CONFIG_FILE}"
		fi
		;;
	-s)	COPY_SRC_FILE="$2" ; shift 2;;
	-v)
		case "$2" in
		0|1)	VERBOSITY="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--overwrite-prompt)
		case "$2" in
		ask|yes|no)	OVERWRITE_PROMPT="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--pause-per-dest-file|--pause-at-loop-last)
		case "$2" in
		yes|no)
			case "${opt}" in
			--pause-per-dest-file)	PAUSE_PER_DEST_FILE="$2" ; shift 2;;
			--pause-at-loop-last)	PAUSE_AT_LOOP_LAST="$2" ; shift 2;;
			esac
			;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--help)
		USAGE ${ACTION};exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 引数のチェック
case ${ACTION} in
copy)
	# 第1引数のチェック
	if [ "$1" = "" ];then
		echo "-E Missing DEST_FILE argument" 1>&2
		USAGE ${ACTION};exit 1
	fi
	;;
esac

# 作業開始前処理
PRE_PROCESS

#####################
# メインループ 開始 #
#####################
case ${ACTION} in
copy)
	for arg in "$@" ; do
		# 画面に改行を出力
		echo

		VAR_INIT

		SRC_FILE_EXIST_CHECK || continue
		SRC_FILE_INFO_GET

		DEST_FILE_EXIST_CHECK
		if [ $? -eq 0 ];then
			DEST_FILE_INFO_GET_BEFORE
			DEST_FILE_OVERWRITE_PROMPT || continue
		fi
		SRC_FILE_COPY_TO_DEST_FILE
		DEST_FILE_INFO_GET_AFTER
		DEST_FILE_INFO_SHOW

		# 宛先ファイル毎に一時停止
		PAUSE_PER_DEST_FILE
	done
	;;
esac
# ループの最後で一時停止
PAUSE_AT_LOOP_LAST
#####################
# メインループ 終了 #
#####################

# 作業終了後処理
POST_PROCESS;exit 0

