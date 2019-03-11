#!/bin/bash

#
# configs
#
bmdfile=$HOME/.bookmarkdirs
bmdcmd_add=ba
bmdcmd_back=bb
bmdcmd_delete=bd
bmdcmd_edit=be
bmdcmd_help=bh
bmdcmd_move=bm
bmdcmd_print=bp
bmdcmd_remove=
verbose=1
editor=vi


#
# set competition
# "-o default" を加えると、ファイルも補完される
#
shopt -s progcomp
eval "complete -o default -F _bookmarkdirs_completion $bmdcmd_add"
eval "complete            -F _bookmarkdirs_completion $bmdcmd_delete"
eval "complete            -F _bookmarkdirs_completion $bmdcmd_move"


#
# set alias command
#
[ -n "$bmdcmd_add" ]    && eval "alias $bmdcmd_add=_bookmarkdirs_add"
[ -n "$bmdcmd_back" ]   && eval "alias $bmdcmd_back=_bookmarkdirs_back"
[ -n "$bmdcmd_delete" ] && eval "alias $bmdcmd_delete=_bookmarkdirs_delete"
[ -n "$bmdcmd_edit" ]   && eval "alias $bmdcmd_edit=_bookmarkdirs_edit"
[ -n "$bmdcmd_help" ]   && eval "alias $bmdcmd_help=_bookmarkdirs_help"
[ -n "$bmdcmd_move" ]   && eval "alias $bmdcmd_move=_bookmarkdirs_move"
[ -n "$bmdcmd_print" ]  && eval "alias $bmdcmd_print=_bookmarkdirs_print"
[ -n "$bmdcmd_remove" ] && eval "alias $bmdcmd_remove=_bookmarkdirs_remove"


#
# gobla functions
#

# main functions
# add bookmark {{{

_bookmarkdirs_add () {
  # bookmark ファイルの作成
  _bookmarkdirs_create_bmdfile
  # 引数のチェック
  local name=$1 dir=$2
  if [ -z "$name" ]; then
    local i
    local name_list=$(cat $bmdfile | cut -d ' ' -f 1)
    for((i=1;i<10000;i++)); do
      [[ $(echo "$name_list" | grep "^$i$") ]] && continue
      name=$i
      break
    done
  fi
  [ -n "$dir" ] && { dir=$(\cd $dir && pwd) || _bookmarkdirs_kill_process; } \
                || dir=$PWD
  # bookmark の削除
  _bookmarkdirs_delete $name
  # bookmark の追加
  if [ -s $bmdfile ]; then
    sed -i "1i$name $dir" $bmdfile;
  else
    echo "$name $dir" > $bmdfile;
  fi
  _bookmarkdirs_print_msg "Add: $name $dir"
}

#  }}}
# back to a previous directory before moving {{{

_bookmarkdirs_back () {
  if [ -n "$_bookmarkdirs_backtodir" ]; then
    local movetodir=$_bookmarkdirs_backtodir
    export _bookmarkdirs_backtodir=$PWD
    cd $movetodir
  fi
}

#  }}}
# delete bookmark {{{

_bookmarkdirs_delete () {
  _bookmarkdirs_check_bmdfile
  local names=$@
  [ -z "$names" ] && _bookmarkdirs_check_cmdargs
  local name matched number line
  while read name; do
    matched=$(grep -n "^$name " $bmdfile)
    if [ -n "$matched" ]; then
      number=$(echo $matched | cut -d ':' -f 1)
      line=$(echo $matched | sed -e "s/^$number://")
      _bookmarkdirs_print_msg "Del: $line"
      sed -i "${number}d" $bmdfile
    fi
  done < <(echo $names | sed -e 's/ /\n/g')
}

#  }}}
# edit bookmark directory  {{{

_bookmarkdirs_edit () {
  eval $editor $bmdfile
}

#  }}}
# help {{{

_bookmarkdirs_help () {

  local nrs=() msgs=()
  [ -n "$bmdcmd_add" ]    && { nrs+=($((${#bmdcmd_add}+13)));    msgs+=("$(echo $bmdcmd_add    \[name\]    \[dir\] SPACE\| add a bookmark               )"); }
  [ -n "$bmdcmd_back" ]   && { nrs+=(${#bmdcmd_back});           msgs+=("$(echo $bmdcmd_back                       SPACE\| back to a previous directory )"); }
  [ -n "$bmdcmd_delete" ] && { nrs+=($((${#bmdcmd_delete}+10))); msgs+=("$(echo $bmdcmd_delete \<name...\>         SPACE\| delete bookmarks             )"); }
  [ -n "$bmdcmd_edit" ]   && { nrs+=(${#bmdcmd_edit});           msgs+=("$(echo $bmdcmd_edit                       SPACE\| edit bookmarks               )"); }
  [ -n "$bmdcmd_help" ]   && { nrs+=(${#bmdcmd_help});           msgs+=("$(echo $bmdcmd_help                       SPACE\| show this message            )"); }
  [ -n "$bmdcmd_move" ]   && { nrs+=($((${#bmdcmd_move}+7)));    msgs+=("$(echo $bmdcmd_move   \[name\]            SPACE\| move to a directory          )"); }
  [ -n "$bmdcmd_print" ]  && { nrs+=(${#bmdcmd_print});          msgs+=("$(echo $bmdcmd_print                      SPACE\| print bookmarks              )"); }
  [ -n "$bmdcmd_remove" ] && { nrs+=(${#bmdcmd_remove});         msgs+=("$(echo $bmdcmd_remove                     SPACE\| remove the file:$bmdfile     )"); }

  local nr max_nr=0
  for nr in ${nrs[@]}; do
    [ $nr -gt $max_nr ] && max_nr=$nr
  done

  local space i idx=0
  for nr in ${nrs[@]}; do
    space=
    for((i=0;i<$((max_nr-nr));i++)); do
      space+=' '
    done
    echo ${msgs[$idx]} | sed -e "s/SPACE/$space/"
    idx=$((idx+1))
  done

}

#  }}}
# move bookmark directory {{{

_bookmarkdirs_move () {
  _bookmarkdirs_check_bmdfile
  local bmdname=$1
  if [ -z "$bmdname" ]; then
    bmdname=$(head -1 $bmdfile | cut -d ' ' -f 1)
    if [ -z "$bmdname" ]; then
      _bookmarkdirs_print_msg "No bookmarks"
      return 1
    fi
  fi
  local line name dir
  while read line; do
    name=$(echo $line | cut -d ' ' -f 1)
    if [ $name == $bmdname ]; then
      dir=$(echo $line | cut -d ' ' -f 2)
      if [ -d $dir ]; then
        export _bookmarkdirs_backtodir=$PWD
        eval "cd $dir"
      else
        _bookmarkdirs_print_msg "No directory:$line"
      fi
      return 0
    fi
  done < $bmdfile
  _bookmarkdirs_move_error $bmdname
  return 1
}

_bookmarkdirs_move_error () {
  _bookmarkdirs_print_msg "Available names: $(_bookmarkdirs_get_bmdnames)"
}

#  }}}
# print bookmark {{{
_bookmarkdirs_print () {
  _bookmarkdirs_check_bmdfile
  local line name len_name max_len=0 dir dirs_exist
  # bookmark name の最大文字数
  while read line; do
    name="$names $(echo $line | cut -d ' ' -f 1)"
    len_name=$(echo ${#name}) # $name contains newline(\n), so if $name=a, then $len_name=2
    [ $len_name -gt $max_len ] && max_len=$len_name
  done < $bmdfile
  max_len=$((max_len-1))
  # ディレクトリの存在確認と表示
  local dir dir_exist
  while read line; do
    dir="$names $(echo $line | cut -d ' ' -f 2)"
    [ -d $dir ] && dir_exist=o || dir_exist=x
    printf "[%s]  %-$(echo ${max_len})s  %s\n" $(echo $dir_exist $line)
  done < $bmdfile
}
#  }}}
# remove bookmark {{{

_bookmarkdirs_remove () {
  [ -f $bmdfile ] && rm $bmdfile
}

#  }}}
# sub functions
# check the bookmarkdirs file {{{

_bookmarkdirs_check_bmdfile () {
  if [ ! -f $bmdfile ]; then
    _bookmarkdirs_print_msg -n "Bookmark file '$bmdfile' does not exist"
    _bookmarkdirs_kill_process
  fi
}

#  }}}
# complete a word at the first column in the bookmarkdirs {{{

# bookmarkdirs file の１列目の文字列が補完対象になる
_bookmarkdirs_completion () {
  [ -f $bmdfile ] || return 0
  local curword=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=($(compgen -W "$(_bookmarkdirs_get_bmdnames)" -- "$curword"))
  return 0
}

#  }}}
# create the bookmarkdirs file {{{

_bookmarkdirs_create_bmdfile () {
  [ ! -f $bmdfile ] && touch $bmdfile
}

#  }}}
# get bookmarkdirs names {{{

_bookmarkdirs_get_bmdnames () {
  local line
  local names=''
  while read line; do
    names="$names $(echo $line | cut -d ' ' -f 1)"
  done < $bmdfile
  echo $names
}

#_bookmarkdirs_get_bmdnames () {
#  while read line; do
#    echo $line | cut -d ' ' -f 1
#  done < $bmdfile
#}

#  }}}
# kill process {{{

_bookmarkdirs_kill_process () {
  kill -SIGINT $$
}

#  }}}
# print an error message that is caused by the argument of a command {{{

_bookmarkdirs_check_cmdargs () {
  _bookmarkdirs_print_msg -n "Require argument"
  _bookmarkdirs_kill_process
}

#  }}}
# print message {{{

_bookmarkdirs_print_msg  () {
  if [ $verbose -eq 1 ]; then
    if [ "$1" == "-n" ]; then
      echo -n $2
    else
      echo $1
    fi
  fi
}

#  }}}



#
# test
#
#_bookmarkdirs_get_bmdnames
#_bookmarkdirs_add aaa
#_bookmarkdirs_delete aaa bbb ccc
#_bookmarkdirs_print


# vim:fileencoding=utf-8
# vim:foldmethod=marker
