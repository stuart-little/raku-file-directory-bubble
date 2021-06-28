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

