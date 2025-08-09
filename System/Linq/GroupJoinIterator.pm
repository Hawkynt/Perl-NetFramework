package System::Linq::GroupJoinCollection; {
  use base 'System::Collections::IEnumerable';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Linq::GroupJoinEnumerator;
  
  sub new {
    my ($class, $outer, $inner, $outerKeySelector, $innerKeySelector, $resultSelector) = @_;
    
    return bless {
      _outer => $outer,
      _inner => $inner,
      _outerKeySelector => $outerKeySelector,
      _innerKeySelector => $innerKeySelector,
      _resultSelector => $resultSelector,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  sub GetEnumerator {
    my ($this) = @_;
    return System::Linq::GroupJoinEnumerator->new(
      $this->{_outer}, 
      $this->{_inner}, 
      $this->{_outerKeySelector}, 
      $this->{_innerKeySelector}, 
      $this->{_resultSelector}
    );
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# GroupJoinEnumerator is in separate file System::Linq::GroupJoinEnumerator.pm

1;