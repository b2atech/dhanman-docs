#  Authentication Flow

- Auth0 custom database connection (PostgreSQL)
- Login  MFA  JWT issued with permissions claims
- Services validate via DynamicPermissionPolicy
"@

New-MarkdownFile "system\security\authorization-model.md" @"
#  Authorization Model

- Permissions table synced from Auth0
- [RequiresPermissions] attributes at controller level
- Gatekeeper CLI validates missing permissions
