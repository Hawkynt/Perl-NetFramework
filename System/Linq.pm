package System::Linq;
package System::Collections::IEnumerable; {
  use strict;
  use warnings;
  
  use CSharp;
  use System::Exceptions;
  use System::Array;
  use System::Object;
  
  sub Contains($$) {
    my($this,$what)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    return($this->Any(sub{System::Object::Equals($_[0],$what,true)}));
  }

  sub Any($;&) {
    my ($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    if (defined($predicate)) {
      my $enumerator=$this->GetEnumerator();
      while($enumerator->MoveNext()) {
        if(&$predicate($enumerator->Current)) {
          return(true);
        }
      }
      return(false);
    } else {
      my $enumerator=$this->GetEnumerator();
      return($enumerator->MoveNext());
    }
  }

  sub All($;&) {
    my ($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::ArgumentNullException->new("predicate")) unless(defined($predicate));
    my $enumerator=$this->GetEnumerator();
    while($enumerator->MoveNext()) {
      return(false) unless(&$predicate($enumerator->Current));
    }
    return(true);
  }

  sub First($;&){
    my ($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    if (defined($predicate)) {
      my $enumerator=$this->GetEnumerator();
      while($enumerator->MoveNext()) {
        my $current=$enumerator->Current;
        return($current) if(&$predicate($current));
      }
      throw(System::InvalidOperationException->new('First','Sequence contains no elements'));
    } else {
      my $enumerator=$this->GetEnumerator();
      return ($enumerator->Current) if ($enumerator->MoveNext());
      throw(System::InvalidOperationException->new('First','Sequence contains no elements'));
    }
  }

  sub FirstOrDefault($;&$){
    my ($this,$predicate,$defaultValue)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    if (defined($predicate)) {
      my $enumerator=$this->GetEnumerator();
      while($enumerator->MoveNext()) {
        my $current=$enumerator->Current;
        return($current) if(&$predicate($current));
      }
      return($defaultValue);
    } else {
      my $enumerator=$this->GetEnumerator();
      return ($enumerator->Current) if ($enumerator->MoveNext());
      return($defaultValue);
    }
  }

  sub Count($;$) {
    my ($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    my $count=0;
    my $enumerator=$this->GetEnumerator();
    
    if(defined($predicate)) {
      # Count with predicate - filter and count
      while($enumerator->MoveNext()) {
        my $current=$enumerator->Current;
        $count++ if(&{$predicate}($current));
      }
    } else {
      # Count without predicate - count all
      while($enumerator->MoveNext()) {
        $count++;
      }
    }
    return($count);
  }

  sub Select($&) {
    my($this,$selector)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::SelectIterator;
    return(new System::Linq::SelectCollection($this,$selector));
  }

  sub Where($&) {
    my($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::WhereIterator;
    return(new System::Linq::WhereCollection($this,$predicate));
  }

  sub OrderBy($;&) {
    my($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::OrderByIterator;
    return(new System::Linq::OrderByCollection($this,0,$predicate));
  }


  sub ToArray($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    my $enumerator=$this->GetEnumerator();
    my @result=();
    while($enumerator->MoveNext()) {
      push(@result,$enumerator->Current);
    }
    return(new System::Array(@result));
  }



  sub ElementAt($$) {
    my($this,$index)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::IndexOutOfBoundsException->new($index)) if ($index<0);
    my $enumerator=$this->GetEnumerator();
    my $i=0;
    while($i++<=$index) {
      throw(System::IndexOutOfBoundsException->new($index)) unless($enumerator->MoveNext());
    }
    return($enumerator->Current);
  }

  sub Distinct($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::DistinctIterator;
    return(new System::Linq::DistinctCollection($this));
  }

  sub DefaultIfEmpty($;$) {
    my($this,$defaultValue)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::DefaultIfEmptyIterator;
    return(new System::Linq::DefaultIfEmptyCollection($this,$defaultValue));
  }

  sub ToDictionary($$$) {
    my($this,$keyFactory,$valueFactory)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::ArgumentNullException->new("keyFactory")) unless(defined($keyFactory));
    throw(System::ArgumentNullException->new("valueFactory")) unless(defined($valueFactory));
    my $enumerator=$this->GetEnumerator();
    require System::Collections::Hashtable;
    my $result=System::Collections::Hashtable->new();
    while($enumerator->MoveNext()) {
      my $current=$enumerator->Current;
      my $key=&{$keyFactory}($current);
      my $value=&{$valueFactory}($current);
      $result->Add($key,$value);
    }
    return($result);
  }

  sub Last($;$){
    my($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    my $enumerator=$this->GetEnumerator();
    my $last;
    my $isValid=false;
    while($enumerator->MoveNext()) {
      my $current=$enumerator->Current;
      next if(defined($predicate) && !&$predicate($current));
      $isValid=true;
      $last=$current;
    }
    throw(System::InvalidOperationException->new('First','Sequence contains no elements'))unless($isValid);
    return($last);
  }
  
  sub GroupBy($$){
    my($this,$selector)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::GroupByIterator;
    return(new System::Linq::GroupByCollection($this,$selector));
  }
    
  sub OrderByDescending($$){
    my($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::OrderByIterator;
    return(new System::Linq::OrderByCollection($this,1,$predicate));
  }
    
  sub SelectMany($;$){
    my($this,$selector)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::SelectManyIterator;
    return(new System::Linq::SelectManyCollection($this,$selector));
  }
  
  sub Take($$){
    my($this,$count)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::TakeIterator;
    return(new System::Linq::TakeCollection($this,$count));
  }
  
  sub TakeWhile($$){
    my($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::ArgumentNullException->new("predicate")) unless (defined($predicate));
    require System::Linq::TakeWhileIterator;
    return(new System::Linq::TakeWhileCollection($this,$predicate));
  }
  
  sub Skip($$){
    my($this,$count)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::SkipIterator;
    return(new System::Linq::SkipCollection($this,$count));
  }
    
  sub SkipWhile($$){
    my($this,$predicate)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::ArgumentNullException->new("predicate")) unless (defined($predicate));
    require System::Linq::SkipWhileIterator;
    return(new System::Linq::SkipWhileCollection($this,$predicate));
  }

  # Mathematical operators
  sub Sum($;$) {
    my ($this, $selector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $sum = 0;
    my $enumerator = $this->GetEnumerator();
    
    if (defined($selector)) {
      while ($enumerator->MoveNext()) {
        my $value = &{$selector}($enumerator->Current);
        $sum += $value;
      }
    } else {
      while ($enumerator->MoveNext()) {
        $sum += $enumerator->Current;
      }
    }
    return $sum;
  }

  sub Average($;$) {
    my ($this, $selector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $sum = 0;
    my $count = 0;
    my $enumerator = $this->GetEnumerator();
    
    if (defined($selector)) {
      while ($enumerator->MoveNext()) {
        my $value = &{$selector}($enumerator->Current);
        $sum += $value;
        $count++;
      }
    } else {
      while ($enumerator->MoveNext()) {
        $sum += $enumerator->Current;
        $count++;
      }
    }
    
    throw(System::InvalidOperationException->new('Sequence contains no elements')) if $count == 0;
    return $sum / $count;
  }

  sub Min($;$) {
    my ($this, $selector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $enumerator = $this->GetEnumerator();
    throw(System::InvalidOperationException->new('Sequence contains no elements')) 
      unless $enumerator->MoveNext();
    
    my $min = defined($selector) ? &{$selector}($enumerator->Current) : $enumerator->Current;
    
    while ($enumerator->MoveNext()) {
      my $value = defined($selector) ? &{$selector}($enumerator->Current) : $enumerator->Current;
      # Use proper comparison (numeric vs string)
      if (_IsNumeric($value) && _IsNumeric($min)) {
        $min = $value if $value < $min;
      } else {
        $min = $value if "$value" lt "$min";
      }
    }
    return $min;
  }

  sub Max($;$) {
    my ($this, $selector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $enumerator = $this->GetEnumerator();
    throw(System::InvalidOperationException->new('Sequence contains no elements')) 
      unless $enumerator->MoveNext();
    
    my $max = defined($selector) ? &{$selector}($enumerator->Current) : $enumerator->Current;
    
    while ($enumerator->MoveNext()) {
      my $value = defined($selector) ? &{$selector}($enumerator->Current) : $enumerator->Current;
      # Use proper comparison (numeric vs string)
      if (_IsNumeric($value) && _IsNumeric($max)) {
        $max = $value if $value > $max;
      } else {
        $max = $value if "$value" gt "$max";
      }
    }
    return $max;
  }

  # Helper method to check if a value is numeric
  sub _IsNumeric {
    my ($value) = @_;
    return 0 unless defined($value);
    return $value =~ /^-?\d+\.?\d*$/;
  }

  # Modern LINQ operators (MinBy, MaxBy, etc.)
  sub MinBy($$) {
    my ($this, $keySelector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('keySelector')) unless defined($keySelector);
    
    my $enumerator = $this->GetEnumerator();
    throw(System::InvalidOperationException->new('Sequence contains no elements'))
      unless $enumerator->MoveNext();
    
    my $minElement = $enumerator->Current;
    my $minKey = &{$keySelector}($minElement);
    
    while ($enumerator->MoveNext()) {
      my $current = $enumerator->Current;
      my $currentKey = &{$keySelector}($current);
      
      # Use proper comparison (numeric vs string)
      if (_IsNumeric($currentKey) && _IsNumeric($minKey)) {
        if ($currentKey < $minKey) {
          $minElement = $current;
          $minKey = $currentKey;
        }
      } else {
        if ("$currentKey" lt "$minKey") {
          $minElement = $current;
          $minKey = $currentKey;
        }
      }
    }
    
    return $minElement;
  }

  sub MaxBy($$) {
    my ($this, $keySelector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('keySelector')) unless defined($keySelector);
    
    my $enumerator = $this->GetEnumerator();
    throw(System::InvalidOperationException->new('Sequence contains no elements'))
      unless $enumerator->MoveNext();
    
    my $maxElement = $enumerator->Current;
    my $maxKey = &{$keySelector}($maxElement);
    
    while ($enumerator->MoveNext()) {
      my $current = $enumerator->Current;
      my $currentKey = &{$keySelector}($current);
      
      # Use proper comparison (numeric vs string)
      if (_IsNumeric($currentKey) && _IsNumeric($maxKey)) {
        if ($currentKey > $maxKey) {
          $maxElement = $current;
          $maxKey = $currentKey;
        }
      } else {
        if ("$currentKey" gt "$maxKey") {
          $maxElement = $current;
          $maxKey = $currentKey;
        }
      }
    }
    
    return $maxElement;
  }

  sub DistinctBy($$) {
    my ($this, $keySelector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('keySelector')) unless defined($keySelector);
    
    require System::Linq::DistinctByIterator;
    return System::Linq::DistinctByCollection->new($this, $keySelector);
  }

  sub CountBy($$) {
    my ($this, $keySelector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('keySelector')) unless defined($keySelector);
    
    # CountBy is inherently eager as it needs to count all items
    require System::Array;
    my %counts;
    
    my $enumerator = $this->GetEnumerator();
    while ($enumerator->MoveNext()) {
      my $element = $enumerator->Current;
      my $key = &{$keySelector}($element);
      my $keyStr = defined($key) ? "$key" : "";
      $counts{$keyStr}++;
    }
    
    my @result;
    for my $key (keys %counts) {
      push @result, { Key => $key, Count => $counts{$key} };
    }
    
    return System::Array->new(@result);
  }

  sub Chunk($$) {
    my ($this, $size) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('size')) if $size <= 0;
    
    require System::Linq::ChunkIterator;
    return System::Linq::ChunkCollection->new($this, $size);
  }

  sub Index($) {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Linq::IndexIterator;
    return System::Linq::IndexCollection->new($this);
  }

  sub TryGetNonEnumeratedCount($) {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # For System::Array, we can get count without enumeration
    if ($this->isa('System::Array')) {
      return ($this->Length(), true);
    }
    
    # For other collections, we'd need to enumerate
    return (0, false);
  }

  # Additional aggregation methods
  sub LongCount($;$) {
    my ($this, $predicate) = @_;
    # Same as Count but conceptually for larger numbers
    return $this->Count($predicate);
  }

  sub ElementAtOrDefault($$;$) {
    my ($this, $index, $defaultValue) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('index')) if $index < 0;
    
    my $enumerator = $this->GetEnumerator();
    my $currentIndex = 0;
    
    while ($enumerator->MoveNext()) {
      return $enumerator->Current if $currentIndex == $index;
      $currentIndex++;
    }
    
    return $defaultValue;
  }

  # Append and Prepend (modern operators)
  sub Append($$) {
    my ($this, $element) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Linq::AppendIterator;
    return System::Linq::AppendCollection->new($this, $element);
  }

  sub Prepend($$) {
    my ($this, $element) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Linq::PrependIterator;
    return System::Linq::PrependCollection->new($this, $element);
  }

  # Set operations
  sub Union($$) {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    
    require System::Array;
    my @seen;
    my @result;
    
    # Add items from first collection
    my $enumerator1 = $this->GetEnumerator();
    while ($enumerator1->MoveNext()) {
      my $item = $enumerator1->Current;
      my $itemStr = defined($item) ? "$item" : "";
      unless (grep { (defined($_) ? "$_" : "") eq $itemStr } @seen) {
        push @seen, $item;
        push @result, $item;
      }
    }
    
    # Add items from second collection
    my $enumerator2 = $other->GetEnumerator();
    while ($enumerator2->MoveNext()) {
      my $item = $enumerator2->Current;
      my $itemStr = defined($item) ? "$item" : "";
      unless (grep { (defined($_) ? "$_" : "") eq $itemStr } @seen) {
        push @seen, $item;
        push @result, $item;
      }
    }
    
    return System::Array->new(@result);
  }

  sub Intersect($$) {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    
    require System::Array;
    my @other_items;
    my @result;
    
    # Collect items from second collection
    my $enumerator2 = $other->GetEnumerator();
    while ($enumerator2->MoveNext()) {
      push @other_items, $enumerator2->Current;
    }
    
    # Find items from first collection that exist in second
    my @seen;
    my $enumerator1 = $this->GetEnumerator();
    while ($enumerator1->MoveNext()) {
      my $item = $enumerator1->Current;
      my $itemStr = defined($item) ? "$item" : "";
      
      # Check if already seen
      next if grep { (defined($_) ? "$_" : "") eq $itemStr } @seen;
      
      # Check if exists in other collection
      if (grep { (defined($_) ? "$_" : "") eq $itemStr } @other_items) {
        push @seen, $item;
        push @result, $item;
      }
    }
    
    return System::Array->new(@result);
  }

  sub Except($$) {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    
    require System::Array;
    my @other_items;
    my @result;
    
    # Collect items from second collection
    my $enumerator2 = $other->GetEnumerator();
    while ($enumerator2->MoveNext()) {
      push @other_items, $enumerator2->Current;
    }
    
    # Find items from first collection that don't exist in second
    my @seen;
    my $enumerator1 = $this->GetEnumerator();
    while ($enumerator1->MoveNext()) {
      my $item = $enumerator1->Current;
      my $itemStr = defined($item) ? "$item" : "";
      
      # Check if already seen
      next if grep { (defined($_) ? "$_" : "") eq $itemStr } @seen;
      
      # Check if doesn't exist in other collection
      unless (grep { (defined($_) ? "$_" : "") eq $itemStr } @other_items) {
        push @seen, $item;
        push @result, $item;
      }
    }
    
    return System::Array->new(@result);
  }

  sub Concat($$) {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    
    require System::Linq::ConcatIterator;
    return System::Linq::ConcatCollection->new($this, $other);
  }

  sub Aggregate($$$) {
    my ($this, $seed, $func) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('func')) unless defined($func);
    
    my $accumulator = $seed;
    my $enumerator = $this->GetEnumerator();
    
    while ($enumerator->MoveNext()) {
      $accumulator = &{$func}($accumulator, $enumerator->Current);
    }
    
    return $accumulator;
  }

  # Join operations
  sub Join($$$$$) {
    my ($this, $inner, $outerKeySelector, $innerKeySelector, $resultSelector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('inner')) unless defined($inner);
    throw(System::ArgumentNullException->new('outerKeySelector')) unless defined($outerKeySelector);
    throw(System::ArgumentNullException->new('innerKeySelector')) unless defined($innerKeySelector);
    throw(System::ArgumentNullException->new('resultSelector')) unless defined($resultSelector);
    
    require System::Linq::JoinIterator;
    return System::Linq::JoinCollection->new($this, $inner, $outerKeySelector, $innerKeySelector, $resultSelector);
  }

  sub GroupJoin($$$$$) {
    my ($this, $inner, $outerKeySelector, $innerKeySelector, $resultSelector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('inner')) unless defined($inner);
    throw(System::ArgumentNullException->new('outerKeySelector')) unless defined($outerKeySelector);
    throw(System::ArgumentNullException->new('innerKeySelector')) unless defined($innerKeySelector);
    throw(System::ArgumentNullException->new('resultSelector')) unless defined($resultSelector);
    
    require System::Linq::GroupJoinIterator;
    return System::Linq::GroupJoinCollection->new($this, $inner, $outerKeySelector, $innerKeySelector, $resultSelector);
  }

  # Single element operations
  sub Single($;$) {
    my ($this, $predicate) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $enumerator = $this->GetEnumerator();
    my $found;
    my $hasFound = false;
    
    if (defined($predicate)) {
      while ($enumerator->MoveNext()) {
        my $current = $enumerator->Current;
        if (&{$predicate}($current)) {
          throw(System::InvalidOperationException->new('Sequence contains more than one matching element'))
            if $hasFound;
          $found = $current;
          $hasFound = true;
        }
      }
    } else {
      if ($enumerator->MoveNext()) {
        $found = $enumerator->Current;
        $hasFound = true;
        throw(System::InvalidOperationException->new('Sequence contains more than one element'))
          if $enumerator->MoveNext();
      }
    }
    
    throw(System::InvalidOperationException->new('Sequence contains no matching elements'))
      unless $hasFound;
    return $found;
  }

  sub SingleOrDefault($;$$) {
    my ($this, $predicate, $defaultValue) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $enumerator = $this->GetEnumerator();
    my $found;
    my $hasFound = false;
    
    if (defined($predicate)) {
      while ($enumerator->MoveNext()) {
        my $current = $enumerator->Current;
        if (&{$predicate}($current)) {
          return $defaultValue if $hasFound; # More than one matching element
          $found = $current;
          $hasFound = true;
        }
      }
    } else {
      if ($enumerator->MoveNext()) {
        $found = $enumerator->Current;
        $hasFound = true;
        return $defaultValue if $enumerator->MoveNext(); # More than one element
      }
    }
    
    return $hasFound ? $found : $defaultValue;
  }

  sub LastOrDefault($;$$) {
    my ($this, $predicate, $defaultValue) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $enumerator = $this->GetEnumerator();
    my $last = $defaultValue;
    my $hasFound = false;
    
    while ($enumerator->MoveNext()) {
      my $current = $enumerator->Current;
      if (!defined($predicate) || &{$predicate}($current)) {
        $last = $current;
        $hasFound = true;
      }
    }
    
    return $last;
  }

  # Sequence operations
  sub Reverse($) {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    require System::Linq::ReverseIterator;
    return System::Linq::ReverseCollection->new($this);
  }

  sub SequenceEqual($$;$) {
    my ($this, $other, $comparer) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    
    my $enumerator1 = $this->GetEnumerator();
    my $enumerator2 = $other->GetEnumerator();
    
    while (1) {
      my $hasNext1 = $enumerator1->MoveNext();
      my $hasNext2 = $enumerator2->MoveNext();
      
      # Different lengths
      return false if $hasNext1 != $hasNext2;
      
      # Both ended - sequences are equal
      return true unless $hasNext1;
      
      # Compare current elements
      my $item1 = $enumerator1->Current;
      my $item2 = $enumerator2->Current;
      
      if (defined($comparer)) {
        return false unless &{$comparer}($item1, $item2);
      } else {
        # Default equality comparison
        my $str1 = defined($item1) ? "$item1" : "";
        my $str2 = defined($item2) ? "$item2" : "";
        return false unless $str1 eq $str2;
      }
    }
  }

  sub Zip($$$) {
    my ($this, $other, $resultSelector) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('other')) unless defined($other);
    throw(System::ArgumentNullException->new('resultSelector')) unless defined($resultSelector);
    
    require System::Linq::ZipIterator;
    return System::Linq::ZipCollection->new($this, $other, $resultSelector);
  }

  # Type operations
  sub OfType($$) {
    my ($this, $typeName) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('typeName')) unless defined($typeName);
    
    require System::Linq::OfTypeIterator;
    return System::Linq::OfTypeCollection->new($this, $typeName);
  }

  sub Cast($$) {
    my ($this, $typeName) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('typeName')) unless defined($typeName);
    
    require System::Linq::CastIterator;
    return System::Linq::CastCollection->new($this, $typeName);
  }
};
package System::Linq::Enumerable;{
  use CSharp;
  
  sub Range($$){
    my($start,$count)=@_;
    require System::Linq::RangeIterator;
    return(new System::Linq::RangeCollection($start,$count));
  }
  
  sub Empty($) {
    my ($typeName) = @_;
    require System::Array;
    return System::Array->new();
  }
  
  sub Repeat($$$) {
    my ($element, $count, $typeName) = @_;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    
    require System::Array;
    my @result = ($element) x $count;
    return System::Array->new(@result);
  }
  
  CSharp::_ShortenPackageName(__PACKAGE__);
};

1;