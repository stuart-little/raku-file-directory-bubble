unit module Bubble;

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
