# Contributing to Dotfiles

Thank you for your interest in contributing to this dotfiles repository!

## How to Contribute

### Reporting Issues

1. Check if the issue already exists
2. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (macOS version, architecture)

### Suggesting Enhancements

1. Open an issue with the `enhancement` label
2. Describe the feature and its benefits
3. Provide examples if possible

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with descriptive messages
6. Push to your branch
7. Open a Pull Request

## Development Guidelines

### Code Style

- Use 4 spaces for indentation in shell scripts
- Follow [ShellCheck](https://www.shellcheck.net/) recommendations
- Add comments for complex logic
- Keep functions small and focused

### Testing

Before submitting:

```bash
# Check syntax
make test

# Test installation in dry-run mode
DRY_RUN=true ./install.sh

# Run health checks
./dotfiles.sh health

# Check for shell script issues
shellcheck install.sh dotfiles.sh
```

### Commit Messages

Follow conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Maintenance tasks

Example:
```
feat: add support for fish shell configuration

- Add fish config file
- Update installation script
- Add fish to health checks
```

## Adding New Tools

To add a new tool or package:

1. Update `install.conf.yaml` with the package
2. Add to appropriate package group
3. Test installation
4. Update documentation
5. Add to health checks if important

Example:
```yaml
# In install.conf.yaml
packages:
  development_tools:
    formulas:
      - your-new-tool
```

## Documentation

- Update README.md for user-facing changes
- Add inline comments for complex code
- Update help text in scripts
- Keep configuration files documented

## Questions?

Feel free to open an issue for any questions about contributing!