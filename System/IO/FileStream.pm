package System::IO::FileStream; {
  use base 'System::IO::Stream';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::IO::Stream;
  
  # File-based stream implementation
  
  sub new {
    my ($class, $path, $mode, $access) = @_;
    
    throw(System::ArgumentNullException->new('path')) unless defined($path);
    
    # Define file modes and access types
    use constant {
      FileMode_CreateNew => 1,
      FileMode_Create => 2,
      FileMode_Open => 3,
      FileMode_OpenOrCreate => 4,
      FileMode_Truncate => 5,
      FileMode_Append => 6,
      
      FileAccess_Read => 1,
      FileAccess_Write => 2,
      FileAccess_ReadWrite => 3,
    };
    
    $mode //= FileMode_OpenOrCreate;
    $access //= FileAccess_ReadWrite;
    
    my $this = $class->SUPER::new();
    
    $this->{_path} = $path;
    $this->{_mode} = $mode;
    $this->{_access} = $access;
    $this->{_disposed} = false;
    $this->{_handle} = undef;
    $this->{_position} = 0;
    
    # Set capabilities based on access
    $this->{_canRead} = ($access == FileAccess_Read || $access == FileAccess_ReadWrite);
    $this->{_canWrite} = ($access == FileAccess_Write || $access == FileAccess_ReadWrite);
    $this->{_canSeek} = true;
    
    # Open the file with appropriate mode
    my $perlMode = $this->_GetPerlMode($mode, $access);
    
    # Check file existence and mode requirements
    my $fileExists = -e $path;
    
    if ($mode == FileMode_CreateNew && $fileExists) {
      throw(System::IO::IOException->new("File '$path' already exists"));
    }
    
    if ($mode == FileMode_Open && !$fileExists) {
      throw(System::IO::FileNotFoundException->new("File '$path' not found"));  
    }
    
    if ($mode == FileMode_Truncate && !$fileExists) {
      throw(System::IO::FileNotFoundException->new("File '$path' not found"));
    }
    
    # Open the file
    unless (open($this->{_handle}, $perlMode, $path)) {
      throw(System::IO::IOException->new("Cannot open file '$path': $!"));
    }
    
    # Set binary mode for proper byte handling
    binmode($this->{_handle});
    
    # Get file length
    if ($fileExists) {
      $this->{_length} = -s $path;
    } else {
      $this->{_length} = 0;
    }
    
    # Set position for append mode
    if ($mode == FileMode_Append) {
      $this->{_position} = $this->{_length};
      seek($this->{_handle}, 0, 2); # Seek to end
    }
    
    return $this;
  }
  
  sub _GetPerlMode {
    my ($this, $mode, $access) = @_;
    
    use constant {
      FileMode_CreateNew => 1,
      FileMode_Create => 2,
      FileMode_Open => 3,
      FileMode_OpenOrCreate => 4,
      FileMode_Truncate => 5,
      FileMode_Append => 6,
      
      FileAccess_Read => 1,
      FileAccess_Write => 2,
      FileAccess_ReadWrite => 3,
    };
    
    if ($access == FileAccess_Read) {
      return '<';  # Read only
    } elsif ($access == FileAccess_Write) {
      if ($mode == FileMode_Append) {
        return '>>';  # Append
      } elsif ($mode == FileMode_Create || $mode == FileMode_CreateNew || $mode == FileMode_Truncate) {
        return '>';   # Write, truncate
      } else {
        return '+<';  # Read/write, no truncate
      }
    } else { # ReadWrite
      if ($mode == FileMode_Append) {
        return '+>>';  # Read/append
      } elsif ($mode == FileMode_Create || $mode == FileMode_CreateNew || $mode == FileMode_Truncate) {
        return '+>';   # Read/write, truncate
      } else {
        return '+<';   # Read/write, no truncate  
      }
    }
  }
  
  sub Length {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('FileStream')) if $this->{_disposed};
    
    # Update length from file system
    if (defined($this->{_path}) && -e $this->{_path}) {
      $this->{_length} = -s $this->{_path};
    }
    
    return $this->{_length};
  }
  
  sub Position {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('FileStream')) if $this->{_disposed};
    
    if (@_ >= 2) {
      # Setter
      throw(System::ArgumentOutOfRangeException->new('position')) if $value < 0;
      seek($this->{_handle}, $value, 0); # SEEK_SET
      $this->{_position} = $value;
      return $value;
    } else {
      # Getter
      return $this->{_position};
    }
  }
  
  sub Read {
    my ($this, $buffer, $offset, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('FileStream')) if $this->{_disposed};
    throw(System::NotSupportedException->new('Stream does not support reading')) unless $this->{_canRead};
    throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
    throw(System::ArgumentOutOfRangeException->new('offset')) if $offset < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid offset/count')) if $offset + $count > @$buffer;
    
    return 0 if $count == 0;
    
    # Read bytes from file
    my $data;
    my $bytesRead = read($this->{_handle}, $data, $count);
    
    return 0 unless defined($bytesRead) && $bytesRead > 0;
    
    # Convert to byte array and copy to buffer
    my @bytes = map { ord($_) } split //, $data;
    
    for my $i (0..$bytesRead-1) {
      $buffer->[$offset + $i] = $bytes[$i];
    }
    
    $this->{_position} += $bytesRead;
    return $bytesRead;
  }
  
  sub Write {
    my ($this, $buffer, $offset, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('FileStream')) if $this->{_disposed};
    throw(System::NotSupportedException->new('Stream does not support writing')) unless $this->{_canWrite};
    throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
    throw(System::ArgumentOutOfRangeException->new('offset')) if $offset < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid offset/count')) if $offset + $count > @$buffer;
    
    return if $count == 0;
    
    # Convert bytes to string and write
    my $data = join('', map { chr($_) } @$buffer[$offset..$offset+$count-1]);
    
    my $bytesWritten = print {$this->{_handle}} $data;
    throw(System::IO::IOException->new("Write failed: $!")) unless $bytesWritten;
    
    $this->{_position} += $count;
    
    # Update length if we extended the file
    if ($this->{_position} > $this->{_length}) {
      $this->{_length} = $this->{_position};
    }
  }
  
  sub Seek {
    my ($this, $offset, $origin) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('FileStream')) if $this->{_disposed};
    
    # Define seek origins
    use constant {
      SeekOrigin_Begin => 0,
      SeekOrigin_Current => 1,
      SeekOrigin_End => 2,
    };
    
    $origin //= SeekOrigin_Begin;
    
    my $whence;
    if ($origin == SeekOrigin_Begin) {
      $whence = 0; # SEEK_SET
    } elsif ($origin == SeekOrigin_Current) {
      $whence = 1; # SEEK_CUR
    } elsif ($origin == SeekOrigin_End) {
      $whence = 2; # SEEK_END
    } else {
      throw(System::ArgumentException->new('Invalid seek origin'));
    }
    
    my $newPosition = seek($this->{_handle}, $offset, $whence);
    throw(System::IO::IOException->new("Seek failed: $!")) unless defined($newPosition);
    
    # Update our position tracking
    $this->{_position} = tell($this->{_handle});
    return $this->{_position};
  }
  
  sub SetLength {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('FileStream')) if $this->{_disposed};
    throw(System::NotSupportedException->new('Stream does not support writing')) unless $this->{_canWrite};
    throw(System::ArgumentOutOfRangeException->new('value')) if $value < 0;
    
    # Truncate file
    unless (truncate($this->{_handle}, $value)) {
      throw(System::IO::IOException->new("SetLength failed: $!"));
    }
    
    $this->{_length} = $value;
    
    # Adjust position if it's beyond the new length
    if ($this->{_position} > $value) {
      $this->Seek($value, 0); # Seek to end
    }
  }
  
  sub Flush {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('FileStream')) if $this->{_disposed};
    
    # Flush the file handle
    unless ($this->{_handle}->flush()) {
      throw(System::IO::IOException->new("Flush failed: $!"));
    }
  }
  
  sub Dispose {
    my ($this) = @_;
    return if $this->{_disposed};
    
    if (defined($this->{_handle})) {
      close($this->{_handle});
      $this->{_handle} = undef;
    }
    
    $this->{_disposed} = true;
  }
  
  # Additional properties
  sub Name {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_path};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;