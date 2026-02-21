# Contributing

Thank you for your interest in contributing to this project!

## Development

1. Fork the repository
2. Create a feature branch: `git checkout -b my-feature`
3. Make your changes
4. Test your changes locally
5. Commit with a descriptive message
6. Push to your fork and open a Pull Request

## Testing Locally

You can test the action locally using the entrypoint script:

```bash
# Dry run — install latest doctl without authentication
./entrypoint.sh -v latest --no-auth

# Install a specific version
./entrypoint.sh -v 1.98.1 --no-auth

# View help
./entrypoint.sh -h
```

Requirements:
- `curl` installed
- `tar` or `unzip` installed (depending on platform)

## Releasing

This project uses semantic versioning and automated releases.

### Creating a Release

1. Ensure all changes are merged to the main branch
2. Create and push a semantic version tag:

```bash
git checkout main
git pull origin main
git tag v1.0.0
git push origin v1.0.0
```

3. The release workflow will automatically:
   - Create a GitHub Release with auto-generated notes
   - Update major version tag (`v1` → points to `v1.0.0`)
   - Update minor version tag (`v1.0` → points to `v1.0.0`)

### Version Guidelines

- **Patch** (`v1.0.1`): Bug fixes, documentation updates
- **Minor** (`v1.1.0`): New features, backward-compatible changes
- **Major** (`v2.0.0`): Breaking changes

### Users Reference Tags

Users can reference this action at different stability levels:

```yaml
# Always get latest v1.x.x (recommended)
- uses: raisedadead/action-doctl-installer@v1

# Pin to minor version
- uses: raisedadead/action-doctl-installer@v1.0

# Pin to exact version
- uses: raisedadead/action-doctl-installer@v1.0.0
```
