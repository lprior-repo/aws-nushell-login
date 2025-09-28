#!/usr/bin/env nu
# Smoke Test - Quick verification that essential functionality works
# Run this as a sanity check after changes

def test_core_loading []: nothing -> nothing {
    try {
        source ../aws-login.nu
        print "✅ Core script loads without errors"
    } catch { |e|
        print $"❌ Core script failed to load: ($e.msg)"
        error make { msg: "Core loading failed" }
    }
}

def test_examples_loading []: nothing -> nothing {
    try {
        source ../examples.nu
        print "✅ Examples load without errors"
    } catch { |e|
        print $"❌ Examples failed to load: ($e.msg)"
        error make { msg: "Examples loading failed" }
    }
}

def test_basic_functions []: nothing -> nothing {
    try {
        source ../aws-login.nu
        
        # Test that core functions exist by checking if we can reference them
        let clear_exists = (which clear_aws_env | length) > 0
        if $clear_exists {
            print "✅ Core functions are accessible"
        } else {
            print "❌ Core functions not found"
            error make { msg: "Functions not accessible" }
        }
    } catch { |e|
        print $"❌ Function test failed: ($e.msg)"
        error make { msg: "Function test failed" }
    }
}

def main []: nothing -> nothing {
    print "💨 Running Smoke Tests..."
    print "========================"
    
    let results = [
        (try { test_core_loading; "passed" } catch { |e| print $"💥 Core loading failed: ($e.msg)"; "failed" })
        (try { test_examples_loading; "passed" } catch { |e| print $"💥 Examples loading failed: ($e.msg)"; "failed" })  
        (try { test_basic_functions; "passed" } catch { |e| print $"💥 Function test failed: ($e.msg)"; "failed" })
    ]
    
    let passed = ($results | where $it == "passed" | length)
    let failed = ($results | where $it == "failed" | length)
    
    print "========================"
    print $"Results: ($passed) passed, ($failed) failed"
    
    if $failed == 0 {
        print "🎉 All smoke tests passed! System is functional."
    } else {
        print "💥 Some smoke tests failed!"
        exit 1
    }
}