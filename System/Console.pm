package System::Console; {

  use strict;
  use warnings;

  use CSharp;
  require System::Environment;
  require System::Exceptions;
  require System::String;
  require System::IO::TextReader;
  require System::IO::TextWriter;

  # Console - provides console I/O operations

  # Static properties
  my $_in;
  my $_out; 
  my $_error;
  my $_foregroundColor;
  my $_backgroundColor;
  
  # Static methods only - this class cannot be instantiated
  sub new {
    throw(System::InvalidOperationException->new('Console class cannot be instantiated'));
  }

  # Input/Output stream properties
  sub In {
    my ($class) = @_;
    $_in //= System::IO::TextReader->new(\*STDIN);
    return $_in;
  }
  
  sub Out {
    my ($class) = @_;
    $_out //= System::IO::TextWriter->new(\*STDOUT);
    return $_out;
  }
  
  sub Error {
    my ($class) = @_;
    $_error //= System::IO::TextWriter->new(\*STDERR);
    return $_error;
  }

  # Console properties
  sub get_ForegroundColor {
    my ($class) = @_;
    return $_foregroundColor || 'Gray';  # Default
  }
  
  sub set_ForegroundColor {
    my ($class, $color) = @_;
    $_foregroundColor = $color;
    # In a full implementation, this would set actual console colors
  }
  
  sub ForegroundColor {
    my ($class, $value) = @_;
    if (defined($value)) {
      $class->set_ForegroundColor($value);
    } else {
      return $class->get_ForegroundColor();
    }
  }
  
  sub get_BackgroundColor {
    my ($class) = @_;
    return $_backgroundColor || 'Black';  # Default
  }
  
  sub set_BackgroundColor {
    my ($class, $color) = @_;
    $_backgroundColor = $color;
    # In a full implementation, this would set actual console colors
  }
  
  sub BackgroundColor {
    my ($class, $value) = @_;
    if (defined($value)) {
      $class->set_BackgroundColor($value);
    } else {
      return $class->get_BackgroundColor();
    }
  }

  sub get_WindowWidth {
    my ($class) = @_;
    # Try to get terminal width
    my $width = 80;  # Default
    
    if ($^O =~ /win/i) {
      # Windows
      eval {
        my $output = `mode con`;
        if ($output =~ /Columns:\s*(\d+)/) {
          $width = $1;
        }
      };
    } else {
      # Unix-like
      eval {
        my $output = `stty size 2>/dev/null`;
        if ($output =~ /\d+\s+(\d+)/) {
          $width = $1;
        }
      };
      
      # Try tput if stty failed
      unless ($width != 80) {
        eval {
          my $output = `tput cols 2>/dev/null`;
          chomp($output);
          $width = $output if $output && $output =~ /^\d+$/;
        };
      }
    }
    
    return $width;
  }
  
  sub WindowWidth {
    my ($class) = @_;
    return $class->get_WindowWidth();
  }
  
  sub get_WindowHeight {
    my ($class) = @_;
    # Try to get terminal height
    my $height = 25;  # Default
    
    if ($^O =~ /win/i) {
      # Windows
      eval {
        my $output = `mode con`;
        if ($output =~ /Lines:\s*(\d+)/) {
          $height = $1;
        }
      };
    } else {
      # Unix-like
      eval {
        my $output = `stty size 2>/dev/null`;
        if ($output =~ /(\d+)\s+\d+/) {
          $height = $1;
        }
      };
      
      # Try tput if stty failed
      unless ($height != 25) {
        eval {
          my $output = `tput lines 2>/dev/null`;
          chomp($output);
          $height = $output if $output && $output =~ /^\d+$/;
        };
      }
    }
    
    return $height;
  }
  
  sub WindowHeight {
    my ($class) = @_;
    return $class->get_WindowHeight();
  }

  # Input methods
  sub Read {
    my ($class) = @_;
    # Read a single character
    my $char;
    
    if ($^O =~ /win/i) {
      # Windows - would need special handling for single char
      $char = getc(STDIN);
    } else {
      # Unix-like
      eval {
        # Try to read single character without enter
        system('stty cbreak -echo');
        $char = getc(STDIN);
        system('stty -cbreak echo');
      };
      
      if ($@) {
        # Fallback to regular read
        $char = getc(STDIN);
      }
    }
    
    return defined($char) ? ord($char) : -1;
  }

  sub ReadLine {
    my ($class) = @_;
    my $text = <STDIN>;
    chomp($text) if defined($text);
    return System::String->new($text || '');
  }

  sub ReadKey {
    my ($class, $intercept) = @_;
    $intercept //= false;
    
    # Simplified implementation - would return ConsoleKeyInfo in full .NET
    my $char;
    
    if ($^O !~ /win/i) {
      eval {
        system('stty cbreak -echo') unless $intercept;
        $char = getc(STDIN);
        system('stty -cbreak echo') unless $intercept;
      };
    } else {
      $char = getc(STDIN);
    }
    
    return defined($char) ? $char : '';
  }

  # Output methods  
  sub Write {
    my ($class, @args) = @_;
    return if @args < 1;
    
    if (@args == 1) {
      my $value = $args[0];
      if (ref($value) && $value->can('ToString')) {
        print $value->ToString();
      } else {
        print defined($value) ? $value : '';
      }
      return;
    }
    
    # Format string with parameters
    my $format = shift @args;
    my $formatted = System::String->Format($format, @args);
    print $formatted;
  }

  sub WriteLine {
    my ($class, @args) = @_;
    my $flush = $|;
    $| = 1;
    
    if (@args == 0) {
      print System::Environment->NewLine();
    } else {
      $class->Write(@args);
      print System::Environment->NewLine();
    }
    
    $| = $flush;
  }

  sub WriteError {
    my ($class, @args) = @_;
    return if @args < 1;
    
    if (@args == 1) {
      my $value = $args[0];
      if (ref($value) && $value->can('ToString')) {
        print STDERR $value->ToString();
      } else {
        print STDERR defined($value) ? $value : '';
      }
      return;
    }
    
    # Format string with parameters
    my $format = shift @args;
    my $formatted = System::String->Format($format, @args);
    print STDERR $formatted;
  }
  
  sub WriteErrorLine {
    my ($class, @args) = @_;
    my $flush = $|;
    $| = 1;
    
    if (@args == 0) {
      print STDERR System::Environment->NewLine();
    } else {
      $class->WriteError(@args);
      print STDERR System::Environment->NewLine();
    }
    
    $| = $flush;
  }

  # Console control methods
  sub Clear {
    my ($class) = @_;
    
    if ($^O =~ /win/i) {
      # Windows
      system('cls');
    } else {
      # Unix-like
      system('clear') or print "\033[2J\033[H";
    }
  }

  sub Beep {
    my ($class, $frequency, $duration) = @_;
    $frequency //= 800;   # Default frequency
    $duration //= 200;    # Default duration in ms
    
    if ($^O =~ /win/i) {
      # Windows - would need Win32::Console::ANSI or similar
      print "\a";  # Bell character
    } else {
      # Unix-like - try different methods
      eval {
        # Method 1: Use speaker-test if available
        system("timeout ${duration}ms speaker-test -t sine -f $frequency >/dev/null 2>&1");
      } or eval {
        # Method 2: Use pactl/pulseaudio if available
        my $duration_sec = $duration / 1000;
        system("pactl upload-sample /usr/share/sounds/alsa/Front_Left.wav beep-sample >/dev/null 2>&1");
        system("pactl play-sample beep-sample >/dev/null 2>&1");
      } or do {
        # Fallback: Bell character
        print "\a";
      };
    }
  }

  sub ResetColor {
    my ($class) = @_;
    $_foregroundColor = 'Gray';
    $_backgroundColor = 'Black';
    
    # Reset console colors to default
    if ($^O !~ /win/i) {
      print "\033[0m";  # ANSI reset
    }
  }

  sub SetCursorPosition {
    my ($class, $left, $top) = @_;
    throw(System::ArgumentOutOfRangeException->new('left')) if $left < 0;
    throw(System::ArgumentOutOfRangeException->new('top')) if $top < 0;
    
    if ($^O =~ /win/i) {
      # Windows - would need Win32::Console
      # For now, just a placeholder
    } else {
      # Unix-like - ANSI escape sequence
      printf "\033[%d;%dH", $top + 1, $left + 1;
    }
  }

  sub get_CursorLeft {
    my ($class) = @_;
    # Getting cursor position is complex - return 0 as default
    return 0;
  }
  
  sub set_CursorLeft {
    my ($class, $value) = @_;
    $class->SetCursorPosition($value, $class->get_CursorTop());
  }
  
  sub CursorLeft {
    my ($class, $value) = @_;
    if (defined($value)) {
      $class->set_CursorLeft($value);
    } else {
      return $class->get_CursorLeft();
    }
  }
  
  sub get_CursorTop {
    my ($class) = @_;
    # Getting cursor position is complex - return 0 as default
    return 0;
  }
  
  sub set_CursorTop {
    my ($class, $value) = @_;
    $class->SetCursorPosition($class->get_CursorLeft(), $value);
  }
  
  sub CursorTop {
    my ($class, $value) = @_;
    if (defined($value)) {
      $class->set_CursorTop($value);
    } else {
      return $class->get_CursorTop();
    }
  }

  sub get_CursorVisible {
    my ($class) = @_;
    return true;  # Default assumption
  }
  
  sub set_CursorVisible {
    my ($class, $visible) = @_;
    if ($^O !~ /win/i) {
      if ($visible) {
        print "\033[?25h";  # Show cursor
      } else {
        print "\033[?25l";  # Hide cursor
      }
    }
  }
  
  sub CursorVisible {
    my ($class, $value) = @_;
    if (defined($value)) {
      $class->set_CursorVisible($value);
    } else {
      return $class->get_CursorVisible();
    }
  }

  sub get_Title {
    my ($class) = @_;
    return '';  # Default - getting title is platform specific
    # TODO: at least we could remember that we set last
  }
  
  sub set_Title {
    my ($class, $title) = @_;
    if ($^O =~ /win/i) {
      # Windows
      system("title \"$title\"");
    } else {
      # Unix-like - xterm compatible
      print "\033]2;$title\007";
    }
  }
  
  sub Title {
    my ($class, $value) = @_;
    if (defined($value)) {
      $class->set_Title($value);
    } else {
      return $class->get_Title();
    }
  }

  # Utility methods
  sub IsInputRedirected {
    my ($class) = @_;
    return !(-t STDIN);
  }
  
  sub IsOutputRedirected {
    my ($class) = @_;
    return !(-t STDOUT);
  }
  
  sub IsErrorRedirected {
    my ($class) = @_;
    return !(-t STDERR);
  }

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};

1;