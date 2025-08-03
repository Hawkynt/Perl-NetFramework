package System::EnvironmentVariableTarget; {
  use CSharp;
  use constant {
    Process=>0,
    User=>1,
    Machine=>2,
  };
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}  
};

package System::Environment::SpecialFolderOption; {
  use CSharp;
  use constant {
    Create=>32768,
    DoNotVerify=>16384,
    None=>0,
  };
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}  
};

package System::Environment::SpecialFolder; {
  use CSharp;
  use constant {
    Desktop => 0,
    Programs => 2,
    MyDocuments => 5,
    Personal => 5,
    Favorites => 6,
    Startup => 7,
    Recent => 8,
    SendTo => 9,
    StartMenu => 11,
    MyMusic => 13,
    MyVideos => 14,
    DesktopDirectory => 16,
    MyComputer => 17,
    NetworkShortcuts => 19,
    Fonts => 20,
    Templates => 21,
    CommonStartMenu => 22,
    CommonPrograms => 23,
    CommonStartup => 24,
    CommonDesktopDirectory => 25,
    ApplicationData => 26,
    PrinterShortcuts => 27,
    LocalApplicationData => 28,
    InternetCache => 32,
    Cookies => 33,
    History => 34,
    CommonApplicationData => 35,
    Windows => 36,
    System => 37,
    ProgramFiles => 38,
    MyPictures => 39,
    UserProfile => 40,
    SystemX86 => 41,
    ProgramFilesX86 => 42,
    CommonProgramFiles => 43,
    CommonProgramFilesX86 => 44,
    CommonTemplates => 45,
    CommonDocuments => 46,
    CommonAdminTools => 47,
    AdminTools => 48,
    CommonMusic => 53,
    CommonPictures => 54,
    CommonVideos => 55,
    Resources => 56,
    LocalizedResources => 57,
    CommonOemLinks => 58,
    CDBurning => 59,
  };
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}  
};

package System::Environment; {
  use strict;
  use warnings;

  use CSharp;
  use System::Exceptions;
  use System::String;
  use System::Array;

  #region static properties
  {
    my $cache;
    sub NewLine($) {
      $cache=__PACKAGE__->_IsWindows?"\r\n":"\n" unless defined($cache);
      return($cache);
    }
  }

  {
    my $cache;
    sub _IsWindows($){
      $cache=$^O=~/MSWin32/i unless defined($cache);
      return($cache)
    }
  }

  sub CommandLine($) {
    return("\"$0\" ".join(" ",map { /\s/?"\"$_\"":$_ } @ARGV));
  }

  sub CurrentManagedThreadId($) {
    return(0) unless eval { require threads };
    return threads->tid();
  }

  sub ExitCode($) {
    throw(System::NotImplementedException->new());
  }

  sub HasShutdownStarted($) {
    throw(System::NotImplementedException->new());
  }

  sub Is64BitOperatingSystem($) {
    if(__PACKAGE__->_IsWindows){
      require Win32;
      my $name=Win32::GetOSDisplayName();
      return($name=~m/\(64-bit\)/i);
    }
    
    throw(System::NotImplementedException->new());
  }

  sub Is64BitProcess($) {
    no warnings;
    require Config;
    my $a=$Config::Config{archname};
    use warnings;
    return($a=~m/x64/i);
  }

  sub MachineName($) {
    require Sys::Hostname;
    return(System::String->new(Sys::Hostname::hostname()));
  }

  sub OSVersion($) {
    throw(System::NotImplementedException->new());
  }

  sub ProcessorCount($) {
    if(__PACKAGE__->_IsWindows){
      my $rows=_GetWMIInfo("SELECT NumberOfLogicalProcessors FROM Win32_ComputerSystem");
      return($ENV{NUMBER_OF_PROCESSORS}) unless(defined($rows));
      my $sum=0;
      foreach my $row(@{$rows}) {
        $sum+=$row->{NumberOfLogicalProcessors} if($row->{NumberOfLogicalProcessors});
      }
      return($sum>0?$sum:$ENV{NUMBER_OF_PROCESSORS});
    }
    throw(System::NotImplementedException->new());
  }

  sub StackTrace($) {
    throw(System::NotImplementedException->new());
  }

  sub SystemDirectory($) {
    throw(System::NotImplementedException->new());
  }

  sub SystemPageSize($) {
    throw(System::NotImplementedException->new());
  }

  sub TickCount($) {
    throw(System::NotImplementedException->new());
  }

  sub UserDomainName($) {
    return(GetEnvironmentVariable("USERDOMAIN"));
  }

  sub UserInteractive($) {
    return(-t STDIN && -t STDOUT);
  }

  sub UserName($) {
    return((__PACKAGE__->_IsWindows()?null:getpwuid($<)) || getlogin() || $ENV{USERNAME} || $ENV{USER});
  }

  sub Version($) {
    throw(System::NotImplementedException->new());
  }

  sub WorkingSet($) {
    throw(System::NotImplementedException->new());
  }
  #endregion

  #region methods
  ### <summary>
  ### Executes a WMI query and returns the results.
  ### </summary>
  ### <param name="query">The query to execute</param>
  ### <returns>An Array of Dictionaries aka Rows and Columns</returns>
  sub _GetWMIInfo($) {
    my($query)=@_;
    return(undef) unless(__PACKAGE__->_IsWindows());
    my $result;
    require Win32::OLE;
    my $path='WinMgmts:{impersonationLevel=impersonate}!\\\\.\\root\\cimv2';
    my $wmi=Win32::OLE->GetObject($path);
    my $rows=$wmi->ExecQuery($query);
    $result=[];
    foreach my $row(Win32::OLE::in($rows)) {
      my $dict={};
      foreach my $item(Win32::OLE::in($row->{'Properties_'})) {
        my $name=$item->{Name};
        my $value=$item->{Value};
        if(ref($value) eq 'ARRAY') {
          my @array=();
          foreach my $data(Win32::OLE::in($value)){
            push(@array,$data);
          }
          $value=\@array;
        }
        $dict->{$name}=$value;
      }
      push(@{$result},$dict);
    }
    return($result);
  }
  
  sub Exit($) {
    my($exitCode)=@_;
    exit($exitCode);
  }

  sub ExpandEnvironmentVariables($) {
    my($text)=@_;
    $text=~s/%(.*?)%/$ENV{$1}/g;
    return(System::String->new($text));
  }

  sub FailFast($;$) {
    throw(System::NotImplementedException->new());
  }

  sub GetCommandLineArgs() {
    return(System::Array->new(@ARGV));
  }

  sub GetEnvironmentVariable($;$) {
    my($name,$target)=@_;
    throw(System::NotImplementedException->new()) if defined($target);
    return(exists($ENV{$name})?System::String->new($ENV{$name}):null);
  }

  sub GetEnvironmentVariables(;$) {
    my($environmentVariableTarget)=@_;
    throw(System::NotImplementedException->new());
  }

  sub GetFolderPath($;$) {
    my($specialFolder,$specialFolderOption)=@_;
    $specialFolderOption=System::Environment::SpecialFolderOption::None unless(defined($specialFolderOption));
    if(__PACKAGE__->_IsWindows){
      require Win32;
      my $result={
        System::Environment::SpecialFolder::Desktop()=>Win32::CSIDL_DESKTOP(),
        System::Environment::SpecialFolder::Programs()=>Win32::CSIDL_PROGRAMS(),
        System::Environment::SpecialFolder::MyDocuments()=>Win32::CSIDL_PROFILE(),
        System::Environment::SpecialFolder::Personal()=>Win32::CSIDL_PERSONAL(),
        System::Environment::SpecialFolder::Favorites()=>Win32::CSIDL_FAVORITES(),
        System::Environment::SpecialFolder::Startup()=>Win32::CSIDL_STARTUP(),
        System::Environment::SpecialFolder::Recent()=>Win32::CSIDL_RECENT(),
        System::Environment::SpecialFolder::SendTo()=>Win32::CSIDL_SENDTO(),
        System::Environment::SpecialFolder::StartMenu()=>Win32::CSIDL_STARTMENU(),
        System::Environment::SpecialFolder::MyMusic()=>Win32::CSIDL_MYMUSIC(),
        System::Environment::SpecialFolder::MyVideos()=>Win32::CSIDL_MYVIDEO(),
        System::Environment::SpecialFolder::DesktopDirectory()=>Win32::CSIDL_DESKTOPDIRECTORY(),
        System::Environment::SpecialFolder::NetworkShortcuts()=>Win32::CSIDL_NETHOOD(),
        System::Environment::SpecialFolder::Fonts()=>Win32::CSIDL_FONTS(),
        System::Environment::SpecialFolder::Templates()=>Win32::CSIDL_TEMPLATES(),
        
      }->{$specialFolder};
      throw(System::NotImplementedException->new()) unless defined($result);
      return(Win32::GetFolderPath($result));
    }
    throw(System::NotImplementedException->new());
  }

  sub GetLogicalDrives($) {
    throw(System::NotImplementedException->new());
  }

  sub SetEnvironmentVariable($$;$) {
    my($name,$value,$target)=@_;
    throw(System::NotImplementedException->new()) if defined($target);
    $ENV{$name}="$value";
  }

  #endregion

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}  

};

1;