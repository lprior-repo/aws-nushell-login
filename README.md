# AWS Nushell Login

🚀 **Single-File AWS Profile Manager for Nushell** - Switch between AWS environments with simple commands like `awsl-dev` and `awsl-prod`.

![Nushell](https://img.shields.io/badge/shell-nushell-green)
![AWS CLI](https://img.shields.io/badge/aws-cli-orange)  
![Tests](https://img.shields.io/badge/coverage-80%25-blue)
![License](https://img.shields.io/badge/license-MIT-blue)

## ⚡ Quick Start (Copy & Paste)

```nu
# 1. Clone the repository
git clone https://github.com/lprior-repo/aws-nushell-login.git
cd aws-nushell-login

# 2. Add this to your ~/.config/nushell/config.nu
def awsl-dev []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu  # Adjust path as needed
    aws-login development  # Replace with your actual AWS profile name
    print "🚀 Connected to Development"
    aws-status
}

def awsl-prod []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    let confirm = (input "⚠️  Connect to PRODUCTION? (y/N): ")
    if $confirm != "y" { return }
    aws-login production --sso  # Replace with your actual profile name
    print "🚨 PRODUCTION ENVIRONMENT - BE CAREFUL!"
    aws-status
}

# 3. Reload and test
source ~/.config/nushell/config.nu
awsl-dev        # Login to development
aws-status      # Check credentials  
aws-clear       # Clear when done
```

## 📋 What You Get

✅ **Single Nushell File** - Everything in `aws-login.nu`, easy to copy anywhere  
✅ **Works with AWS SSO** - `aws-login profile --sso`  
✅ **Production Safety** - Built-in confirmation prompts  
✅ **Environment Export** - All AWS CLI tools work automatically  
✅ **Comprehensive Testing** - 80% code coverage following Martin Fowler's pyramid  
✅ **Copy-Paste Examples** - Ready-to-use patterns for common scenarios  

## 🎯 Core Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `aws-login` | Main authentication | `aws-login production --sso` |
| `awsl` | Short form alias | `awsl dev` |
| `aws-status` | Check current credentials | Shows profile, region, expiration |
| `aws-profiles` | List available profiles | Shows all configured AWS profiles |
| `aws-clear` | Clear credentials | Removes AWS environment variables |

## 🏗️ Essential Alias Patterns

### Basic Development
```nu
def awsl-dev []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login development
    print "🚀 Connected to Development"
    aws-status
}
```

### Production with Confirmation
```nu
def awsl-prod []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    let confirm = (input "⚠️  Connect to PRODUCTION? (y/N): ")
    if $confirm != "y" { return }
    aws-login production --sso
    print "🚨 PRODUCTION ENVIRONMENT - BE CAREFUL!"
    aws-status
}
```

### SSO Profiles
```nu
def awsl-sso [profile: string]: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login $profile --sso
    print $"🔐 SSO login completed for: ($profile)"
    aws-status
}
```

### Region-Specific
```nu
def awsl-prod-us-east []: nothing -> nothing {
    awsl-prod  # Calls your production alias above
    if ("AWS_PROFILE" in ($env | columns)) {
        $env.AWS_DEFAULT_REGION = "us-east-1"
        $env.AWS_REGION = "us-east-1"
        print "🌍 Region: US-East-1"
    }
}
```

## 🔧 Advanced Use Cases

### Multi-Client Management
```nu
def awsl-clienta-dev []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login client-a-development
    print "🏢 Connected to Client A Development"
}

def awsl-clientb-prod []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    let confirm = (input "⚠️  Connect to Client B PROD? (y/N): ")
    if $confirm != "y" { return }
    aws-login client-b-production --sso
    print "🏬 CLIENT B PRODUCTION ACTIVE"
}
```

### EKS/Kubernetes Integration
```nu
def awsl-k8s-prod [cluster: string]: nothing -> nothing {
    awsl-prod  # Use your production alias
    if ("AWS_PROFILE" in ($env | columns)) {
        ^aws eks update-kubeconfig --name $cluster --region $env.AWS_DEFAULT_REGION
        print $"⚙️ kubectl configured for: ($cluster)"
    }
}
```

### Workflow Automation
```nu
def dev-start []: nothing -> nothing {
    print "🌅 Starting Development Day"
    awsl-dev
    $env.ENVIRONMENT = "development"
    print "✅ Development environment ready"
}

def dev-end []: nothing -> nothing {
    print "🌙 Ending Development Session"  
    aws-clear
    hide-env -i ENVIRONMENT
    print "✅ Session cleaned up"
}
```

## 🔐 AWS Configuration Examples

### For AWS SSO (in `~/.aws/config`)
```ini
[profile sso-development]
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = DeveloperRole
region = us-east-1

[profile sso-production]
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-east-1
sso_account_id = 987654321098
sso_role_name = AdministratorRole
region = us-west-2
```

### For Traditional Profiles (in `~/.aws/credentials`)
```ini
[development]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY

[production]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

## 🧪 Testing (Martin Fowler's Pyramid)

Comprehensive test suite with 80% code coverage:

```nu
# Run all tests (70% unit, 20% integration, 10% e2e)
./tests/run_tests.nu full

# Quick CI tests (unit only)  
./tests/run_tests.nu quick --fail

# Development tests (unit + integration)
./tests/run_tests.nu dev --verbose

# Generate JUnit report for CI/CD
./tests/run_tests.nu full --report junit
```

## 🚨 Security Best Practices

1. **Production Confirmations**: Always require explicit confirmation for production
2. **Session Cleanup**: Use `aws-clear` when switching contexts or ending sessions
3. **SSO for Production**: Use `--sso` flag for production environments
4. **Regular Validation**: Check `aws-status` to verify current credentials
5. **Environment Isolation**: Clear credentials between different client work

## 📋 Requirements

- [Nushell](https://www.nushell.sh/) 0.106+
- [AWS CLI](https://aws.amazon.com/cli/) v2
- Configured AWS profiles in `~/.aws/config` and `~/.aws/credentials`

## ❓ Troubleshooting

### "Profile not found"
```nu
# Check available profiles
aws-profiles

# Verify AWS configuration files exist
ls ~/.aws/
```

### "SSO login failed"  
```nu
# Test SSO configuration
aws sso login --profile your-profile

# Check SSO URL in ~/.aws/config
```

### "Credentials expired"
```nu
# Check current status
aws-status

# Refresh credentials
aws-login your-profile --sso
```

## 🚀 Quick Installation

### Option 1: Direct Use (Recommended)
```nu
# Clone anywhere and reference directly
git clone https://github.com/lprior-repo/aws-nushell-login.git ~/aws-nushell-login

# In your ~/.config/nushell/config.nu
def awsl-dev []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login development
    aws-status
}
```

### Option 2: Automated Installation
```nu
# Run the installer
./install.nu

# Then create aliases in ~/.config/nushell/config.nu
def awsl-dev []: nothing -> nothing { aws-login development }
```

## 🎯 Real-World Alias Examples

Copy these patterns and customize the profile names for your setup:

```nu
# Personal vs Work
def awsl-personal []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login personal
    print "🏠 Personal AWS Account"
}

def awsl-work-dev []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login work-development
    print "💼 Work Development"
}

# Multi-Environment Startup
def awsl-startup-dev []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login startup-development
    print "🚀 Startup Development"
}

def awsl-startup-prod []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    let confirm = (input "⚠️  Connect to Startup PRODUCTION? (y/N): ")
    if $confirm != "y" { return }
    aws-login startup-production --sso
    print "🚨 STARTUP PRODUCTION"
}

# Enterprise Multi-Account
def awsl-master []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login org-master --sso
    print "🏢 Organization Master Account"
}

def awsl-security []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login security-account --sso
    print "🔒 Security Account"
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Add tests for new functionality
4. Ensure tests pass: `./tests/run_tests.nu full`
5. Submit a pull request

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

---

⭐ **Star this repo** if it helps you manage AWS profiles more easily!

**Made with ❤️ for the Nushell community**