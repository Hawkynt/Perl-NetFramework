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

  sub Count($) {
    my ($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    my $count=0;
    my $enumerator=$this->GetEnumerator();
    while($enumerator->MoveNext()) {
      $count++;
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

  sub Concat($$) {
    my($this,$collection)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    require System::Linq::ConcatIterator;
    return(new System::Linq::ConcatCollection($this,$collection));
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

  sub Min($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    my $enumerator=$this->GetEnumerator();
    throw(System::InvalidOperationException->new('MoveNext','The collection is empty')) unless($enumerator->MoveNext());
    my $result=$enumerator->Current;
    while($enumerator->MoveNext()) {
      my $current=$enumerator->Current;
      $result=$current if(CSharp::_compare($result,$current)>0);
    }
    return($result);
  }

  sub Max($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    my $enumerator=$this->GetEnumerator();
    throw(System::InvalidOperationException->new('MoveNext','The collection is empty')) unless($enumerator->MoveNext());
    my $result=$enumerator->Current;
    while($enumerator->MoveNext()) {
      my $current=$enumerator->Current;
      $result=$current if(CSharp::_compare($result,$current)<0);
    }
    return($result);
  }

  sub Sum($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    my $enumerator=$this->GetEnumerator();
    throw(System::InvalidOperationException->new('MoveNext','The collection is empty')) unless($enumerator->MoveNext());
    my $result=$enumerator->Current;
    while($enumerator->MoveNext()) {
      $result=CSharp::_add($result,$enumerator->Current);
    }
    return($result);
  }

  sub Average($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    my $enumerator=$this->GetEnumerator();
    throw(System::InvalidOperationException->new('MoveNext','The collection is empty')) unless($enumerator->MoveNext());
    my $count=1;
    my $result=$enumerator->Current;
    while($enumerator->MoveNext()) {
      ++$count;
      $result=CSharp::_add($result,$enumerator->Current);
    }
    return($result/$count);
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
};
package System::Linq::Enumerable;{
  use CSharp;
  
  sub Range($$){
    my($start,$count)=@_;
    require System::Linq::RangeIterator;
    return(new System::Linq::RangeCollection($start,$count));
  }
  
  CSharp::_ShortenPackageName(__PACKAGE__);
};

1;