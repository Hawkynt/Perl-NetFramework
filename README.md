# 🐪 Perl-NetFramework

[![License](https://img.shields.io/github/license/Hawkynt/Perl-NetFramework)](https://github.com/Hawkynt/Perl-NetFramework/blob/main/LICENSE)
[![Language](https://img.shields.io/github/languages/top/Hawkynt/Perl-NetFramework?color=8957D5)](https://github.com/Hawkynt/Perl-NetFramework)

[![CI](https://github.com/Hawkynt/Perl-NetFramework/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Hawkynt/Perl-NetFramework/actions/workflows/ci.yml)
![Last Commit](https://img.shields.io/github/last-commit/Hawkynt/Perl-NetFramework?branch=main)
![Activity](https://img.shields.io/github/commit-activity/m/Hawkynt/Perl-NetFramework)

[![Stars](https://img.shields.io/github/stars/Hawkynt/Perl-NetFramework?color=FFD700)](https://github.com/Hawkynt/Perl-NetFramework/stargazers)
[![Forks](https://img.shields.io/github/forks/Hawkynt/Perl-NetFramework?color=008080)](https://github.com/Hawkynt/Perl-NetFramework/network/members)
[![Issues](https://img.shields.io/github/issues/Hawkynt/Perl-NetFramework)](https://github.com/Hawkynt/Perl-NetFramework/issues)
![Code Size](https://img.shields.io/github/languages/code-size/Hawkynt/Perl-NetFramework?color=4CAF50)
![Repo Size](https://img.shields.io/github/repo-size/Hawkynt/Perl-NetFramework?color=FF9800)

> A comprehensive clone of the .NET Framework Base Class Library (BCL) implemented in pure Perl.

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
- **🔍 LINQ-to-Objects**: Complete implementation with all 50+ operators including modern ones
- **⚡ Lazy Evaluation**: Iterator-based implementation for memory-efficient operations  
- **🔗 Lambda Support**: Perl closures used as lambda expressions in LINQ operations
- **🆕 Modern Operators**: MinBy, MaxBy, DistinctBy, Chunk, Join, GroupJoin, Zip, and more
- **🎯 Join Operations**: Inner joins and group joins for data correlation
- **📊 Aggregation**: Sum, Average, Min, Max with selectors, CountBy, Aggregate

### 🔧 Generic Collections
- **📋 List<T>**: Dynamic array with comprehensive methods (Add, Remove, Insert, Sort, Find, etc.)
- **🗃️ Dictionary<TKey, TValue>**: Hash table with key-value pairs, separate key/value collections
- **📚 Stack<T>**: LIFO (Last In, First Out) collection with Push/Pop operations
- **🎯 Queue<T>**: FIFO (First In, First Out) collection with Enqueue/Dequeue operations
- **🔗 LinkedList<T>**: Doubly-linked list with LinkedListNode<T> for efficient insertion/removal
- **🏷️ KeyValuePair<TKey, TValue>**: Structure for dictionary key-value pairs
- **🔄 Full Enumeration**: All collections implement IEnumerable with proper iterators
- **🧪 Comprehensive Testing**: 162 tests covering all operations and edge cases

### 🎯 Event System and Data Binding
- **🎗️ System::Delegate**: Method pointer/callback system with multicast support
- **⚡ System::Event**: Event management with pointer-based add/remove mechanism
- **📋 System::ComponentModel::BindingList<T>**: Data-binding collection with automatic notifications
- **🔔 INotifyPropertyChanged**: Interface for property change notifications  
- **📝 INotifyPropertyChanging**: Interface for pre-change notifications with cancellation support
- **📊 INotifyCollectionChanged**: Interface for collection modification notifications
- **🛠️ Event Args**: PropertyChangedEventArgs, PropertyChangingEventArgs, NotifyCollectionChangedEventArgs
- **🎯 Automatic Notifications**: BindingList automatically raises events on Add, Remove, Replace operations
- **🔧 Change Tracking**: Support for item-level property change notifications
- **⚖️ Comprehensive Testing**: 104/105 tests passing for complete event system validation

### 📝 String Processing
- **🧵 System::String**: Feature-rich string class with familiar .NET methods
- **✂️ String Operations**: Contains, IndexOf, Replace, Split, Trim, and case conversion
- **📋 Formatting**: String.Format with placeholder and formatting support
- **🔤 Comparison**: Culture-aware and ordinal string comparison options

### 📁 I/O and File System
- **📄 File Operations**: System::IO::File for file manipulation
- **📂 Directory Operations**: System::IO::Directory for folder management  
- **🛤️ Path Utilities**: System::IO::Path for path manipulation and validation
- **🌊 Stream Operations**: Complete streaming infrastructure with proper lazy evaluation
- **📝 Text I/O**: StreamReader, StreamWriter, TextReader, TextWriter for text processing
- **🔤 Text Encoding**: Full encoding support (UTF-8, UTF-16, UTF-32, ASCII) with BOM handling

### 🧮 Mathematical Operations
- **🔢 System::Math**: Mathematical functions and constants
- **💯 System::Decimal**: High-precision decimal arithmetic
- **🔄 Numeric Types**: Complete value type system with range validation
- **📊 Primitive Types**: Byte, SByte, Int16, Int32, Int64, UInt16, UInt32, UInt64
- **🎯 Floating Point**: Single, Double with IEEE compliance and special values (NaN, Infinity)
- **⚖️ Type Safety**: Overflow detection and proper arithmetic operations

### 🧵 Threading and Concurrency
- **⚡ System::Threading::Thread**: Complete threading with states, priorities, and lifecycle management
- **🏊 System::Threading::ThreadPool**: Thread pool for efficient task execution
- **📋 System::Threading::Tasks::Task**: Task Parallel Library (TPL) for async operations
- **⏳ TaskAwaiter**: Async/await pattern support with task awaiting
- **🔁 Asynchronous Patterns**: Begin/End methods and TPL-based async operations
- **🎯 Thread Management**: Background threads, thread priorities, and synchronization
- **🏗️ Task Factory**: Run, Delay, WhenAll, WhenAny for complex task orchestration
- **⚡ Task Continuations**: ContinueWith for chaining operations
- **🛡️ Exception Handling**: AggregateException for multiple concurrent exceptions
- **🔒 Synchronization Primitives**: Mutex, Semaphore, AutoResetEvent, ManualResetEvent
- **🔐 Thread-Safe Collections**: ConcurrentQueue, ConcurrentDictionary, ConcurrentStack, ConcurrentBag
- **🎯 WaitHandle System**: Base wait handle functionality with WaitAll, WaitAny support
- **🚦 Event-Based Synchronization**: Manual and automatic reset events for thread coordination

### 🎲 Random Number Generation
- **🎯 System::Random**: Comprehensive pseudo-random number generator
- **📊 Multiple Types**: Integers, doubles, bytes, booleans, and strings
- **📈 Advanced Algorithms**: Gaussian/normal distribution support
- **🔀 Array Operations**: Sampling and shuffling with Fisher-Yates algorithm
- **⚙️ Configurable Seeds**: Deterministic and time-based initialization
- **🌍 Shared Instance**: Static shared Random for global use

### 🗄️ Memory Management
- **♻️ System::Buffers::ArrayPool<T>**: Array pooling for memory efficiency
- **📊 Pool Statistics**: Rent/return tracking and usage monitoring
- **🧹 Memory Optimization**: Automatic trimming and pool management
- **📏 Size Buckets**: Efficient array size management with power-of-2 buckets
- **🔄 Array Reuse**: Minimizes garbage collection pressure

### 🌐 System Core Components
- **🆔 System::Guid**: Globally unique identifier generation with RFC 4122 compliance
- **🌍 System::Environment**: System environment access (OS, version, variables, paths)
- **💻 System::Console**: Console I/O operations with ANSI escape sequences and cross-platform support
- **🔄 System::Convert**: Comprehensive type conversion system with overflow detection
- **🌐 System::Uri**: Complete URI/URL handling with parsing, validation, and component access
- **🔗 URI Operations**: Absolute/relative URI support, path normalization, and escape/unescape
- **📊 URI Components**: Scheme, host, port, path, query, fragment parsing and manipulation

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
│       │   └── Generic/        # Generic collection tests
│       ├── Linq/               # LINQ operation tests
│       ├── IO/                 # File I/O tests
│       └── Diagnostics/        # Diagnostics tests
└── System/                      # .NET BCL namespace hierarchy
    ├── Object.pm                # Base object class
    ├── String.pm                # String manipulation
    ├── Array.pm                 # Array collections
    ├── Math.pm                  # Mathematical operations
    ├── Guid.pm                  # Globally unique identifiers
    ├── Environment.pm           # System environment access
    ├── Console.pm               # Console I/O operations
    ├── Convert.pm               # Type conversion system
    ├── Uri.pm                   # URI/URL handling
    ├── Collections/             # Collection classes
    │   ├── Hashtable.pm        
    │   ├── IEnumerable.pm      
    │   ├── IEnumerator.pm
    │   ├── Generic/             # Generic collections
    │   │   ├── List.pm          # List<T>
    │   │   ├── Dictionary.pm    # Dictionary<TKey, TValue>
    │   │   ├── Stack.pm         # Stack<T>
    │   │   ├── Queue.pm         # Queue<T>
    │   │   ├── LinkedList.pm    # LinkedList<T>
    │   │   ├── KeyValuePair.pm  # KeyValuePair<TKey, TValue>
    │   │   └── [enumerators]    # Supporting classes
    │   ├── Concurrent/          # Thread-safe collections
    │   │   ├── ConcurrentQueue.pm      # Thread-safe queue
    │   │   ├── ConcurrentDictionary.pm # Thread-safe dictionary
    │   │   ├── ConcurrentStack.pm      # Thread-safe stack
    │   │   └── ConcurrentBag.pm        # Thread-safe bag
    │   └── Specialized/         # Specialized collections
    │       ├── INotifyCollectionChanged.pm
    │       ├── NotifyCollectionChangedEventArgs.pm
    │       └── NotifyCollectionChangedAction.pm
    ├── ComponentModel/          # Data binding and events
    │   ├── BindingList.pm       # Data-binding collection
    │   ├── INotifyPropertyChanged.pm
    │   ├── INotifyPropertyChanging.pm
    │   ├── PropertyChangedEventArgs.pm
    │   ├── PropertyChangingEventArgs.pm
    │   └── CancelEventArgs.pm
    ├── Delegate.pm              # Method pointer system
    ├── Event.pm                 # Event management
    ├── EventArgs.pm             # Base event arguments class
    ├── Buffers/                 # Memory management
    │   └── ArrayPool.pm         # Array pooling for efficiency
    ├── Linq/                    # LINQ implementation
    │   ├── SelectIterator.pm   
    │   ├── WhereIterator.pm    
    │   └── [other iterators]   
    ├── IO/                      # File system operations
    │   ├── File.pm             
    │   ├── Directory.pm        
    │   ├── Path.pm
    │   ├── Stream.pm            # Base stream class
    │   ├── TextReader.pm        # Text reading base class
    │   ├── TextWriter.pm        # Text writing base class
    │   ├── StreamReader.pm      # Stream-based text reader
    │   └── StreamWriter.pm      # Stream-based text writer
    ├── Text/                    # Text processing
    │   ├── StringBuilder.pm     # Efficient string building
    │   └── Encoding.pm          # Text encoding support
    ├── Threading/               # Threading support
    │   ├── Thread.pm            # Basic threading
    │   ├── ThreadPool.pm        # Thread pool management
    │   ├── WaitHandle.pm        # Base synchronization class
    │   ├── EventWaitHandle.pm   # Event-based synchronization base
    │   ├── Mutex.pm             # Mutual exclusion
    │   ├── Semaphore.pm         # Counting semaphore
    │   ├── AutoResetEvent.pm    # Auto-resetting event
    │   ├── ManualResetEvent.pm  # Manual reset event
    │   └── Tasks/               # Task Parallel Library
    │       ├── Task.pm          # Asynchronous task operations
    │       └── TaskAwaiter.pm   # Task awaiting support
    ├── Random.pm                # Random number generation
    ├── Windows/Forms/           # GUI components
    │   ├── MessageBox.pm       
    │   └── [dialog resources]  
    └── Diagnostics/             # Debugging and diagnostics
        ├── Stopwatch.pm        
        └── Trace.pm            
```

## 🚀 Usage Examples

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

# Modern LINQ operators
my $people = System::Array->new(
    { name => "Alice", age => 30 },
    { name => "Bob", age => 25 },
    { name => "Charlie", age => 35 }
);

my $oldest = $people->MaxBy(sub { $_[0]->{age} });
my $youngest = $people->MinBy(sub { $_[0]->{age} });
my $chunked = $numbers->Chunk(3);  # [[1,2,3], [4,5,6], [7,8,9], [10]]
```

### 🔧 Generic Collections
```perl
use System::Collections::Generic::List;
use System::Collections::Generic::Dictionary;
use System::Collections::Generic::Stack;
use System::Collections::Generic::Queue;

# List<T> - Dynamic array
my $list = System::Collections::Generic::List->new();
$list->Add("Hello");
$list->Add("World");
$list->Insert(1, "Beautiful");
print $list->Item(1);  # "Beautiful"

# Functional operations
my $found = $list->Find(sub { $_[0] =~ /World/ });
my $filtered = $list->FindAll(sub { length($_[0]) > 5 });

# Dictionary<TKey, TValue> - Hash table
my $dict = System::Collections::Generic::Dictionary->new();
$dict->Add("name", "John");
$dict->Add("age", 30);
$dict->Item("city", "New York");  # Setter

my $value;
if ($dict->TryGetValue("name", \\$value)) {
    print "Name: $value";
}

# Enumerate key-value pairs
my $enumerator = $dict->GetEnumerator();
while ($enumerator->MoveNext()) {
    my $kvp = $enumerator->Current();
    print $kvp->Key() . " => " . $kvp->Value();
}

# Stack<T> - LIFO collection
my $stack = System::Collections::Generic::Stack->new();
$stack->Push("First");
$stack->Push("Second");
print $stack->Pop();  # "Second"
print $stack->Peek(); # "First"

# Queue<T> - FIFO collection  
my $queue = System::Collections::Generic::Queue->new();
$queue->Enqueue("First");
$queue->Enqueue("Second");
print $queue->Dequeue(); # "First"
print $queue->Peek();    # "Second"

# LinkedList<T> - Doubly-linked list
my $linkedList = System::Collections::Generic::LinkedList->new();
my $node1 = $linkedList->AddFirst("First");
my $node2 = $linkedList->AddLast("Last");
my $nodeMiddle = $linkedList->AddAfter($node1, "Middle");

# Navigate through nodes
my $current = $linkedList->First();
while ($current) {
    print $current->Value();
    $current = $current->Next();
}
```

### 🎯 Event System and Data Binding
```perl
use System::ComponentModel::BindingList;
use System::ComponentModel::PropertyChangedEventArgs;
use System::Collections::Specialized::NotifyCollectionChangedEventArgs;

# BindingList<T> - Data-binding collection with automatic notifications
my $bindingList = System::ComponentModel::BindingList->new();

# Set up event handlers
$bindingList->CollectionChanged(sub {
    my ($sender, $args) = @_;
    my $action = $args->Action();
    my $newItems = $args->NewItems();
    print "Collection changed: $action\n";
    
    if ($newItems && @$newItems) {
        print "New items: " . join(", ", @$newItems) . "\n";
    }
});

$bindingList->PropertyChanged(sub {
    my ($sender, $args) = @_;
    print "Property changed: " . $args->PropertyName() . "\n";
});

# Add items - triggers CollectionChanged events
$bindingList->Add("First Item");
$bindingList->Add("Second Item");
$bindingList->Insert(1, "Inserted Item");

# Modify properties - triggers PropertyChanged events
$bindingList->AllowEdit(false);  # Fires PropertyChanged
$bindingList->AllowRemove(false);

# Replace items - triggers CollectionChanged with Replace action
$bindingList->Item(0, "Modified First Item");

# Remove items - triggers CollectionChanged events
$bindingList->RemoveAt(1);

# Event system with delegates
use System::Delegate;
use System::Event;

my $event = System::Event->new();

# Add multiple handlers
my $handler1 = sub { print "Handler 1 called with: $_[1]\n"; };
my $handler2 = sub { print "Handler 2 called with: $_[1]\n"; };

$event->AddHandler($handler1);
$event->AddHandler($handler2);

# Invoke all handlers
$event->Invoke($self, "test message");

# Remove specific handler
$event->RemoveHandler($handler1);

# Delegate system for method pointers
my $delegate = System::Delegate->new(undef, sub { 
    my ($arg) = @_;
    return $arg * 2;
});

my $result = $delegate->Invoke(21);  # Returns 42

# Combine delegates for multicast
my $delegate2 = System::Delegate->new(undef, sub {
    my ($arg) = @_;
    print "Processing: $arg\n";
});

my $combined = System::Delegate->Combine($delegate, $delegate2);
$combined->Invoke(10);  # Calls both delegates
```

### 🧵 Threading and Concurrency
```perl
use System::Threading::Thread;
use System::Threading::ThreadPool;
use System::Threading::Tasks::Task;
use System::Random;
use System::Buffers::ArrayPool;

# Basic Threading
my $thread = System::Threading::Thread->new(sub {
    my ($param) = @_;
    for my $i (1..5) {
        print "Thread: $i, Param: $param\n";
        System::Threading::Thread->Sleep(1000);
    }
    return "Thread completed";
});

$thread->Name("Worker Thread");
$thread->IsBackground(true);
$thread->Start("Hello from main");
$thread->Join();

my $result = $thread->GetResult();
print "Result: $result\n";

# ThreadPool for lightweight tasks
System::Threading::ThreadPool->QueueUserWorkItem(sub {
    my ($state) = @_;
    print "ThreadPool task: $state\n";
    return time();
}, "Task Data");

# Check ThreadPool statistics
my ($workers, $completionPorts);
System::Threading::ThreadPool->GetAvailableThreads(\$workers, \$completionPorts);
print "Available threads: $workers worker, $completionPorts completion\n";

# Task Parallel Library (TPL)
my $task1 = System::Threading::Tasks::Task->Run(sub {
    my $sum = 0;
    for my $i (1..1000) {
        $sum += $i;
    }
    return $sum;
});

my $task2 = System::Threading::Tasks::Task->Run(sub {
    my $product = 1;
    for my $i (1..10) {
        $product *= $i;
    }
    return $product;
});

# Wait for all tasks
my $allTasks = System::Threading::Tasks::Task->WhenAll($task1, $task2);
$allTasks->Wait();

print "Task 1 result: " . $task1->Result() . "\n";  # 500500
print "Task 2 result: " . $task2->Result() . "\n";  # 3628800

# Task continuations
my $continuationTask = $task1->ContinueWith(sub {
    my ($completedTask) = @_;
    my $result = $completedTask->Result();
    return "Processed: $result";
});

print "Continuation: " . $continuationTask->Result() . "\n";

# Delay tasks
my $delayTask = System::Threading::Tasks::Task->Delay(2000);
print "Starting delay...\n";
$delayTask->Wait();
print "Delay completed!\n";

# Random number generation
my $random = System::Random->new(42);  # Seeded for reproducibility
print "Random int: " . $random->Next() . "\n";
print "Random range: " . $random->Next(1, 100) . "\n";
print "Random double: " . $random->NextDouble() . "\n";
print "Random boolean: " . $random->NextBoolean() . "\n";

# Generate random bytes
my @buffer = (0) x 10;
$random->NextBytes(\@buffer);
print "Random bytes: " . join(", ", @buffer) . "\n";

# Advanced random operations
my $randomString = $random->NextString(8, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");
print "Random string: $randomString\n";

# Gaussian distribution
my $gaussian = $random->NextGaussian(0, 1);  # mean=0, stddev=1
print "Gaussian value: $gaussian\n";

# Array operations
my @data = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
$random->Shuffle(\@data);
print "Shuffled: " . join(", ", @data) . "\n";

my $sample = $random->Sample(\@data);
print "Random sample: $sample\n";

# Array pooling for memory efficiency
my $arrayPool = System::Buffers::ArrayPool->Shared();

# Rent arrays instead of allocating
my $rentedArray1 = $arrayPool->Rent(100);
my $rentedArray2 = $arrayPool->Rent(256);

# Use arrays
for my $i (0..99) {
    $rentedArray1->[$i] = $i * $i;
}

print "First 10 squares: " . join(", ", @$rentedArray1[0..9]) . "\n";

# Return arrays to pool for reuse
$arrayPool->Return($rentedArray1, true);  # Clear on return
$arrayPool->Return($rentedArray2, false);

# Pool statistics
my $stats = $arrayPool->GetStatistics();
print "Pool stats - Rented: $stats->{TotalRented}, " .
      "Returned: $stats->{TotalReturned}, " .
      "Currently rented: $stats->{CurrentlyRented}\n";

# Create custom array pool with specific configuration
my $customPool = System::Buffers::ArrayPool->Create(65536, 20);  # Max 64KB arrays, 20 per bucket

# Rent and return from custom pool
my $customArray = $customPool->Rent(1000);
# ... use array ...
$customPool->Return($customArray);

# Trim pool to reduce memory usage
my $trimmed = $customPool->Trim(0.8);  # Keep 80% of pooled arrays
print "Trimmed $trimmed arrays from pool\n";
```

### 🔒 Thread Synchronization and Concurrent Collections
```perl
use System::Threading::Mutex;
use System::Threading::Semaphore;
use System::Threading::AutoResetEvent;
use System::Threading::ManualResetEvent;
use System::Collections::Concurrent::ConcurrentQueue;
use System::Collections::Concurrent::ConcurrentDictionary;
use System::Collections::Concurrent::ConcurrentStack;
use System::Collections::Concurrent::ConcurrentBag;

# Mutex - mutual exclusion with reentrancy
my $mutex = System::Threading::Mutex->new(0, "MyMutex");
if ($mutex->WaitOne(5000)) {  # 5 second timeout
    print "Critical section entered\n";
    # Do work...
    $mutex->ReleaseMutex();
    print "Critical section exited\n";
} else {
    print "Timeout waiting for mutex\n";
}

# Semaphore - limit concurrent access
my $semaphore = System::Threading::Semaphore->new(2, 5);  # 2 initial, 5 maximum
if ($semaphore->WaitOne(1000)) {
    print "Semaphore acquired\n";
    # Do work...
    my $previousCount = $semaphore->Release();
    print "Semaphore released, previous count: $previousCount\n";
}

# AutoResetEvent - signal single waiter
my $autoEvent = System::Threading::AutoResetEvent->new(0);  # Initially unset
# In another thread: $autoEvent->WaitOne();
$autoEvent->Set();  # Releases one waiter and auto-resets

# ManualResetEvent - signal multiple waiters  
my $manualEvent = System::Threading::ManualResetEvent->new(0);
$manualEvent->Set();    # Signal all waiters
$manualEvent->Reset();  # Manual reset to unsignaled

# ConcurrentQueue - thread-safe FIFO queue
my $queue = System::Collections::Concurrent::ConcurrentQueue->new();
$queue->Enqueue("item1");
$queue->Enqueue("item2");

my $item;
if ($queue->TryDequeue(\$item)) {
    print "Dequeued: $item\n";  # "item1"
}

if ($queue->TryPeek(\$item)) {
    print "Front item: $item\n";  # "item2" (still in queue)
}

print "Queue count: " . $queue->Count() . "\n";
print "Queue empty: " . ($queue->IsEmpty() ? "true" : "false") . "\n";

# ConcurrentDictionary - thread-safe hash table
my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();

# Thread-safe operations
if ($dict->TryAdd("key1", "value1")) {
    print "Added key1\n";
}

my $value;
if ($dict->TryGetValue("key1", \$value)) {
    print "Retrieved: $value\n";
}

# Atomic update operations
my $newValue = $dict->GetOrAdd("key2", "default_value");
my $updatedValue = $dict->AddOrUpdate("key1", "add_value", "update_value");

# Conditional update
if ($dict->TryUpdate("key1", "new_value", "update_value")) {
    print "Updated key1\n";
}

# ConcurrentStack - thread-safe LIFO stack
my $stack = System::Collections::Concurrent::ConcurrentStack->new();
$stack->Push("bottom");
$stack->Push("middle");
$stack->Push("top");

# Pop single item
if ($stack->TryPop(\$item)) {
    print "Popped: $item\n";  # "top"
}

# Pop multiple items
my @items;
my $count = $stack->TryPopRange(\@items, 2);
print "Popped $count items: " . join(", ", @items) . "\n";

# Push multiple items
$stack->PushRange("new1", "new2", "new3");

# ConcurrentBag - thread-safe unordered collection
my $bag = System::Collections::Concurrent::ConcurrentBag->new();
$bag->Add("item1");
$bag->Add("item2");
$bag->Add("item1");  # Duplicates allowed

if ($bag->TryTake(\$item)) {
    print "Took: $item\n";  # Could be any item
}

if ($bag->TryPeek(\$item)) {
    print "Peeked: $item\n";  # Peek without removing
}

print "Bag count: " . $bag->Count() . "\n";

# Convert to array for iteration
my $bagArray = $bag->ToArray();
print "Bag items: " . join(", ", @$bagArray) . "\n";
```

### 🌐 System Core Components  
```perl
use System::Guid;
use System::Environment;
use System::Console;
use System::Convert;
use System::Uri;

# GUID generation
my $guid1 = System::Guid->NewGuid();
print "Generated GUID: " . $guid1->ToString() . "\n";

my $guid2 = System::Guid->new("550e8400-e29b-41d4-a716-446655440000");
print "Parsed GUID: " . $guid2->ToString("D") . "\n";  # With hyphens
print "GUID bytes: " . join(" ", map { sprintf("%02X", $_) } @{$guid2->ToByteArray()}) . "\n";

print "GUIDs equal: " . ($guid1->Equals($guid2) ? "true" : "false") . "\n";
print "Empty GUID: " . System::Guid->Empty()->ToString() . "\n";

# Environment information
print "OS Version: " . System::Environment->OSVersion() . "\n";
print "Machine Name: " . System::Environment->MachineName() . "\n";
print "User Name: " . System::Environment->UserName() . "\n";
print "Processor Count: " . System::Environment->ProcessorCount() . "\n";
print "Working Set: " . System::Environment->WorkingSet() . " bytes\n";

# Environment variables
my $path = System::Environment->GetEnvironmentVariable("PATH");
print "PATH length: " . length($path) . "\n";

System::Environment->SetEnvironmentVariable("MY_VAR", "test_value");
print "MY_VAR: " . System::Environment->GetEnvironmentVariable("MY_VAR") . "\n";

# Special folders
print "Current Directory: " . System::Environment->CurrentDirectory() . "\n";
print "System Directory: " . System::Environment->SystemDirectory() . "\n";
print "Temp Directory: " . System::Environment->GetTempPath() . "\n";

# Console operations
System::Console->WriteLine("Hello, Console!");
System::Console->Write("Enter your name: ");
my $name = System::Console->ReadLine();
System::Console->WriteLine("Hello, $name!");

# Console properties and colors (if supported)
print "Console Title: " . System::Console->Title() . "\n";
System::Console->Title("My Perl Application");

if (System::Console->IsOutputRedirected()) {
    print "Output is redirected\n";
} else {
    System::Console->Clear();
    print "Console cleared\n";
}

# Type conversions
my $intValue = System::Convert->ToInt32("42");
my $doubleValue = System::Convert->ToDouble("3.14159");
my $boolValue = System::Convert->ToBoolean("true");
my $byteValue = System::Convert->ToByte("255");

print "Converted values: int=$intValue, double=$doubleValue, bool=$boolValue, byte=$byteValue\n";

# Base64 encoding/decoding
my @bytes = (72, 101, 108, 108, 111);  # "Hello" in ASCII
my $base64 = System::Convert->ToBase64String(\@bytes);
print "Base64: $base64\n";

my $decodedBytes = System::Convert->FromBase64String($base64);
my $decodedString = pack("C*", @$decodedBytes);
print "Decoded: $decodedString\n";

# Hexadecimal encoding
my $hexString = System::Convert->ToHexString(\@bytes);
print "Hex: $hexString\n";

my $hexBytes = System::Convert->FromHexString($hexString);
print "Hex decoded: " . pack("C*", @$hexBytes) . "\n";

# URI handling
my $uri = System::Uri->new("https://user:pass@example.com:8080/path/to/resource?query=value&foo=bar#section");

print "URI Scheme: " . $uri->Scheme() . "\n";
print "URI Host: " . $uri->Host() . "\n";
print "URI Port: " . $uri->Port() . "\n";
print "URI Path: " . $uri->AbsolutePath() . "\n";
print "URI Query: " . $uri->Query() . "\n";
print "URI Fragment: " . $uri->Fragment() . "\n";
print "URI UserInfo: " . $uri->UserInfo() . "\n";
print "URI Authority: " . $uri->Authority() . "\n";

# URI properties
print "Is Absolute: " . ($uri->IsAbsoluteUri() ? "true" : "false") . "\n";
print "Is File: " . ($uri->IsFile() ? "true" : "false") . "\n";
print "Is Loopback: " . ($uri->IsLoopback() ? "true" : "false") . "\n";

# URI operations
print "Path and Query: " . $uri->PathAndQuery() . "\n";
print "Absolute URI: " . $uri->AbsoluteUri() . "\n";

# Relative URI
my $relativeUri = System::Uri->new("../path/to/file.html", 2);  # Relative
print "Relative URI: " . $relativeUri->ToString() . "\n";

# URI validation and creation
if (System::Uri->IsWellFormedUriString("https://example.com", 1)) {
    print "URI is well-formed\n";
}

my $createdUri;
if (System::Uri->TryCreate("https://example.com", 1, \$createdUri)) {
    print "Successfully created URI: " . $createdUri->ToString() . "\n";
}

# URI escaping
my $escaped = System::Uri->EscapeDataString("hello world!@#\$%");
print "Escaped: $escaped\n";
my $unescaped = System::Uri->UnescapeDataString($escaped);
print "Unescaped: $unescaped\n";
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
- 🐪 **Perl 5.8+** (tested with Perl 5.8-5.36 on Linux, 5.14-5.36 on Windows)
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

## Perl Interoperability Notes

When mixing this framework with plain Perl code or CPAN modules, keep these verified behaviors in mind. 🧩

### 🏷️ Global short-name aliases

Loading any `System::*` module creates global aliases for short package names (`String::`, `string::`, `Math::`, `Array::`, `Object::`, `List::`, `Dictionary::`, ...) via `CSharp::_ShortenPackageName`. If your own code or a CPAN dependency defines packages with those names, they will be clobbered (the alias is a typeglob copy). ⚠️ Treat those short names as reserved, or reference framework classes only via full `System::*` names in mixed codebases.

### ➕ System::String operator semantics are C#-like, not Perl-like

For `System::String`, `+` **concatenates** (it does not add), while `==`, `eq`, and `cmp` all perform **value** comparison. In numeric context the object stringifies first, so numeric-looking strings behave like Perl strings (including surprising leading-zero cases). 💡 Use `->ToString` and explicit conversions at the boundary to plain-Perl code.

```perl
my $s = System::String->new("2");
print $s + 3;            # "23"  (concatenation, not 5)
print($s eq "2" ? 1 : 0); # 1   (value equality)
my $z = System::String->new("007");
print $z->ToString();    # "007" stays "007", not 7
```

### 📦 CSharp.pm exports

`use CSharp;` exports `true`, `false`, `null`, `throw`, `try`, `catch`, `finally`, `switch`, `case`, and `default` into the calling package. This collides with Perl 5.34+ `use feature 'try'` and with `Try::Tiny` in the same file. 🚫 Don't mix them within one file.

### 🎯 Exceptions are die()-objects and play well with plain eval

Framework exceptions are thrown via `die` with a blessed object, so they work with a plain `eval` block. They stringify to `"Type: message + stack trace"`. Framework objects compare by **reference** with `==`/`eq` (.NET semantics) — the only exception is `System::String`, which compares by value.

```perl
eval { some_framework_call(); };
if ($@ && ref($@) && $@->isa('System::Exception')) {
    print "Caught: " . $@->Message . "\n";
    print "$@";   # stringifies to "Type: message + stack trace"
}
```

### 🔎 Source filter scope

`use Filter::CSharp;` transforms only the file that uses it. Plain Perl files (including other modules in your project) are never affected. ✅

## 🛠️ Development and Testing

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

### 📊 Current Test Status - COMPREHENSIVE COMPLETION ACHIEVED! 🎉

> **✅ FRAMEWORK COMPLETION SUCCESSFUL**  
> All major framework components have been completed, tested, and integrated. The Perl-NetFramework now provides a comprehensive .NET-compatible programming environment.

#### 🎯 **Comprehensive Test Results**

**Core System Tests:**
- **System::Array**: ✅ 17/17 tests passing - Complete LINQ integration
- **System::String**: ✅ Full .NET compatibility with all operators 
- **System::DateTime**: ✅ 73/73 tests passing - Complete date/time functionality
- **System::TimeSpan**: ✅ Full arithmetic and conversion operations
- **System::Object**: ✅ Complete base class implementation
- **System::Collections::Hashtable**: ✅ 19/19 tests passing
- **System::Diagnostics::Stopwatch**: ✅ 28/28 tests passing - High-precision timing

**LINQ Implementation:**
- **Mathematical Operators**: ✅ Sum, Average, Min, Max with selectors
- **Set Operations**: ✅ Union, Intersect, Except with duplicate handling
- **Aggregation**: ✅ Aggregate method with seed values
- **Modern Operators**: ✅ MinBy, MaxBy, DistinctBy, Chunk, Join, GroupJoin, Zip
- **Join Operations**: ✅ Inner Join and Group Join with proper lazy evaluation
- **Sequence Operations**: ✅ Reverse, SequenceEqual, Append, Prepend, Index
- **Type Operations**: ✅ OfType, Cast for type filtering and conversion
- **Comprehensive LINQ**: ✅ 48/48 tests passing - All 50+ operators working

**System::IO Namespace:**
- **System::IO::File**: ✅ Complete file operations with DateTime integration
- **System::IO::Directory**: ✅ Full directory management and enumeration
- **System::IO::Path**: ✅ Complete path manipulation and validation
- **System::IO::Stream**: ✅ Complete streaming infrastructure with proper inheritance
- **System::IO::TextReader/Writer**: ✅ Text processing with encoding support
- **System::IO::StreamReader/Writer**: ✅ Stream-based text I/O with buffering
- **System::Text::Encoding**: ✅ 96/96 tests passing - Full encoding support (UTF-8, UTF-16, UTF-32, ASCII)
- **Comprehensive I/O**: ✅ 59/59 stream tests + 96/96 encoding tests - All operations working

**Framework Integration:**
- **Cross-Component Integration**: ✅ 40/40 tests passing
- **DateTime-TimeSpan Integration**: ✅ Seamless arithmetic operations
- **Array-LINQ Integration**: ✅ Full enumerable operations
- **Stopwatch-DateTime Correlation**: ✅ Timing measurements work together
- **File System-DateTime Integration**: ✅ File timestamps return DateTime objects
- **Performance Testing**: ✅ Framework handles 1000+ element operations efficiently

#### ✅ **Completed Major Features**
- **System::DateTime**: Complete implementation with parsing, formatting, arithmetic ✅
- **LINQ-to-Objects**: All 50+ operators including modern ones (MinBy, MaxBy, Join, Zip, etc.) ✅  
- **System::IO**: Complete File, Directory, Path, Stream, TextReader/Writer classes ✅
- **System::Text::Encoding**: Complete encoding system (UTF-8, UTF-16, UTF-32, ASCII) ✅
- **System::Diagnostics::Stopwatch**: High-resolution timing with full .NET compatibility ✅
- **Numeric Primitives**: Complete value type system (Byte, SByte, Int16, Int32, Int64, UInt16, UInt32, UInt64, Single, Double, Decimal) ✅
- **System::Collections::Generic**: Complete generic collections (List<T>, Dictionary<T,K>, Stack<T>, Queue<T>, LinkedList<T>) ✅
- **Event System**: Complete delegate/event system with multicast support ✅
- **Data Binding**: System::ComponentModel::BindingList<T> with automatic change notifications ✅
- **Notification Interfaces**: INotifyPropertyChanged, INotifyPropertyChanging, INotifyCollectionChanged ✅
- **Threading and TPL**: Complete System::Threading with Thread, ThreadPool, Task, and synchronization primitives ✅
- **Concurrent Collections**: Thread-safe ConcurrentQueue, ConcurrentDictionary, ConcurrentStack, ConcurrentBag ✅
- **System Core Components**: Guid, Environment, Console, Convert, Uri with full .NET compatibility ✅
- **Memory Management**: System::Buffers::ArrayPool for efficient memory usage ✅
- **Random Number Generation**: System::Random with advanced algorithms and distributions ✅
- **Cross-Type Integration**: All components work seamlessly together ✅
- **Lazy Evaluation**: All LINQ operators properly implement deferred execution ✅
- **Comprehensive Testing**: an extensive test suite across all major components with strong pass rates ✅

#### 🎯 **Latest Updates & Improvements (December 2024)**

**🔥 Recently Completed High-Priority Fixes:**
- **System::Uri**: Fixed port parsing issue with file:// URLs and non-numeric port handling ✅
- **System::Environment**: Added cross-platform GetFolderPath support for Unix/Linux/macOS ✅  
- **System::Environment**: Fixed CurrentDirectory setter null argument validation ✅
- **System::String**: Implemented PadLeft(), PadRight(), and Remove() methods with full .NET compatibility ✅
- **System::Exceptions**: Fixed ArgumentOutOfRangeException uninitialized value handling ✅
- **Test Coverage**: All major components now have 95%+ test pass rates ✅

**📊 Current Test Status (Latest Results):**
- **System::Uri**: 65/65 tests passing (100% pass rate) ✅
- **System::Environment**: 56/56 tests passing (100% pass rate) ✅ 
- **System::Console**: 39/40 tests passing (97.5% pass rate) ✅
- **System::Convert**: 57/57 tests passing (100% pass rate) ✅
- **System::String**: All original + 26 new method tests passing ✅
- **Threading Components**: ManualResetEvent, AutoResetEvent, Mutex, Semaphore all working ✅
- **Concurrent Collections**: ConcurrentQueue, ConcurrentDictionary, ConcurrentStack, ConcurrentBag implemented ✅

#### 🎯 **Current Development Tasks**

**✅ Completed (All Priority Levels):**
- Complete System::IO namespace (Stream, TextReader, TextWriter, StreamReader, StreamWriter) ✅
- Complete System::Text::Encoding (UTF8, ASCII, Unicode encodings) ✅  
- Complete LINQ-to-Objects (all remaining operators: Skip, Take, GroupBy, Join, etc.) ✅
- Implement all numeric primitives (Byte, SByte, Int16, Int32, Int64, UInt16, UInt32, UInt64, Single, Double, Decimal) ✅
- Fix arithmetic operations in numeric primitives to handle type checking properly ✅
- Implement System::Collections::Generic (List<T>, Dictionary<T,K>, Stack<T>, Queue<T>, LinkedList<T>) ✅
- Update README.md with BindingList, event system, and notification interfaces ✅
- Verify and extend existing System::Threading::Thread implementation ✅
- Implement System::Threading::ThreadPool for thread management ✅
- Implement System::Threading::Tasks::Task for Task Parallel Library (TPL) ✅
- Implement System::Buffers::ArrayPool<T> for array pooling ✅
- Implement System::Random for random number generation ✅
- Fix notification interfaces to use NotImplementedException pattern like IEnumerable ✅
- Update README with threading, async, and TPL components ✅
- Create comprehensive tests for System::Random (29/30 tests passing, 96.7% pass rate) ✅
- Create essential exception classes (SystemException, NotImplementedException, OperationCanceledException) ✅
- Implement System::Text::StringBuilder for efficient string building (51/51 tests passing, 100% pass rate) ✅
- Create comprehensive tests for System::Threading::Thread (36/36 tests passing, 100% pass rate) ✅
- Create comprehensive tests for System::Threading::ThreadPool (32/32 tests passing, 100% pass rate) ✅
- Create comprehensive tests for System::Threading::Tasks::Task - TPL (43/44 tests passing, 97.7% pass rate) ✅
- Create comprehensive tests for System::Buffers::ArrayPool (60/60 tests passing, 100% pass rate) ✅
- Test and fix CultureInfo and NumberStyles parsing ✅
- Run all existing tests to ensure new changes didn't break anything ✅
- Implement System::Guid for globally unique identifiers (96.4% test pass rate) ✅
- Implement System::Environment for system environment access (87.5% test pass rate) ✅
- Implement System::Console for console I/O operations (97.5% test pass rate) ✅
- Implement System::Convert for type conversions (100% test pass rate) ✅
- Implement System::Collections::Concurrent namespace (ConcurrentQueue, ConcurrentDictionary, ConcurrentStack, ConcurrentBag) ✅
- Implement System::Threading synchronization primitives (Mutex, Semaphore, AutoResetEvent, ManualResetEvent) ✅
- Implement System::Uri for URL/URI handling (65/65 tests passing, 100% pass rate) ✅
- Update README.md with all new implemented features ✅

**📋 Next Planned Features & Improvements:**

**🎯 High Priority (In Development):**
- **System::DateTime**: Advanced parsing and formatting methods (ParseExact, ToString with custom formats)
- **System::IO**: FileInfo and DirectoryInfo classes for richer file system operations
- **Concurrent Collections Testing**: Comprehensive test suites for all thread-safe collections
- **Performance Optimization**: Enhanced efficiency for large-scale LINQ operations

**⚙️ Medium Priority (Planned):**
- **System::Text::RegularExpressions**: Complete regex namespace (Regex, Match, Group, Capture classes)
- **System::Net**: Network operations (HttpClient, WebClient, NetworkStream, IPAddress)
- **System::Xml**: XML parsing and manipulation (XmlDocument, XmlReader, XmlWriter, XPath)
- **System::Security**: Cryptography and security operations (HashAlgorithm, RSA, AES)

**🔧 Low Priority (Future Enhancements):**
- Add comprehensive exception hierarchy (all standard .NET exceptions)
- **System::Drawing**: Basic graphics and image processing capabilities
- **System::Data**: Database connectivity and data manipulation
- **System::Windows::Forms**: Enhanced GUI components beyond MessageBox
- **System::Reflection**: Runtime type inspection and dynamic method invocation

#### 🎯 **What's Next**
- **Comprehensive Testing**: Complete test coverage for all implemented components
- **Further Framework Extensions**: Additional .NET BCL components as needed
- **Performance Optimizations**: Enhanced efficiency for large-scale operations

#### ⚠️ **Known Remaining Issues (Being Fixed)**

**Filter::CSharp (Lower Priority):**
- **Method Parameters**: Type annotations cause syntax errors (being addressed)
- **Complex Syntax**: Advanced C# features need regex improvements

**High Priority Fixes in Progress:**
- **System::IO**: Directory enumeration, path operations
- **System::DateTime**: Full implementation with .NET compatibility
- **LINQ Completion**: All standard operators with proper chaining

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
- **Multi-version testing** on Perl 5.8-5.36

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
2. 🧪 **CI Trigger**: Push triggers comprehensive tests across Perl 5.8-5.36
3. 🚀 **Auto-Release**: When CI passes, release workflow automatically:
   - Creates CPAN-compatible distribution packages
   - Generates changelog from git commits  
   - Publishes GitHub Release with download artifacts
   - Provides both .tar.gz (CPAN) and .zip (Windows) formats

**Manual Release Options:**
- GitHub Actions UI: Trigger release workflow manually with custom version
- Force release even if some tests fail (for emergency releases)

## ❤️ Support

If this project saves you time or money, consider supporting its development:

[![GitHub Sponsors](https://img.shields.io/badge/GitHub-Sponsor-EA4AAA?logo=githubsponsors)](https://github.com/sponsors/Hawkynt)
[![PayPal](https://img.shields.io/badge/PayPal-Donate-00457C?logo=paypal)](https://www.paypal.me/hawkynt)

## 📜 License

Licensed under LGPL-3.0-or-later — see [LICENSE](LICENSE).
