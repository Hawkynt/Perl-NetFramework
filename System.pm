package System; {
  use base 'Exporter';
  our @EXPORT=qw(true false null try catch finally throw switch case default);

  use CSharp;
  
  # basic types
  require System::Object;
  require System::Array;
  require System::Exception;
  require System::String;
  require System::TimeSpan;
  require System::Decimal;
  require System::Tuple;

  # exceptions
  require System::Exceptions;

  # complex types
  require System::StringComparer;

  # libraries
  require System::Console;
  require System::Environment;
  
  # interfaces
  require System::IDisposable;
  require System::IEquatable;
  require System::IFormattable;
  require System::IConvertible;
  require System::IComparable;
  
  # enums
  require System::StringComparison;
  require System::StringSplitOptions;
  require System::TypeCode;
};

1;