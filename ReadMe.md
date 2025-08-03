# 🐪 Perl-NetFramework

[![License](https://img.shields.io/badge/License-GPL_3.0-blue)](https://licenses.nuget.org/GPL-3.0-or-later)
![Language](https://img.shields.io/github/languages/top/Hawkynt/Perl-NetFramework?color=purple)
[![Tests](https://github.com/Hawkynt/Perl-NetFramework/actions/workflows/tests.yml/badge.svg)](https://github.com/Hawkynt/Perl-NetFramework/actions/workflows/tests.yml)
[![Release](https://github.com/Hawkynt/Perl-NetFramework/actions/workflows/release.yml/badge.svg)](https://github.com/Hawkynt/Perl-NetFramework/actions/workflows/release.yml)
[![GitHub release](https://img.shields.io/github/v/release/Hawkynt/Perl-NetFramework)](https://github.com/Hawkynt/Perl-NetFramework/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/Hawkynt/Perl-NetFramework/total)](https://github.com/Hawkynt/Perl-NetFramework/releases)

> 🚀 A comprehensive clone of the .NET Framework Base Class Library (BCL) implemented in pure Perl.

## 📖 Overview

Perl-NetFramework brings the familiar .NET programming model to Perl, providing a rich set of classes, interfaces, and language constructs that mirror the .NET Framework's Base Class Library. This project enables developers to write Perl code using .NET-style patterns, object-oriented design, and familiar APIs.

## ✨ Features

### 🔧 Core Language Constructs
- **⚡ Exception Handling**: Complete try/catch/finally implementation with custom exception types
- **🔀 Switch Statements**: C#-style switch/case/default constructs
- **🎯 Constants**: `true`, `false`, and `null` constants for cleaner code
- **🏗️ Type System**: Comprehensive object-oriented hierarchy starting from `System::Object`

### 🎭 Revolutionary C# Syntax Filter (`Filter::CSharp`)
**The game-changing feature**: Write pure C# syntax that gets automatically transformed to valid Perl!

- **📋 Class Declarations**: Use `namespace MyApp { public class User { ... } }` syntax
- **🔐 Access Modifiers**: Support for `public`, `private`, `protected`, `internal` keywords  
- **⚡ Properties**: Auto-implemented properties with `{ get; set; }` syntax
- **🏗️ Constructors/Destructors**: Natural C#-style `ctor()` and `~ctor()` methods
- **📊 Fields**: Static/instance fields with proper type declarations
- **🔄 `using` Statements**: Resource management with automatic disposal
- **🔁 `foreach` Loops**: LINQ-compatible enumeration syntax
- **🏷️ `var` Declarations**: Type inference for cleaner code
- **➡️ Lambda Expressions**: Arrow function syntax `()=>{}` and `$x=>{}`

### 📦 Collections and LINQ
- **🗂️ Collections**: Hashtable, Array, and enumerable collections with .NET-compatible APIs
- **🔍 LINQ-to-Objects**: Full implementation including Select, Where, OrderBy, GroupBy, and more
- **⚡ Lazy Evaluation**: Iterator-based implementation for memory-efficient operations
- **🔗 Lambda Support**: Perl closures used as lambda expressions in LINQ operations

### 📝 String Processing
- **🧵 System::String**: Feature-rich string class with familiar .NET methods
- **✂️ String Operations**: Contains, IndexOf, Replace, Split, Trim, and case conversion
- **📋 Formatting**: String.Format with placeholder and formatting support
- **🔤 Comparison**: Culture-aware and ordinal string comparison options

### 📁 I/O and File System
- **📄 File Operations**: System::IO::File for file manipulation
- **📂 Directory Operations**: System::IO::Directory for folder management  
- **🛤️ Path Utilities**: System::IO::Path for path manipulation and validation

### 🧮 Mathematical Operations
- **🔢 System::Math**: Mathematical functions and constants
- **💯 System::Decimal**: High-precision decimal arithmetic
- **🔄 Numeric Types**: Type-safe numeric operations with automatic conversion

### 🧵 Threading Support
- **⚡ System::Threading::Thread**: Basic threading capabilities
- **🔐 Synchronization**: Thread-safe operations and coordination

### 🖥️ GUI Components
- **💬 MessageBox**: Windows-style message boxes using Tk backend
- **✅ Dialog Results**: Standard dialog button and result handling
- **🎨 Icons**: Support for standard system icons (Error, Warning, Information, Question)

### 🔧 Diagnostics and Debugging
- **⏱️ System::Diagnostics::Stopwatch**: High-precision timing
- **📊 System::Diagnostics::Trace**: Debug and trace output
- **✅ Contracts**: Code contract assertions for defensive programming

### 🏢 Directory Services
- **👥 Active Directory**: User and group management through System::DirectoryServices
- **🔐 Authentication**: Principal-based authentication and authorization

## 📁 Project Structure

```
Perl-NetFramework/
├── System.pm                    # Main namespace entry point
├── CSharp.pm                    # Core language constructs and utilities
├── Filter/                      # Alternative implementations
│   └── CSharp.pm               
├── tests/                       # Comprehensive test suite
│   ├── README.md               # Test documentation and usage
│   ├── run_tests.pl            # Test runner with colored output
│   └── System/                 # Test files organized by namespace
│       ├── Object.pl           # System::Object tests
│       ├── String.pl           # System::String tests
│       ├── Array.pl            # System::Array tests
│       ├── Collections/        # Collection tests
│       ├── Linq/               # LINQ operation tests
│       ├── IO/                 # File I/O tests
│       └── Diagnostics/        # Diagnostics tests
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

## 💡 Usage Examples

### 🎭 C# Syntax Transformation (Filter::CSharp)

**Write this C# code:**
```csharp
use Filter::CSharp;

namespace MyApp {
    public class UserService {
        private string name;
        public int Age { get; set; }
        
        public UserService(string userName) {
            this.name = userName;
            this.Age = 0;
        }
        
        public string GetWelcomeMessage() {
            return "Hello, " + this.name + "! Age: " + this.Age;
        }
        
        public static void ProcessUsers() {
            var users = new System::Array("Alice", "Bob", "Charlie");
            foreach (var user in users) {
                var service = new UserService(user);
                service.Age = 25;
                print service.GetWelcomeMessage();
            }
        }
    }
}
```

**Gets automatically transformed to valid Perl** with full .NET BCL integration!

### 🧵 Traditional Perl Syntax
```perl
use System;

my $str = System::String->new("Hello, World!");
my $upper = $str->ToUpper();
my $parts = $str->Split(", ");
print $upper->ToString();  # "HELLO, WORLD!"
```

### ⚡ Exception Handling
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

### 🔍 LINQ Operations
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

### 🗂️ Collections and Hashtables
```perl
use System;

my $hash = System::Collections::Hashtable->new();
$hash->Add("key1", "value1");
$hash->Add("key2", "value2");

my $keys = $hash->Keys()->ToArray();
my $hasKey = $hash->ContainsKey("key1");
```

### 🔀 Switch Statements
```perl
use System;

my $value = 42;
switch $value,
    case 1, sub { print "One" },
    case 42, sub { print "The Answer" },
    default { print "Unknown" };
```

## 📦 Installation and Dependencies

### 📥 Quick Install (Recommended)

**Download the latest release:**
```bash
# Download from GitHub Releases
wget https://github.com/Hawkynt/Perl-NetFramework/releases/latest/download/Perl-NetFramework-1.00.tar.gz
tar -xzf Perl-NetFramework-1.00.tar.gz
cd Perl-NetFramework-1.00

# Install using standard Perl tools
perl Makefile.PL
make test
make install
```

**Or use cpanm (if published to CPAN):**
```bash
cpanm Perl::NetFramework
```

### 🔧 Development Install
```bash
# Clone the repository for development
git clone https://github.com/Hawkynt/Perl-NetFramework.git
cd Perl-NetFramework

# Install dependencies
cpanm --installdeps .

# Run tests
perl tests/run_tests.pl
# Or comprehensive test runner
perl run_all_tests.pl
```

### 🔧 Core Dependencies
- 🐪 **Perl 5.10.1+** (tested with Perl 5.30-5.36)
- 📦 **Core modules**: strict, warnings, Exporter, Scalar::Util, Filter::Simple

### 🎨 Optional Dependencies
- **🖥️ Tk**: Required for GUI components (MessageBox)
- **🎨 Image::Xbm**: For icon processing in message boxes
- **🌈 Term::ANSIColor**: For colored test output

### 📦 Available Downloads
- **📦 .tar.gz**: CPAN-compatible distribution
- **📁 .zip**: Windows-friendly archive  
- **📄 Source**: Complete source with Git history

Visit my [**Releases Page**](https://github.com/Hawkynt/Perl-NetFramework/releases) for all download options.

## 🔧 Development and Testing

### 🧪 Running the Test Suite

The project includes a comprehensive test suite organized into two main categories:

#### **System Framework Tests**
Tests for the core .NET BCL implementation:
```bash
# Run all System framework tests
perl -I. tests/System/String.pl      # String operations
perl -I. tests/System/Array.pl       # Array functionality  
perl -I. tests/System/Types.pl       # Decimal, TimeSpan, String comprehensive tests
perl -I. tests/System/Collections/Hashtable.pl  # Hashtable operations
perl -I. tests/System/Text/RegularExpressions.pl  # Regex support
```

#### **Filter::CSharp Tests**
Tests for the C# syntax transformation:
```bash
# Run Filter::CSharp transformation tests
perl -I. tests/Filter/CSharp_Working.pl        # Basic working features
perl -I. tests/Filter/CSharp_Constructor.pl    # Constructor/destructor syntax
perl -I. tests/Filter/CSharp_Foreach.pl        # foreach loop transformation
perl -I. tests/Filter/CSharp_LineNumbers.pl    # Line number preservation
perl -I. tests/Filter/CSharp_Comprehensive.pl  # Full syntax coverage
```

#### **Automated Test Runner**
```bash
# Run complete test suite with colored output
cd tests
perl run_tests.pl

# Individual test categories
perl run_tests.pl --verbose           # Detailed output
perl run_tests.pl --pattern "Filter*" # Filter tests only
perl run_tests.pl --pattern "System*" # System tests only
```

### 📊 Current Test Status

#### ✅ **Fully Working Components**
- **Filter::CSharp Basic Syntax**: var, new, namespaces, constants ✅
- **Line Number Preservation**: Debugging maintains correct line numbers ✅
- **System::Decimal**: Full arithmetic, comparisons, ToString ✅
- **Basic foreach Loops**: C# foreach syntax transformation ✅
- **Core String Operations**: Most string methods working ✅

#### ⚠️ **Known Issues & Limitations**

**Filter::CSharp Limitations:**
- ❌ **Method Parameters**: Type annotations cause syntax errors
- ❌ **this Keyword**: Not transformed properly in methods
- ❌ **Auto-Properties**: `{ get; set; }` syntax has parsing issues
- ❌ **Constructor Parameters**: Complex constructors fail
- ❌ **Destructor Syntax**: `~ctor` not implemented

**System Framework Issues:**
- ❌ **TimeSpan Static Methods**: `FromDays`/`FromHours` numeric conversion issues
- ❌ **String.Substring**: Position parameters not working correctly  
- ❌ **Array.Get Method**: Method not implemented
- ❌ **System::IO::Directory**: `EnumerateFiles` method missing
- ❌ **System::Text::RegularExpressions**: Module not implemented

### 🧪 Testing Methodology

#### **Filter::CSharp Testing Strategy**
Uses behavioral testing with temporary files and `MO=Deparse` compilation:
```perl
# Example test approach
my ($fh, $temp_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
print $fh $csharp_code;
close $fh;

my $output = `perl -I. "$temp_file" 2>&1`;
# Test actual execution behavior, not just regex patterns
```

#### **System Framework Testing**
Traditional Test::More approach with comprehensive edge case coverage:
```perl
use Test::More;
plan tests => 50;

# Test arithmetic operations, comparisons, edge cases
ok($decimal1 + $decimal2 == $expected, "Decimal addition works");
is($string->Substring(0, 5), "Hello", "Substring extraction");
```

### ✅ **Compilation Verification**
```bash
# Verify core modules compile correctly
perl -I. -c System.pm
perl -I. -c CSharp.pm  
perl -I. -c Filter/CSharp.pm

# Test syntax transformation
perl -MO=Deparse -MFilter::CSharp -e 'var $x = 42;'
```

### 📈 **CI/CD Integration**
GitHub Actions automatically runs:
- **Syntax checks** across all .pm files
- **Individual test files** with proper -I. flags
- **System framework tests** for core functionality
- **Filter::CSharp tests** for syntax transformation
- **Multi-version testing** on Perl 5.30-5.36

### 🔧 **Test Development Notes**
- All tests use `-I.` flag to include current directory in @INC
- Filter tests create temporary files to test actual transformation behavior
- System tests focus on API compatibility with .NET BCL
- Line number preservation is critical for debugging transformed C# code
- Tests document both working features and known limitations

## 🏗️ Architecture Notes

- **🎯 Object-Oriented Design**: All classes inherit from System::Object
- **🔗 Interface Simulation**: Multiple inheritance used to simulate .NET interfaces
- **⚡ Operator Overloading**: String and numeric types support natural operators
- **🚀 Lazy Evaluation**: LINQ operations use iterator pattern for memory efficiency
- **🛡️ Exception Safety**: Comprehensive exception handling throughout the framework
- **🏷️ Namespace Aliasing**: Short aliases available (e.g., `String` instead of `System::String`)

## 🤝 Sister Projects

This project is part of a multi-language effort to bring .NET Framework functionality to various programming languages:

- **🐪 [Perl-NetFramework](https://github.com/Hawkynt/Perl-NetFramework)** - .NET BCL implementation in Perl
- **🐘 [PHP-NetFramework](https://github.com/Hawkynt/PHP-NetFramework)** - .NET BCL implementation in PHP

## 📝 Contributing

This project follows .NET naming conventions and design patterns. When contributing:

1. ✅ Maintain compatibility with .NET BCL APIs
2. ⚡ Include proper error handling with custom exceptions  
3. 🏷️ Add package name aliases for convenience
4. 🏗️ Follow the established object hierarchy
5. 📝 Include inline documentation for complex methods

### 🚀 Creating Releases

For maintainers, releases are fully automated and triggered by successful CI runs:

```bash
# Prepare a new release (runs CI, then auto-creates release when tests pass)
./create_release.sh 1.2.0

# Prepare a pre-release
./create_release.sh 1.2.0-beta1 --prerelease
```

**Automated Release Process:**
1. 📝 **Version Update**: Script updates version in `System.pm` and commits
2. 🧪 **CI Trigger**: Push triggers comprehensive tests across Perl 5.30-5.36
3. 🚀 **Auto-Release**: When CI passes, release workflow automatically:
   - Creates CPAN-compatible distribution packages
   - Generates changelog from git commits  
   - Publishes GitHub Release with download artifacts
   - Provides both .tar.gz (CPAN) and .zip (Windows) formats

**Manual Release Options:**
- GitHub Actions UI: Trigger release workflow manually with custom version
- Force release even if some tests fail (for emergency releases)

## 📄 License

This project is licensed under the GNU Lesser General Public License v3.0 or later. See the LICENSE file for details.
