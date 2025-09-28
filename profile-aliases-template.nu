# Profile-Specific Aliases Configuration Template
#
# Copy this content to your ~/.config/nushell/config.nu file and customize
# the profile names and settings for your AWS environment.

# =============================================================================
# BASIC AWS LOGIN ALIASES
# =============================================================================

# Main AWS login commands
alias aws-login = ~/bin/aws-login.nu
alias awsl = ~/bin/aws-login.nu
alias aws-status = ~/bin/aws-login.nu --status

# Utility functions
def aws-clear []: nothing -> nothing { 
    use ~/bin/aws-login.nu clear_aws_env
    clear_aws_env
}

def aws-profiles []: nothing -> table {
    use ~/bin/aws-login.nu list_aws_profiles
    list_aws_profiles
}

# =============================================================================
# PROFILE-SPECIFIC ALIASES - CUSTOMIZE THESE FOR YOUR ORGANIZATION
# =============================================================================

# Development Environment
alias awsl-dev = aws-login dev
alias awsl-development = aws-login development

# Staging/Testing Environments  
alias awsl-staging = aws-login staging --sso
alias awsl-test = aws-login test
alias awsl-qa = aws-login qa --sso

# Production Environment (with SSO for security)
alias awsl-prod = aws-login production --sso
alias awsl-production = aws-login production --sso

# Sandbox/Personal Environment
alias awsl-sandbox = aws-login sandbox
alias awsl-personal = aws-login personal

# Multi-account scenarios (customize account names)
alias awsl-company-dev = aws-login company-dev --sso
alias awsl-company-prod = aws-login company-prod --sso
alias awsl-client1-prod = aws-login client1-production --sso
alias awsl-client2-dev = aws-login client2-development

# =============================================================================
# REGION-SPECIFIC ALIASES (optional)
# =============================================================================

# Quick region switching after login
def awsl-us-east [] {
    $env.AWS_DEFAULT_REGION = "us-east-1"
    $env.AWS_REGION = "us-east-1"
    print $"🌎 Switched to region: (ansi cyan)us-east-1(ansi reset)"
}

def awsl-us-west [] {
    $env.AWS_DEFAULT_REGION = "us-west-2"
    $env.AWS_REGION = "us-west-2"
    print $"🌎 Switched to region: (ansi cyan)us-west-2(ansi reset)"
}

def awsl-eu [] {
    $env.AWS_DEFAULT_REGION = "eu-west-1"
    $env.AWS_REGION = "eu-west-1"
    print $"🌎 Switched to region: (ansi cyan)eu-west-1(ansi reset)"
}

# =============================================================================
# WORKFLOW-SPECIFIC ALIASES (optional advanced usage)
# =============================================================================

# Quick deployment workflows
def deploy-dev [] {
    awsl-dev
    print "🚀 Ready for development deployment"
    aws-status
}

def deploy-staging [] {
    awsl-staging
    print "🚀 Ready for staging deployment"
    aws-status
}

def deploy-prod [] {
    awsl-prod
    let confirm = (input "⚠️  You are about to access PRODUCTION. Continue? (y/N): ")
    if $confirm == "y" {
        print "🚀 Ready for production deployment"
        aws-status
    } else {
        print "❌ Production access cancelled"
        aws-clear
    }
}

# =============================================================================
# SERVICE-SPECIFIC SHORTCUTS (optional)
# =============================================================================

# EKS cluster access
def awsl-eks [cluster: string, profile: string = "default"] {
    aws-login $profile
    aws eks update-kubeconfig --name $cluster
    print $"⚙️  Configured kubectl for cluster: (ansi green)($cluster)(ansi reset)"
}

# ECR login helper
def awsl-ecr [profile: string = "default", region: string = "us-west-2"] {
    aws-login $profile
    aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $"(aws sts get-caller-identity --query Account --output text).dkr.ecr.($region).amazonaws.com"
    print $"🐳 Docker authenticated with ECR in (ansi cyan)($region)(ansi reset)"
}

# =============================================================================
# EXAMPLE CUSTOMIZATIONS FOR DIFFERENT ORGANIZATIONS
# =============================================================================

# Example 1: Startup with simple dev/prod setup
# alias awsl-dev = aws-login development
# alias awsl-prod = aws-login production --sso

# Example 2: Large enterprise with multiple clients
# alias awsl-acme-dev = aws-login acme-development --sso
# alias awsl-acme-prod = aws-login acme-production --sso
# alias awsl-widgets-dev = aws-login widgets-development --sso
# alias awsl-widgets-prod = aws-login widgets-production --sso

# Example 3: Multi-region deployment
# alias awsl-us = aws-login production-us --sso; awsl-us-east
# alias awsl-eu = aws-login production-eu --sso; awsl-eu
# alias awsl-asia = aws-login production-asia --sso

# =============================================================================
# TIPS FOR CUSTOMIZATION
# =============================================================================

# 1. Use descriptive names that match your team's terminology
# 2. Always use --sso for production environments
# 3. Consider adding confirmation prompts for sensitive environments
# 4. Group related aliases together with comments
# 5. Use consistent naming patterns across your organization
# 6. Document any special requirements or workflows

# =============================================================================
# ORGANIZATION-SPECIFIC EXAMPLES TO COPY AND MODIFY
# =============================================================================

# For teams using AWS Organizations:
# alias awsl-master = aws-login organization-master --sso
# alias awsl-security = aws-login security-account --sso
# alias awsl-logs = aws-login logging-account --sso

# For consulting/agencies managing multiple clients:
# alias awsl-client1 = aws-login client1-main --sso
# alias awsl-client2 = aws-login client2-main --sso
# alias awsl-internal = aws-login company-internal

# For teams with temporary/contractor access:
# alias awsl-contractor = aws-login contractor-limited --temp