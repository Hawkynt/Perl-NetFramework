package System::IO::Directory; {
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  use System::String;
  use System::Exceptions;
  use Symbol;
  use System::IO::Path;

  use constant {
    TopDirectoryOnly=>0,
    AllDirectories=>1,
  };

  use constant DEBUG=>false;
    
  # TODO: all the filesysteminfo stuff from .NET

  ### <summary>
  ### Gets all sub-directories in a given directory.
  ### </summary>
  ### <param name="path">The path</param>
  ### <param name="searchPattern">The file name pattern</param>
  ### <param name="searchOption">A value indicating whether to use recursive search or not.</param>
  ### <returns>An array of strings</returns>
  sub GetDirectories($;$$) {
    my($path,$searchPattern,$searchOption)=@_;
    return(_GetFileSystemObjectsRaw($path,$searchPattern,$searchOption,sub{-d$_[0]}));
  }

  ### <summary>
  ### Gets all files in a given directory.
  ### </summary>
  ### <param name="path">The path</param>
  ### <param name="searchPattern">The file name pattern</param>
  ### <param name="searchOption">A value indicating whether to use recursive search or not.</param>
  ### <returns>An array of strings</returns>
  sub GetFiles($;$$) {
    my($path,$searchPattern,$searchOption)=@_;
    return(_GetFileSystemObjectsRaw($path,$searchPattern,$searchOption,sub{-f$_[0]}));
  }

  ### <summary>
  ### Gets all items in a given directory.
  ### </summary>
  ### <param name="path">The path</param>
  ### <param name="searchPattern">The file name pattern</param>
  ### <param name="searchOption">A value indicating whether to use recursive search or not.</param>
  ### <returns>An array of strings</returns>
  sub GetFileSystemEntries($;$$){
    my($path,$searchPattern,$searchOption)=@_;
    return(_GetFileSystemObjectsRaw($path,$searchPattern,$searchOption,sub{1}));
  }

  ### <summary>
  ### Gets all items in a given directory matching a given predicate.
  ### </summary>
  ### <param name="path">The path</param>
  ### <param name="searchPattern">The file name pattern</param>
  ### <param name="searchOption">A value indicating whether to use recursive search or not.</param>
  ### <param name="predicate">The predicate to match</param>
  ### <returns>An array of strings</returns>
  sub _GetFileSystemObjectsRaw($$$$) {
    my($path,$searchPattern,$searchOption,$predicate)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::DirectoryNotFoundException->new(undef,$path)) unless(-e $path && -d $path);
    $searchPattern="*" unless(defined($searchPattern));
    $searchOption=TopDirectoryOnly() unless(defined($searchOption));
    throw(System::ArgumentOutOfRangeException->new()) unless($searchOption==TopDirectoryOnly()||$searchOption==AllDirectories()); 
    
    my $handle=Symbol::gensym();
    my @result=();
    
    my @paths=($path);
    while(@paths){
      $path=pop(@paths);
      throw(System::IOException->new("Could not open directory")) unless(opendir($handle,"$path"));
      foreach my $item(readdir($handle)) {
        next if($item eq "." || $item eq "..");
        next unless(_MatchesFilter($item,$searchPattern));
        my $itemPath=System::IO::Path::Combine($path,$item);
        next unless(-e $itemPath);
        push(@paths,$itemPath)if(-d$itemPath);
        next unless(&{$predicate}($itemPath));
        push(@result,new System::String($itemPath));
      }
      throw(System::IOException->new("Could not close directory")) unless(closedir($handle));
      
      # if recursive is off - skip existing elements on stack
      last unless($searchOption==AllDirectories());
    }
    
    return(new Array(@result));
  }

  ### <summary>
  ### Checks whether a given item name matches a DOS file filter.
  ### </summary>
  ### <param name="fileOrDirName">The path</param>
  ### <param name="filter">The file filter</param>
  ### <returns><c>true</c> if it matches; otherwise, <c>false</c>.</returns>
  sub _MatchesFilter($$){
    my($fileOrDirName,$filter)=@_;
    my $regex=$filter;
    my $alt=System::IO::Path::AltDirectorySeparatorChar();
    my $sep=System::IO::Path::DirectorySeparatorChar();
    $regex=String::Replace($regex,$alt,$sep);
    $regex=~s/([\\\^\$\[\]\(\)\.])/\\$1/g;
    $regex=String::Replace($regex,"?",".");
    $regex=String::Replace($regex,"*",".*?");
    $regex='^'.$regex.'$';
    my $result=$fileOrDirName=~m/$regex/i;
    return($result);
  }

  sub Exists($) {
    my ($path) = @_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    return(-e"$path"&&-d"$path");
  }

  sub Create($) {
    my ($path) = @_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    mkdir($path);
  }

  # Enumerable versions (aliases for compatibility)
  sub EnumerateFiles($;$$) {
    my($path,$searchPattern,$searchOption)=@_;
    return GetFiles($path,$searchPattern,$searchOption);
  }

  sub EnumerateDirectories($;$$) {
    my($path,$searchPattern,$searchOption)=@_;
    return GetDirectories($path,$searchPattern,$searchOption);
  }

  sub EnumerateFileSystemEntries($;$$) {
    my($path,$searchPattern,$searchOption)=@_;
    return GetFileSystemEntries($path,$searchPattern,$searchOption);
  }

  sub Delete($;$) {
    my($path,$recursive)=@_;
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    $recursive=false unless defined($recursive);
    if($recursive) {
      
      my @readStack=($path);
      my @deleteStack=();
      while(my $folder=pop(@readStack)){
        Console::WriteLine("Reading $folder") if(DEBUG);
        my $items=GetFileSystemEntries($folder);
        my $hasFolders=false;
        foreach my$item(@{$items}){
          Console::WriteLine(" + Processing $item") if(DEBUG);
          if(Exists($item)){
            Console::WriteLine("    + Marking $item for later inspection") if(DEBUG);
            push(@readStack,$item);
            $hasFolders=true;
          }else{
            Console::WriteLine("    + Deleting $item") if(DEBUG);
            unlink($item);
          }
        }
        if($hasFolders){
          Console::WriteLine(" + Marking $folder for later deletion") if(DEBUG);
          push(@deleteStack,$folder);
        }else{
          Console::WriteLine(" + Removing $folder") if(DEBUG);
          rmdir("$folder");
        }
      }
      
      while(my $folder=pop(@deleteStack)){
        Console::WriteLine("Removing $folder") if(DEBUG);
        rmdir("$folder");
      }
      
    } else {
      rmdir("$path");
    }
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};
1;