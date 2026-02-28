# Security Policy

## Scope

WarGames Risk is a standalone macOS game with no network communication, no server components, no user authentication, and no collection of personal data. The game runs entirely offline within the macOS application sandbox.

The attack surface is therefore minimal. However, if you discover a security concern, we still want to hear about it.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

Only the latest release is actively maintained.

## Reporting a Vulnerability

If you believe you have found a security vulnerability, please report it responsibly:

1. **Do not** open a public GitHub issue
2. Use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) feature on this repository
3. Alternatively, contact the maintainer directly via email

Please include:

- A description of the issue
- Steps to reproduce
- Potential impact
- Suggested fix, if any

You can expect an initial response within 7 days. If the vulnerability is confirmed, a fix will be prioritized and released as soon as practical.

## What Qualifies

Given the nature of this project, relevant security concerns would include:

- Malicious code injection through crafted game state or save data
- Application sandbox escape
- Unintended file system access
- Dependency supply chain issues (though the project currently has zero external dependencies)

## What Does Not Qualify

- Bugs, crashes, or gameplay issues (use regular GitHub issues for these)
- Theoretical attacks that require physical access to the machine
- Issues in Xcode, macOS, or SpriteKit itself (report these to Apple)

Thank you for helping keep this project safe.
