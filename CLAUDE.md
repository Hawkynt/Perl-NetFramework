# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Perl-NetFramework**, a clone of the .NET Framework Base Class Library (BCL) implemented in pure Perl. The project recreates .NET's familiar class structure, methods, and APIs in Perl, allowing developers to use .NET-style programming patterns in Perl.

## Architecture

### Core Components

- **CSharp.pm**: Foundation module providing C#-like language constructs including try/catch/finally, switch/case/default, and fundamental helper functions
- **System.pm**: Main namespace entry point that imports core types and provides constants like `true`, `false`, `null`
- **System/**: Contains all the .NET BCL equivalents organized by namespace

### Key Design Patterns

1. **Object-Oriented Structure**: All classes inherit from `System::Object` and follow .NET naming conventions
2. **Exception Handling**: Custom exception system with try/catch/finally blocks via `CSharp.pm`
3. **Interface Implementation**: Uses Perl's multiple inheritance to simulate .NET interfaces (e.g., `System::Collections::IEnumerable`)
4. **Operator Overloading**: String class overloads operators like `""` (ToString), `+` (Concat), and `cmp` (Compare)
5. **LINQ Support**: Full LINQ-to-Objects implementation with iterators for lazy evaluation
6. **Package Aliasing**: `BEGIN` blocks create short aliases (e.g., `String` for `System::String`)

### Module Organization

- **Basic Types**: Object, String, Array, Decimal, TimeSpan, Tuple
- **Collections**: Hashtable, IEnumerable, IEnumerator, DictionaryEntry  
- **LINQ**: Complete implementation with iterators for Select, Where, OrderBy, etc.
- **I/O**: File, Directory, Path operations
- **Threading**: Thread support
- **Windows Forms**: MessageBox with Tk-based GUI
- **Diagnostics**: Stopwatch, Trace, Contracts
- **DirectoryServices**: Active Directory integration
- **Math**: Mathematical operations

## Development Notes

### No Build System
This is a pure Perl library with no build process, test framework, or package management files. Development involves directly editing `.pm` files.

### Testing
Some modules include embedded test methods (e.g., `System::String::Test()`) but there's no unified test framework.

### Dependencies
- Core Perl modules (strict, warnings, Exporter)
- Tk for GUI components (MessageBox)
- Additional modules like Scalar::Util, Image::Xbm for specific features

### File Structure
- Root `.pm` files are main namespace entry points
- Subdirectories mirror .NET namespace hierarchy  
- `Filter/` contains alternative implementations
- Icons (`.png` files) for MessageBox dialogs

## Common Tasks

### Adding New Classes
1. Create `.pm` file in appropriate `System/` subdirectory
2. Inherit from `System::Object` or relevant base class
3. Add short name alias in `BEGIN` block: `CSharp::_ShortenPackageName(__PACKAGE__)`
4. Include proper exception handling with `throw()` calls

### Working with LINQ
Use the extensive LINQ implementation for collection operations. Most collections inherit from `System::Collections::IEnumerable` providing methods like `Select()`, `Where()`, `OrderBy()`, etc.

### Exception Handling
Use the C#-style syntax provided by `CSharp.pm`:
```perl
try {
    # code that might fail
} catch {
    my $exception = shift;
    # handle exception
} finally {
    # cleanup code
};
```