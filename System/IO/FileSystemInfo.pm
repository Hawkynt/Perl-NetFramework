package System::IO::FileSystemInfo; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::DateTime;
  
  # Abstract base class for FileInfo and DirectoryInfo
  
  sub new {
    my ($class, $path) = @_;
    throw(System::ArgumentNullException->new('path')) unless defined($path);
    throw(System::ArgumentException->new('Path cannot be empty')) if $path eq '';
    
    return bless {
      _originalPath => $path,
      _fullPath => $path, # Simplified - use path as-is
      _exists => undef, # Will be cached on first access
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub FullName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_fullPath};
  }
  
  sub Name {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::NotImplementedException->new('Name property must be implemented by derived classes'));
  }
  
  sub Exists {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    if (!defined($this->{_exists})) {
      $this->_RefreshExistence();
    }
    return $this->{_exists};
  }
  
  sub CreationTime {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    my $ctime = (stat($this->{_fullPath}))[10];
    return System::DateTime->FromUnixTime($ctime);
  }
  
  sub CreationTimeUtc {
    my ($this) = @_;
    # For simplicity, same as CreationTime (would need timezone handling in real implementation)
    return $this->CreationTime();
  }
  
  sub LastAccessTime {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    my $atime = (stat($this->{_fullPath}))[8];
    return System::DateTime->FromUnixTime($atime);
  }
  
  sub LastAccessTimeUtc {
    my ($this) = @_;
    # For simplicity, same as LastAccessTime (would need timezone handling in real implementation)
    return $this->LastAccessTime();
  }
  
  sub LastWriteTime {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    my $mtime = (stat($this->{_fullPath}))[9];
    return System::DateTime->FromUnixTime($mtime);
  }
  
  sub LastWriteTimeUtc {
    my ($this) = @_;
    # For simplicity, same as LastWriteTime (would need timezone handling in real implementation)
    return $this->LastWriteTime();
  }
  
  sub Attributes {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::FileNotFoundException->new($this->{_fullPath})) unless $this->Exists();
    
    # Return basic file attributes as a bitmask (simplified)
    my $attrs = 0;
    my $path = $this->{_fullPath};
    
    $attrs |= 1 if (!-w $path);      # ReadOnly (inverted writable)
    $attrs |= 2 if (-d $path);       # Directory
    $attrs |= 4 if (-l $path);       # ReparsePoint (symlink)
    $attrs |= 32 if (-f $path);      # Archive (normal files)
    $attrs |= 2048 if (index($path, '.') == 0); # Hidden (starts with dot on Unix-like systems)
    
    return $attrs;
  }
  
  # Methods
  sub Delete {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::NotImplementedException->new('Delete method must be implemented by derived classes'));
  }
  
  sub Refresh {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    $this->{_exists} = undef; # Clear cached existence
    $this->_RefreshExistence();
  }
  
  # Protected/Private methods
  sub _RefreshExistence {
    my ($this) = @_;
    throw(System::NotImplementedException->new('_RefreshExistence method must be implemented by derived classes'));
  }
  
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_originalPath};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;