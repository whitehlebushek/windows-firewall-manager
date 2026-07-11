# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.1.x   | Yes       |
| 1.0.x   | Yes       |
| < 1.0   | No        |

## Scope

This tool modifies **Windows Firewall rules** in the group `FirewallManager_Custom` only.
It does not disable the firewall globally.

## Reporting a vulnerability

**Do not** open public Issues for security problems.

Send details to the repository owner via GitHub private report or email (if listed in profile).

Include:
- Windows version
- Steps to reproduce
- Impact (privilege escalation, rule bypass, data leak, etc.)
- Suggested fix (optional)

## Safe usage guidelines

1. Always run as Administrator (required by Windows Firewall API)
2. Export rules before bulk import
3. Test new rules on a single port/IP first
4. Review imported JSON before applying
5. Do not import backups from untrusted sources

## Known limitations

- Requires administrator privileges (by design)
- Rules are stored in Windows Firewall policy store
- Incorrect rules may block network access — keep a backup

## Security design principles

- Isolated rule group: `FirewallManager_Custom`
- No remote code execution
- No network calls from the application
- Open source — auditable MIT-licensed code