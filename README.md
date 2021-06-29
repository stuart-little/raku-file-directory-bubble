File::Directory::Bubble
=======================

A file-removal tool that

  * optionally bubbles deletion up the directory tree until it hits a non-empty directory;

  * allows for dry runs, only showing you what *would* be deleted.

Installation
------------

With [zef](https://github.com/ugexe/zef):

  * just running `zef install File::Directory::Bubble` should work once the module has been indexed;

  * or clone this repo and issue `zef install <path-to-cloned-repo>`;

  * or clone, `cd` into the repo, and `zef install .`.

Usage 
------

The module provides the executable `bin/bbrm` for access to (what I believe would be) the most common functionality.

First, you can run `bbrm --help` for a quick breakdown of the usage. For the examples, I will assume access to the [tree](https://linux.die.net/man/1/tree) utility in order to visualize the directory structure that `bbrm` is meant to alter.

Throughout, assume you're in a directory with the following structure:

    $ tree .
    .
    ├── a
    │   ├── b
    │   │   └── c
    │   ├── b1
    │   │   └── c
    │   │       └── d
    │   └── b2
    │       └── c
    │           └── d
    └── foo.txt

    9 directories, 1 file

I will run the `bbrm` command with the `--dry` option, so it only shows us what it would remove.

    $ bbrm a/b* --dry

    Would remove:
    <fully-expanded path>/a/b/c
    <fully-expanded path>/a/b
    <fully-expanded path>/a/b1/c/d
    <fully-expanded path>/a/b1/c
    <fully-expanded path>/a/b1
    <fully-expanded path>/a/b2/c/d
    <fully-expanded path>/a/b2/c
    <fully-expanded path>/a/b2

As expected, that would remove everything under the directories `./a/b*`. On the other hand, the `--up` flag would also remove the `./a` directory, because it would become empty upon removing the other ones:

    $ bbrm a/b* --dry --up

    Would remove:
    <fully-expanded path>/a/b2/c/d
    <fully-expanded path>/a/b2/c
    <fully-expanded path>/a/b2
    <fully-expanded path>/a/b1/c/d
    <fully-expanded path>/a/b1/c
    <fully-expanded path>/a/b1
    <fully-expanded path>/a/b/c
    <fully-expanded path>/a/b
    <fully-expanded path>/a

In fact, the same would happen if you were to first remove everything at lower levels: empty-directory deletion would still bubble up.

    $ bbrm a/b*/c --dry --up

    Would remove:
    <fully-expanded path>/a/b2/c/d
    <fully-expanded path>/a/b2/c
    <fully-expanded path>/a/b2
    <fully-expanded path>/a/b1/c/d
    <fully-expanded path>/a/b1/c
    <fully-expanded path>/a/b1
    <fully-expanded path>/a/b/c
    <fully-expanded path>/a/b
    <fully-expanded path>/a

Though again, that only happens with the `--up` flag. Without it you're only deleting *down* the directory tree.

    $ bbrm a/b*/c --dry

    Would remove:
    <fully-expanded path>/a/b/c
    <fully-expanded path>/a/b1/c/d
    <fully-expanded path>/a/b1/c
    <fully-expanded path>/a/b2/c/d
    <fully-expanded path>/a/b2/c

Other modules in the **Raku** ecosystem
---------------------------------------

There's of course [File::Directory::Tree](https://github.com/labster/p6-file-directory-tree), but because it [deletes](https://github.com/labster/p6-file-directory-tree/blob/master/lib/File/Directory/Tree.pm) files/directories recursively using [unlink](https://docs.raku.org/routine/unlink#(IO::Path)_routine_unlink) and [rmdir](https://docs.raku.org/type/IO::Path#routine_rmdir), it's not easy to build a `--dry` option on top of it:

If you're doing a dry run you're not actually empty-ing directories, so [rmdir](https://docs.raku.org/type/IO::Path#routine_rmdir) doesn't know what it *would* remove if you *were*..

Module functions 
-----------------

The library `lib/File/Directory/Bubble.rakumod` exports a number of functions, some of which are used by the `bbrm` utility discussed above.

A summary follows.

### sub listParents

```raku
sub listParents(
    IO::Path $file
) returns Mu
```

List the argument's parents, as far up as possible.

### sub bbUpWith

```raku
sub bbUpWith(
    IO::Path $file,
    &cond
) returns Mu
```

Starting with a file, walk up its parent list until a callback function (of your choosing) returns false. Returns the list of parents for which the callback holds.

### sub noChildrenExcept

```raku
sub noChildrenExcept(
    IO::Path $dir where { ... },
    $fList
) returns Mu
```

Check whether a directory has no children except those in a given list.

### sub has1childExcept

```raku
sub has1childExcept(
    $dirList,
    $fList
) returns Mu
```

A check whether, in a lost of directories, the last one's children consist at most of the next-to-last one plus a list you pass as a second argument.

This is a utility function, for use with `&bbUpWith` above to produce `&bbUpEmpty` below.

### sub bbUpEmpty

```raku
sub bbUpEmpty(
    IO::Path $file,
    $fList
) returns Mu
```

Given a file and a list of other files, bubble up the parent list of the former until you hit directories that have other children, apart from the list you passed and the children you've already walked over.

This function allows the `bbrm` script to list what it *would* remove upon passing the `--up` flag, even during a `--dry` run.

You can presumably build your own more complicated examples using the more general callback-driven `&bbUpWith` above.

### sub bbDown

```raku
sub bbDown(
    IO::Path $file
) returns Mu
```

Recurse down a directory, retrieving the files/directories under it.

### sub smartRm

```raku
sub smartRm(
    IO::Path $file
) returns Mu
```

Unlink a file or remove an empty directory.

