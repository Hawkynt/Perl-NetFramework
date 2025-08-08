package System::IO::File; {

  use strict;
  use warnings;

  use CSharp;
  use System::Exceptions;

  sub ReadAllLines($) {
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::FileNotFoundException->new($path)) unless(-e $path && -f $path);
    throw(System::IOException->new($!)) unless(open my $fileHandle,"<",$path);
    my @result=<$fileHandle>;
    chomp(@result);
    throw(System::IOException->new($!)) unless(close($fileHandle));
    require System::Array;
    require System::String;
    return(new System::Array(map {System::String->new($_)} @result));
  }

  sub ReadAllText($) {
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::FileNotFoundException->new($path)) unless(-e $path && -f $path);
    throw(System::IOException->new($!)) unless(open my $fileHandle,"<",$path);
    my @result=<$fileHandle>;
    throw(System::IOException->new($!)) unless(close($fileHandle));
    require System::String;
    return(System::String->new(join("",@result)));
  }

  sub ReadAllBytes($) {
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::FileNotFoundException->new($path)) unless(-e $path && -f $path);
    throw(System::IOException->new($!)) unless(open my $fileHandle,"<",$path);
    binmode($fileHandle);
    my $data;
    read($fileHandle,$data,-s $path);
    my @result=map {ord($_)} split //,$data;
    throw(System::IOException->new($!)) unless(close($fileHandle));
    require System::Array;
    return(new System::Array(@result));
  }

  sub WriteAllLines($$) {
    my($path,$content)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::IOException->new($!)) unless(open my $fileHandle,">",$path);
    throw(System::IOException->new($!)) unless(flock($fileHandle,2));
    print $fileHandle join("\n",@{$content})."\n";
    throw(System::IOException->new($!)) unless(close($fileHandle));
  }

  sub WriteAllText($$) {
    my($path,$content)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::IOException->new($!)) unless(open my $fileHandle,">",$path);
    throw(System::IOException->new($!)) unless(flock($fileHandle,2));
    print $fileHandle $content;
    throw(System::IOException->new($!)) unless(close($fileHandle));
  }

  sub WriteAllBytes($$) {
    my($path,$content)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::IOException->new($!)) unless(open my $fileHandle,">",$path);
    throw(System::IOException->new($!)) unless(flock($fileHandle,2));
    binmode($fileHandle);
    print $fileHandle join('',map{chr($_)} @{$content});
    throw(System::IOException->new($!)) unless(close($fileHandle));
  }

  sub AppendAllLines($$) {
    my($path,$content)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::IOException->new($!)) unless(open my $fileHandle,">>",$path);
    throw(System::IOException->new($!)) unless(flock($fileHandle,2));
    print $fileHandle join("\n",@{$content})."\n";
    throw(System::IOException->new($!)) unless(close($fileHandle));
  }

  sub AppendAllText($$) {
    my($path,$content)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::IOException->new($!)) unless(open my $fileHandle,">>",$path);
    throw(System::IOException->new($!)) unless(flock($fileHandle,2));
    print $fileHandle $content;
    throw(System::IOException->new($!)) unless(close($fileHandle));
  }

  sub Exists($) {
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    return(-e $path && -f $path);
  }

  sub Delete($){
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::FileNotFoundException->new($path)) unless(-e $path && -f $path);
    unlink $path;
  }

  sub Copy($$){
    my($source,$target)=@_;
    throw(System::ArgumentNullException->new('source')) unless(defined($source));
    throw(System::FileNotFoundException->new($source)) unless(-e $source && -f $source);
    throw(System::ArgumentNullException->new('target')) unless(defined($target));
    use File::Copy;
    File::Copy::copy($source,$target);
  }

  sub Move($$){
    my($source,$target)=@_;
    throw(System::ArgumentNullException->new('source')) unless(defined($source));
    throw(System::FileNotFoundException->new($source)) unless(-e $source && -f $source);
    throw(System::ArgumentNullException->new('target')) unless(defined($target));
    use File::Copy;
    File::Copy::move($source,$target);
  }

  # Add methods missing in test
  sub GetSize($) {
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::FileNotFoundException->new($path)) unless(-e $path && -f $path);
    return(-s $path);
  }

  sub GetLastWriteTime($) {
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::FileNotFoundException->new($path)) unless(-e $path && -f $path);
    my $mtime = (stat($path))[9];
    require System::DateTime;
    return System::DateTime->FromUnixTime($mtime);
  }

  sub GetCreationTime($) {
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::FileNotFoundException->new($path)) unless(-e $path && -f $path);
    my $ctime = (stat($path))[10];
    require System::DateTime;
    return System::DateTime->FromUnixTime($ctime);
  }

  sub GetLastAccessTime($) {
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::FileNotFoundException->new($path)) unless(-e $path && -f $path);
    my $atime = (stat($path))[8];
    require System::DateTime;
    return System::DateTime->FromUnixTime($atime);
  }

  sub GetAttributes($) {
    my($path)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::FileNotFoundException->new($path)) unless(-e $path && -f $path);
    
    # Return basic file attributes as a bitmask (simplified)
    my $attrs = 0;
    $attrs |= 1 if(-r $path);    # ReadOnly equivalent 
    $attrs |= 2 if(-d $path);    # Directory
    $attrs |= 4 if(-l $path);    # ReparsePoint (symlink)
    return $attrs;
  }

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

1;