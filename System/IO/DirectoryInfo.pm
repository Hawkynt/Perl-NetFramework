package System::IO::DirectoryInfo; {
  use base 'System::IO::FileSystemInfo';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::IO::FileInfo;
  require System::Array;
  use File::Basename qw(basename dirname);
  
  # DirectoryInfo - provides instance methods for directory operations
  
  sub new {
    my ($class, $path) = @_;
    my $this = $class->SUPER::new($path);
    return bless $this, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Name {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return basename($this->{_fullPath});
  }
  
  sub Parent {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my $parentPath = dirname($this->{_fullPath});
    return ($parentPath ne $this->{_fullPath}) ? 
           System::IO::DirectoryInfo->new($parentPath) : undef;
  }
  
  sub Root {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Simple root detection - works on both Unix and Windows
    my $path = $this->{_fullPath};
    my $rootPath;
    
    if ($path =~ /^([A-Za-z]:)/) {
      # Windows drive letter
      $rootPath = $1 . '/';
    } elsif ($path =~ /^\//) {
      # Unix root
      $rootPath = '/';
    } else {
      # Relative path - use current working directory root
      require Cwd;
      my $cwd = Cwd::getcwd();
      if ($cwd =~ /^([A-Za-z]:)/) {
        $rootPath = $1 . '/';
      } else {
        $rootPath = '/';
      }
    }
    
    return System::IO::DirectoryInfo->new($rootPath);
  }
  
  # Directory operations
  sub Create {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!$this->Exists()) {
      $this->_CreatePath($this->{_fullPath});
      $this->Refresh();
    }
  }
  
  sub CreateSubdirectory {
    my ($this, $path) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('path')) unless defined($path);
    
    my $fullPath = "$this->{_fullPath}/$path";
    $this->_CreatePath($fullPath);
    
    return System::IO::DirectoryInfo->new($fullPath);
  }
  
  # Internal method for creating directory paths
  sub _CreatePath {
    my ($this, $path) = @_;
    return if -d $path;
    
    # Get parent directory
    my $parent = dirname($path);
    
    # Recursively create parent if it doesn't exist
    if ($parent ne $path && !-d $parent) {
      $this->_CreatePath($parent);
    }
    
    # Create this directory
    mkdir($path) or
      throw(System::IOException->new("Failed to create directory: $path - $!"));
  }
  
  sub Delete {
    my ($this, $recursive) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::DirectoryNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    $recursive //= 0;
    
    if ($recursive) {
      $this->_DeleteRecursively($this->{_fullPath});
    } else {
      rmdir($this->{_fullPath}) or
        throw(System::IOException->new("Failed to delete directory: $!"));
    }
    
    $this->Refresh();
  }
  
  # Internal method for recursive deletion
  sub _DeleteRecursively {
    my ($this, $path) = @_;
    return unless -d $path;
    
    opendir(my $dh, $path) or 
      throw(System::IOException->new("Cannot open directory for deletion: $!"));
    
    my @entries = readdir($dh);
    closedir($dh);
    
    for my $entry (@entries) {
      next if $entry eq '.' || $entry eq '..';
      my $fullPath = "$path/$entry";
      
      if (-d $fullPath) {
        $this->_DeleteRecursively($fullPath);
      } else {
        unlink($fullPath) or
          throw(System::IOException->new("Failed to delete file: $fullPath"));
      }
    }
    
    rmdir($path) or
      throw(System::IOException->new("Failed to delete directory: $path"));
  }
  
  sub MoveTo {
    my ($this, $destDirName) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('destDirName')) unless defined($destDirName);
    throw(System::DirectoryNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    # Use File::Copy::move for directory moving
    require File::Copy;
    File::Copy::move($this->{_fullPath}, $destDirName) or
      throw(System::IOException->new("Failed to move directory: $!"));
    
    # Update this object's paths
    $this->{_originalPath} = $destDirName;
    $this->{_fullPath} = File::Spec->rel2abs($destDirName);
    $this->Refresh();
  }
  
  # Enumeration methods
  sub GetDirectories {
    my ($this, $searchPattern, $searchOption) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::DirectoryNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    $searchPattern //= '*';
    $searchOption //= 0; # TopDirectoryOnly
    
    my @directories;
    my @queue = ($this->{_fullPath});
    
    while (@queue) {
      my $currentDir = shift @queue;
      
      opendir(my $dh, $currentDir) or
        throw(System::IOException->new("Cannot open directory: $!"));
      
      while (my $entry = readdir($dh)) {
        next if $entry eq '.' || $entry eq '..';
        
        my $fullPath = "$currentDir/$entry";
        next unless -d $fullPath;
        
        if (_MatchesPattern($entry, $searchPattern)) {
          push @directories, System::IO::DirectoryInfo->new($fullPath);
        }
        
        if ($searchOption == 1) { # AllDirectories
          push @queue, $fullPath;
        }
      }
      
      closedir($dh);
    }
    
    return System::Array->new(@directories);
  }
  
  sub GetFiles {
    my ($this, $searchPattern, $searchOption) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::DirectoryNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    $searchPattern //= '*';
    $searchOption //= 0; # TopDirectoryOnly
    
    my @files;
    my @queue = ($this->{_fullPath});
    
    while (@queue) {
      my $currentDir = shift @queue;
      
      opendir(my $dh, $currentDir) or
        throw(System::IOException->new("Cannot open directory: $!"));
      
      while (my $entry = readdir($dh)) {
        next if $entry eq '.' || $entry eq '..';
        
        my $fullPath = "$currentDir/$entry";
        
        if (-f $fullPath && _MatchesPattern($entry, $searchPattern)) {
          push @files, System::IO::FileInfo->new($fullPath);
        } elsif (-d $fullPath && $searchOption == 1) { # AllDirectories
          push @queue, $fullPath;
        }
      }
      
      closedir($dh);
    }
    
    return System::Array->new(@files);
  }
  
  sub GetFileSystemInfos {
    my ($this, $searchPattern, $searchOption) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::DirectoryNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    $searchPattern //= '*';
    $searchOption //= 0; # TopDirectoryOnly
    
    my @items;
    my @queue = ($this->{_fullPath});
    
    while (@queue) {
      my $currentDir = shift @queue;
      
      opendir(my $dh, $currentDir) or
        throw(System::IOException->new("Cannot open directory: $!"));
      
      while (my $entry = readdir($dh)) {
        next if $entry eq '.' || $entry eq '..';
        
        my $fullPath = "$currentDir/$entry";
        
        if (_MatchesPattern($entry, $searchPattern)) {
          if (-f $fullPath) {
            push @items, System::IO::FileInfo->new($fullPath);
          } elsif (-d $fullPath) {
            push @items, System::IO::DirectoryInfo->new($fullPath);
          }
        }
        
        if (-d $fullPath && $searchOption == 1) { # AllDirectories
          push @queue, $fullPath;
        }
      }
      
      closedir($dh);
    }
    
    return System::Array->new(@items);
  }
  
  # Enumerable versions
  sub EnumerateDirectories {
    my ($this, $searchPattern, $searchOption) = @_;
    return $this->GetDirectories($searchPattern, $searchOption);
  }
  
  sub EnumerateFiles {
    my ($this, $searchPattern, $searchOption) = @_;
    return $this->GetFiles($searchPattern, $searchOption);
  }
  
  sub EnumerateFileSystemInfos {
    my ($this, $searchPattern, $searchOption) = @_;
    return $this->GetFileSystemInfos($searchPattern, $searchOption);
  }
  
  # Protected methods
  sub _RefreshExistence {
    my ($this) = @_;
    $this->{_exists} = (-e $this->{_fullPath} && -d $this->{_fullPath}) ? 1 : 0;
  }
  
  # Helper method for pattern matching
  sub _MatchesPattern {
    my ($name, $pattern) = @_;
    
    # Convert DOS-style wildcards to regex
    # First escape regex special characters except * and ?
    $pattern =~ s/([\[\]{}().+^$|\\])/\\$1/g;
    
    # Then convert wildcards to regex
    $pattern =~ s/\*/.\*/g;     # Convert * to .*
    $pattern =~ s/\?/./g;       # Convert ? to .
    
    return $name =~ /^$pattern$/i;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;