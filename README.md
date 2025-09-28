# AWS Nushell Login

A comprehensive Nushell script for AWS CLI authentication with profile-specific aliases. Switch between AWS environments with simple commands like `awsl-dev` and `awsl-prod`.

![Nushell](https://img.shields.io/badge/shell-nushell-green)
![AWS CLI](https://img.shields.io/badge/aws-cli-orange)
![Tests](https://img.shields.io/badge/tests-comprehensive-blue)
![License](https://img.shields.io/badge/license-MIT-blue)

## 🚀 Quick Start

```bash
# Install
git clone https://github.com/lprior-repo/aws-nushell-login.git
cd aws-nushell-login
./install.nu

# Create your first alias (add to ~/.config/nushell/config.nu)
def awsl-dev []: nothing -> nothing {
    aws-login development  # Replace with your dev profile
    print "🚀 Connected to Development"
    aws-status
}

# Use it
awsl-dev        # Login to development
aws-status      # Check credentials  
aws-clear       # Clear when done
```

## ⚡ Essential Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `aws-login` | Main authentication | `aws-login production --sso` |
| `awsl` | Short form | `awsl dev` |
| `aws-status` | Check credentials | Shows current profile and expiration |
| `aws-profiles` | List profiles | Shows all available AWS profiles |
| `aws-clear` | Clear credentials | Removes AWS env vars |

## 🔧 Core Patterns

### Basic Profile Alias
```nu
def awsl-dev []: nothing -> nothing {
    aws-login development
    print "🚀 Connected to Development"
    aws-status
}
```

### Production with Safety
```nu
def awsl-prod []: nothing -> nothing {
    let confirm = (input "⚠️  Connect to PRODUCTION? (y/N): ")
    if $confirm != "y" { return }
    aws-login production --sso
    print "🚨 PRODUCTION ENVIRONMENT - BE CAREFUL!"
    aws-status
}
```

### Region-Specific
```nu
def awsl-prod-us []: nothing -> nothing {
    awsl-prod
    if ("AWS_PROFILE" in ($env | columns)) {
        $env.AWS_DEFAULT_REGION = "us-east-1"
        $env.AWS_REGION = "us-east-1"
    }
}
```

## 🧪 Testing

Following Martin Fowler's Testing Pyramid:

```bash
# Run all tests (70% unit, 20% integration, 10% e2e)
./tests/run-tests.nu

# Quick unit tests for CI
./tests/run-tests.nu quick

# Development tests (unit + integration)
./tests/run-tests.nu dev
```

## 📚 More Examples

See `examples.nu` for comprehensive patterns:
- Multi-client management
- EKS/Kubernetes integration
- Interactive profile selection
- Organization-specific templates

## 🔧 Advanced Features

- **SSO Support**: `aws-login profile --sso`
- **Temporary Credentials**: `aws-login profile --temp`
- **Auto-Region Detection**: Reads from AWS config
- **Production Safeguards**: Confirmation prompts
- **Environment Export**: All AWS CLI tools work automatically

## 🛠️ Requirements

- [Nushell](https://www.nushell.sh/) (shell)
- [AWS CLI](https://aws.amazon.com/cli/) (authentication)
- Configured AWS profiles in `~/.aws/config` and `~/.aws/credentials`

## 📖 Documentation

- **This README** - Essential information (80% of needs)
- **`examples.nu`** - Copy-paste patterns for common use cases
- **`tests/`** - Comprehensive test suite for reliability

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `./tests/run-tests.nu`
5. Submit a pull request

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

---

⭐ **Star this repo** if it helped you manage AWS profiles more easily!