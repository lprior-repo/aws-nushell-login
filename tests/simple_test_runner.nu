#!/usr/bin/env nu
# Simple test runner to verify AWS login functionality

use ../nutest

def main [test_type: string = "quick"]: nothing -> nothing {
    print $"🧪 Running ($test_type) tests for AWS Nushell Login"
    
    match $test_type {
        "quick" => {
            print "⚡ Running quick unit tests..."
            nutest run-tests --path . --match-suites "test_core_functions" --display terminal
        }
        "full" => {
            print "🚀 Running full test suite..."
            nutest run-tests --path . --display terminal
        }
        _ => {
            print "Usage: ./simple_test_runner.nu [quick|full]"
        }
    }
}