package System::Collections::Hashtable; {
  use base 'System::Object','System::Collections::IEnumerable';

  use strict;
  use warnings;

  use CSharp;
  require System::Exceptions;
  
  sub new {
    my($class)=shift;
    my $this={};
    
    # this could be called like
    #  ->new()
    #  ->new(\%hashRef)
    #  ->new(\@arrayRef)
    #  ->new(%hash)
    
    if(scalar(@_)<1) {
      # do nothing
    } elsif(scalar(@_)==1) {
      my ($ref)=@_;
      if(ref($ref) eq 'ARRAY') {
        my $key;
        my $i=0;
        foreach my $item (@{$ref}) {
          if($i==0) {
            $key=$item;
          } else {
            $this->{$key}=$item;
          }
          $i=($i+1)&1;
        }
      } elsif(ref($ref) eq 'HASH') {
        foreach my $key(keys(%{$ref})) {
          $this->{$key}=$ref->{$key};
        }
      } else {
        throw(System::NotSupportedException->new("Need hash or array reference"));
      }
    } else {
      my %hash=@_;
      foreach my $key(keys(%hash)) {
        $this->{$key}=$hash{$key};
      }
    }
    bless $this,ref($class)||$class||__PACKAGE__;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(System::Collections::_KVPEnumerator->new($this));
  }

  sub Keys($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    require System::Linq;
    return($this->Select(sub{$_[0]->Key}));
  }

  sub Values($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    require System::Linq;
    return($this->Select(sub{$_[0]->Value}));
  }

  sub Add($$$) {
    my($this,$key,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentNullException->new('key')) unless(defined($key));
    throw(System::ArgumentException->new('key')) if($this->ContainsKey($key));
    $this->{$key}=$value;
  }

  sub AddOrUpdate($$$) {
    my($this,$key,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentNullException->new('key')) unless(defined($key));
    $this->{$key}=$value;
  }

  sub Clear($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    delete @{$this}{keys(%{$this})};
  }

  sub ContainsKey($$) {
    my($this,$key)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentNullException->new('key')) unless(defined($key));
    return(exists $this->{$key});
  }

  sub ContainsValue($$) {
    my($this,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    foreach my $curVal (values(%{$this})) {
      return(true()) if (System::Object::Equals($value,$curVal,true));
    }
    return(false());
  }

  sub Remove($$) {
    my($this,$key)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentNullException->new('key')) unless(defined($key));
    delete $this->{$key};
  }

  sub Count($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(scalar(keys(%{$this})));
  }

  sub Item($$;$) {
    my($this,$key,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentNullException->new('key')) unless(defined($key));
    
    if(@_ >= 3) {
      # Setter: $hashtable->Item($key, $value)
      $this->{$key} = $value;
      return $value;
    } else {
      # Getter: $hashtable->Item($key)
      return $this->{$key};
    }
  }

  sub Get($$) {
    my($this,$key)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentNullException->new('key')) unless(defined($key));
    return $this->{$key};
  }

  sub Set($$$) {
    my($this,$key,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::ArgumentNullException->new('key')) unless(defined($key));
    $this->{$key} = $value;
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}
  
package System::Collections::_KVPEnumerator; {
  use base 'System::Collections::IEnumerator';
  
  use strict;
  use warnings;

  use CSharp;
  use System::Exceptions;
  use System::Collections::DictionaryEntry;

  sub new {
    my $class=shift(@_);
    my ($hash)=@_;
    my @keys=keys(%{$hash});
    bless {
      _hash=>$hash,
      _array=>\@keys,
      _index=>-1,
      _endIndex=>scalar(@keys)
    },ref($class)||$class||__PACKAGE__;
  }

  sub MoveNext($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    if($this->{_index}<$this->{_endIndex}) {
      $this->{_index}++;
      return($this->{_index}<$this->{_endIndex}?true():false());
    }
    return false;
  }

  sub Reset($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    my @keys=keys(%{$this->{_hash}});
    $this->{_index}=-1;
    $this->{_array}=\@keys;
    $this->{_endIndex}=scalar(@keys);
  }

  sub Current($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::InvalidOperationException->new('Current','Enumeration not started')) if ($this->{_index} < 0);
    throw(System::InvalidOperationException->new('Current','Enumeration already ended')) if ($this->{_index} >= $this->{_endIndex});
    my $key=$this->{_array}->[$this->{_index}];
    my $value=$this->{_hash}->{$key};
    return System::Collections::DictionaryEntry->new($key,$value);
  }

  sub Dispose(){}

}
1;