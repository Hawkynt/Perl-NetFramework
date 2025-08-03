# Perl-NetFramework

[![License](https://img.shields.io/badge/License-GPL_3.0-blue)](https://licenses.nuget.org/GPL-3.0-or-later)
![Language](https://img.shields.io/github/languages/top/Hawkynt/Perl-NetFramework?color=purple)

> A comprehensive clone of the .NET Framework Base Class Library (BCL) implemented in pure Perl.

## Overview

Perl-NetFramework brings the familiar .NET programming model to Perl, providing a rich set of classes, interfaces, and language constructs that mirror the .NET Framework's Base Class Library. This project enables developers to write Perl code using .NET-style patterns, object-oriented design, and familiar APIs.

## Features

### Core Language Constructs
- **Exception Handling**: Complete try/catch/finally implementation with custom exception types
- **Switch Statements**: C#-style switch/case/default constructs
- **Constants**: `true`, `false`, and `null` constants for cleaner code
- **Type System**: Comprehensive object-oriented hierarchy starting from `System::Object`

### Collections and LINQ
- **Collections**: Hashtable, Array, and enumerable collections with .NET-compatible APIs
- **LINQ-to-Objects**: Full implementation including Select, Where, OrderBy, GroupBy, and more
- **Lazy Evaluation**: Iterator-based implementation for memory-efficient operations
- **Lambda Support**: Perl closures used as lambda expressions in LINQ operations

### String Processing
- **System::String**: Feature-rich string class with familiar .NET methods
- **String Operations**: Contains, IndexOf, Replace, Split, Trim, and case conversion
- **Formatting**: String.Format with placeholder and formatting support
- **Comparison**: Culture-aware and ordinal string comparison options

### I/O and File System
- **File Operations**: System::IO::File for file manipulation
- **Directory Operations**: System::IO::Directory for folder management  
- **Path Utilities**: System::IO::Path for path manipulation and validation

### Mathematical Operations
- **System::Math**: Mathematical functions and constants
- **System::Decimal**: High-precision decimal arithmetic
- **Numeric Types**: Type-safe numeric operations with automatic conversion

### Threading Support
- **System::Threading::Thread**: Basic threading capabilities
- **Synchronization**: Thread-safe operations and coordination

### GUI Components
- **MessageBox**: Windows-style message boxes using Tk backend
- **Dialog Results**: Standard dialog button and result handling
- **Icons**: Support for standard system icons (Error, Warning, Information, Question)

### Diagnostics and Debugging
- **System::Diagnostics::Stopwatch**: High-precision timing
- **System::Diagnostics::Trace**: Debug and trace output
- **Contracts**: Code contract assertions for defensive programming

### Directory Services
- **Active Directory**: User and group management through System::DirectoryServices
- **Authentication**: Principal-based authentication and authorization

## Project Structure

```
Perl-NetFramework/
├── System.pm                    # Main namespace entry point
├── CSharp.pm                    # Core language constructs and utilities
├── Filter/                      # Alternative implementations
│   └── CSharp.pm               
└── System/                      # .NET BCL namespace hierarchy
    ├── Object.pm                # Base object class
    ├── String.pm                # String manipulation
    ├── Array.pm                 # Array collections
    ├── Math.pm                  # Mathematical operations
    ├── Collections/             # Collection classes
    │   ├── Hashtable.pm        
    │   ├── IEnumerable.pm      
    │   └── IEnumerator.pm      
    ├── Linq/                    # LINQ implementation
    │   ├── SelectIterator.pm   
    │   ├── WhereIterator.pm    
    │   └── [other iterators]   
    ├── IO/                      # File system operations
    │   ├── File.pm             
    │   ├── Directory.pm        
    │   └── Path.pm             
    ├── Threading/               # Threading support
    │   └── Thread.pm           
    ├── Windows/Forms/           # GUI components
    │   ├── MessageBox.pm       
    │   └── [dialog resources]  
    └── Diagnostics/             # Debugging and diagnostics
        ├── Stopwatch.pm        
        └── Trace.pm            
```

## Usage Examples

### Basic Object Creation and String Operations
```perl
use System;

my $str = System::String->new("Hello, World!");
my $upper = $str->ToUpper();
my $parts = $str->Split(", ");
print $upper->ToString();  # "HELLO, WORLD!"
```

### Exception Handling
```perl
use System;

try {
    my $result = risky_operation();
} catch {
    my $exception = shift;
    print "Error: " . $exception->Message;
} finally {
    cleanup_resources();
};
```

### LINQ Operations
```perl
use System;
use System::Linq;

my $numbers = System::Array->new(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
my $evenSquares = $numbers
    ->Where(sub { $_[0] % 2 == 0 })
    ->Select(sub { $_[0] * $_[0] })
    ->OrderByDescending(sub { $_[0] })
    ->ToArray();
```

### Collections and Hashtables
```perl
use System;

my $hash = System::Collections::Hashtable->new();
$hash->Add("key1", "value1");
$hash->Add("key2", "value2");

my $keys = $hash->Keys()->ToArray();
my $hasKey = $hash->ContainsKey("key1");
```

### Switch Statements
```perl
use System;

my $value = 42;
switch $value,
    case 1, sub { print "One" },
    case 42, sub { print "The Answer" },
    default { print "Unknown" };
```

## Installation and Dependencies

This is a pure Perl implementation requiring no compilation. Simply ensure the modules are in your Perl path.

### Core Dependencies
- Perl 5.x (tested with modern Perl versions)
- Core modules: strict, warnings, Exporter, Scalar::Util

### Optional Dependencies
- **Tk**: Required for GUI components (MessageBox)
- **Image::Xbm**: For icon processing in message boxes

### Installation
```bash
# Clone the repository
git clone https://github.com/Hawkynt/Perl-NetFramework.git

# Add to Perl path or copy modules to desired location
export PERL5LIB=$PERL5LIB:/path/to/Perl-NetFramework
```

## Development and Testing

### Compilation Check
Verify syntax and compilation:
```bash
perl -MO=Deparse System.pm
perl -MO=Deparse CSharp.pm
```

### Running Embedded Tests
Some modules include test methods:
```perl
use System::String;
System::String::Test();  # Run string tests
```

## Architecture Notes

- **Object-Oriented Design**: All classes inherit from System::Object
- **Interface Simulation**: Multiple inheritance used to simulate .NET interfaces
- **Operator Overloading**: String and numeric types support natural operators
- **Lazy Evaluation**: LINQ operations use iterator pattern for memory efficiency
- **Exception Safety**: Comprehensive exception handling throughout the framework
- **Namespace Aliasing**: Short aliases available (e.g., `String` instead of `System::String`)

## Contributing

This project follows .NET naming conventions and design patterns. When contributing:

1. Maintain compatibility with .NET BCL APIs
2. Include proper error handling with custom exceptions  
3. Add package name aliases for convenience
4. Follow the established object hierarchy
5. Include inline documentation for complex methods

## License

This project is licensed under the GNU Lesser General Public License v3.0 or later. See the LICENSE file for details.
