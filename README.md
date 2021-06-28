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

Module functions 
-----------------

### sub listParents

```raku
sub listParents(
    IO::Path $file
) returns Mu
```

List the argument's parents, as far up as possible

### sub smartRm

```raku
sub smartRm(
    IO::Path $file
) returns Mu
```

Unlink a file or remove an empty directory

