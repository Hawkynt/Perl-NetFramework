package System::StringComparison; {
  use CSharp;
  
  use constant {
    CurrentCulture=>0,
    CurrentCultureIgnoreCase=>1,
    InvariantCulture=>2,
    InvariantCultureIgnoreCase=>3,
    Ordinal=>4,
    OrdinalIgnoreCase=>5,
  };
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
};

1;