package System::IO::DirectoryInfo; {
  use base 'System::IO::FileSystemInfo';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::IO::FileInfo;
  require System::Array;
  use File::Basename qw(basename dirname);
  use File::Path qw(make_path remove_tree);
  use File::Spec;
  
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
    my ($volume, $directories, $file) = File::Spec->splitpath($this->{_fullPath}, 1);
    my $rootPath = File::Spec->catpath($volume, File::Spec->rootdir(), '');
    return System::IO::DirectoryInfo->new($rootPath);
  }
  
  # Directory operations
  sub Create {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!$this->Exists()) {
      make_path($this->{_fullPath}) or
        throw(System::IOException->new("Failed to create directory: $!"));
      $this->Refresh();
    }
  }
  
  sub CreateSubdirectory {
    my ($this, $path) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('path')) unless defined($path);
    
    my $fullPath = "$this->{_fullPath}/$path";
    make_path($fullPath) or
      throw(System::IOException->new("Failed to create subdirectory: $!"));
    
    return System::IO::DirectoryInfo->new($fullPath);
  }
  
  sub Delete {
    my ($this, $recursive) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::DirectoryNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    $recursive //= 0;
    
    if ($recursive) {
      remove_tree($this->{_fullPath}) or
        throw(System::IOException->new("Failed to delete directory recursively: $!"));
    } else {
      rmdir($this->{_fullPath}) or
        throw(System::IOException->new("Failed to delete directory: $!"));
    }
    
    $this->Refresh();
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
    $pattern =~ s/\\./\\\\./g;  # Escape dots
    $pattern =~ s/\\*/.\*/g;     # Convert * to .*
    $pattern =~ s/\\?/./g;       # Convert ? to .
    
    return $name =~ /^$pattern$/i;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;