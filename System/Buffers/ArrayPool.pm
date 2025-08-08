package System::Buffers::ArrayPool; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # ArrayPool<T> - provides array pooling for memory efficiency
  
  # Static shared pools by type
  my %_sharedPools = ();
  
  # Pool configuration
  my $DEFAULT_MAX_ARRAY_LENGTH = 1048576;  # 1MB
  my $DEFAULT_MAX_ARRAYS_PER_BUCKET = 50;
  my @BUCKET_SIZES = (16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576);
  
  sub new {
    my ($class, $maxArrayLength, $maxArraysPerBucket) = @_;
    
    return bless {
      _buckets => {},
      _maxArrayLength => $maxArrayLength // $DEFAULT_MAX_ARRAY_LENGTH,
      _maxArraysPerBucket => $maxArraysPerBucket // $DEFAULT_MAX_ARRAYS_PER_BUCKET,
      _rentedArrays => {},
      _totalRented => 0,
      _totalReturned => 0,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Static method to get shared pool
  sub Shared {
    my ($class, $elementType) = @_;
    $elementType //= 'SCALAR';  # Default element type
    
    if (!exists($_sharedPools{$elementType})) {
      $_sharedPools{$elementType} = $class->new();
    }
    
    return $_sharedPools{$elementType};
  }
  
  # Create a pool with specific configuration
  sub Create {
    my ($class, $maxArrayLength, $maxArraysPerBucket) = @_;
    return $class->new($maxArrayLength, $maxArraysPerBucket);
  }
  
  # Rent an array from the pool
  sub Rent {
    my ($this, $minimumLength) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('minimumLength'))
      if defined($minimumLength) && $minimumLength < 0;
    
    $minimumLength //= 0;
    
    # Find appropriate bucket size
    my $bucketSize = _GetBucketSize($minimumLength);
    
    # Try to get array from bucket
    my $bucket = $this->{_buckets}->{$bucketSize};
    if ($bucket && @$bucket > 0) {
      my $array = pop @$bucket;
      $this->{_rentedArrays}->{$array} = {
        size => $bucketSize,
        rentTime => time(),
      };
      $this->{_totalRented}++;
      return $array;
    }
    
    # Create new array if bucket is empty
    my $newArray = [(undef) x $bucketSize];  # Initialize with undef values
    $this->{_rentedArrays}->{$newArray} = {
      size => $bucketSize,
      rentTime => time(),
    };
    $this->{_totalRented}++;
    
    return $newArray;
  }
  
  # Return an array to the pool
  sub Return {
    my ($this, $array, $clearArray) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('array')) unless defined($array);
    
    $clearArray //= false;
    
    # Validate that this array was rented from this pool
    my $rentInfo = delete $this->{_rentedArrays}->{$array};
    if (!$rentInfo) {
      # Array was not rented from this pool, ignore or warn
      warn "Array was not rented from this ArrayPool" if $ENV{DEBUG};
      return;
    }
    
    my $bucketSize = $rentInfo->{size};
    
    # Clear array if requested
    if ($clearArray) {
      @$array = ((undef) x scalar(@$array));
    }
    
    # Add to appropriate bucket if not full
    $this->{_buckets}->{$bucketSize} //= [];
    my $bucket = $this->{_buckets}->{$bucketSize};
    
    if (scalar(@$bucket) < $this->{_maxArraysPerBucket}) {
      push @$bucket, $array;
      $this->{_totalReturned}++;
    }
    # If bucket is full, just discard the array (let GC handle it)
  }
  
  # Get statistics about pool usage
  sub GetStatistics {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $totalPooled = 0;
    my $totalBuckets = 0;
    
    for my $bucketSize (keys %{$this->{_buckets}}) {
      my $bucket = $this->{_buckets}->{$bucketSize};
      $totalPooled += scalar(@$bucket) if $bucket;
      $totalBuckets++;
    }
    
    return {
      TotalRented => $this->{_totalRented},
      TotalReturned => $this->{_totalReturned},
      CurrentlyRented => scalar(keys %{$this->{_rentedArrays}}),
      TotalPooledArrays => $totalPooled,
      TotalBuckets => $totalBuckets,
      MaxArrayLength => $this->{_maxArrayLength},
      MaxArraysPerBucket => $this->{_maxArraysPerBucket},
    };
  }
  
  # Clear all pools
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_buckets} = {};
    # Don't clear rented arrays tracking - they're still out there
  }
  
  # Trim pool to reduce memory usage
  sub Trim {
    my ($this, $factor) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $factor //= 0.9;  # Trim 10% by default
    throw(System::ArgumentOutOfRangeException->new('factor'))
      if $factor < 0 || $factor > 1;
    
    my $trimmed = 0;
    
    for my $bucketSize (keys %{$this->{_buckets}}) {
      my $bucket = $this->{_buckets}->{$bucketSize};
      next unless $bucket && @$bucket > 0;
      
      my $currentCount = scalar(@$bucket);
      my $targetCount = int($currentCount * $factor);
      
      if ($targetCount < $currentCount) {
        splice @$bucket, $targetCount;
        $trimmed += ($currentCount - $targetCount);
      }
    }
    
    return $trimmed;
  }
  
  # Internal helper methods
  sub _GetBucketSize {
    my ($minimumLength) = @_;
    
    # Find the smallest bucket size that can accommodate the minimum length
    for my $size (@BUCKET_SIZES) {
      return $size if $size >= $minimumLength;
    }
    
    # If no predefined bucket fits, use next power of 2
    my $size = 1;
    while ($size < $minimumLength) {
      $size <<= 1;
    }
    
    return $size;
  }
  
  # Utility methods for typed arrays
  sub RentByteArray {
    my ($this, $minimumLength) = @_;
    my $array = $this->Rent($minimumLength);
    # In Perl, arrays are untyped, but we can document the intent
    return $array;
  }
  
  sub RentIntArray {
    my ($this, $minimumLength) = @_;
    my $array = $this->Rent($minimumLength);
    return $array;
  }
  
  sub RentStringArray {
    my ($this, $minimumLength) = @_;
    my $array = $this->Rent($minimumLength);
    return $array;
  }
  
  # Dispose pattern
  sub Dispose {
    my ($this) = @_;
    $this->Clear();
  }
  
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $stats = $this->GetStatistics();
    return sprintf("ArrayPool (Rented: %d, Returned: %d, Pooled: %d)", 
                  $stats->{TotalRented}, $stats->{TotalReturned}, $stats->{TotalPooledArrays});
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;