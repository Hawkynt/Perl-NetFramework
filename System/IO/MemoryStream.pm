package System::IO::MemoryStream; {
  use base 'System::IO::Stream';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::IO::Stream;
  
  # Memory-based stream implementation
  
  sub new {
    my ($class, $buffer) = @_;
    
    my $this = $class->SUPER::new();
    
    if (defined($buffer)) {
      # Initialize with existing buffer
      if (ref($buffer) eq 'ARRAY') {
        $this->{_buffer} = [@$buffer]; # Copy the array
      } elsif ($buffer->isa('System::Array')) {
        my @data = ();
        for my $i (0..$buffer->Length()-1) {
          push @data, $buffer->GetValue($i);
        }
        $this->{_buffer} = \@data;
      } else {
        throw(System::ArgumentException->new('buffer must be an array or System::Array'));
      }
    } else {
      # Empty buffer
      $this->{_buffer} = [];
    }
    
    $this->{_position} = 0;
    $this->{_length} = scalar(@{$this->{_buffer}});
    $this->{_canRead} = true;
    $this->{_canWrite} = true;
    $this->{_canSeek} = true;
    $this->{_disposed} = false;
    
    return $this;
  }
  
  sub Length {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('MemoryStream')) if $this->{_disposed};
    return $this->{_length};
  }
  
  sub Position {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('MemoryStream')) if $this->{_disposed};
    
    if (@_ >= 2) {
      # Setter
      throw(System::ArgumentOutOfRangeException->new('position')) if $value < 0;
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
    throw(System::ObjectDisposedException->new('MemoryStream')) if $this->{_disposed};
    throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
    throw(System::ArgumentOutOfRangeException->new('offset')) if $offset < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid offset/count')) if $offset + $count > @$buffer;
    
    # Calculate how many bytes we can actually read
    my $availableBytes = $this->{_length} - $this->{_position};
    my $bytesToRead = $count > $availableBytes ? $availableBytes : $count;
    
    return 0 if $bytesToRead <= 0;
    
    # Copy bytes from internal buffer to destination buffer
    for my $i (0..$bytesToRead-1) {
      $buffer->[$offset + $i] = $this->{_buffer}->[$this->{_position} + $i];
    }
    
    $this->{_position} += $bytesToRead;
    return $bytesToRead;
  }
  
  sub Write {
    my ($this, $buffer, $offset, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('MemoryStream')) if $this->{_disposed};
    throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
    throw(System::ArgumentOutOfRangeException->new('offset')) if $offset < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid offset/count')) if $offset + $count > @$buffer;
    
    return if $count == 0;
    
    # Ensure buffer is large enough
    my $requiredSize = $this->{_position} + $count;
    if ($requiredSize > @{$this->{_buffer}}) {
      # Expand the buffer
      my $newSize = $requiredSize * 2; # Double the size for growth
      while (@{$this->{_buffer}} < $newSize) {
        push @{$this->{_buffer}}, 0;
      }
    }
    
    # Copy bytes from source buffer to internal buffer
    for my $i (0..$count-1) {
      $this->{_buffer}->[$this->{_position} + $i] = $buffer->[$offset + $i];
    }
    
    $this->{_position} += $count;
    
    # Update length if we extended the stream
    if ($this->{_position} > $this->{_length}) {
      $this->{_length} = $this->{_position};
    }
  }
  
  sub Seek {
    my ($this, $offset, $origin) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('MemoryStream')) if $this->{_disposed};
    
    # Define seek origins
    use constant {
      SeekOrigin_Begin => 0,
      SeekOrigin_Current => 1, 
      SeekOrigin_End => 2,
    };
    
    $origin //= SeekOrigin_Begin;
    
    my $newPosition;
    if ($origin == SeekOrigin_Begin) {
      $newPosition = $offset;
    } elsif ($origin == SeekOrigin_Current) {
      $newPosition = $this->{_position} + $offset;
    } elsif ($origin == SeekOrigin_End) {
      $newPosition = $this->{_length} + $offset;
    } else {
      throw(System::ArgumentException->new('Invalid seek origin'));
    }
    
    throw(System::ArgumentOutOfRangeException->new('offset')) if $newPosition < 0;
    
    $this->{_position} = $newPosition;
    return $newPosition;
  }
  
  sub SetLength {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('MemoryStream')) if $this->{_disposed};
    throw(System::ArgumentOutOfRangeException->new('value')) if $value < 0;
    
    if ($value < $this->{_length}) {
      # Truncate
      splice @{$this->{_buffer}}, $value;
    } elsif ($value > $this->{_length}) {
      # Extend with zeros
      while (@{$this->{_buffer}} < $value) {
        push @{$this->{_buffer}}, 0;
      }
    }
    
    $this->{_length} = $value;
    
    # Adjust position if it's beyond the new length
    if ($this->{_position} > $value) {
      $this->{_position} = $value;
    }
  }
  
  sub Flush {
    my ($this) = @_;
    # MemoryStream doesn't need flushing
    throw(System::ObjectDisposedException->new('MemoryStream')) if $this->{_disposed};
  }
  
  sub Dispose {
    my ($this) = @_;
    $this->{_disposed} = true;
    $this->{_buffer} = undef;
  }
  
  # Get the internal buffer as a byte array
  sub ToArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('MemoryStream')) if $this->{_disposed};
    
    require System::Array;
    my @result = @{$this->{_buffer}}[0..$this->{_length}-1];
    return System::Array->new(@result);
  }
  
  # Get the buffer (direct reference - use carefully)
  sub GetBuffer {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('MemoryStream')) if $this->{_disposed};
    
    require System::Array;
    return System::Array->new(@{$this->{_buffer}});
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;