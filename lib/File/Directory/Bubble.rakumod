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
     
=end pod

sub listParents(IO::Path $file) is export {
    return ($file, { $_.parent.resolve } ... *.Str eq '.' | '/').[1..*]
}

sub bbUpWith(IO::Path $file, &cond) is export {
    ([\,] ($file.resolve, |listParents($file))).[1..*].first({ ! $_.&cond }).head(*-1)
}

sub noChildrenExcept(IO::Path $dir where *.d, $fList) is export {
    ($dir.dir.map({.resolve.Str}) (-) $fList.map({.resolve.Str})).elems == 0;
}

sub has1childExcept($dirList,$fList) is export {
    noChildrenExcept($dirList.[*-1], [$dirList.[*-2], |$fList]);
}

sub bbUpEmpty(IO::Path $file, $fList) is export {
    return bbUpWith($file, &has1childExcept.assuming(*,$fList));
}

sub bbDown(IO::Path $file) is export {
    ($file.f || ($file.d && (! $file.dir))) && return [$file.resolve,];
    ($file.d) && return [|$file.dir.map({ |$_.&bbDown }),$file.resolve];    
}

sub smartRm(IO::Path $file) is export {
    $file.f ?? (unlink $file) !! (rmdir $file);
}
