# Git Commit Guidelines

## Format

```
type(scope): description

- Brief summary of key changes
- Additional context if needed
```

## Commit Types

| Type     | Description                                    |
|----------|------------------------------------------------|
| feat     | New feature or functionality                   |
| fix      | Bug fix                                        |
| docs     | Documentation updates                          |
| refactor | Code restructuring without behavior changes    |
| test     | Adding or updating tests                       |
| chore    | Maintenance tasks, dependencies, build changes |
| style    | Code formatting, whitespace fixes             |

## Examples

```
feat(auth): add JWT token validation
fix(ui): resolve crash on iOS 14
docs(readme): update installation guide
refactor(api): simplify user service logic
test(banner): add impression tracking tests
chore(deps): update CocoaPods version
```

## Guidelines

- Use lowercase for type and description
- Keep description under 50 characters
- Use present tense ("add" not "added")
- Don't end description with a period
- Scope is optional but helpful for context
- Limit bullet points to 8 lines maximum
- No extra footers or "Generated with Claude Code" messages