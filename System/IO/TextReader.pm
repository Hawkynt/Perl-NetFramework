package System::IO::TextReader; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # Abstract base class for text readers
  
  sub new {
    my ($class) = @_;
    return bless {
      _disposed => false,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Abstract methods - must be implemented by derived classes
  sub Read {
    my ($this, $buffer, $index, $count) = @_;
    throw(System::NotImplementedException->new('Read method must be implemented by derived class'));
  }
  
  sub ReadLine {
    my ($this) = @_;
    throw(System::NotImplementedException->new('ReadLine method must be implemented by derived class'));
  }
  
  sub ReadToEnd {
    my ($this) = @_;
    throw(System::NotImplementedException->new('ReadToEnd method must be implemented by derived class'));
  }
  
  # Virtual methods with default implementations
  sub ReadBlock {
    my ($this, $buffer, $index, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('TextReader')) if $this->{_disposed};
    throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
    throw(System::ArgumentOutOfRangeException->new('index')) if $index < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid index/count')) if $index + $count > @$buffer;
    
    my $totalRead = 0;
    while ($totalRead < $count) {
      my $read = $this->Read($buffer, $index + $totalRead, $count - $totalRead);
      last if $read == 0; # End of stream
      $totalRead += $read;
    }
    
    return $totalRead;
  }
  
  # Convenience method - reads a single character
  sub ReadChar {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('TextReader')) if $this->{_disposed};
    
    my @buffer = ('');
    my $read = $this->Read(\@buffer, 0, 1);
    return $read == 0 ? undef : $buffer[0];
  }
  
  # Read all lines and return as array
  sub ReadLines {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('TextReader')) if $this->{_disposed};
    
    my @lines = ();
    my $line;
    while (defined($line = $this->ReadLine())) {
      push @lines, $line;
    }
    
    require System::Array;
    return System::Array->new(@lines);
  }
  
  # Peek at next character without consuming it
  sub Peek {
    my ($this) = @_;
    # Default implementation returns -1 (not supported)
    return -1;
  }
  
  sub Close {
    my ($this) = @_;
    $this->Dispose();
  }
  
  sub Dispose {
    my ($this) = @_;
    return if $this->{_disposed};
    $this->{_disposed} = true;
  }
  
  # Static null reader
  my $_nullReader;
  sub Null {
    $_nullReader //= System::IO::TextReader::NullTextReader->new();
    return $_nullReader;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Null TextReader implementation
package System::IO::TextReader::NullTextReader; {
  use base 'System::IO::TextReader';
  
  sub Read {
    my ($this, $buffer, $index, $count) = @_;
    return 0; # Always return 0 (end of stream)
  }
  
  sub ReadLine {
    my ($this) = @_;
    return undef; # Always return undef (end of stream)
  }
  
  sub ReadToEnd {
    my ($this) = @_;
    require System::String;
    return System::String->new(''); # Always return empty string
  }
  
  sub Peek {
    my ($this) = @_;
    return -1; # Always return -1 (end of stream)
  }
};

1;