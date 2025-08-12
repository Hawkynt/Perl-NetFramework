package System::Diagnostics::TraceListener; {
  use base "System::Object";
  
  use strict;
  use warnings;
  use CSharp;
  
  sub new {
    my $class = shift;
    my ($name) = @_;
    return bless {
      name => $name // 'TraceListener',
      indent_level => 0,
      indent_size => 4,
      need_indent => 1
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Virtual methods to be overridden by derived classes
  sub Write {
    my ($this, $message) = @_;
    # Default implementation - should be overridden
    print $message if defined $message;
  }
  
  sub WriteLine {
    my ($this, $message) = @_;
    $this->Write(($message // '') . "\n");
  }
  
  sub Flush {
    my ($this) = @_;
    # Default implementation - can be overridden
    STDOUT->flush() if STDOUT->can('flush');
  }
  
  sub Close {
    my ($this) = @_;
    $this->Flush();
  }
  
  # Properties
  sub Name {
    my ($this, $value) = @_;
    if (defined $value) {
      $this->{name} = $value;
    }
    return $this->{name};
  }
  
  sub IndentLevel {
    my ($this, $value) = @_;
    if (defined $value) {
      $this->{indent_level} = $value >= 0 ? $value : 0;
    }
    return $this->{indent_level};
  }
  
  sub IndentSize {
    my ($this, $value) = @_;
    if (defined $value) {
      $this->{indent_size} = $value >= 0 ? $value : 0;
    }
    return $this->{indent_size};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Console TraceListener - writes to console
package System::Diagnostics::ConsoleTraceListener; {
  use base "System::Diagnostics::TraceListener";
  
  use strict;
  use warnings;
  use CSharp;
  use System;
  
  sub new {
    my $class = shift;
    my $this = System::Diagnostics::TraceListener::new($class, 'ConsoleTraceListener');
    return $this;
  }
  
  sub Write {
    my ($this, $message) = @_;
    Console::Write($message) if defined $message;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Text Writer TraceListener - writes to a file or stream
package System::Diagnostics::TextWriterTraceListener; {
  use base "System::Diagnostics::TraceListener";
  
  use strict;
  use warnings;
  use CSharp;
  
  sub new {
    my $class = shift;
    my ($stream_or_filename, $name) = @_;
    
    my $this = System::Diagnostics::TraceListener::new($class, $name // 'TextWriterTraceListener');
    
    if (ref($stream_or_filename)) {
      # It's a file handle or stream object
      $this->{stream} = $stream_or_filename;
    } elsif (defined $stream_or_filename) {
      # It's a filename
      $this->{filename} = $stream_or_filename;
      if (open(my $fh, '>', $stream_or_filename)) {
        $this->{stream} = $fh;
      } else {
        warn "Could not open trace file '$stream_or_filename': $!";
      }
    }
    
    return $this;
  }
  
  sub Write {
    my ($this, $message) = @_;
    return unless defined $message;
    
    if ($this->{stream}) {
      print {$this->{stream}} $message;
    }
  }
  
  sub Flush {
    my ($this) = @_;
    if ($this->{stream} && $this->{stream}->can('flush')) {
      $this->{stream}->flush();
    }
  }
  
  sub Close {
    my ($this) = @_;
    $this->Flush();
    if ($this->{stream} && $this->{filename}) {
      close($this->{stream});
      undef $this->{stream};
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;