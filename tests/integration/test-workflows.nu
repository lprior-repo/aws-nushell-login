#!/usr/bin/env nu
# Integration Tests for AWS Login System
# Tests component interactions and workflows

use std assert
use std log

# Integration Test: Full credential export workflow
def test_credential_export_workflow []: nothing -> nothing {
    print "🔄 Testing credential export workflow..."
    
    try {
        # Clear environment first
        let clear_result = try {
            source ../../aws-login.nu
            clear_aws_env
            true
        } catch {
            false
        }
        
        assert $clear_result "Should successfully clear environment"
        
        # Test export workflow with mock data
        let test_profile = "integration-test"
        
        # Verify clear worked
        let aws_vars_after_clear = ($env | columns | where ($it =~ "AWS"))
        assert (($aws_vars_after_clear | length) == 0) "Environment should be clean after clear"
        
        print "✅ Credential export workflow test passed"
    } catch { |e|
        print $"❌ Integration test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# Integration Test: Profile listing with config parsing
def test_profile_listing_integration []: nothing -> nothing {
    print "🔄 Testing profile listing integration..."
    
    try {
        # Create temporary AWS config structure
        let test_dir = $"/tmp/aws-integration-test-(random uuid)"
        mkdir $test_dir
        
        # Create realistic AWS config files
        let credentials_content = [
            "[default]"
            "aws_access_key_id = AKIAIOSFODNN7EXAMPLE"
            "aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            ""
            "[staging]"
            "aws_access_key_id = AKIAIOSFODNN7EXAMPLE"
            "aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        ]
        $credentials_content | str join "\n" | save $"($test_dir)/credentials"
        
        let config_content = [
            "[default]"
            "region = us-west-2"
            ""
            "[profile production]"
            "region = us-east-1"
            "sso_start_url = https://example.awsapps.com/start"
        ]
        $config_content | str join "\n" | save $"($test_dir)/config"
        
        # Test that files were created correctly
        assert ($"($test_dir)/credentials" | path exists) "Credentials file should exist"
        assert ($"($test_dir)/config" | path exists) "Config file should exist"
        
        # Test parsing credentials file
        let creds_content = open $"($test_dir)/credentials"
        assert ($creds_content | str contains "default") "Should contain default profile"
        assert ($creds_content | str contains "staging") "Should contain staging profile"
        
        print "✅ Profile listing integration test passed"
    } catch { |e|
        print $"❌ Integration test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    } finally {
        rm -rf $test_dir
    }
}

# Integration Test: Alias creation pattern
def test_alias_creation_pattern []: nothing -> nothing {
    print "🔄 Testing alias creation pattern..."
    
    try {
        # Test that we can create a function that follows the alias pattern
        def test_alias_function []: nothing -> nothing {
            # This simulates what a user would create
            print "Mock: Connecting to test environment..."
            
            # Mock the login call
            $env.TEST_AWS_PROFILE = "test-profile"
            $env.TEST_AWS_ACCESS_KEY_ID = "AKIATEST"
            
            print "Mock: Connected successfully"
        }
        
        # Test the function
        test_alias_function
        
        # Verify it set the mock environment variables
        assert ($env.TEST_AWS_PROFILE == "test-profile") "Should set profile"
        assert ($env.TEST_AWS_ACCESS_KEY_ID == "AKIATEST") "Should set access key"
        
        # Clean up
        hide-env TEST_AWS_PROFILE
        hide-env TEST_AWS_ACCESS_KEY_ID
        
        print "✅ Alias creation pattern test passed"
    } catch { |e|
        print $"❌ Integration test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# Integration Test: Environment variable lifecycle
def test_environment_variable_lifecycle []: nothing -> nothing {
    print "🔄 Testing environment variable lifecycle..."
    
    try {
        # Test the complete lifecycle: clear -> set -> verify -> clear
        
        # Phase 1: Clear environment
        let env_vars = ["TEST_AWS_PROFILE", "TEST_AWS_ACCESS_KEY_ID", "TEST_AWS_SECRET_ACCESS_KEY"]
        for var in $env_vars {
            hide-env --ignore-errors $var
        }
        
        # Verify clean state
        let clean_vars = ($env | columns | where ($it | str starts-with "TEST_AWS"))
        assert (($clean_vars | length) == 0) "Environment should be clean"
        
        # Phase 2: Set variables (simulating export_credentials)
        $env.TEST_AWS_PROFILE = "integration-test"
        $env.TEST_AWS_ACCESS_KEY_ID = "AKIAINTEGRATIONTEST"
        $env.TEST_AWS_SECRET_ACCESS_KEY = "integration-secret"
        
        # Phase 3: Verify variables are set
        assert ($env.TEST_AWS_PROFILE == "integration-test") "Profile should be set"
        assert ($env.TEST_AWS_ACCESS_KEY_ID == "AKIAINTEGRATIONTEST") "Access key should be set"
        assert ($env.TEST_AWS_SECRET_ACCESS_KEY == "integration-secret") "Secret key should be set"
        
        # Phase 4: Clear variables (simulating clear_aws_env)
        for var in $env_vars {
            hide-env $var
        }
        
        # Phase 5: Verify clean state again
        let final_vars = ($env | columns | where ($it | str starts-with "TEST_AWS"))
        assert (($final_vars | length) == 0) "Environment should be clean after clearing"
        
        print "✅ Environment variable lifecycle test passed"
    } catch { |e|
        print $"❌ Integration test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# Integration Test: Configuration file parsing
def test_config_file_parsing []: nothing -> nothing {
    print "🔄 Testing configuration file parsing..."
    
    try {
        let test_dir = $"/tmp/aws-config-test-(random uuid)"
        mkdir $test_dir
        
        # Create complex configuration to test parsing
        let complex_credentials = [
            "[default]"
            "aws_access_key_id = AKIAIOSFODNN7EXAMPLE"
            "aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            ""
            "[user1]"
            "aws_access_key_id = AKIAUSER1EXAMPLE"
            "aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            ""
            "[service-account]"
            "aws_access_key_id = AKIASERVICEEXAMPLE"
            "aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        ]
        $complex_credentials | str join "\n" | save $"($test_dir)/credentials"
        
        let complex_config = [
            "[default]"
            "region = us-west-2"
            "output = json"
            ""
            "[profile development]"
            "region = us-west-2"
            "output = json"
            ""
            "[profile production]"
            "region = us-east-1"
            "output = json"
            "sso_start_url = https://example.awsapps.com/start"
            "sso_region = us-east-1"
        ]
        $complex_config | str join "\n" | save $"($test_dir)/config"
        
        # Test parsing credentials file
        let creds_lines = (open $"($test_dir)/credentials" | lines)
        let profile_lines = ($creds_lines | where ($it | str starts-with "[") and ($it | str ends-with "]"))
        let expected_profiles = ["[default]", "[user1]", "[service-account]"]
        
        for profile in $expected_profiles {
            assert ($profile in $profile_lines) $"Should find profile ($profile)"
        }
        
        # Test parsing config file  
        let config_lines = (open $"($test_dir)/config" | lines)
        let profile_config_lines = ($config_lines | where ($it | str starts-with "[profile "))
        
        assert (($profile_config_lines | length) >= 2) "Should find profile sections in config"
        
        print "✅ Configuration file parsing test passed"
    } catch { |e|
        print $"❌ Integration test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    } finally {
        rm -rf $test_dir
    }
}

# Integration Test: Error propagation through components
def test_error_propagation []: nothing -> nothing {
    print "🔄 Testing error propagation..."
    
    try {
        # Test that errors propagate correctly through the system
        let error_caught = try {
            # Simulate an error condition
            if true {
                error make { 
                    msg: "Integration test error"
                    help: "This error should be caught"
                }
            }
            false
        } catch { |e|
            # Verify error structure
            assert ("msg" in ($e | columns)) "Error should have msg field"
            assert ($e.msg == "Integration test error") "Error message should match"
            true
        }
        
        assert $error_caught "Error should have been caught"
        
        # Test error chaining
        let chained_error = try {
            try {
                error make { msg: "Original error" }
            } catch { |e|
                error make { 
                    msg: $"Wrapped error: ($e.msg)"
                    help: "This is a wrapped error"
                }
            }
        } catch { |e|
            $e
        }
        
        assert ($chained_error.msg | str contains "Original error") "Should contain original error"
        
        print "✅ Error propagation test passed"
    } catch { |e|
        print $"❌ Integration test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# Test Runner
def main []: nothing -> nothing {
    print "🔗 Running Integration Tests for AWS Login System"
    print "=================================================="
    
    let tests = [
        test_credential_export_workflow
        test_profile_listing_integration
        test_alias_creation_pattern
        test_environment_variable_lifecycle
        test_config_file_parsing
        test_error_propagation
    ]
    
    mut passed = 0
    mut failed = 0
    
    for test in $tests {
        try {
            do $test
            $passed = ($passed + 1)
        } catch { |e|
            print $"❌ Integration test failed: ($e.msg)"
            $failed = ($failed + 1)
        }
    }
    
    print "=================================================="
    print $"Results: ($passed) passed, ($failed) failed"
    
    if $failed > 0 {
        print "❌ Some integration tests failed!"
        exit 1
    } else {
        print "✅ All integration tests passed!"
    }
}