package System::IO::StreamWriter; {
  use base 'System::IO::TextWriter';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::IO::TextWriter;
  require System::IO::Stream;
  
  # Stream-based text writer
  
  sub new {
    my ($class, $stream_or_path, $append, $encoding) = @_;
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
      my $mode = $append ? 6 : 2; # Append or Create
      $this->{_stream} = System::IO::FileStream->new($stream_or_path, $mode, 2); # Write access
      $this->{_ownsStream} = true;
    }
    
    throw(System::ArgumentException->new('Stream must support writing')) unless $this->{_stream}->CanWrite();
    
    # Set up encoding (simplified - just UTF-8 for now)
    $this->{_encoding} = $encoding // 'utf8';
    $this->{_autoFlush} = false;
    
    return $this;
  }
  
  # Properties
  sub AutoFlush {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (@_ >= 2) {
      # Setter
      $this->{_autoFlush} = $value ? true : false;
      if ($this->{_autoFlush}) {
        $this->Flush();
      }
      return $value;
    } else {
      # Getter
      return $this->{_autoFlush};
    }
  }
  
  sub BaseStream {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_stream};
  }
  
  # Write methods
  sub Write {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamWriter')) if $this->{_disposed};
    
    return unless defined($value);
    
    # Convert value to string if needed
    my $text;
    if (ref($value) && $value->can('ToString')) {
      $text = $value->ToString();
    } else {
      $text = "$value";
    }
    
    # Convert string to bytes (simplified UTF-8 encoding)
    my @bytes = map { ord($_) } split //, $text;
    
    # Write to stream
    $this->{_stream}->Write(\@bytes, 0, scalar(@bytes));
    
    # Auto-flush if enabled
    if ($this->{_autoFlush}) {
      $this->Flush();
    }
  }
  
  sub WriteLine {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamWriter')) if $this->{_disposed};
    
    if (defined($value)) {
      $this->Write($value);
    }
    $this->Write($this->{_newLine});
  }
  
  sub WriteChar {
    my ($this, $char) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamWriter')) if $this->{_disposed};
    
    return unless defined($char);
    
    # Convert character to byte
    my @bytes = (ord($char));
    $this->{_stream}->Write(\@bytes, 0, 1);
    
    # Auto-flush if enabled
    if ($this->{_autoFlush}) {
      $this->Flush();
    }
  }
  
  sub WriteChars {
    my ($this, $chars, $index, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamWriter')) if $this->{_disposed};
    throw(System::ArgumentNullException->new('chars')) unless defined($chars);
    
    $index //= 0;
    $count //= @$chars - $index;
    
    throw(System::ArgumentOutOfRangeException->new('index')) if $index < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid index/count')) if $index + $count > @$chars;
    
    return if $count == 0;
    
    # Convert characters to bytes
    my @bytes = ();
    for my $i ($index..$index+$count-1) {
      push @bytes, ord($chars->[$i]);
    }
    
    $this->{_stream}->Write(\@bytes, 0, scalar(@bytes));
    
    # Auto-flush if enabled
    if ($this->{_autoFlush}) {
      $this->Flush();
    }
  }
  
  # Write with formatting
  sub WriteFormat {
    my ($this, $format, @args) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamWriter')) if $this->{_disposed};
    throw(System::ArgumentNullException->new('format')) unless defined($format);
    
    # Simple format implementation using sprintf
    my $formatted = sprintf($format, @args);
    $this->Write($formatted);
  }
  
  sub WriteLineFormat {
    my ($this, $format, @args) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamWriter')) if $this->{_disposed};
    
    if (defined($format)) {
      $this->WriteFormat($format, @args);
    }
    $this->Write($this->{_newLine});
  }
  
  sub Flush {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('StreamWriter')) if $this->{_disposed};
    
    if (defined($this->{_stream})) {
      $this->{_stream}->Flush();
    }
  }
  
  sub Dispose {
    my ($this) = @_;
    return if $this->{_disposed};
    
    # Flush any remaining data if stream is still available
    if (defined($this->{_stream})) {
      eval { $this->Flush(); };
    }
    
    if ($this->{_ownsStream} && defined($this->{_stream})) {
      $this->{_stream}->Dispose();
    }
    
    $this->{_stream} = undef;
    $this->SUPER::Dispose();
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;