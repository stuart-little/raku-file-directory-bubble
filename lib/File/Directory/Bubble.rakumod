unit module Bubble;

=begin pod
=head1 File::Directory::Bubble

A file-removal tool that

=item optionally bubbles deletion up the directory tree until it hits a non-empty directory;
=item allows for dry runs, only showing you what *would* be deleted.

=head2 Installation

With L<zef|https://github.com/ugexe/zef>:

=item just running C<zef install File::Directory::Bubble> should work once the module has been indexed;
=item or clone this repo and issue C<zef install <path-to-cloned-repo>>;
=item or clone, C<cd> into the repo, and C<zef install .>.

=head2 Usage 

The module provides the executable C<bin/bbrm> for access to (what I believe would be) the most common functionality.

First, you can run C<bbrm --help> for a quick breakdown of the usage. For the examples, I will assume access to the L<tree|https://linux.die.net/man/1/tree> utility in order to visualize the directory structure that C<bbrm> is meant to alter.

Throughout, assume you're in a directory with the following structure:

=begin code
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
=end code

I will run the C<bbrm> command with the C<--dry> option, so it only shows us what it would remove.

=begin code
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
=end code

As expected, that would remove everything under the directories C<./a/b*>. On the other hand, the C<--up> flag would also remove the C<./a> directory, because it would become empty upon removing the other ones:

=begin code
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
=end code

In fact, the same would happen if you were to first remove everything at lower levels: empty-directory deletion would still bubble up.

=begin code
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
=end code

Though again, that only happens with the C<--up> flag. Without it you're only deleting I<down> the directory tree.

=begin code
$ bbrm a/b*/c --dry

Would remove:
<fully-expanded path>/a/b/c
<fully-expanded path>/a/b1/c/d
<fully-expanded path>/a/b1/c
<fully-expanded path>/a/b2/c/d
<fully-expanded path>/a/b2/c
=end code

=end pod

=begin pod
=head2 Other modules in the B<Raku> ecosystem

There's of course L<File::Directory::Tree|https://github.com/labster/p6-file-directory-tree>, but because it L<deletes|https://github.com/labster/p6-file-directory-tree/blob/master/lib/File/Directory/Tree.pm> files/directories recursively using L<unlink|https://docs.raku.org/routine/unlink#(IO::Path)_routine_unlink> and L<rmdir|https://docs.raku.org/type/IO::Path#routine_rmdir>, it's not easy to build a C<--dry> option on top of it:

If you're doing a dry run you're not actually emptying directories, so L<rmdir|https://docs.raku.org/type/IO::Path#routine_rmdir> doesn't know what it I<would> remove if you I<were>..
=end pod

=begin pod
=head2 Module functions 

The library C<lib/File/Directory/Bubble.rakumod> exports a number of functions, some of which are used by the C<bbrm> utility discussed above.

A summary follows.
=end pod

#| List the argument's parents, as far up as possible.
sub listParents(IO::Path $file) is export {
    return ($file, { $_.parent.resolve } ... *.Str eq '.' | '/').[1..*]
}

#| Starting with a file, walk up its parent list until a callback function (of your choosing) returns false. Returns the list of parents for which the callback holds.
sub bbUpWith(IO::Path $file, &cond) is export {
    ([\,] ($file.resolve, |listParents($file))).[1..*].first({ ! $_.&cond }).head(*-1)
}

=begin pod
Starting with the C<$file> you pass in, it builds the increasingly longer lists of ancestors, as in

=item C<$file, parent>
=item C<$file, parent, parent-of-parent>
=item etc.

The predicate C<&cond> is called on these lists, so there's quite a bit of generality built into the kinds of conditions you can check for.

The iteration stops when C<&cond> first returns false, giving you back the last list of parents I<before> that happened.
=end pod

#| Check whether a directory has no children except those in a given list.
sub noChildrenExcept(IO::Path $dir where *.d, $fList) is export {
    ($dir.dir.map({.resolve.Str}) (-) $fList.map({.resolve.Str})).elems == 0;
}

#| A check whether, in a lost of directories, the last one's children consist at most of the next-to-last one plus a list you pass as a second argument.
sub has1childExcept($dirList,$fList) is export {
    noChildrenExcept($dirList.[*-1], [$dirList.[*-2], |$fList]);
}

=begin pod
This is a utility function, for use with C<&bbUpWith> above to produce C<&bbUpEmpty> below.
=end pod

#| Given a file and a list of other files, bubble up the parent list of the former until you hit directories that have other children, apart from the list you passed and the children you've already walked over.
sub bbUpEmpty(IO::Path $file, $fList) is export {
    return bbUpWith($file, &has1childExcept.assuming(*,$fList));
}

=begin pod
This function allows the C<bbrm> script to list what it I<would> remove upon passing the C<--up> flag, even during a C<--dry> run.

You can presumably build your own more complicated examples using the more general callback-driven C<&bbUpWith> above.
=end pod

#| Recurse down a directory, retrieving the files/directories under it.
sub bbDown(IO::Path $file) is export {
    ($file.f || ($file.d && (! $file.dir))) && return [$file.resolve,];
    ($file.d) && return [|$file.dir.map({ |$_.&bbDown }),$file.resolve];    
}

#| Unlink a file or remove an empty directory.
sub smartRm(IO::Path $file) is export {
    $file.f ?? (unlink $file) !! (rmdir $file);
}
