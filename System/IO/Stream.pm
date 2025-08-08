package System::IO::Stream; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # Abstract base class for all streams
  # This provides the common interface that all streams must implement
  
  sub new {
    my ($class) = @_;
    return bless {
      _position => 0,
      _length => 0,
      _canRead => false,
      _canWrite => false,
      _canSeek => false,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Abstract properties - must be overriden by derived classes
  sub CanRead {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_canRead};
  }
  
  sub CanWrite {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_canWrite};
  }
  
  sub CanSeek {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_canSeek};
  }
  
  sub Length {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::NotSupportedException->new('Stream does not support seeking')) unless $this->CanSeek();
    return $this->{_length};
  }
  
  sub Position {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (@_ >= 2) {
      # Setter
      throw(System::NotSupportedException->new('Stream does not support seeking')) unless $this->CanSeek();
      throw(System::ArgumentOutOfRangeException->new('position')) if $value < 0;
      $this->{_position} = $value;
      return $value;
    } else {
      # Getter
      return $this->{_position};
    }
  }
  
  # Abstract methods - must be implemented by derived classes
  sub Read {
    my ($this, $buffer, $offset, $count) = @_;
    throw(System::NotImplementedException->new('Read method must be implemented by derived class'));
  }
  
  sub Write {
    my ($this, $buffer, $offset, $count) = @_;
    throw(System::NotImplementedException->new('Write method must be implemented by derived class'));
  }
  
  sub Seek {
    my ($this, $offset, $origin) = @_;
    throw(System::NotSupportedException->new('Stream does not support seeking'));
  }
  
  sub SetLength {
    my ($this, $value) = @_;
    throw(System::NotSupportedException->new('Stream does not support SetLength'));
  }
  
  sub Flush {
    my ($this) = @_;
    # Default implementation does nothing
    # Override in derived classes if needed
  }
  
  sub Close {
    my ($this) = @_;
    $this->Dispose();
  }
  
  sub Dispose {
    my ($this) = @_;
    # Default implementation does nothing
    # Override in derived classes for cleanup
  }
  
  # Convenience methods
  sub ReadByte {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::NotSupportedException->new('Stream does not support reading')) unless $this->CanRead();
    
    my @buffer = (0);
    my $bytesRead = $this->Read(\@buffer, 0, 1);
    return $bytesRead == 0 ? -1 : $buffer[0];
  }
  
  sub WriteByte {
    my ($this, $byte) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::NotSupportedException->new('Stream does not support writing')) unless $this->CanWrite();
    throw(System::ArgumentOutOfRangeException->new('byte')) if $byte < 0 || $byte > 255;
    
    my @buffer = ($byte);
    $this->Write(\@buffer, 0, 1);
  }
  
  # Copy stream to another stream
  sub CopyTo {
    my ($this, $destination, $bufferSize) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('destination')) unless defined($destination);
    throw(System::NotSupportedException->new('Stream does not support reading')) unless $this->CanRead();
    throw(System::NotSupportedException->new('Destination stream does not support writing')) unless $destination->CanWrite();
    
    $bufferSize //= 4096; # Default buffer size
    throw(System::ArgumentOutOfRangeException->new('bufferSize')) if $bufferSize <= 0;
    
    my @buffer = (0) x $bufferSize;
    my $bytesRead;
    
    while (($bytesRead = $this->Read(\@buffer, 0, $bufferSize)) > 0) {
      $destination->Write(\@buffer, 0, $bytesRead);
    }
  }
  
  # Read all bytes from current position to end
  sub ReadToEnd {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::NotSupportedException->new('Stream does not support reading')) unless $this->CanRead();
    
    my @result = ();
    my @buffer = (0) x 4096;
    my $bytesRead;
    
    while (($bytesRead = $this->Read(\@buffer, 0, 4096)) > 0) {
      push @result, @buffer[0..$bytesRead-1];
    }
    
    require System::Array;
    return System::Array->new(@result);
  }
  
  # APM (Asynchronous Programming Model) methods
  sub BeginRead {
    my ($this, $buffer, $offset, $count, $callback, $state) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
    throw(System::NotSupportedException->new('Stream does not support reading')) unless $this->CanRead();
    
    require System::Threading::AsyncResult;
    require System::Threading::ThreadPool;
    
    my $asyncResult = System::Threading::AsyncResult->new($callback, $state);
    
    # Queue the read operation to run asynchronously
    System::Threading::ThreadPool->QueueUserWorkItem(sub {
      my $bytesRead = 0;
      my $exception = undef;
      
      eval {
        $bytesRead = $this->Read($buffer, $offset, $count);
      };
      if ($@) {
        $exception = $@;
      }
      
      # Mark as completed asynchronously
      $asyncResult->_SetCompleted($bytesRead, $exception, 0);
    });
    
    return $asyncResult;
  }
  
  sub EndRead {
    my ($this, $asyncResult) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('asyncResult')) unless defined($asyncResult);
    throw(System::ArgumentException->new('Invalid AsyncResult')) 
      unless $asyncResult->isa('System::Threading::AsyncResult');
    
    return $asyncResult->_GetResult();
  }
  
  sub BeginWrite {
    my ($this, $buffer, $offset, $count, $callback, $state) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
    throw(System::NotSupportedException->new('Stream does not support writing')) unless $this->CanWrite();
    
    require System::Threading::AsyncResult;
    require System::Threading::ThreadPool;
    
    my $asyncResult = System::Threading::AsyncResult->new($callback, $state);
    
    # Queue the write operation to run asynchronously
    System::Threading::ThreadPool->QueueUserWorkItem(sub {
      my $exception = undef;
      
      eval {
        $this->Write($buffer, $offset, $count);
      };
      if ($@) {
        $exception = $@;
      }
      
      # Mark as completed asynchronously
      $asyncResult->_SetCompleted(undef, $exception, 0);
    });
    
    return $asyncResult;
  }
  
  sub EndWrite {
    my ($this, $asyncResult) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('asyncResult')) unless defined($asyncResult);
    throw(System::ArgumentException->new('Invalid AsyncResult')) 
      unless $asyncResult->isa('System::Threading::AsyncResult');
    
    $asyncResult->_GetResult();
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;