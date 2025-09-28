#!/usr/bin/env nu
# AWS Profile-Specific Aliases - Essential Examples
# Copy these patterns to your ~/.config/nushell/config.nu and customize

print "📚 AWS Profile Alias Examples - Copy and Customize These Patterns"
print ""

# =============================================================================
# ESSENTIAL PATTERNS (80% of use cases)
# =============================================================================

print "🔧 Essential Patterns (copy to ~/.config/nushell/config.nu):"
print ""

print "# Basic development alias"
print 'def awsl-dev []: nothing -> nothing {'
print '    aws-login development  # Replace with your dev profile name'
print '    print "🚀 Connected to Development"'
print '    aws-status'
print '}'
print ""

print "# Production with safety confirmation"
print 'def awsl-prod []: nothing -> nothing {'
print '    let confirm = (input "⚠️  Connect to PRODUCTION? (y/N): ")'
print '    if $confirm != "y" {'
print '        print "❌ Cancelled"'
print '        return'
print '    }'
print '    aws-login production --sso  # Replace with your prod profile'
print '    print "🚨 PRODUCTION ENVIRONMENT - BE CAREFUL!"'
print '    aws-status'
print '}'
print ""

print "# Region-specific alias"
print 'def awsl-prod-us []: nothing -> nothing {'
print '    awsl-prod'
print '    if ("AWS_PROFILE" in ($env | columns)) {'
print '        $env.AWS_DEFAULT_REGION = "us-east-1"'
print '        $env.AWS_REGION = "us-east-1"'
print '        print "🌎 Region: US-East-1"'
print '    }'
print '}'
print ""

# =============================================================================
# ADVANCED PATTERNS (for specific needs)
# =============================================================================

print "🚀 Advanced Patterns:"
print ""

print "# EKS/Kubernetes integration"
print 'def awsl-k8s-prod []: nothing -> nothing {'
print '    awsl-prod'
print '    if ("AWS_PROFILE" in ($env | columns)) {'
print '        aws eks update-kubeconfig --name production-cluster'
print '        print "⚙️ kubectl configured"'
print '    }'
print '}'
print ""

print "# Multi-client management"
print 'def awsl-client1-prod []: nothing -> nothing {'
print '    let confirm = (input "⚠️  Connect to Client1 PROD? (y/N): ")'
print '    if $confirm != "y" { return }'
print '    aws-login client1-production --sso'
print '    aws-status'
print '}'
print ""

print "# Interactive profile selector"
print 'def awsi []: nothing -> nothing {'
print '    let profiles = (aws-profiles)'
print '    $profiles | enumerate | each { |item|'
print '        print $"  ($item.index + 1). ($item.item.profile)"'
print '    }'
print '    let selection = (input "Enter number or name: ")'
print '    let profile = try {'
print '        let idx = ($selection | into int) - 1'
print '        $profiles | get $idx | get profile'
print '    } catch { $selection }'
print '    aws-login $profile'
print '    aws-status'
print '}'
print ""

# =============================================================================
# WORKING EXAMPLES (test these patterns)
# =============================================================================

print "🧪 Working Examples (test these now):"
print ""

# Example 1: Basic alias pattern
def example_awsl_dev []: nothing -> nothing {
    print "🚀 Mock: Connecting to development..."
    $env.EXAMPLE_AWS_PROFILE = "development"
    $env.EXAMPLE_AWS_ACCESS_KEY_ID = "AKIAEXAMPLE"
    $env.EXAMPLE_AWS_DEFAULT_REGION = "us-west-2"
    print "✅ Mock: Connected to development"
    print $"   Profile: ($env.EXAMPLE_AWS_PROFILE)"
    print $"   Region: ($env.EXAMPLE_AWS_DEFAULT_REGION)"
}

print "Test basic alias pattern:"
print "  example_awsl_dev"
example_awsl_dev
print ""

# Example 2: Production safety pattern
def example_awsl_prod [confirm: bool]: nothing -> nothing {
    if not $confirm {
        print "❌ Mock: Production access cancelled"
        return
    }
    print "🚀 Mock: Connecting to production..."
    $env.EXAMPLE_AWS_PROFILE = "production"
    print "🚨 Mock: PRODUCTION ENVIRONMENT - BE CAREFUL!"
}

print "Test production safety pattern:"
print "  example_awsl_prod false  # Should cancel"
example_awsl_prod false
print "  example_awsl_prod true   # Should connect"
example_awsl_prod true
print ""

# Example 3: Multi-environment workflow
def example_multi_env_workflow []: nothing -> nothing {
    let environments = ["development", "staging", "production"]
    
    for env in $environments {
        print $"🔄 Mock: Switching to ($env)..."
        $env.EXAMPLE_CURRENT_ENV = $env
        print $"   Current environment: ($env.EXAMPLE_CURRENT_ENV)"
    }
    
    print "🧹 Mock: Clearing credentials..."
    hide-env --ignore-errors EXAMPLE_CURRENT_ENV
}

print "Test multi-environment workflow:"
print "  example_multi_env_workflow"
example_multi_env_workflow
print ""

# Cleanup examples
let example_vars = ($env | columns | where ($it | str starts-with "EXAMPLE_"))
for var in $example_vars {
    hide-env $var
}

# =============================================================================
# ORGANIZATION-SPECIFIC TEMPLATES
# =============================================================================

print "🏢 Organization-Specific Templates:"
print ""

print "# Startup (dev/prod):"
print 'alias awsl-dev = aws-login development'
print 'alias awsl-prod = aws-login production --sso'
print ""

print "# Enterprise (multiple accounts):"
print 'alias awsl-master = aws-login org-master --sso'
print 'alias awsl-security = aws-login security-account --sso'
print 'alias awsl-finance = aws-login finance-prod --sso'
print ""

print "# Consulting/Agency (multiple clients):"
print 'alias awsl-client1-dev = aws-login client1-dev --sso'
print 'alias awsl-client1-prod = aws-login client1-prod --sso'
print 'alias awsl-client2-dev = aws-login client2-dev --sso'
print ""

# =============================================================================
# CUSTOMIZATION GUIDE
# =============================================================================

print "📝 Customization Steps:"
print ""
print "1. Check your profiles:"
print "   aws-profiles"
print ""
print "2. Copy patterns above to ~/.config/nushell/config.nu"
print ""
print "3. Replace profile names:"
print "   - Change 'development' to your actual dev profile"
print "   - Change 'production' to your actual prod profile"
print "   - Add --sso flag for SSO-enabled profiles"
print ""
print "4. Customize regions:"
print "   - Update regions to match your setup"
print "   - Add region-specific aliases if needed"
print ""
print "5. Test your aliases:"
print "   source ~/.config/nushell/config.nu"
print "   awsl-dev"
print "   aws-status"
print "   aws-clear"
print ""

print "✅ Examples complete! Copy the patterns above to get started."
print "📖 For more details, see README.md"