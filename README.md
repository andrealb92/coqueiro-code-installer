# Cqro Code — installer

Public installer script for [Cqro Code CLI](https://github.com/andrealb92/cqro-code-cli),
a private repository. This repo contains nothing but the install script — no
source code.

```bash
curl -fsSL https://raw.githubusercontent.com/andrealb92/cqro-code-installer/main/install.sh | bash
```

You still need access to `andrealb92/cqro-code-cli` (an SSH key or HTTPS
credentials with permission on that repo) for the clone step to succeed.

## SSH clone

```bash
CQRO_SSH=1 curl -fsSL https://raw.githubusercontent.com/andrealb92/cqro-code-installer/main/install.sh | bash
```

## Requirements

- [Bun](https://bun.sh) 1.1+
- `git`, `npm`
