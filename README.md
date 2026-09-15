# Coqueiro Code — installer

Public installer script for [Coqueiro Code CLI](https://github.com/andrealb92/coqueiro-code-cli),
a private repository. This repo contains nothing but the install script — no
source code.

```bash
curl -fsSL https://raw.githubusercontent.com/andrealb92/coqueiro-code-installer/main/install.sh | bash
```

It installs the `coqueiro` command and its short alias `cqro`.

You still need access to `andrealb92/coqueiro-code-cli` (an SSH key or HTTPS
credentials with permission on that repo) for the clone step to succeed.

## SSH clone

```bash
curl -fsSL https://raw.githubusercontent.com/andrealb92/coqueiro-code-installer/main/install.sh | COQUEIRO_SSH=1 bash
```

## Coming from Cqro Code

Re-run the installer. It moves a managed install from `~/.cqro-code` to
`~/.coqueiro-cli` and relinks it. `CQRO_*` variables are still honored.

## Requirements

- [Bun](https://bun.sh) 1.1+
- `git`, `npm`
