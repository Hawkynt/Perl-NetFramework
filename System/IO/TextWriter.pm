package System::IO::TextWriter; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # Abstract base class for text writers
  
  sub new {
    my ($class) = @_;
    return bless {
      _disposed => false,
      _newLine => "\n", # Default line separator
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub NewLine {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (@_ >= 2) {
      # Setter
      $this->{_newLine} = $value // "\n";
      return $value;
    } else {
      # Getter
      return $this->{_newLine};
    }
  }
  
  # Abstract methods - must be implemented by derived classes
  sub Write {
    my ($this, $value) = @_;
    throw(System::NotImplementedException->new('Write method must be implemented by derived class'));
  }
  
  sub Flush {
    my ($this) = @_;
    # Default implementation does nothing
    # Override in derived classes if needed
  }
  
  # Virtual methods with default implementations
  sub WriteLine {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('TextWriter')) if $this->{_disposed};
    
    if (defined($value)) {
      $this->Write($value);
    }
    $this->Write($this->{_newLine});
  }
  
  # Write multiple values
  sub WriteValues {
    my ($this, @values) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('TextWriter')) if $this->{_disposed};
    
    foreach my $value (@values) {
      $this->Write($value) if defined($value);
    }
  }
  
  # Write with format
  sub WriteFormat {
    my ($this, $format, @args) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('TextWriter')) if $this->{_disposed};
    throw(System::ArgumentNullException->new('format')) unless defined($format);
    
    # Simple format implementation
    my $formatted = sprintf($format, @args);
    $this->Write($formatted);
  }
  
  # WriteLine with format
  sub WriteLineFormat {
    my ($this, $format, @args) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('TextWriter')) if $this->{_disposed};
    
    if (defined($format)) {
      $this->WriteFormat($format, @args);
    }
    $this->Write($this->{_newLine});
  }
  
  # Write character
  sub WriteChar {
    my ($this, $char) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('TextWriter')) if $this->{_disposed};
    
    $this->Write($char);
  }
  
  # Write character array
  sub WriteChars {
    my ($this, $chars, $index, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ObjectDisposedException->new('TextWriter')) if $this->{_disposed};
    throw(System::ArgumentNullException->new('chars')) unless defined($chars);
    
    $index //= 0;
    $count //= @$chars - $index;
    
    throw(System::ArgumentOutOfRangeException->new('index')) if $index < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid index/count')) if $index + $count > @$chars;
    
    for my $i ($index..$index+$count-1) {
      $this->Write($chars->[$i]);
    }
  }
  
  sub Close {
    my ($this) = @_;
    $this->Dispose();
  }
  
  sub Dispose {
    my ($this) = @_;
    return if $this->{_disposed};
    $this->Flush();
    $this->{_disposed} = true;
  }
  
  # Static null writer
  my $_nullWriter;
  sub Null {
    $_nullWriter //= System::IO::TextWriter::NullTextWriter->new();
    return $_nullWriter;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Null TextWriter implementation
package System::IO::TextWriter::NullTextWriter; {
  use base 'System::IO::TextWriter';
  
  sub Write {
    my ($this, $value) = @_;
    # Do nothing - discard all output
  }
  
  sub Flush {
    my ($this) = @_;
    # Do nothing
  }
};

1;