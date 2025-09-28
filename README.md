# AWS Nushell Login

🚀 **One-File AWS Profile Manager for Nushell** - Switch between AWS environments with simple commands like `awsl-dev` and `awsl-prod`.

![Nushell](https://img.shields.io/badge/shell-nushell-green)
![AWS CLI](https://img.shields.io/badge/aws-cli-orange)  
![Tests](https://img.shields.io/badge/tests-comprehensive-blue)
![License](https://img.shields.io/badge/license-MIT-blue)

## ⚡ Quick Start (2 Minutes)

```nu
# 1. Clone and set up
git clone https://github.com/YOUR_USERNAME/aws-nushell-login.git
cd aws-nushell-login
nu install.nu

# 2. Create your first alias (add to ~/.config/nushell/config.nu)
def awsl-dev []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login development  # Replace with your AWS profile
    print "🚀 Connected to Development"
    aws-status
}

# 3. Use it
awsl-dev        # Login to development
aws-status      # Check credentials  
aws-clear       # Clear when done
```

## 🎯 Core Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `aws-login` | Main authentication | `aws-login production --sso` |
| `awsl` | Short form | `awsl dev` |
| `aws-status` | Check current credentials | Shows profile, region, expiration |
| `aws-profiles` | List available profiles | Shows all configured AWS profiles |
| `aws-clear` | Clear credentials | Removes AWS environment variables |

## 🏗️ Essential Patterns

### Development Environment
```nu
def awsl-dev []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu  # Path to your aws-login.nu
    aws-login development
    print "🚀 Connected to Development"
    aws-status
}
```

### Production with Safety
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

### SSO Authentication
```nu
def awsl-sso [profile: string]: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login $profile --sso
    print $"🔐 SSO login completed for: ($profile)"
    aws-status
}
```

### Region Override
```nu
def awsl-prod-us-east []: nothing -> nothing {
    awsl-prod
    if ("AWS_PROFILE" in ($env | columns)) {
        $env.AWS_DEFAULT_REGION = "us-east-1"
        $env.AWS_REGION = "us-east-1"
        print "🌍 Region: US-East-1"
    }
}
```

## 🔧 Features

- ✅ **Single File**: Everything in `aws-login.nu` - easy to copy/paste
- ✅ **SSO Support**: `aws-login profile --sso` 
- ✅ **Temporary Credentials**: `aws-login profile --temp`
- ✅ **Auto-Region Detection**: Reads from AWS config files
- ✅ **Production Safeguards**: Built-in confirmation prompts
- ✅ **Environment Export**: All AWS CLI tools work automatically
- ✅ **Comprehensive Testing**: 80% code coverage with unit/integration/e2e tests

## 📋 Requirements

- [Nushell](https://www.nushell.sh/) 0.106+
- [AWS CLI](https://aws.amazon.com/cli/) v2
- Configured AWS profiles in `~/.aws/config` and `~/.aws/credentials`

## 🧪 Testing

Following Martin Fowler's Testing Pyramid (70% unit, 20% integration, 10% e2e):

```nu
# Run all tests
./tests/run_tests.nu full

# Quick CI tests (unit only)  
./tests/run_tests.nu quick --fail

# Development tests (unit + integration)
./tests/run_tests.nu dev --verbose

# Generate test report
./tests/run_tests.nu full --report junit
```

## 🔍 Common Use Cases

### Multi-Client Management
```nu
# Client A
def awsl-clienta-dev []: nothing -> nothing {
    source ~/aws-nushell-login/aws-login.nu
    aws-login client-a-development
    print "🏢 Connected to Client A Development"
}

# Client B Production
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
    awsl-prod
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

## 🚨 Security Best Practices

1. **Production Confirmations**: Always require explicit confirmation for production
2. **Session Cleanup**: Use `aws-clear` when switching contexts or ending sessions
3. **SSO for Production**: Use `--sso` flag for production environments
4. **Regular Validation**: Check `aws-status` to verify current credentials
5. **Environment Isolation**: Clear credentials between different client work

## 📖 Installation Options

### Option 1: Direct Source (Recommended)
```nu
# Add to ~/.config/nushell/config.nu
def awsl-dev []: nothing -> nothing {
    source /path/to/aws-nushell-login/aws-login.nu
    aws-login development
    aws-status
}
```

### Option 2: Path Installation
```nu
# Run once
./install.nu  # Adds to PATH

# Then use globally
aws-login production --sso
```

### Option 3: Module Installation
```nu
# Add to ~/.config/nushell/config.nu
use /path/to/aws-nushell-login/aws-login.nu *

# Then create aliases
def awsl-prod []: nothing -> nothing { aws-login production --sso }
```

## 🔧 Configuration Examples

### AWS SSO Setup (`~/.aws/config`)
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

### Traditional Setup (`~/.aws/credentials`)
```ini
[development]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY

[production]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

## ❓ Troubleshooting

### Problem: "Profile not found"
```nu
# Check available profiles
aws-profiles

# Verify AWS configuration
ls ~/.aws/
```

### Problem: "SSO login failed"  
```nu
# Check SSO configuration
aws sso login --profile your-profile

# Verify SSO URL is correct in ~/.aws/config
```

### Problem: "Credentials expired"
```nu
# Check current status
aws-status

# Refresh credentials
aws-login your-profile --sso
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