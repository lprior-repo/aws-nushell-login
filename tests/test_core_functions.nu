#!/usr/bin/env nu
# Core Functions Unit Tests (70% of test suite - Unit Tests)
# Tests individual functions in isolation with mocked dependencies

use std assert
source ../aws-login.nu

# =============================================================================
# SETUP AND TEARDOWN
# =============================================================================

#[before-each]
def setup [] {
    # Create clean test environment
    {
        temp_dir: (mktemp -d),
        original_aws_dir: ($env.AWS_CONFIG_DIR? | default "~/.aws"),
        test_profile: "test-profile-unit"
    }
}

#[after-each] 
def cleanup [] {
    let context = $in
    # Clean up test environment
    try { 
        rm -rf $context.temp_dir 
    } catch { 
        # Ignore cleanup errors
    }
    clear_aws_env
}

# =============================================================================
# UTILITY FUNCTION TESTS
# =============================================================================

#[test]
def "validate_profile_name - should accept valid names" [] {
    validate_profile_name "valid-profile"
    validate_profile_name "valid_profile" 
    validate_profile_name "profile123"
    validate_profile_name "production"
    assert true "Valid profile names should pass"
}

#[test] 
def "validate_profile_name - should reject empty name" [] {
    let error_caught = try {
        validate_profile_name ""
        false
    } catch {
        true  
    }
    assert $error_caught "Empty profile name should fail validation"
}

#[test]
def "validate_profile_name - should reject names with spaces" [] {
    let error_caught = try {
        validate_profile_name "profile with spaces"
        false
    } catch {
        true
    }
    assert $error_caught "Profile names with spaces should fail"
}

#[test]
def "validate_profile_name - should reject names with slashes" [] {
    let error_caught = try {
        validate_profile_name "profile/with/slashes"
        false
    } catch {
        true
    }
    assert $error_caught "Profile names with slashes should fail"
}

#[test]
def "mask_sensitive - should mask AWS access keys" [] {
    let masked = mask_sensitive "AKIA1234567890123456 some other text"
    assert ($masked | str contains "AKIA****************") "Should mask AWS access keys"
    assert ($masked | str contains "some other text") "Should preserve non-sensitive text"
}

#[test]
def "mask_sensitive - should mask secret keys" [] {
    let secret = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN"  # 40 chars
    let masked = mask_sensitive $"Secret: ($secret)"
    assert ($masked | str contains "****************************************") "Should mask 40-char secrets"
    assert ($masked | str contains "Secret:") "Should preserve context"
}

#[test]
def "mask_sensitive - should handle multiple sensitive values" [] {
    let text = "Access: AKIA1234567890123456 Secret: abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN"
    let masked = mask_sensitive $text
    assert ($masked | str contains "AKIA****************") "Should mask access key"
    assert ($masked | str contains "****************************************") "Should mask secret"
}

#[test]
def "mask_sensitive - should handle no sensitive data" [] {
    let text = "No sensitive data here"
    let masked = mask_sensitive $text
    assert ($masked == $text) "Should return unchanged text when no sensitive data"
}

# =============================================================================
# ENVIRONMENT MANAGEMENT TESTS
# =============================================================================

#[test]
def "clear_aws_env - should clear existing AWS variables" [] {
    # Set up test AWS environment variables
    $env.AWS_PROFILE = "test"
    $env.AWS_ACCESS_KEY_ID = "test-key"
    $env.AWS_SECRET_ACCESS_KEY = "test-secret"
    $env.AWS_SESSION_TOKEN = "test-token"
    $env.AWS_DEFAULT_REGION = "us-east-1"
    $env.AWS_REGION = "us-east-1" 
    $env.AWS_CREDENTIAL_EXPIRY = "2024-01-01 12:00:00"
    
    # Clear environment
    clear_aws_env
    
    # Verify variables are cleared
    assert not ("AWS_PROFILE" in ($env | columns)) "AWS_PROFILE should be cleared"
    assert not ("AWS_ACCESS_KEY_ID" in ($env | columns)) "AWS_ACCESS_KEY_ID should be cleared"
    assert not ("AWS_SECRET_ACCESS_KEY" in ($env | columns)) "AWS_SECRET_ACCESS_KEY should be cleared"
    assert not ("AWS_SESSION_TOKEN" in ($env | columns)) "AWS_SESSION_TOKEN should be cleared"
    assert not ("AWS_DEFAULT_REGION" in ($env | columns)) "AWS_DEFAULT_REGION should be cleared"
    assert not ("AWS_REGION" in ($env | columns)) "AWS_REGION should be cleared"
    assert not ("AWS_CREDENTIAL_EXPIRY" in ($env | columns)) "AWS_CREDENTIAL_EXPIRY should be cleared"
}

#[test]
def "clear_aws_env - should handle missing variables gracefully" [] {
    # Ensure clean start
    clear_aws_env
    
    # Try to clear again (should not error)
    clear_aws_env
    
    assert true "Should handle clearing non-existent variables"
}

# =============================================================================
# PROFILE LISTING TESTS  
# =============================================================================

#[test]
def "list_aws_profiles - should return empty table when no profiles exist" [] {
    let context = $in
    # Create temporary AWS config directory without files
    mkdir $context.temp_dir
    
    # Mock AWS_CONFIG_DIR to point to temp directory
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        let profiles = list_aws_profiles
        assert (($profiles | length) == 0) "Should return empty list when no profiles"
        assert ($profiles | describe | str starts-with "table") "Should return table structure"
    }
}

#[test]
def "list_aws_profiles - should parse credentials file correctly" [] {
    let context = $in
    mkdir $context.temp_dir
    
    # Create mock credentials file
    let creds_content = "[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE  
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[production]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY"
    
    $creds_content | save $"($context.temp_dir)/credentials"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        let profiles = list_aws_profiles
        assert (($profiles | length) == 2) "Should find 2 profiles"
        assert ("default" in ($profiles | get profile)) "Should include default profile"
        assert ("production" in ($profiles | get profile)) "Should include production profile"
    }
}

#[test]
def "list_aws_profiles - should identify SSO profiles correctly" [] {
    let context = $in
    mkdir $context.temp_dir
    
    # Create mock config file with SSO profile
    let config_content = "[default]
region = us-east-1

[profile sso-profile]
sso_start_url = https://example.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = AdminRole
region = us-east-1"
    
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        let profiles = list_aws_profiles
        let sso_profile = $profiles | where profile == "sso-profile" | first
        assert ($sso_profile.type == "SSO") "Should identify SSO profile type"
        
        let default_profile = $profiles | where profile == "default" | first  
        assert ($default_profile.type == "Standard") "Should identify standard profile type"
    }
}

# =============================================================================
# SSO DETECTION TESTS
# =============================================================================

#[test] 
def "is_sso_profile - should detect SSO profiles" [] {
    let context = $in
    mkdir $context.temp_dir
    
    let config_content = "[profile sso-test]
sso_start_url = https://example.awsapps.com/start
sso_region = us-east-1"
    
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        assert (is_sso_profile "sso-test") "Should detect SSO profile"
    }
}

#[test]
def "is_sso_profile - should return false for non-SSO profiles" [] {
    let context = $in
    mkdir $context.temp_dir
    
    let config_content = "[profile regular-profile]  
region = us-east-1"
    
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        assert not (is_sso_profile "regular-profile") "Should not detect non-SSO profile as SSO"
    }
}

#[test]
def "is_sso_profile - should handle missing config file" [] {
    let context = $in
    mkdir $context.temp_dir
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        assert not (is_sso_profile "any-profile") "Should return false when config file missing"
    }
}

# =============================================================================
# REGION PARSING TESTS
# =============================================================================

#[test]
def "get_profile_region - should parse region from config" [] {
    let context = $in
    mkdir $context.temp_dir
    
    let config_content = "[default]
region = us-west-2

[profile test-profile]
region = eu-west-1"
    
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        let default_region = get_profile_region "default"
        assert ($default_region == "us-west-2") "Should get default profile region"
        
        let test_region = get_profile_region "test-profile"
        assert ($test_region == "eu-west-1") "Should get named profile region"
    }
}

#[test]
def "get_profile_region - should return null for missing profile" [] {
    let context = $in
    mkdir $context.temp_dir
    
    let config_content = "[default]
region = us-east-1"
    
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        let region = get_profile_region "nonexistent"
        assert ($region == null) "Should return null for missing profile"
    }
}

#[test]
def "get_profile_region - should handle missing config file" [] {
    let context = $in
    mkdir $context.temp_dir
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        let region = get_profile_region "any-profile"
        assert ($region == null) "Should return null when config file missing"
    }
}

# =============================================================================
# ERROR HANDLING TESTS
# =============================================================================

#[test]
def "error handling - should create proper error structures" [] {
    let error_caught = try {
        error make {
            msg: "Test error message"
            help: "Test help message"
        }
        null
    } catch { |e|
        $e
    }
    
    assert ($error_caught.msg == "Test error message") "Should preserve error message"
    assert ($error_caught.help == "Test help message") "Should preserve help message"
}

#[test] 
def "error handling - should propagate through function calls" [] {
    def failing_function []: nothing -> string {
        error make { msg: "Inner function failed" }
    }
    
    def calling_function []: nothing -> string {
        failing_function
    }
    
    let error_caught = try {
        calling_function
        null
    } catch { |e|
        $e
    }
    
    assert ($error_caught.msg == "Inner function failed") "Should propagate error through call chain"
}