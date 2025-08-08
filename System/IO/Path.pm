package System::IO::Path; {

  use strict;
  use warnings;

  use CSharp;
  use System::Exceptions;
  use System::String;

  {
    my $cache=!($^O =~ m/Win/);
    sub PLATFORM_UNIX() {
      return($cache);
    }
  }
    
  {
    my $cache=PLATFORM_UNIX?'/':'\\';
    sub DirectorySeparatorChar() {
      return($cache);
    }
  }

  {
    my $cache=PLATFORM_UNIX?'\\':'/';
    sub AltDirectorySeparatorChar() {
      return($cache);
    }
  }

  {
    my $cache=PLATFORM_UNIX?':':';';
    sub PathSeparator() {
      return($cache);
    }
  }

  {
    my $cache=PLATFORM_UNIX?'/':':';
    sub VolumeSeparatorChar() {
      return($cache);
    }
  }

  sub ChangeExtension($$) {
    my($path,$extension)=@_;
    $path=_CheckStringArg($path,"path");
    $extension=_CheckStringArg($extension,"extension");
    
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    my $index=rindex($path,'.');
    $extension='.'.$extension if(substr($extension,0,1)ne'.');
    return System::String->new($index<0?$path.$extension:substr($path,0,$index).$extension);
  }

  sub Combine {
    my($args)=@_;
    if(scalar(@_)==1) {
      # test for array ref first
      return(System::String->new(join(DirectorySeparatorChar(),grep {/\S/} map { my $a=$_;$a=~s/[\\\/]$//;my $b=DirectorySeparatorChar();$a=~s/[\\\/]/$b/g;$a } @{$args}))) if((ref($args) eq 'ARRAY') || ($args->isa("System::Collections::IEnumerable")));
      return(System::String->new("$args"));
    } else {
      # assume an array of parts in @_
      return(System::String->new(join(DirectorySeparatorChar(),grep {/\S/} map { my $a=$_;$a=~s/[\\\/]$//;my $b=DirectorySeparatorChar();$a=~s/[\\\/]/$b/g;$a } @_)));
    }
  }

  sub GetDirectoryName($) {
    my($path)=@_;
    $path=_CheckStringArg($path,"path");
    return(undef) unless(defined($path));
    
    $path = _NormalizePath($path, false); 
    my $root = _GetRootLength($path);
    my $i = length($path); 
    return(undef) if ($i<=$root);
    $i=length($path);
    return(undef) if ($i==$root);
    while (($i > $root) && !(_IsDirectorySeparator(substr($path,--$i,1)))) {}
    return System::String->new(substr($path,0,$i));
  }

  sub GetExtension($) {
    my($path)=@_;
    $path=_CheckStringArg($path,"path");
    return(undef) unless(defined($path));
    
    my $length = length($path); 
    for (my $i = $length; --$i >= 0;) { 
      my $ch = substr($path,$i,1);
      return System::String->new(($i != $length - 1)?substr($path,$i,$length-$i):'') if ($ch eq '.');
      last if (_IsDirectorySeparator($ch) || $ch eq VolumeSeparatorChar);
    }
    return('');
  }

  sub GetFileName($) {
    my($path)=@_;
    $path=_CheckStringArg($path,"path");
    return(undef) unless(defined($path));
      
    my $length = length($path); 
    for (my $i = $length; --$i >= 0;) {
      my $ch = substr($path,$i,1);
      return (System::String->new(substr($path,$i + 1, $length - $i - 1))) if (_IsDirectorySeparator($ch) || $ch eq VolumeSeparatorChar);
    }
    return(System::String->new($path));
  }

  sub GetFileNameWithoutExtension($) {
    my($path)=@_;
    $path = GetFileName($path)->ToString();
    return(undef) unless(defined($path));
    my $i=rindex($path,'.');
    return System::String->new($i<0?$path:substr($path,0,$i));
  }

  sub GetRandomFileName() {
    my $chars='0123456789abcdefghijklmnopqrstuvwxyz';
    my $result='';
    my $length=length($chars);
    for(my $i=0;$i<8;++$i) {
      $result.=substr($chars,int(rand($length)),1);
    }
    return System::String->new($result);
  }

  sub _IsValidAndExists($){
    my($path)=@_;
    return(defined($path)&&-e($path)&&-d($path));
  }

  sub GetTempFileName() {
    my $path=$ENV{"TEMP"};
    $path=$ENV{"TMP"} unless(_IsValidAndExists($path));
    $path="/tmp" unless(_IsValidAndExists($path));
    $path="C:\\TEMP" unless(_IsValidAndExists($path));
    $path="C:\\WINDOWS\\TEMP" unless(_IsValidAndExists($path));
    throw(System::NotSupportedException->new("Could not find temporary directory")) unless(_IsValidAndExists($path));
    while(true) {
      my $random=GetRandomFileName();
      my $result=$path.DirectorySeparatorChar.'tmp'.substr($random,0,5).'.tmp';
      unless(-e $result) {
        throw(System::IOException->new($!)) unless(open my $fh,'>',$result);
        throw(System::IOException->new($!)) unless(close($fh));
        return System::String->new($result);
      }
    }
  }

  sub GetTempPath() {
    my $path=$ENV{"TEMP"};
    $path=$ENV{"TMP"} unless(_IsValidAndExists($path));
    $path="/tmp" unless(_IsValidAndExists($path));
    $path="C:\\TEMP" unless(_IsValidAndExists($path));
    $path="C:\\WINDOWS\\TEMP" unless(_IsValidAndExists($path));
    throw(System::NotSupportedException->new("Could not find temporary directory")) unless(_IsValidAndExists($path));
    return System::String->new($path);
  }

  sub GetFullPath($) {
    my($path)=@_;
    $path=_CheckStringArg($path,"path");
    throw(System::ArgumentNullException->new('path')) unless(defined($path));
    throw(System::ArgumentException->new('path cannot be empty')) if($path eq '');
    
    # Use Perl's File::Spec to get absolute path
    require File::Spec;
    my $fullPath = File::Spec->rel2abs($path);
    return System::String->new($fullPath);
  }

  sub IsPathRooted($) {
    my($path)=@_;
    $path=_CheckStringArg($path,"path");
    return false unless(defined($path) && $path ne '');
    
    if (PLATFORM_UNIX) {
      return(substr($path,0,1) eq '/');
    } else {
      # Windows: check for drive letter or UNC path
      return(length($path) >= 1 && _IsDirectorySeparator(substr($path,0,1))) ||
            (length($path) >= 2 && substr($path,1,1) eq VolumeSeparatorChar);
    }
  }

  sub GetPathRoot($) {
    my($path)=@_;
    $path=_CheckStringArg($path,"path");
    return System::String->new('') unless(defined($path));
    
    my $rootLength = _GetRootLength($path);
    return System::String->new(substr($path, 0, $rootLength));
  }

  sub HasExtension($) {
    my($path)=@_;
    $path=_CheckStringArg($path,"path");
    return false unless(defined($path));
    
    my $length = length($path);
    for (my $i = $length; --$i >= 0;) {
      my $ch = substr($path,$i,1);
      return true if ($ch eq '.');
      last if (_IsDirectorySeparator($ch) || $ch eq VolumeSeparatorChar);
    }
    return false;
  }

  sub GetInvalidFileNameChars() {
    if (PLATFORM_UNIX) {
      return System::Array->new('/', '\0');
    } else {
      return System::Array->new('<', '>', ':', '"', '|', '?', '*', '\0',
                                 chr(1), chr(2), chr(3), chr(4), chr(5), chr(6), chr(7), chr(8), chr(9),
                                 chr(10), chr(11), chr(12), chr(13), chr(14), chr(15), chr(16), chr(17),
                                 chr(18), chr(19), chr(20), chr(21), chr(22), chr(23), chr(24), chr(25),
                                 chr(26), chr(27), chr(28), chr(29), chr(30), chr(31));
    }
  }

  sub GetInvalidPathChars() {
    if (PLATFORM_UNIX) {
      return System::Array->new('\0');
    } else {
      return System::Array->new('|', '\0',
                                 chr(1), chr(2), chr(3), chr(4), chr(5), chr(6), chr(7), chr(8), chr(9),
                                 chr(10), chr(11), chr(12), chr(13), chr(14), chr(15), chr(16), chr(17),
                                 chr(18), chr(19), chr(20), chr(21), chr(22), chr(23), chr(24), chr(25),
                                 chr(26), chr(27), chr(28), chr(29), chr(30), chr(31));
    }
  }

  sub _IsDirectorySeparator($) {
    my($char)=@_;
    return($char eq DirectorySeparatorChar||$char eq AltDirectorySeparatorChar);
  }

  sub _GetRootLength($) {
    my($path)=@_;
    my $i = 0;
    my $length = length($path);
    if (PLATFORM_UNIX) {
      $i = 1 if ($length >= 1 && (_IsDirectorySeparator(substr($path,0,1))));
      return($i);
    } 
    if ($length >= 1 && (_IsDirectorySeparator(substr($path,0,1)))) {
      # handles UNC names and directories off current drive's root. 
      $i = 1;
      if ($length >= 2 && (_IsDirectorySeparator(substr($path,1,1)))) { 
        $i = 2; 
        my $n = 2;
        while ($i < $length && (!_IsDirectorySeparator(substr($path,$i,1)) || --$n > 0)) { $i++ }
      }
    } elsif ($length >= 2 && substr($path,1,1) eq VolumeSeparatorChar) {
      # handles A:\foo. 
      $i = 2;
      $i++ if ($length >= 3 && (_IsDirectorySeparator(substr($path,2,1))));
    } 
    return($i);
  }

  sub _NormalizePath($$) {
    my($path,$fullCheck)=@_;
      
    # TODO: strip out . and .. etc. to normalize this path
    return($path);
  }

  sub _CheckStringArg($$) {
    my($value,$argName)=@_;
    return(undef) unless(defined($value));
    return($value->ToString()) if (ref($value)&&$value->isa("System::String"));
    System::throw(System::InvalidArgumentException($argName)) if(ref($value));
    return($value);
  }
 
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};
1;