package System::Diagnostics::PerformanceCounter; {
  use base "System::Object";
  
  use strict;
  use warnings;
  use CSharp;
  use Time::HiRes qw(time);
  
  sub new {
    my $class = shift;
    my ($category, $counter, $instance) = @_;
    
    return bless {
      category => $category // 'Custom',
      counter => $counter // 'Counter',
      instance => $instance // '',
      _value => 0,
      _last_sample_time => time(),
      _samples => [],
      _sample_limit => 100
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub CategoryName {
    my ($this, $value) = @_;
    if (defined $value) {
      $this->{category} = $value;
    }
    return $this->{category};
  }
  
  sub CounterName {
    my ($this, $value) = @_;
    if (defined $value) {
      $this->{counter} = $value;
    }
    return $this->{counter};
  }
  
  sub InstanceName {
    my ($this, $value) = @_;
    if (defined $value) {
      $this->{instance} = $value;
    }
    return $this->{instance};
  }
  
  sub RawValue {
    my ($this, $value) = @_;
    if (defined $value) {
      $this->{_value} = $value;
      $this->_AddSample($value);
    }
    return $this->{_value};
  }
  
  # Methods
  sub NextValue {
    my ($this) = @_;
    # For simulation, we'll return the current value
    # In a real implementation, this would read from system performance counters
    return $this->{_value};
  }
  
  sub Increment {
    my ($this, $by) = @_;
    $by //= 1;
    $this->{_value} += $by;
    $this->_AddSample($this->{_value});
    return $this->{_value};
  }
  
  sub Decrement {
    my ($this, $by) = @_;
    $by //= 1;
    $this->{_value} -= $by;
    $this->_AddSample($this->{_value});
    return $this->{_value};
  }
  
  sub Reset {
    my ($this) = @_;
    $this->{_value} = 0;
    $this->{_samples} = [];
    # Don't automatically add a sample on reset - let the first operation add it
  }
  
  # Statistics methods
  sub GetAverageValue {
    my ($this) = @_;
    my $samples = $this->{_samples};
    return 0 unless @$samples;
    
    my $sum = 0;
    $sum += $_ for @$samples;
    return $sum / @$samples;
  }
  
  sub GetMinimumValue {
    my ($this) = @_;
    my $samples = $this->{_samples};
    return 0 unless @$samples;
    
    my $min = $samples->[0];
    for my $sample (@$samples) {
      $min = $sample if $sample < $min;
    }
    return $min;
  }
  
  sub GetMaximumValue {
    my ($this) = @_;
    my $samples = $this->{_samples};
    return 0 unless @$samples;
    
    my $max = $samples->[0];
    for my $sample (@$samples) {
      $max = $sample if $sample > $max;
    }
    return $max;
  }
  
  sub GetSampleCount {
    my ($this) = @_;
    return scalar(@{$this->{_samples}});
  }
  
  # Internal methods
  sub _AddSample {
    my ($this, $value) = @_;
    push @{$this->{_samples}}, $value;
    $this->{_last_sample_time} = time();
    
    # Limit sample history
    if (@{$this->{_samples}} > $this->{_sample_limit}) {
      shift @{$this->{_samples}};
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;