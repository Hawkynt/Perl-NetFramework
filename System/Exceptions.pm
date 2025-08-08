#!/usr/bin/perl

use strict;
use warnings;

use System::Resources;

#region various exceptions following

# thrown when an argument is wrong
package System::ArgumentException;{
  use base 'System::Exception';

  sub new($;$$$) {
    my $class=shift(@_);
    my($message,$paramName,$innerException)=@_;
    
    # special case where second parameter is an inner exception
    if(!$innerException && ref($paramName) && UNIVERSAL::isa($paramName,"System::Exception")) {
      $innerException=$paramName;
      $paramName=undef;
    }
    
    my $this=System::Exception::new($class,$message,$innerException);
    $this->{ParamName}=$paramName;
    return($this);
  }

  sub Message($) {
    my($this)=@_;
    throw(System::NullReferenceException()) unless(defined($this));
    return($this->SUPER::Message().($this->{ParamName}?"\n".sprintf(System::Resources::TX_PARAMETER, $this->{ParamName}):""));
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}  
};
  
# thrown when an argument went null that shouldn't
package System::ArgumentNullException;{
  use base 'System::Exception';

  sub new($;$$) {
    my $class=shift(@_);
    my($p,$m)=@_;
    my $i;
    
    # special case where second parameter is an inner exception
    if($m && ref($m) && UNIVERSAL::isa($m,"System::Exception")) {
      $i=$m;
      $m=$p;
      $p=undef;
    }
    
    my $this=System::Exception::new($class,$m?$m:System::Resources::EX_ARGUMENT_NULL,$i);
    $this->{ParamName}=$p;
    return($this);
  }

  sub Message($) {
    my($this)=@_;
    throw(System::NullReferenceException()) unless(defined($this));
    return($this->SUPER::Message().($this->{ParamName}?"\n".sprintf(System::Resources::TX_PARAMETER, $this->{ParamName}):""));
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when a file was not found
package System::FileNotFoundException;{
  use base 'System::Exception';

  sub new($;$$$) {
    my $class=shift(@_);
    my($m,$f,$i)=@_;
    if(!defined($i) && ref($f) && UNIVERSAL::isa($f,"System::Exception")) {
      $i=$f;
      $f=undef;
    }
    my $this=System::Exception::new($class,$m?$m:$f?sprintf(System::Resources::EX_ASSEMBLY_NOT_FOUND,$f):System::Resources::EX_FILE_NOT_FOUND,$i);
    $this->{FileName}=$f;
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when a directory was not found
package System::DirectoryNotFoundException;{
  use base 'System::Exception';

  sub new($;$$$) {
    my $class=shift(@_);
    my($m,$f,$i)=@_;
    if(!defined($i) && ref($f) && UNIVERSAL::isa($f,"System::Exception")) {
      $i=$f;
      $f=undef;
    }
    my $this=System::Exception::new($class,$m?$m:$f?sprintf(System::Resources::EX_DIR_NOT_FOUND,$f):System::Resources::EX_DIR_NOT_FOUND2,$i);
    $this->{Path}=$f;
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};
# thrown when an i/o error occured
package System::IOException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($ioMessage)=@_;
    my $this=System::Exception::new($class,sprintf(System::Resources::EX_IO,$ioMessage));
    $this->{IOMessage}=$ioMessage;
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when an index accessed out of valid bounds
package System::IndexOutOfBoundsException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($index)=@_;
    my $this=System::Exception::new($class,sprintf(System::Resources::EX_INDEX_OUT_OF_BOUNDS,$index));
    $this->{Index}=$index;
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown on invalid operations
package System::InvalidOperationException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($operationName,$description)=@_;
    my $this=System::Exception::new($class,sprintf(System::Resources::EX_INVALID_OPERATION,$operationName).(defined($description)?': '.$description:''));
    $this->{OperationName}=$operationName;
    $this->{Description}=$description;
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when something was not supported
package System::NotSupportedException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($name)=@_;
    my $this=System::Exception::new($class,sprintf(System::Resources::EX_NOT_SUPPORTED,$name));
    $this->{Name}=$name;
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when something is not (yet) implemented
package System::NotImplementedException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($name)=@_;
    my $this=System::Exception::new($class,sprintf(System::Resources::EX_NOT_IMPLEMENTED,defined($name)?'\''.$name.'\' ':""));
    $this->{Name}=$name;
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when a reference went null that should be called
package System::NullReferenceException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($m,$i)=@_;
    
    my $this=System::Exception::new($class,$m?$m:System::Resources::EX_NULL_REFERENCE,$i);
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when an argument was out of valid ranges
package System::ArgumentOutOfRangeException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($argumentName,$argumentValue)=@_;
    $argumentName //= 'argument';
    $argumentValue //= 'undefined';
    my $this=System::Exception::new($class,sprintf(System::Resources::EX_ARGUMENT_OUT_OF_RANGE,$argumentName,$argumentValue));
    $this->{ArgumentName}=$argumentName;
    $this->{Value}=$argumentValue;
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when a contract failed
package System::ContractException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($m)=@_;
    my $this=System::Exception::new($class,sprintf(System::Resources::EX_CONTRACT,$m));
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when input is not in a correct format
package System::FormatException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($m,$innerException)=@_;
    my $this=System::Exception::new($class,$m||"Input string was not in a correct format.",$innerException);
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when an arithmetic operation results in overflow
package System::OverflowException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($m,$innerException)=@_;
    my $this=System::Exception::new($class,$m||"Arithmetic operation resulted in an overflow.",$innerException);
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when an invalid cast is attempted
package System::InvalidCastException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($m,$innerException)=@_;
    my $this=System::Exception::new($class,$m||"Unable to cast object.",$innerException);
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when an object has been disposed
package System::ObjectDisposedException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($objectName,$m,$innerException)=@_;
    my $this=System::Exception::new($class,$m||"Cannot access a disposed object.",$innerException);
    $this->{ObjectName}=$objectName;
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when application logic error occurs
package System::ApplicationException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($m,$innerException)=@_;
    my $this=System::Exception::new($class,$m||"Application error occurred.",$innerException);
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when semaphore is full
package System::SemaphoreFullException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($m,$innerException)=@_;
    my $this=System::Exception::new($class,$m||"Adding the specified count to the semaphore would cause it to exceed its maximum count.",$innerException);
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when wait handle cannot be opened
package System::WaitHandleCannotBeOpenedException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($m,$innerException)=@_;
    my $this=System::Exception::new($class,$m||"No handle of the given name exists.",$innerException);
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

# thrown when URI format is invalid
package System::UriFormatException;{
  use base 'System::Exception';

  sub new {
    my $class=shift(@_);
    my($m,$innerException)=@_;
    my $this=System::Exception::new($class,$m||"Invalid URI format.",$innerException);
    return($this);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};
#endregion

1;