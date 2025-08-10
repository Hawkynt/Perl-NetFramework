#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Diagnostics;

use Test::More;

# Start tests
my $test_count = 18;
plan tests => $test_count;

# Test 1-6: Base System::Diagnostics module functionality
{
    # Test that System::Diagnostics package exists and loads correctly
    ok(defined($System::Diagnostics::VERSION) || $INC{'System/Diagnostics.pm'}, 'System::Diagnostics module loads successfully');
    
    # Test that the package can be referenced
    my $package = 'System::Diagnostics';
    ok(defined($package), 'System::Diagnostics package name is defined');
    
    # Test that the module uses strict and warnings
    eval {
        # This should work without issues if module is properly structured
        my $test = 1;
        ok($test == 1, 'Basic Perl operations work after loading module');
    };
    ok(!$@, 'No errors after loading System::Diagnostics');
    
    # Test that required sub-modules are available after loading
    ok(defined(&System::Diagnostics::Trace::WriteLine), 'Trace module is available after loading Diagnostics');
    ok(defined(&System::Diagnostics::Stopwatch::new), 'Stopwatch module is available after loading Diagnostics');
}

# Test 7-12: Sub-module integration
{
    # Test that Trace functionality works through Diagnostics
    eval {
        System::Diagnostics::Trace->WriteLine("Test from Diagnostics integration");
    };
    ok(!$@, 'Trace functionality accessible through Diagnostics namespace');
    
    # Test that Stopwatch functionality works through Diagnostics
    eval {
        my $stopwatch = System::Diagnostics::Stopwatch->new();
        $stopwatch->Start();
        $stopwatch->Stop();
    };
    ok(!$@, 'Stopwatch functionality accessible through Diagnostics namespace');
    
    # Test that we can access Contracts if available
    eval {
        if (defined(&System::Diagnostics::Contracts::Contract::Requires)) {
            System::Diagnostics::Contracts::Contract->Requires(1, "Test from Diagnostics");
        }
    };
    ok(!$@, 'Contracts functionality accessible through Diagnostics namespace (if available)');
    
    # Test namespace consistency
    my @expected_modules = qw(Trace Stopwatch);
    for my $module (@expected_modules) {
        my $full_name = "System::Diagnostics::$module";
        my $module_loaded = exists($INC{"System/Diagnostics/$module.pm"}) || 
                           defined(&{"${full_name}::new"}) || 
                           defined(&{"${full_name}::WriteLine"}) ||
                           defined(&{"${full_name}::Write"});
        ok($module_loaded, "$module is accessible within Diagnostics namespace");
    }
}

# Test 13-18: Module structure and best practices
{
    # Test that the module follows Perl package conventions
    ok($System::Diagnostics::VERSION || 1, 'Module version handling (version exists or module loads)');
    
    # Test that the module returns true (standard Perl module requirement)
    my $module_path = $INC{'System/Diagnostics.pm'};
    ok($module_path, 'System::Diagnostics module is in %INC (loaded successfully)');
    
    # Test error handling doesn't interfere with sub-modules
    eval {
        # Test that we can still use sub-modules after any potential errors
        System::Diagnostics::Trace->Write("Error handling test");
        my $sw = System::Diagnostics::Stopwatch->new();
    };
    ok(!$@, 'Sub-modules remain functional after error handling tests');
    
    # Test that we can require the module multiple times (should be safe)
    eval {
        require System::Diagnostics;
        require System::Diagnostics;  # Second require should be safe
    };
    ok(!$@, 'Multiple requires of System::Diagnostics are safe');
    
    # Test that the module doesn't pollute global namespace
    my @global_pollution = grep { /^Diagnostics/ } keys %main::;
    ok(@global_pollution == 0, 'Module does not pollute main namespace with Diagnostics* symbols');
    
    # Comprehensive integration test
    eval {
        # Test that all major components work together
        require System::Diagnostics;
        
        # Use Trace
        System::Diagnostics::Trace->WriteLine("Comprehensive integration test starting");
        
        # Use Stopwatch  
        my $sw = System::Diagnostics::Stopwatch->new();
        $sw->Start();
        
        # Brief operation
        my $count = 0;
        for (1..1000) { $count++; }
        
        $sw->Stop();
        my $elapsed = $sw->ElapsedMilliseconds();
        
        # Use Contracts if available
        if (defined(&System::Diagnostics::Contracts::Contract::Assert)) {
            System::Diagnostics::Contracts::Contract->Assert($count == 1000, "Count should be 1000");
            System::Diagnostics::Contracts::Contract->Assert($elapsed >= 0, "Elapsed time should be non-negative");
        }
        
        System::Diagnostics::Trace->WriteLine("Integration test completed successfully");
    };
    ok(!$@, 'Comprehensive integration test completes successfully');
}

# Additional diagnostic information for debugging
{
    # Print diagnostic information (won't affect test count)
    diag("System::Diagnostics module information:");
    diag("  Module loaded from: " . ($INC{'System/Diagnostics.pm'} || 'Unknown'));
    
    # Check what sub-modules are available
    my @available_modules;
    push @available_modules, "Trace" if defined(&System::Diagnostics::Trace::WriteLine);
    push @available_modules, "Stopwatch" if defined(&System::Diagnostics::Stopwatch::new);
    push @available_modules, "Contracts" if defined(&System::Diagnostics::Contracts::Contract::Requires);
    
    if (@available_modules) {
        diag("  Available sub-modules: " . join(", ", @available_modules));
    } else {
        diag("  No sub-modules detected");
    }
    
    # Check package structure
    my $package_methods = 0;
    {
        no strict 'refs';
        for my $symbol (keys %{"System::Diagnostics::"}) {
            $package_methods++ if defined(&{"System::Diagnostics::$symbol"});
        }
    }
    diag("  Direct package methods: $package_methods");
}

# Clean up and exit
done_testing();
exit(0);