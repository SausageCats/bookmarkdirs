# bookmarkdirs

This **bookmarkdirs** script enables you to simply bookmark directories and move to them.
You can also easily delete and print a content in bookmark list.

## Installation

Copy `bookmarkdirs.sh` file from this repository and run the source command from the command line:

``` bash
source bookmarkdirs.sh
```

## Usage

After installation, you can use the several commands.
For example,

1. Enter `ba` to add a current directory to a bookmark file (`$HOME/.bookmarkdirs`) with a bookmark name (1).
1. Enter `bm 1` to move the directory with the bookmark name 1.
1. Enter `bd 1` to delete the directory name from the bookmark file.

Note that the bookmark name can be changed with the option of the `ba` command.


## Available commands

The following commands are available.
You can change the default command names to something more meaningful.
The command names are defined in the `configs` of the source file.
The **`Tab`** key allows you to autocomplete bookmark names \[name\] and directory path \[dir\] of the command options.

Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|Description
:--|:--
ba [name] [dir]  | Add a current directory or specified directory by the argument [dir] to a bookmark file with a bookmark name, which is automatically assigned when the argument [name] is omitted. The bookmark file is created at `$HOME/.bookmarkdirs` as default.
bb               | Back to the previous directory.
bd \<name...\>   | Delete the bookmark names. Multiple names are accepted.
be               | Edit the bookmark file.
bh               | Show the help message.
bm \[name\]      | Move to the specified directory. When the \[name\] is omitted, the last directory you added will be moved.
bp               | Print bookmarks.

## Get started

This is an example to deepen your understanding.

``` bash
# make directories
$ cd
$ mkdir -p hoge/fuga
$ cd hoge/fuga


# add bookmarks
$ ba fuga    # Add: fuga $HOME/hoge/fuga
$ ba hoge .. # Add: hoge $HOME/hoge
$ ba         # Add: 1 $HOME/hoge/fuga
$ ba         # Add: 2 $HOME/hoge/fuga


# print the bookmark list
# The mark [o] indicates the existing directory
$ bp         # [o]  2     $HOME/hoge/fuga
             # [o]  1     $HOME/hoge/fuga
             # [o]  hoge  $HOME/hoge
             # [o]  fuga  $HOME/hoge/fuga


# move to the bookmark directory
$ pwd        # $HOME/hoge/fuga
$ bm hoge    # press the Tab key to autocomplete the name after pressing 'h' of 'hoge'
$ pwd        # $HOME/hoge
$ bm         # move to the last added directory (bookmark name 2)
$ pwd        # $HOME/hoge/fuga


# back to the previous directory
$ bb
$ pwd        # $HOME/hoge
$ bb
$ pwd        # $HOME/hoge/fuga
$ bb
$ pwd        # $HOME/hoge


# delete the bookmarks
$ bd fuga    # Del: fuga $HOME/hoge/fuga
$ bd 1 2     # Del: 1 $HOME/hoge/fuga
             # Del: 2 $HOME/hoge/fuga


# print the bookmark list
$ bp         # [o]  hoge  $HOME/hoge


# edit the bookmark file using vi (default)
$ be
# type ":q<Enter>" to close the editor
```
