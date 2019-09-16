#!/bin/bash

_bookmarkdirs_configs () {
declare -A bmd

#
# configs (begin)
# bCC : dangerous command
#
bmd[bmdfile]=$HOME/.bookmarkdirs; [[ -L ${bmd[bmdfile]} ]] && bmd[bmdfile]=$(readlink ${bmd[bmdfile]})
bmd[cmd_add]=ba
bmd[cmd_back]=bb
bmd[cmd_copy]=bCC
bmd[cmd_delete]=bd
bmd[cmd_edit]=be
bmd[cmd_help]=bh
bmd[cmd_move]=bm
bmd[cmd_print]=bp
bmd[cmd_remove]=
bmd[cmd_save]=bs
bmd[editor]=vi
bmd[verbose]=1
#
# configs (end)
#

declare -p bmd
}


#
# init
#
# create alias command {{{
_bookmarkdirs_alias () {

  eval $(_bookmarkdirs_configs)

  #
  # set competition
  # complete file names with option "-o default"
  #
  shopt -s progcomp
  eval "complete -o default -F _bookmarkdirs_completion ${bmd[cmd_add]}"
  eval "complete            -F _bookmarkdirs_completion ${bmd[cmd_delete]}"
  eval "complete            -F _bookmarkdirs_completion ${bmd[cmd_move]}"

  #
  # set alias command
  #
  [ -n "${bmd[cmd_add]}" ]    && eval "alias ${bmd[cmd_add]}=_bookmarkdirs_add"
  [ -n "${bmd[cmd_back]}" ]   && eval "alias ${bmd[cmd_back]}=_bookmarkdirs_back"
  [ -n "${bmd[cmd_copy]}" ]   && eval "alias ${bmd[cmd_copy]}=_bookmarkdirs_copy"
  [ -n "${bmd[cmd_delete]}" ] && eval "alias ${bmd[cmd_delete]}=_bookmarkdirs_delete"
  [ -n "${bmd[cmd_edit]}" ]   && eval "alias ${bmd[cmd_edit]}=_bookmarkdirs_edit"
  [ -n "${bmd[cmd_help]}" ]   && eval "alias ${bmd[cmd_help]}=_bookmarkdirs_help"
  [ -n "${bmd[cmd_move]}" ]   && eval "alias ${bmd[cmd_move]}=_bookmarkdirs_move"
  [ -n "${bmd[cmd_print]}" ]  && eval "alias ${bmd[cmd_print]}=_bookmarkdirs_print"
  [ -n "${bmd[cmd_remove]}" ] && eval "alias ${bmd[cmd_remove]}=_bookmarkdirs_remove"
  [ -n "${bmd[cmd_save]}" ]   && eval "alias ${bmd[cmd_save]}=_bookmarkdirs_save"

}
#  }}}
# complete a word at the first column in the bookmarkdirs {{{

# the bookmark name will be completed
# the name corresponds to the first column in .bookmarkdirs
_bookmarkdirs_completion () {
  [ -f ${bmd[bmdfile]} ] || return 0
  local curword=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=($(compgen -W "$(_bookmarkdirs_get_bmdnames)" -- "$curword"))
  return 0
}

#  }}}
# get bookmarkdirs names {{{

_bookmarkdirs_get_bmdnames () {
  eval $(_bookmarkdirs_configs)
  local line path names=''
  while read name path; do
    echo $name
  done < ${bmd[bmdfile]}
}

#  }}}
_bookmarkdirs_alias


#
# main functions
#
# add bookmark {{{

_bookmarkdirs_add () {
  eval $(_bookmarkdirs_configs)
  _bookmarkdirs_create_bmdfile
  local name=$1 path=$2
  if [ -z "$name" ]; then
    # determine a bookmark name consisting of numbers
    local path nrs=''
    while read name path; do
      [[ $name =~ [0-9]+ ]] || continue
      nrs=$nrs' '$name
    done < ${bmd[bmdfile]}
    nrs=$nrs' '
    local i
    for((i=1; i<10000; i++)); do
      [[ $nrs =~ " $i " ]] && continue
      name=$i
      break
    done
  fi
  [ -n "$path" ] \
    && { path=$(\cd $path && pwd) || _bookmarkdirs_kill_process; } \
    || path=$PWD
  # delete a bookmark name
  _bookmarkdirs_delete $name
  # add a bookmark name
  if [ -s ${bmd[bmdfile]} ]; then
    # FIXME: format
    sed -i "1i$name $path" ${bmd[bmdfile]}
  else
    echo "$name $path" > ${bmd[bmdfile]}
  fi
  _bookmarkdirs_print_msg "Add: $name $path"
}

#  }}}
# back to a previous directory before moving {{{

_bookmarkdirs_back () {
  if [ -n "$_bookmarkdirs_backtodir" ]; then
    local savedir=$_bookmarkdirs_backtodir
    if [ $PWD != "$savedir" ]; then
      _bookmarkdirs_backtodir=$PWD
      cd $savedir
    fi
  fi
}

#  }}}
# copy savelist to current directory (dangerous command) {{{

_bookmarkdirs_copy () {
  eval $(_bookmarkdirs_configs)
  if [[ -z $_bookmarkdirs_savelist ]]; then
    _bookmarkdirs_print_msg "No saved list"
    return 1
  fi
  local saved_targetdir=$(echo $_bookmarkdirs_savelist | cut -f 1 -d '|')
  local saved_list=$(echo $_bookmarkdirs_savelist | cut -f 2 -d '|')
  local file_or_dir target
  for file_or_dir in $saved_list; do
    target=$saved_targetdir/$file_or_dir
    if [ ! -e $target ]; then
      echo No file or directory: $target
      continue
    elif [ -e $file_or_dir ]; then
      echo Not copy: $target
      continue
    else
       echo cp -r $target .
            cp -r $target .
    fi
#    echo cp -ir $target .
#         cp -ir $target .
  done
}

#  }}}
# delete bookmark {{{

_bookmarkdirs_delete () {
  eval $(_bookmarkdirs_configs)
  _bookmarkdirs_check_bmdfile
  [[ -z $@ ]] \
    && local names=$(read name path <<< $(head -1 ${bmd[bmdfile]}) && echo $name) \
    || local names=$@
  [ -z "$names" ] && _bookmarkdirs_check_cmdargs
  local name matched number line
  while read name; do
    matched=$(grep -n "^$name " ${bmd[bmdfile]})
    if [ -n "$matched" ]; then
      number=$(echo $matched | cut -d ':' -f 1)
      line=$(echo $matched | sed -e "s/^$number://")
      _bookmarkdirs_print_msg "Del: $line"
      sed -i "${number}d" ${bmd[bmdfile]}
    fi
  done < <(echo $names | sed -e 's/ /\n/g')
}

#  }}}
# edit bookmark directory  {{{

_bookmarkdirs_edit () {
  eval $(_bookmarkdirs_configs)
  eval ${bmd[editor]} ${bmd[bmdfile]}
}

#  }}}
# help {{{

_bookmarkdirs_help () {

  eval $(_bookmarkdirs_configs)

  local nrs=() msgs=()
  [ -n "${bmd[cmd_add]}" ]    && { nrs+=($((${#bmd[cmd_add]}+13)));    msgs+=("$(echo ${bmd[cmd_add]}    \[name\]  \[dir\] SPACE\| Add a bookmark                  )"); }
  [ -n "${bmd[cmd_back]}" ]   && { nrs+=(${#bmd[cmd_back]});           msgs+=("$(echo ${bmd[cmd_back]}                     SPACE\| Back to a previous directory    )"); }
  [ -n "${bmd[cmd_copy]}" ]   && { nrs+=(${#bmd[cmd_copy]});           msgs+=("$(echo ${bmd[cmd_copy]}                     SPACE\| Copy to current directory       )"); }
  [ -n "${bmd[cmd_delete]}" ] && { nrs+=($((${#bmd[cmd_delete]}+10))); msgs+=("$(echo ${bmd[cmd_delete]} \<name...\>       SPACE\| Delete bookmarks                )"); }
  [ -n "${bmd[cmd_edit]}" ]   && { nrs+=(${#bmd[cmd_edit]});           msgs+=("$(echo ${bmd[cmd_edit]}                     SPACE\| Edit bookmarks                  )"); }
  [ -n "${bmd[cmd_help]}" ]   && { nrs+=(${#bmd[cmd_help]});           msgs+=("$(echo ${bmd[cmd_help]}                     SPACE\| Show this message               )"); }
  [ -n "${bmd[cmd_move]}" ]   && { nrs+=($((${#bmd[cmd_move]}+7)));    msgs+=("$(echo ${bmd[cmd_move]}   \[name\]          SPACE\| Move to a directory             )"); }
  [ -n "${bmd[cmd_print]}" ]  && { nrs+=(${#bmd[cmd_print]});          msgs+=("$(echo ${bmd[cmd_print]}                    SPACE\| Print bookmarks                 )"); }
  [ -n "${bmd[cmd_remove]}" ] && { nrs+=(${#bmd[cmd_remove]});         msgs+=("$(echo ${bmd[cmd_remove]}                   SPACE\| Remove the file:${bmd[bmdfile]} )"); }
  [ -n "${bmd[cmd_save]}" ]   && { nrs+=($((${#bmd[cmd_save]}+10)));   msgs+=("$(echo ${bmd[cmd_save]}   \<name...\>       SPACE\| Save files and directories      )"); }

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
  eval $(_bookmarkdirs_configs)
  _bookmarkdirs_check_bmdfile
  local bmdname=$1
  if [ -z "$bmdname" ]; then
    bmdname=$(read name path <<< $(head -1 ${bmd[bmdfile]}) && echo $name)
    if [ -z "$bmdname" ]; then
      _bookmarkdirs_print_msg "Empty bookmark name"
      return 1
    fi
  fi
  local name path
  while read name path; do
    if [ $name == $bmdname ]; then
      if [ -d $path ]; then
        if [ $PWD != $path ]; then
          _bookmarkdirs_backtodir=$PWD
          cd $path
        fi
      else
        _bookmarkdirs_print_msg "Directory does not exist: $path ($name)"
      fi
      return 0
    fi
  done < ${bmd[bmdfile]}
  _bookmarkdirs_print_msg "Available bookmark names: $(_bookmarkdirs_get_bmdnames)"
  return 1
}

#  }}}
# print bookmark {{{
_bookmarkdirs_print () {
  eval $(_bookmarkdirs_configs)
  _bookmarkdirs_check_bmdfile
  local name path maxlen_name=0
  while read name path; do
    [ ${#name} -gt $maxlen_name ] && maxlen_name=${#name}
  done < ${bmd[bmdfile]}
  local path_exist
  while read name path; do
    [ -d $path ] && path_exist=o || path_exist=x
    printf "[%s]  %-${maxlen_name}s  %s\n" $path_exist $name $path
  done < ${bmd[bmdfile]}
}
#  }}}
# remove bookmark {{{

_bookmarkdirs_remove () {
  eval $(_bookmarkdirs_configs)
  [ -f ${bmd[bmdfile]} ] && rm ${bmd[bmdfile]}
}

#  }}}
# save multiple files and directories {{{

_bookmarkdirs_save () {
  eval $(_bookmarkdirs_configs)
  [ $# -eq 0 ] && _bookmarkdirs_check_cmdargs
  for arg; do
    [ -e $arg ] && { local file_or_dir_exists=1; break; }
  done
  if [ -z "$file_or_dir_exists" ]; then
    _bookmarkdirs_print_msg "$@: No files and directories to save"
    return 1
  fi
  if [[ $PWD =~ '|' ]]; then
    _bookmarkdirs_print_msg "Cannot make a save list because a bar(|) is included in current path"
    return 1
  fi
  _bookmarkdirs_savelist="$PWD|$@"
  echo Save: $_bookmarkdirs_savelist
}

#  }}}
#
# sub functions
#
# check the bookmarkdirs file {{{

_bookmarkdirs_check_bmdfile () {
  if [ ! -f ${bmd[bmdfile]} ]; then
    _bookmarkdirs_print_msg -n "Bookmark file '${bmd[bmdfile]}' does not exist"
    _bookmarkdirs_kill_process
  fi
}

#  }}}
# create the bookmarkdirs file {{{

_bookmarkdirs_create_bmdfile () {
  [ ! -f ${bmd[bmdfile]} ] && touch ${bmd[bmdfile]}
}

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
  if [ ${bmd[verbose]} -eq 1 ]; then
    if [ "$1" == "-n" ]; then
      shift
      echo -n $@
    else
      echo $@
    fi
  fi
}

#  }}}



# vim:foldmethod=marker
