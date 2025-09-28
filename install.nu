#!/usr/bin/env nu
# AWS Nushell Login - Installation Script (Native Nushell)
# 
# This script installs the AWS login system with all components written in pure Nushell

use std log

const INSTALL_DIR = "~/bin"
const CONFIG_FILE = "~/.config/nushell/config.nu"

# Print formatted messages
def print_step [message: string]: nothing -> nothing {
    print $"✅ ($message)"
}

def print_warning [message: string]: nothing -> nothing {
    print $"⚠️  ($message)"
}

def print_error [message: string]: nothing -> nothing {
    print $"❌ ($message)"
}

def print_header []: nothing -> nothing {
    print "╔══════════════════════════════════════════════════════════════════════╗"
    print "║                    AWS Nushell Login - Installer                     ║"
    print "╚══════════════════════════════════════════════════════════════════════╝"
}

# Check if required tools are available
def check_requirements []: nothing -> record {
    log info "Checking requirements..."
    
    let nu_available = (which nu | length) > 0
    let aws_available = (which aws | length) > 0
    
    if not $nu_available {
        print_error "Nushell is not available. This script requires Nushell."
        error make {
            msg: "Missing Nushell"
            help: "Install from: https://www.nushell.sh/book/installation.html"
        }
    }
    print_step "Nushell is available"
    
    if not $aws_available {
        print_warning "AWS CLI not found. Install it for full functionality."
        print "  Install from: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    } else {
        print_step "AWS CLI is available"
    }
    
    { nu_available: $nu_available, aws_available: $aws_available }
}

# Install the main script files
def install_scripts []: nothing -> nothing {
    log info "Installing AWS Nushell Login scripts..."
    
    let install_path = ($INSTALL_DIR | path expand)
    mkdir $install_path
    
    # Copy main script
    try {
        cp aws-login.nu $"($install_path)/aws-login.nu"
        chmod +x $"($install_path)/aws-login.nu"
        print_step "Installed aws-login.nu"
    } catch { |e|
        print_error $"Failed to install aws-login.nu: ($e.msg)"
        error make { msg: "Installation failed" }
    }
    
    # Copy example script
    try {
        cp aws-example.nu $"($install_path)/aws-example.nu"
        chmod +x $"($install_path)/aws-example.nu"
        print_step "Installed aws-example.nu"
    } catch {
        print_warning "Failed to install aws-example.nu (optional)"
    }
    
    # Copy documentation
    let docs = [
        "AWS_QUICK_REFERENCE.md"
        "AWS_SETUP_COMPLETE.md"
        "profile-aliases-template.nu"
    ]
    
    $docs | each { |doc|
        try {
            cp $doc $"($install_path)/($doc)"
            print_step $"Copied ($doc)"
        } catch {
            print_warning $"Failed to copy ($doc) (optional)"
        }
    }
}

# Generate profile-specific aliases based on user's AWS config
def generate_profile_aliases []: nothing -> list<string> {
    log info "Generating profile-specific aliases..."
    
    let aws_config_path = "~/.aws/config" | path expand
    let aws_creds_path = "~/.aws/credentials" | path expand
    
    mut profiles = []
    
    # Parse profiles from config file
    if ($aws_config_path | path exists) {
        try {
            let config_profiles = open $aws_config_path 
            | lines 
            | where ($it | str starts-with "[profile ") and ($it | str ends-with "]")
            | each { |line| $line | str replace -r '^\[profile (.+)\]$' '${1}' }
            $profiles = ($profiles | append $config_profiles)
        } catch {
            print_warning "Could not parse AWS config file"
        }
    }
    
    # Parse profiles from credentials file
    if ($aws_creds_path | path exists) {
        try {
            let cred_profiles = open $aws_creds_path
            | lines
            | where ($it | str starts-with "[") and ($it | str ends-with "]") and not ($it | str starts-with "[profile ")
            | each { |line| $line | str replace -r '^\[(.+)\]$' '${1}' }
            $profiles = ($profiles | append $cred_profiles)
        } catch {
            print_warning "Could not parse AWS credentials file"
        }
    }
    
    let unique_profiles = ($profiles | uniq | sort)
    
    if ($unique_profiles | length) == 0 {
        print_warning "No AWS profiles found. Using default examples."
        return [
            "# Profile-specific aliases (customize these for your profiles)"
            "alias awsl-dev = aws-login dev"
            "alias awsl-staging = aws-login staging --sso"
            "alias awsl-prod = aws-login production --sso"
            "alias awsl-sandbox = aws-login sandbox"
        ]
    }
    
    mut alias_lines = ["# Profile-specific aliases (auto-generated from your AWS config)"]
    
    for profile in $unique_profiles {
        let safe_name = ($profile | str replace -a "-" "_" | str replace -a "." "_")
        let use_sso = ($profile | str contains "prod") or ($profile | str contains "production")
        
        if $use_sso {
            $alias_lines = ($alias_lines | append $"alias awsl_($safe_name) = aws-login ($profile) --sso")
        } else {
            $alias_lines = ($alias_lines | append $"alias awsl_($safe_name) = aws-login ($profile)")
        }
    }
    
    print_step $"Generated aliases for ($unique_profiles | length) profiles: ($unique_profiles | str join ', ')"
    $alias_lines
}

# Setup Nushell configuration with aliases
def setup_nushell_config []: nothing -> nothing {
    log info "Setting up Nushell configuration..."
    
    let config_path = ($CONFIG_FILE | path expand)
    
    if not ($config_path | path exists) {
        print_warning $"Nushell config not found at ($config_path)"
        print_warning "You'll need to manually add aliases to your config"
        return
    }
    
    # Check if aliases already exist
    let existing_content = open $config_path
    if ($existing_content | str contains "aws-login.*~/bin/aws-login.nu") {
        print_warning "AWS aliases already exist in config, skipping..."
        return
    }
    
    # Generate the configuration block
    let profile_aliases = (generate_profile_aliases)
    
    let config_block = [
        ""
        "# AWS Nushell Login aliases (auto-installed)"
        "alias aws-login = ~/bin/aws-login.nu"
        "alias awsl = ~/bin/aws-login.nu"
        "alias aws-status = ~/bin/aws-login.nu --status"
        ""
        ...$profile_aliases
        ""
        "# AWS utility functions"
        "def aws-clear []: nothing -> nothing {"
        "    use ~/bin/aws-login.nu clear_aws_env"
        "    clear_aws_env"
        "}"
        ""
        "def aws-profiles []: nothing -> table {"
        "    use ~/bin/aws-login.nu list_aws_profiles"
        "    list_aws_profiles"
        "}"
        ""
    ]
    
    # Append to config file
    $config_block | str join "\n" | save --append $config_path
    print_step "Added aliases to Nushell config"
}

# Create profile-specific quick access functions
def create_profile_functions []: nothing -> nothing {
    log info "Creating profile-specific functions..."
    
    let functions_file = ($"($INSTALL_DIR)/aws-profile-functions.nu" | path expand)
    
    let profile_functions = [
        "#!/usr/bin/env nu"
        "# AWS Profile-Specific Functions (Generated)"
        "# Source this file for additional profile management functions"
        ""
        "# Quick profile switching with validation"
        "export def awsp [profile: string]: nothing -> nothing {"
        "    aws-login $profile"
        "    aws-status"
        "}"
        ""
        "# Switch profile and set region"
        "export def awspr [profile: string, region: string]: nothing -> nothing {"
        "    aws-login $profile"
        "    $env.AWS_DEFAULT_REGION = $region"
        "    $env.AWS_REGION = $region"
        "    print $\"🌎 Profile: (ansi cyan)($profile)(ansi reset), Region: (ansi cyan)($region)(ansi reset)\""
        "    aws-status"
        "}"
        ""
        "# Multi-profile status check"
        "export def aws-check-all []: nothing -> table {"
        "    aws-profiles | each { |p|"
        "        let status = try {"
        "            aws-login $p.profile --export-only"
        "            \"✅ Valid\""
        "        } catch {"
        "            \"❌ Invalid\""
        "        }"
        "        {profile: $p.profile, type: $p.type, status: $status}"
        "    }"
        "}"
        ""
        "# Interactive profile selector"
        "export def awsi []: nothing -> nothing {"
        "    let profiles = (aws-profiles)"
        "    if ($profiles | length) == 0 {"
        "        print \"No AWS profiles found\""
        "        return"
        "    }"
        "    print \"Available AWS profiles:\""
        "    $profiles | each { |p| print $\"  ($p.profile) (($p.type))\" }"
        "    let selected = (input \"Enter profile name: \")"
        "    if $selected in ($profiles | get profile) {"
        "        aws-login $selected"
        "        aws-status"
        "    } else {"
        "        print $\"Invalid profile: ($selected)\""
        "    }"
        "}"
    ]
    
    $profile_functions | str join "\n" | save $functions_file
    chmod +x $functions_file
    print_step "Created profile management functions"
}

# Show completion message with next steps
def show_completion []: nothing -> nothing {
    print ""
    print "🎉 (ansi green)Installation completed successfully!(ansi reset)"
    print ""
    print "📋 Available commands (restart your shell first):"
    print "   (ansi cyan)aws-login(ansi reset)              # Main authentication command"
    print "   (ansi cyan)awsl(ansi reset)                   # Short version"
    print "   (ansi cyan)aws-status(ansi reset)             # Check credential status"
    print "   (ansi cyan)aws-profiles(ansi reset)           # List available profiles"
    print "   (ansi cyan)aws-clear(ansi reset)              # Clear credentials"
    print ""
    print "🚀 Profile-specific aliases were generated based on your AWS config:"
    
    # Show generated aliases
    try {
        let config_content = open ($CONFIG_FILE | path expand)
        let alias_lines = ($config_content | lines | where ($it | str starts-with "alias awsl_"))
        if ($alias_lines | length) > 0 {
            $alias_lines | each { |line| print $"   (ansi yellow)($line)(ansi reset)" }
        }
    } catch {
        print "   Check ~/.config/nushell/config.nu for your custom aliases"
    }
    
    print ""
    print "💡 Next steps:"
    print "   1. Restart your shell or run: (ansi cyan)source ~/.config/nushell/config.nu(ansi reset)"
    print "   2. Test: (ansi cyan)aws-login --help(ansi reset)"
    print "   3. Configure AWS if needed: (ansi cyan)aws configure(ansi reset)"
    print "   4. Try: (ansi cyan)awsl-dev(ansi reset) or (ansi cyan)awsl-prod(ansi reset) (if you have those profiles)"
    print ""
    print "📖 Documentation:"
    print $"   ~/bin/AWS_QUICK_REFERENCE.md"
    print $"   ~/bin/profile-aliases-template.nu"
    print ""
    print "🔧 Advanced functions:"
    print "   Source ~/bin/aws-profile-functions.nu for additional profile management tools"
}

# Main installation function
def main [
    --force (-f)        # Force reinstallation even if files exist
    --skip-config (-s)  # Skip Nushell config modification
    --verbose (-v)      # Enable verbose logging
]: nothing -> nothing {
    
    if $verbose {
        $env.LOG_LEVEL = "DEBUG"
    }
    
    print_header
    
    try {
        let requirements = (check_requirements)
        install_scripts
        
        if not $skip_config {
            setup_nushell_config
        }
        
        create_profile_functions
        show_completion
        
    } catch { |error|
        print_error $"Installation failed: ($error.msg)"
        if "help" in ($error | columns) {
            print $"💡 ($error.help)"
        }
        exit 1
    }
}