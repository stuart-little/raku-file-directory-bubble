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
