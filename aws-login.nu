#!/usr/bin/env nu
# AWS Nushell Login - Complete Implementation in Single File
# Comprehensive AWS CLI authentication with profile-specific aliases
# 
# Usage:
#   aws-login [profile] [flags]
#   awsl [profile] [flags]
#
# Examples:
#   aws-login                     # Use default profile
#   aws-login production --sso    # SSO login
#   aws-login dev --temp          # Temporary credentials
#   aws-status                    # Check current status
#   aws-clear                     # Clear credentials

use std log

# =============================================================================
# CONSTANTS AND CONFIGURATION
# =============================================================================

const AWS_CONFIG_DIR = "~/.aws"
const DEFAULT_PROFILE = "default"
const CREDENTIAL_TIMEOUT = 3600  # 1 hour in seconds
const LOG_LEVEL = "INFO"

# =============================================================================
# CORE CREDENTIAL MANAGEMENT FUNCTIONS
# =============================================================================

# Get AWS credentials from config files for a specific profile
def get_aws_credentials [profile: string]: nothing -> record {
    log debug $"Getting credentials for profile: ($profile)"
    
    let credentials_file = $"($AWS_CONFIG_DIR)/credentials" | path expand
    let config_file = $"($AWS_CONFIG_DIR)/config" | path expand
    
    if not ($credentials_file | path exists) {
        error make {
            msg: "AWS credentials file not found"
            help: "Run 'aws configure' to set up your credentials"
        }
    }
    
    # Parse credentials file
    let creds_content = try {
        open $credentials_file
    } catch {
        error make {
            msg: "Failed to read AWS credentials file"
            help: "Check file permissions and format"
        }
    }
    
    # Extract credentials for the specified profile
    let cred_lines = ($creds_content | lines)
    let profile_start = ($cred_lines | enumerate | where item == $"[($profile)]" | first | get index)
    
    if ($profile_start | describe) == "nothing" {
        error make {
            msg: $"Profile '($profile)' not found in credentials file"
            help: $"Available profiles: (list_aws_profiles | get profile | str join ', ')"
        }
    }
    
    # Find the next profile section or end of file
    let next_profile_indices = ($cred_lines | enumerate | skip ($profile_start + 1) | where ($it.item | str starts-with "[") | get index)
    let profile_end = if ($next_profile_indices | length) > 0 { $next_profile_indices | first } else { ($cred_lines | length) }
    
    # Extract profile section
    let profile_section = ($cred_lines | range ($profile_start + 1)..($profile_end - 1) | where ($it | str trim | str length) > 0)
    
    mut credentials = {}
    for line in $profile_section {
        let parts = ($line | str trim | split row " = " | take 2)
        if ($parts | length) == 2 {
            let key = ($parts | first | str trim)
            let value = ($parts | last | str trim)
            $credentials = ($credentials | insert $key $value)
        }
    }
    
    # Validate required fields
    if not ("aws_access_key_id" in ($credentials | columns)) {
        error make {
            msg: $"Missing aws_access_key_id for profile '($profile)'"
        }
    }
    
    if not ("aws_secret_access_key" in ($credentials | columns)) {
        error make {
            msg: $"Missing aws_secret_access_key for profile '($profile)'"
        }
    }
    
    # Get region from config file if available
    let region = try {
        get_profile_region $profile
    } catch {
        null
    }
    
    if $region != null {
        $credentials = ($credentials | insert region $region)
    }
    
    # Add account information
    let account_info = try {
        validate_credentials $profile
    } catch {
        null
    }
    
    if $account_info != null {
        $credentials = ($credentials | insert account_id $account_info.Account)
    }
    
    $credentials
}

# Get region for a profile from AWS config file
def get_profile_region [profile: string]: nothing -> any {
    let config_file = $"($AWS_CONFIG_DIR)/config" | path expand
    
    if not ($config_file | path exists) {
        return null
    }
    
    let config_content = try {
        open $config_file
    } catch {
        return null
    }
    
    let config_lines = ($config_content | lines)
    let section_name = if $profile == "default" { "[default]" } else { $"[profile ($profile)]" }
    let profile_start_idx = ($config_lines | enumerate | where item == $section_name | get index | first?)
    
    if $profile_start_idx == null {
        return null
    }
    
    # Find the next section or end of file
    let next_section_indices = ($config_lines | enumerate | skip ($profile_start_idx + 1) | where ($it.item | str starts-with "[") | get index)
    let profile_end = if ($next_section_indices | length) > 0 { $next_section_indices | first } else { ($config_lines | length) }
    
    # Look for region in this section
    let profile_section = ($config_lines | range ($profile_start_idx + 1)..($profile_end - 1))
    
    for line in $profile_section {
        let trimmed = ($line | str trim)
        if ($trimmed | str starts-with "region") {
            let parts = ($trimmed | split row " = " | take 2)
            if ($parts | length) == 2 {
                return ($parts | last | str trim)
            }
        }
    }
    
    null
}

# Validate credentials by calling AWS STS
def validate_credentials [profile: string]: nothing -> record {
    log debug $"Validating credentials for profile: ($profile)"
    
    let result = try {
        ^aws sts get-caller-identity --profile $profile | complete
    } catch { |e|
        error make {
            msg: $"Failed to validate credentials: ($e.msg)"
        }
    }
    
    if $result.exit_code != 0 {
        error make {
            msg: $"Invalid AWS credentials for profile '($profile)'"
            help: $"Error: ($result.stderr)"
        }
    }
    
    try {
        $result.stdout | from json
    } catch {
        error make {
            msg: "Failed to parse AWS identity response"
        }
    }
}

# Export AWS credentials as environment variables
def export_credentials [credentials: record, profile: string]: nothing -> nothing {
    log info $"Exporting AWS credentials for profile: ($profile)"
    
    # Export standard AWS environment variables
    $env.AWS_PROFILE = $profile
    $env.AWS_ACCESS_KEY_ID = $credentials.aws_access_key_id
    $env.AWS_SECRET_ACCESS_KEY = $credentials.aws_secret_access_key
    
    # Export session token if available (for temporary credentials)
    if "aws_session_token" in ($credentials | columns) {
        $env.AWS_SESSION_TOKEN = $credentials.aws_session_token
    } else {
        # Clear any existing session token - check if it exists first
        let aws_session_exists = ("AWS_SESSION_TOKEN" in ($env | columns))
        if $aws_session_exists {
            hide-env AWS_SESSION_TOKEN
        }
    }
    
    # Export region if specified
    if "region" in ($credentials | columns) {
        $env.AWS_DEFAULT_REGION = $credentials.region
        $env.AWS_REGION = $credentials.region
    }
    
    # Set credential expiration warning
    let expiry_time = (date now) + ($CREDENTIAL_TIMEOUT | into duration --unit sec)
    $env.AWS_CREDENTIAL_EXPIRY = ($expiry_time | format date "%Y-%m-%d %H:%M:%S")
    
    print $"✅ AWS credentials exported for profile: (ansi green)($profile)(ansi reset)"
    print $"   Region: (ansi cyan)($env.AWS_DEFAULT_REGION? | default 'not set')(ansi reset)"
    print $"   Account: (ansi cyan)($credentials.account_id? | default 'unknown')(ansi reset)"
    print $"   Expires: (ansi yellow)($env.AWS_CREDENTIAL_EXPIRY)(ansi reset)"
}

# Get temporary credentials for a profile (useful for MFA/AssumeRole)
def get_temporary_credentials [profile: string]: nothing -> record {
    log info $"Getting temporary credentials for profile: ($profile)"
    
    let result = try {
        ^aws sts get-session-token --profile $profile --duration-seconds $CREDENTIAL_TIMEOUT 
        | complete
    } catch { |e|
        error make {
            msg: $"Failed to get temporary credentials: ($e.msg)"
        }
    }
    
    if $result.exit_code != 0 {
        # Try without session token (might not be needed)
        log warning "Failed to get session token, using existing credentials"
        return (get_aws_credentials $profile)
    }
    
    let temp_creds = try {
        $result.stdout | from json | get Credentials
    } catch {
        error make {
            msg: "Failed to parse temporary credentials response"
        }
    }
    
    {
        aws_access_key_id: $temp_creds.AccessKeyId
        aws_secret_access_key: $temp_creds.SecretAccessKey
        aws_session_token: $temp_creds.SessionToken
        account_id: (validate_credentials $profile | get Account)
    }
}

# Display current AWS credential status
def show_credential_status []: nothing -> nothing {
    print "\n📊 Current AWS Credential Status:"
    print $"   Profile: (ansi green)($env.AWS_PROFILE? | default 'not set')(ansi reset)"
    print $"   Access Key: (ansi cyan)($env.AWS_ACCESS_KEY_ID? | default 'not set' | str substring 0..8)...(ansi reset)"
    print $"   Region: (ansi cyan)($env.AWS_DEFAULT_REGION? | default 'not set')(ansi reset)"
    
    if "AWS_CREDENTIAL_EXPIRY" in ($env | columns) {
        print $"   Expires: (ansi yellow)($env.AWS_CREDENTIAL_EXPIRY)(ansi reset)"
    }
    
    # Test current credentials
    try {
        let identity = ^aws sts get-caller-identity | complete
        if $identity.exit_code == 0 {
            let info = $identity.stdout | from json
            print $"   Account: (ansi green)($info.Account)(ansi reset)"
            print $"   User/Role: (ansi green)($info.Arn | split row '/' | last)(ansi reset)"
            print $"   Status: (ansi green)✓ Valid(ansi reset)"
        } else {
            print $"   Status: (ansi red)✗ Invalid or expired(ansi reset)"
        }
    } catch {
        print $"   Status: (ansi red)✗ Cannot validate(ansi reset)"
    }
}

# =============================================================================
# SSO SUPPORT FUNCTIONS
# =============================================================================

# Login using AWS SSO
def sso_login [profile: string]: nothing -> record {
    log info $"Starting SSO login for profile: ($profile)"
    
    let result = try {
        ^aws sso login --profile $profile | complete
    } catch { |e|
        error make {
            msg: $"SSO login failed: ($e.msg)"
        }
    }
    
    if $result.exit_code != 0 {
        error make {
            msg: $"SSO login failed for profile '($profile)'"
            help: $"Error: ($result.stderr)"
        }
    }
    
    print $"✅ SSO login completed for profile: (ansi green)($profile)(ansi reset)"
    
    # Get credentials after SSO login
    get_aws_credentials $profile
}

# Check if a profile is configured for SSO
def is_sso_profile [profile: string]: nothing -> bool {
    let config_file = $"($AWS_CONFIG_DIR)/config" | path expand
    
    if not ($config_file | path exists) {
        return false
    }
    
    let config_content = try {
        open $config_file
    } catch {
        return false
    }
    
    let section_name = if $profile == "default" { "[default]" } else { $"[profile ($profile)]" }
    let has_sso = ($config_content | str contains $section_name) and ($config_content | str contains "sso_start_url")
    
    $has_sso
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Utility function to clear AWS credentials from environment
export def clear_aws_env []: nothing -> nothing {
    # Safely hide environment variables only if they exist
    let env_vars = ["AWS_PROFILE" "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_SESSION_TOKEN" "AWS_DEFAULT_REGION" "AWS_REGION" "AWS_CREDENTIAL_EXPIRY"]
    
    for var in $env_vars {
        let var_exists = ($var in ($env | columns))
        if $var_exists {
            hide-env $var
        }
    }
    
    print "🧹 AWS credentials cleared from environment"
}

# Utility function to list available AWS profiles
export def list_aws_profiles []: nothing -> table {
    let credentials_file = $"($AWS_CONFIG_DIR)/credentials" | path expand
    let config_file = $"($AWS_CONFIG_DIR)/config" | path expand
    
    mut profiles = []
    
    # Parse credentials file for profiles
    if ($credentials_file | path exists) {
        let cred_profiles = try {
            open $credentials_file 
            | lines 
            | where ($it | str starts-with "[") and ($it | str ends-with "]")
            | each { |line| 
                $line | str replace -r '^\[(.+)\]$' '${1}'
            }
        } catch {
            []
        }
        $profiles = ($profiles | append $cred_profiles)
    }
    
    # Parse config file for profiles  
    if ($config_file | path exists) {
        let conf_profiles = try {
            open $config_file 
            | lines
            | where ($it | str starts-with "[profile ") and ($it | str ends-with "]")
            | each { |line|
                $line | str replace -r '^\[profile (.+)\]$' '${1}'
            }
        } catch {
            []
        }
        $profiles = ($profiles | append $conf_profiles)
    }
    
    $profiles 
    | uniq 
    | sort 
    | each { |profile| 
        {
            profile: $profile
            type: (if (is_sso_profile $profile) { "SSO" } else { "Standard" })
        }
    }
}

# Input validation for profile names
def validate_profile_name [profile: string]: nothing -> nothing {
    if ($profile | str length) == 0 {
        error make {
            msg: "Profile name cannot be empty"
        }
    }
    
    if ($profile | str contains " ") {
        error make {
            msg: "Profile name cannot contain spaces"
        }
    }
    
    if ($profile | str contains "/") {
        error make {
            msg: "Profile name cannot contain forward slashes"
        }
    }
}

# Mask sensitive data in logs
def mask_sensitive [text: string]: nothing -> string {
    $text 
    | str replace -a --regex 'AKIA[0-9A-Z]{16}' 'AKIA****************'
    | str replace -a --regex '[A-Za-z0-9+/]{40}' '****************************************'
}

# =============================================================================
# MAIN COMMAND FUNCTION
# =============================================================================

# Main command function
def main [
    profile: string = $DEFAULT_PROFILE  # AWS profile to use
    --sso                              # Use AWS SSO login
    --export-only                     # Only export existing credentials, don't validate
    --temp                             # Get temporary credentials (useful for MFA)
    --status                           # Show current credential status
    --verbose                          # Enable verbose logging
]: nothing -> nothing {
    
    # Set up logging
    if $verbose {
        $env.LOG_LEVEL = "DEBUG"
    }
    
    # Handle status flag
    if $status {
        show_credential_status
        return
    }
    
    log info $"AWS Login starting for profile: ($profile)"
    
    # Validate profile name
    validate_profile_name $profile
    
    try {
        # Determine credentials source and method
        let credentials = if $temp {
            print $"🔐 Getting temporary credentials for profile: (ansi cyan)($profile)(ansi reset)"
            get_temporary_credentials $profile
        } else if $sso {
            print $"🔐 Starting SSO login for profile: (ansi cyan)($profile)(ansi reset)"
            sso_login $profile
        } else if $export_only {
            print $"📤 Exporting existing credentials for profile: (ansi cyan)($profile)(ansi reset)"
            get_aws_credentials $profile
        } else {
            # Default: get and validate credentials
            let creds = (get_aws_credentials $profile)
            
            # Validate unless export-only mode
            try {
                validate_credentials $profile
                print $"✅ Credentials validated for profile: (ansi green)($profile)(ansi reset)"
            } catch { |e|
                if not $export_only {
                    print $"⚠️  Credential validation failed: ($e.msg)"
                    print "   Proceeding with export anyway (use --status to check validity)"
                }
            }
            
            $creds
        }
        
        # Export credentials to environment
        export_credentials $credentials $profile
        
        # Show status
        show_credential_status
        
        print "\n🎉 AWS login completed successfully!"
        print "   Credentials are now available in your shell environment."
        print "   Use AWS CLI commands normally, or check status with: aws-login --status"
        
    } catch { |error|
        log error $"AWS login failed: ($error.msg)"
        print $"❌ AWS login failed: ($error.msg)"
        if "help" in ($error | columns) {
            print $"💡 ($error.help)"
        }
        exit 1
    }
}

# =============================================================================
# ALIASES AND SHORTCUTS
# =============================================================================

# Short alias for main command
export alias awsl = main

# Status check alias
export alias aws-status = main --status

# Profile listing alias  
export alias aws-profiles = list_aws_profiles

# Clear credentials alias
export alias aws-clear = clear_aws_env