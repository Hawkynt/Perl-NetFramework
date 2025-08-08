package System::IO::StreamReader; {
  use base 'System::IO::TextReader';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::IO::TextReader;
  require System::IO::Stream;
  
  # Stream-based text reader
  
  sub new {
    my ($class, $stream_or_path, $encoding) = @_;
    throw(System::ArgumentNullException->new('stream_or_path')) unless defined($stream_or_path);
    
    my $this = $class->SUPER::new();
    
    # Handle both stream and path inputs
    if (ref($stream_or_path) && $stream_or_path->isa('System::IO::Stream')) {
      # Stream input
      $this->{_stream} = $stream_or_path;
      $this->{_ownsStream} = false;
    } else {
      # Path input - create FileStream
      require System::IO::FileStream;
      $this->{_stream} = System::IO::FileStream->new($stream_or_path, 3, 1); # Open, Read
      $this->{_ownsStream} = true;
    }
    
    throw(System::ArgumentException->new('Stream must support reading')) unless $this->{_stream}->CanRead();
    
    # Set up encoding (simplified - just UTF-8 for now)
    $this->{_encoding} = $encoding // 'utf8';
    $this->{_buffer} = '';
    $this->{_bufferPos} = 0;
    $this->{_byteBuf} = [];
    $this->{_endOfStream} = false;
    
    return $this;
  }
  
  # Read a single character
  sub Read {
    my ($this, $buffer, $index, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamReader')) if $this->{_disposed};
    
    if (defined($buffer)) {
      # Read into buffer
      throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
      throw(System::ArgumentOutOfRangeException->new('index')) if $index < 0;
      throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
      throw(System::ArgumentException->new('Invalid index/count')) if $index + $count > @$buffer;
      
      my $totalRead = 0;
      for my $i (0..$count-1) {
        my $char = $this->_ReadChar();
        last unless defined($char);
        $buffer->[$index + $i] = $char;
        $totalRead++;
      }
      return $totalRead;
    } else {
      # Read single character
      return $this->_ReadChar();
    }
  }
  
  sub _ReadChar {
    my ($this) = @_;
    return undef if $this->{_endOfStream};
    
    # If we have characters in buffer, return next one
    if ($this->{_bufferPos} < length($this->{_buffer})) {
      my $char = substr($this->{_buffer}, $this->{_bufferPos}, 1);
      $this->{_bufferPos}++;
      return $char;
    }
    
    # Need to read more data from stream
    $this->_FillBuffer();
    
    if ($this->{_bufferPos} < length($this->{_buffer})) {
      my $char = substr($this->{_buffer}, $this->{_bufferPos}, 1);
      $this->{_bufferPos}++;
      return $char;
    }
    
    return undef; # End of stream
  }
  
  sub _FillBuffer {
    my ($this) = @_;
    return if $this->{_endOfStream};
    
    # Read bytes from stream
    my @byteBuffer = (0) x 1024;
    my $bytesRead = $this->{_stream}->Read(\@byteBuffer, 0, 1024);
    
    if ($bytesRead == 0) {
      $this->{_endOfStream} = true;
      return;
    }
    
    # Convert bytes to string (simplified UTF-8 handling)
    my $newData = join('', map { chr($_) } @byteBuffer[0..$bytesRead-1]);
    
    # Add to buffer
    $this->{_buffer} = substr($this->{_buffer}, $this->{_bufferPos}) . $newData;
    $this->{_bufferPos} = 0;
  }
  
  sub ReadLine {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamReader')) if $this->{_disposed};
    
    return undef if $this->{_endOfStream} && $this->{_bufferPos} >= length($this->{_buffer});
    
    my $line = '';
    
    while (1) {
      # Check if we have a newline in current buffer
      my $remaining = substr($this->{_buffer}, $this->{_bufferPos});
      my $newlinePos = index($remaining, "\n");
      
      if ($newlinePos >= 0) {
        # Found newline
        $line .= substr($remaining, 0, $newlinePos);
        $this->{_bufferPos} += $newlinePos + 1;
        
        # Remove carriage return if present
        $line =~ s/\r$//;
        
        require System::String;
        return System::String->new($line);
      }
      
      # No newline found, add all remaining buffer to line
      $line .= $remaining;
      $this->{_bufferPos} = length($this->{_buffer});
      
      # Try to read more data
      $this->_FillBuffer();
      
      # If end of stream and we have some data, return it
      if ($this->{_endOfStream} && length($line) > 0) {
        require System::String;
        return System::String->new($line);
      }
      
      # If end of stream and no data, return undef
      last if $this->{_endOfStream};
    }
    
    return undef;
  }
  
  sub ReadToEnd {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamReader')) if $this->{_disposed};
    
    my $result = '';
    
    # Add remaining buffer content
    if ($this->{_bufferPos} < length($this->{_buffer})) {
      $result .= substr($this->{_buffer}, $this->{_bufferPos});
      $this->{_bufferPos} = length($this->{_buffer});
    }
    
    # Read all remaining data from stream
    while (!$this->{_endOfStream}) {
      $this->_FillBuffer();
      if ($this->{_bufferPos} < length($this->{_buffer})) {
        $result .= substr($this->{_buffer}, $this->{_bufferPos});
        $this->{_bufferPos} = length($this->{_buffer});
      }
    }
    
    require System::String;
    return System::String->new($result);
  }
  
  sub Peek {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamReader')) if $this->{_disposed};
    
    return -1 if $this->{_endOfStream} && $this->{_bufferPos} >= length($this->{_buffer});
    
    # If we have characters in buffer, return next one without consuming
    if ($this->{_bufferPos} < length($this->{_buffer})) {
      return ord(substr($this->{_buffer}, $this->{_bufferPos}, 1));
    }
    
    # Need to read more data from stream
    $this->_FillBuffer();
    
    if ($this->{_bufferPos} < length($this->{_buffer})) {
      return ord(substr($this->{_buffer}, $this->{_bufferPos}, 1));
    }
    
    return -1; # End of stream
  }
  
  # Properties
  sub EndOfStream {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamReader')) if $this->{_disposed};
    
    return $this->{_endOfStream} && $this->{_bufferPos} >= length($this->{_buffer});
  }
  
  sub BaseStream {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_stream};
  }
  
  sub Dispose {
    my ($this) = @_;
    return if $this->{_disposed};
    
    if ($this->{_ownsStream} && defined($this->{_stream})) {
      $this->{_stream}->Dispose();
    }
    
    $this->{_stream} = undef;
    $this->{_buffer} = '';
    $this->SUPER::Dispose();
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;