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
    return(System::String->new("\"$0\" ".join(" ",map { /\s/?"\"$_\"":$_ } @ARGV)));
  }

  sub CurrentManagedThreadId($) {
    return(0) unless eval { require threads };
    return threads->tid();
  }

  sub ExitCode($) {
    # Return the process exit code (not directly settable in Perl)
    return 0;
  }

  sub HasShutdownStarted($) {
    # In Perl, there's no direct way to detect shutdown
    return 0;
  }

  sub Is64BitOperatingSystem($) {
    if(__PACKAGE__->_IsWindows){
      require Win32;
      my $name=Win32::GetOSDisplayName();
      return($name=~m/\(64-bit\)/i);
    }
    
    # For Unix-like systems, check architecture
    eval {
      my $arch = `uname -m 2>/dev/null`;
      return true if $arch && $arch =~ /(x86_64|amd64|ia64|ppc64|sparc64)/i;
    };
    
    # Default based on process architecture
    return __PACKAGE__->Is64BitProcess();
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
    # Return OS version information
    my $os = $^O;
    my $version = '';
    
    if (__PACKAGE__->_IsWindows()) {
      eval {
        require Win32;
        $version = Win32::GetOSDisplayName() || Win32::GetOSName() || 'Windows';
      };
      $version ||= $ENV{'OS'} || 'Windows';
    } elsif ($os eq 'linux') {
      eval {
        my $release = `uname -r 2>/dev/null`;
        chomp($version = $release) if $release;
      };
      $version ||= 'Unknown';
      $version = "Linux $version";
    } elsif ($os eq 'darwin') {
      eval {
        my $version_info = `sw_vers -productVersion 2>/dev/null`;
        chomp($version = $version_info) if $version_info;
      };
      $version ||= 'Unknown';
      $version = "macOS $version";
    } else {
      $version = "$os (Unknown version)";
    }
    
    return System::String->new($version);
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
    
    # Unix-like systems
    my $count = 1;  # Default to 1
    
    if ($^O eq 'linux') {
      eval {
        my $cpuinfo = `nproc 2>/dev/null`;
        chomp($count = $cpuinfo) if $cpuinfo && $cpuinfo =~ /^\d+$/;
      };
      
      unless ($count > 1) {
        eval {
          my $cpuinfo = `cat /proc/cpuinfo 2>/dev/null | grep -c ^processor`;
          chomp($count = $cpuinfo) if $cpuinfo && $cpuinfo =~ /^\d+$/;
        };
      }
    } elsif ($^O eq 'darwin') {
      eval {
        my $cpuinfo = `sysctl -n hw.ncpu 2>/dev/null`;
        chomp($count = $cpuinfo) if $cpuinfo && $cpuinfo =~ /^\d+$/;
      };
    }
    
    return int($count) || 1;
  }

  sub StackTrace($) {
    # Generate a simple stack trace
    my @stack;
    my $i = 1;
    while (my @caller_info = caller($i)) {
      my ($package, $filename, $line, $sub) = @caller_info;
      push @stack, "   at $sub in $filename:line $line";
      $i++;
      last if $i > 50; # Prevent infinite loops
    }
    return join("\n", @stack);
  }

  sub SystemDirectory($) {
    if (__PACKAGE__->_IsWindows()) {
      return $ENV{SYSTEMROOT} || $ENV{WINDIR} || 'C:\Windows';
    } elsif ($^O eq 'darwin') {
      return '/System';
    } else {
      return '/usr';
    }
  }

  sub SystemPageSize($) {
    # Default to 4KB page size (common on most systems)
    if (__PACKAGE__->_IsWindows()) {
      eval {
        require Win32;
        my ($string, $major, $minor, $build, $id) = Win32::GetOSVersion();
        return 4096; # Windows typically uses 4KB pages
      };
    }
    # Unix-like systems typically use 4KB pages
    return 4096;
  }

  sub TickCount($) {
    # Return milliseconds since some reference point
    # Using times() which returns clock ticks, convert to milliseconds
    my @times = times();
    my $ticks = $times[0] + $times[1] + $times[2] + $times[3];
    
    # Convert to milliseconds (approximate)
    return int($ticks * 1000 / ($ENV{'CLK_TCK'} || 100));
  }

  sub UserDomainName($) {
    return(__PACKAGE__->GetEnvironmentVariable("USERDOMAIN") || System::String->new(__PACKAGE__->MachineName()));
  }

  sub UserInteractive($) {
    return(-t STDIN && -t STDOUT);
  }

  sub UserName($) {
    return((__PACKAGE__->_IsWindows()?null:getpwuid($<)) || getlogin() || $ENV{USERNAME} || $ENV{USER});
  }
  
  sub CurrentDirectory {
    my ($class, $value) = @_;
    if (@_ > 1) {  # Setter was called (value parameter provided, even if undef)
      throw(System::ArgumentNullException->new('value')) unless defined($value);
      throw(System::ArgumentException->new('path cannot be empty')) if $value eq '';
      
      chdir($value) or throw(System::DirectoryNotFoundException->new("Directory not found: $value"));
    } else {
      # Getter
      require Cwd;
      return System::String->new(Cwd::getcwd());
    }
  }

  sub Version($) {
    # Return .NET Framework version equivalent (this Perl implementation)
    return System::String->new("Perl-NetFramework 1.0.0");
  }

  sub WorkingSet($) {
    # Return working set size in bytes (approximate)
    my $size = 0;
    
    if ($^O eq 'linux') {
      eval {
        open my $fh, '<', '/proc/self/status' or return 1024 * 1024;
        while (my $line = <$fh>) {
          if ($line =~ /^VmRSS:\s*(\d+)\s*kB/) {
            $size = $1 * 1024;  # Convert KB to bytes
            last;
          }
        }
        close $fh;
      };
    } elsif (__PACKAGE__->_IsWindows()) {
      # For Windows, could use WMI but keep it simple for now
      $size = 1024 * 1024;  # 1MB default
    }
    
    # Fallback - return a reasonable default
    return $size || 1024 * 1024;  # 1MB default
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

  sub ExpandEnvironmentVariables {
    my ($class, $text) = @_;
    throw(System::ArgumentNullException->new('name')) unless defined($text);
    $text=~s/%(.*?)%/$ENV{$1}/g;
    return(System::String->new($text));
  }

  sub FailFast($;$) {
    my ($class, $message) = @_;
    # Print error message and exit immediately
    if (defined($message)) {
      print STDERR "Fatal Error: $message\n";
    } else {
      print STDERR "Fatal Error: Process terminated.\n";
    }
    CORE::exit(1);
  }

  sub GetCommandLineArgs() {
    return(System::Array->new(@ARGV));
  }

  sub GetEnvironmentVariable {
    my ($class, $name, $target) = @_;
    throw(System::ArgumentNullException->new('name')) unless defined($name);
    throw(System::NotImplementedException->new()) if defined($target);
    return(exists($ENV{$name})?System::String->new($ENV{$name}):null);
  }

  sub GetEnvironmentVariables(;$) {
    my($environmentVariableTarget)=@_;
    # For now, ignore target and just return process environment variables
    
    # Return a copy of %ENV as a hashtable-like structure  
    my $hashtable = {};
    for my $key (keys %ENV) {
      $hashtable->{$key} = System::String->new($ENV{$key});
    }
    
    return $hashtable;
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
    } else {
      # Unix/Linux/macOS implementation
      my $homeDir = $ENV{HOME} || '/tmp';
      
      # Standard Unix paths based on XDG Base Directory Specification and common conventions
      my $pathMap = {
        System::Environment::SpecialFolder::Desktop() => "$homeDir/Desktop",
        System::Environment::SpecialFolder::MyDocuments() => "$homeDir/Documents", 
        System::Environment::SpecialFolder::Personal() => "$homeDir/Documents",
        System::Environment::SpecialFolder::MyMusic() => "$homeDir/Music",
        System::Environment::SpecialFolder::MyVideos() => "$homeDir/Videos",
        System::Environment::SpecialFolder::MyPictures() => "$homeDir/Pictures",
        System::Environment::SpecialFolder::Templates() => "$homeDir/Templates",
        System::Environment::SpecialFolder::ApplicationData() => "$homeDir/.local/share",
        System::Environment::SpecialFolder::LocalApplicationData() => "$homeDir/.local/share",
        System::Environment::SpecialFolder::CommonApplicationData() => "/usr/share",
        System::Environment::SpecialFolder::UserProfile() => $homeDir,
        System::Environment::SpecialFolder::System() => "/usr",
        System::Environment::SpecialFolder::ProgramFiles() => "/usr/bin",
        System::Environment::SpecialFolder::CommonProgramFiles() => "/usr/share",
      };
      
      # Check for macOS-specific paths
      if ($^O eq 'darwin') {
        $pathMap->{System::Environment::SpecialFolder::ApplicationData()} = "$homeDir/Library/Application Support";
        $pathMap->{System::Environment::SpecialFolder::LocalApplicationData()} = "$homeDir/Library/Application Support";
        $pathMap->{System::Environment::SpecialFolder::MyMusic()} = "$homeDir/Music";
        $pathMap->{System::Environment::SpecialFolder::MyPictures()} = "$homeDir/Pictures";
      }
      
      my $path = $pathMap->{$specialFolder};
      return System::String->new($path) if defined($path);
      
      # Default fallback
      return System::String->new($homeDir);
    }
  }

  sub GetLogicalDrives($) {
    if (__PACKAGE__->_IsWindows()) {
      eval {
        require Win32::DriveInfo;
        my @drives = Win32::DriveInfo::DriveInfo();
        return System::Array->new(map { System::String->new($_) } @drives);
      };
      # Fallback: common Windows drives
      return System::Array->new(
        map { System::String->new($_) } 
        grep { -d $_ } ('C:\\', 'D:\\', 'E:\\', 'F:\\', 'G:\\', 'H:\\')
      );
    } else {
      # Unix-like: return mount points
      return System::Array->new(System::String->new('/'));
    }
  }

  sub SetEnvironmentVariable {
    my ($class, $name, $value, $target) = @_;
    throw(System::ArgumentNullException->new('name')) unless defined($name);
    throw(System::NotImplementedException->new()) if defined($target);
    
    if (defined($value)) {
      $ENV{$name} = "$value";
    } else {
      # Setting to undef/null removes the variable
      delete $ENV{$name};
    }
  }

  #endregion

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}  

};

1;