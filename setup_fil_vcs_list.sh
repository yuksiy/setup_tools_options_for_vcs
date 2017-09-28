#!/bin/sh

# ==============================================================================
#   機能
#     ファイルリストに従ってVCSの操作を実行する
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

SETUP_FIL_VCS_OPTIONS=""

HOST_DIR_SUFFIX=""

# システム環境 依存変数

# プログラム内部変数
PKG_GROUP=""							#初期状態が「空文字」でなければならない変数
FILE_NAME=""							#初期状態が「空文字」でなければならない変数
HOST=""									#初期状態が「空文字」でなければならない変数
SETUP_MANUAL=""							#初期状態が「空文字」でなければならない変数
VERBOSITY="1"
FIL_IMPORT=""							#初期状態が「空文字」でなければならない変数
HOST_DIR="${HOSTNAME}"

CONFIG_FILE="${HOME}/.setup_fil_vcs_list.conf"
# # 変数定義ファイルの読み込み
# if [ -f "${CONFIG_FILE}" ];then
# 	. "${CONFIG_FILE}"
# fi

#DEBUG=TRUE
TMP_DIR="/tmp"
SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}.${PID}"
FILE_LIST_TMP="${SCRIPT_TMP_DIR}/file_list.tmp"

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	# 一時ディレクトリの作成
	mkdir -p "${SCRIPT_TMP_DIR}"
}

POST_PROCESS() {
	# 一時ディレクトリの削除
	if [ ! ${DEBUG} ];then
		rm -fr "${SCRIPT_TMP_DIR}"
	fi
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    setup_fil_vcs_list.sh ACTION [OPTIONS ...] [ARGUMENTS ...]
		
		ACTIONS:
		    copy [OPTIONS ...] FILE_LIST
		       Copy files.
		
		ARGUMENTS:
		    FILE_LIST : Specify a file list.
		
		OPTIONS:
		    --setup_fil_vcs_options="SETUP_FIL_VCS_OPTIONS ..."
		       Specify options which execute setup_fil_vcs.sh command with.
		       See also "setup_fil_vcs.sh --help" for the further information on each
		       option.
		       (Available with: copy)
		    -C CONFIG_FILE
		       Specify a config file.
		       (Available with: copy)
		    -g PKG_GROUP
		       Specify package group field value in FILE_LIST.
		       (Available with: copy)
		    -f FILE_NAME
		       Specify file name field value in FILE_LIST.
		       (Available with: copy)
		    -h HOST
		       Specify host field value in FILE_LIST.
		       (Available with: copy)
		    -s SETUP_MANUAL
		       Specify setup manual field value in FILE_LIST.
		       (Available with: copy)
		    -v {0|1}
		       Specify output verbosity.
		       (Available with: copy)
		    --fil_import=FIL_IMPORT
		       Specify fil_import field value in FILE_LIST.
		       (Available with: copy)
		    --hd=HOST_DIR
		       Specify host directory.
		       (Available with: copy)
		    --hds=HOST_DIR_SUFFIX
		       Specify suffix of host directory.
		       (Available with: copy)
		    --help
		       Display this help and exit.
	EOF
}

. yesno_function.sh

. setup_common_function.sh
. setup_fil_list_function.sh

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
CMD_ARG="`getopt -o C:g:f:h:s:v: -l setup_fil_vcs_options:,fil_import:,hd:,hds:,help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	--setup_fil_vcs_options)	SETUP_FIL_VCS_OPTIONS="$2" ; shift 2;;
	-C)
		CONFIG_FILE="$2" ; shift 2
		# 変数定義ファイルの読み込み
		if [ ! -f "${CONFIG_FILE}" ];then
			echo "-E CONFIG_FILE not a file -- \"${CONFIG_FILE}\"" 1>&2
			USAGE;exit 1
		else
			. "${CONFIG_FILE}"
		fi
		;;
	-g)	PKG_GROUP="$2" ; shift 2;;
	-f)	FILE_NAME="$2" ; shift 2;;
	-h)	HOST="$2" ; shift 2;;
	-s)	SETUP_MANUAL="$2" ; shift 2;;
	-v)
		case "$2" in
		0|1)	VERBOSITY="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE;exit 1
			;;
		esac
		;;
	--fil_import)	FIL_IMPORT="$2" ; shift 2;;
	--hd)	HOST_DIR="$2" ; shift 2;;
	--hds)	HOST_DIR_SUFFIX="$2" ; shift 2;;
	--help)
		USAGE;exit 0
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
		echo "-E Missing FILE_LIST argument" 1>&2
		USAGE;exit 1
	else
		FILE_LIST="$1"
		# ファイルリストのチェック
		if [ ! -f "${FILE_LIST}" ];then
			echo "-E FILE_LIST not a file -- \"${FILE_LIST}\"" 1>&2
			USAGE;exit 1
		fi
	fi
	;;
esac

# 変数定義(引数のチェック後)
case ${ACTION} in
copy)
	VCS="1"
	;;
esac

# 作業開始前処理
PRE_PROCESS

#####################
# メインループ 開始 #
#####################

FILE_LIST_FIELD_SEARCH
FILE_LIST_TMP_MAKE

case ${ACTION} in
copy)
	# 処理継続確認
	file_count=0
	file_names=""
	while read line ; do
		file_name="$(echo "${line}" \
			| awk -F'\t' \
				-v ACTION="${ACTION}" \
				-v FIELD_FILE_NAME="${TMP_FIELD_FILE_NAME}" \
			'{
				if (ACTION == "copy") {
					print $FIELD_FILE_NAME
				}
			}')"
		if [ ! "${file_name}" = "" ];then
			file_count=`expr ${file_count} + 1`
			file_names="${file_names:+${file_names}
}${file_name}"
		fi
	done < "${FILE_LIST_TMP}"
	echo "-I The following ${file_count} files will be MARKED to ${ACTION}:"
	echo "${file_names}" | sed 's#^#     #'
	if [ ${file_count} -gt 0 ];then
		echo "-Q Continue?" 1>&2
		YESNO
		if [ $? -ne 0 ];then
			echo "-I Interrupted."
			# 作業終了後処理
			POST_PROCESS;exit 0
		fi
	else
		# 作業終了後処理
		POST_PROCESS;exit 0
	fi
	;;
esac

case ${ACTION} in
copy)
	awk -F '\t' \
		-v ACTION="${ACTION}" \
		-v SETUP_FIL_VCS_OPTIONS="${SETUP_FIL_VCS_OPTIONS}" \
		-v HOST_DIR="${HOST_DIR}" \
		-v HOST_DIR_SUFFIX="${HOST_DIR_SUFFIX}" \
		-v FIELD_FILE_NAME="${TMP_FIELD_FILE_NAME}" \
	'{
		# フィールド値の取得
		if (ACTION == "copy") {
			split($FIELD_FILE_NAME, files, " +")
		}

		# コマンドラインの構成
		if (ACTION ~/^(copy)$/) {
			cmd_line=sprintf("setup_fil_vcs.sh %s", ACTION)
			if (SETUP_FIL_VCS_OPTIONS !~/^$/) cmd_line=sprintf("%s %s"           ,cmd_line ,SETUP_FIL_VCS_OPTIONS)
			if (HOST_DIR              !~/^$/) cmd_line=sprintf("%s --hd=\"%s\""  ,cmd_line ,HOST_DIR)
			if (HOST_DIR_SUFFIX       !~/^$/) cmd_line=sprintf("%s --hds=\"%s\"" ,cmd_line ,HOST_DIR_SUFFIX)
			for (i in files) {
				cmd_line=sprintf("%s \"%s\"" ,cmd_line ,files[i])
			}
		}

		# コマンドラインの出力・実行
		printf("+ %s\n", cmd_line)
		system(cmd_line)
	}' "${FILE_LIST_TMP}"
	if [ $? -ne 0 ];then
		POST_PROCESS;exit 1
	fi

	# 作業終了後処理
	POST_PROCESS;exit 0
	;;
esac

#####################
# メインループ 終了 #
#####################

