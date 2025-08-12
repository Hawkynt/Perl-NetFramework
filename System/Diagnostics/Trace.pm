package System::Diagnostics::Trace; {
  use strict;
  use warnings;
  
  use CSharp;
  use System;
  use constant DEBUG=>true;
  
  # Initialize listeners collection
  our @listeners = ();
  our $indent_level = 0;
  our $indent_size = 4;
  our $auto_flush = false;
  
  sub WriteLine {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($text) = @_;
    $text //= '';
    _WriteToListeners($text . "\n") if DEBUG;
  }
  
  sub Write {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($text) = @_;
    $text //= '';
    _WriteToListeners($text) if DEBUG;
  }
  
  sub WriteIf {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($condition, $text) = @_;
    Write($text) if $condition && DEBUG;
  }
  
  sub WriteLineIf {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($condition, $text) = @_;
    WriteLine($text) if $condition && DEBUG;
  }
  
  sub Indent {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    $indent_level++;
  }
  
  sub Unindent {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    $indent_level-- if $indent_level > 0;
  }
  
  sub Flush {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    _FlushListeners();
  }
  
  sub Close {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    _CloseListeners();
  }
  
  sub Assert {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($condition, $message) = @_;
    unless ($condition) {
      $message //= 'Assertion failed';
      WriteLine("ASSERTION FAILED: $message");
      # In .NET this would show a dialog, but we'll just write to trace
    }
  }
  
  # Internal helper methods
  sub _WriteToListeners {
    my ($text) = @_;
    my $indented_text = (' ' x ($indent_level * $indent_size)) . $text;
    
    if (@listeners) {
      for my $listener (@listeners) {
        $listener->Write($indented_text);
      }
    } else {
      # Default behavior: write to console
      Console::Write($indented_text);
    }
    
    _FlushListeners() if $auto_flush;
  }
  
  sub _FlushListeners {
    for my $listener (@listeners) {
      $listener->Flush() if $listener->can('Flush');
    }
  }
  
  sub _CloseListeners {
    for my $listener (@listeners) {
      $listener->Close() if $listener->can('Close');
    }
  }
  
  # Properties
  sub IndentLevel {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($value) = @_;
    if (defined $value) {
      $indent_level = $value >= 0 ? $value : 0;
    }
    return $indent_level;
  }
  
  sub IndentSize {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($value) = @_;
    if (defined $value) {
      $indent_size = $value >= 0 ? $value : 0;
    }
    return $indent_size;
  }
  
  sub AutoFlush {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($value) = @_;
    if (defined $value) {
      $auto_flush = $value ? true : false;
    }
    return $auto_flush;
  }
  
  # Listeners management
  sub AddListener {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($listener) = @_;
    push @listeners, $listener if defined $listener;
  }
  
  sub RemoveListener {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    my ($listener) = @_;
    @listeners = grep { $_ != $listener } @listeners;
  }
  
  sub ClearListeners {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    @listeners = ();
  }
  
  sub GetListeners {
    my $class = shift if @_ && !ref($_[0]) && $_[0] =~ /::Trace$/;
    return @listeners;
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};

1;