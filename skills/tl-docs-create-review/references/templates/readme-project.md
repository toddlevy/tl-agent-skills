# README Project Template

"Absurdly thorough" project README template serving three purposes: Deploy, Understand, Develop.

---

## Template

```markdown
# {{PROJECT_NAME}}

{{ONE_LINE_DESCRIPTION}}

[![License](https://img.shields.io/badge/license-{{LICENSE}}-blue.svg)](LICENSE)

## Overview

{{2-3_PARAGRAPH_OVERVIEW}}

## Features

- **{{FEATURE_1}}** — {{FEATURE_1_DESCRIPTION}}
- **{{FEATURE_2}}** — {{FEATURE_2_DESCRIPTION}}
- **{{FEATURE_3}}** — {{FEATURE_3_DESCRIPTION}}

## Quick Start

Get up and running in under 5 minutes.

### Prerequisites

- Node.js {{NODE_VERSION}}+
- pnpm {{PNPM_VERSION}}+
- {{OTHER_PREREQS}}

### Installation

```bash
# Clone the repository
git clone {{REPO_URL}}
cd {{PROJECT_DIR}}

# Install dependencies
pnpm install

# Set up environment
cp .env.example .env
# Edit .env with your values

# Start development server
pnpm dev
```

The server runs at http://localhost:{{PORT}}.

## Usage

### Basic Usage

{{BASIC_USAGE_EXAMPLES}}

### Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `{{OPTION_1}}` | `{{DEFAULT_1}}` | {{OPTION_1_DESC}} |
| `{{OPTION_2}}` | `{{DEFAULT_2}}` | {{OPTION_2_DESC}} |

See [Configuration Reference](./docs/reference/config.md) for all options.

### Examples

{{USAGE_EXAMPLES}}

## Architecture

{{ARCHITECTURE_OVERVIEW}}

```
{{DIRECTORY_STRUCTURE}}
```

See [Architecture Guide](./docs/developer/architecture.md) for details.

## Development

### Setup

{{DEV_SETUP_STEPS}}

### Commands

| Command | Description |
|---------|-------------|
| `pnpm dev` | Start development server |
| `pnpm build` | Production build |
| `pnpm test` | Run tests |
| `pnpm lint` | Lint code |
| `pnpm typecheck` | Type check |

### Testing

{{TESTING_OVERVIEW}}

```bash
# Run all tests
pnpm test

# Run specific test file
pnpm test path/to/file.test.ts

# Run with coverage
pnpm test:coverage
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

## Deployment

### Production Build

```bash
pnpm build
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection |
| `{{ENV_VAR}}` | {{REQUIRED}} | {{ENV_VAR_DESC}} |

See [Environment Variables Reference](./docs/reference/env-vars.md).

### Docker

```bash
docker build -t {{PROJECT_NAME}} .
docker run -p {{PORT}}:{{PORT}} {{PROJECT_NAME}}
```

### {{PLATFORM}} Deployment

{{PLATFORM_SPECIFIC_INSTRUCTIONS}}

## Troubleshooting

### Common Issues

#### {{ISSUE_1}}

{{ISSUE_1_SOLUTION}}

#### {{ISSUE_2}}

{{ISSUE_2_SOLUTION}}

See [Troubleshooting Guide](./docs/operations/troubleshooting.md) for more.

## Documentation

- [Full Documentation](./docs/README.md)
- [API Reference](./docs/reference/api/README.md)
- [Changelog](./CHANGELOG.md)

## License

{{LICENSE_TYPE}} — see [LICENSE](./LICENSE) for details.

## Acknowledgments

{{ACKNOWLEDGMENTS}}
```

---

## Usage Notes

### Three Purposes

Every README should enable:

1. **Deploy** — Someone can get this running in production
2. **Understand** — Someone can grasp what this does and how
3. **Develop** — Someone can contribute code effectively

### Absurd Thoroughness Principle

From shpigford skill: When in doubt, include it. It's easier to remove than to discover missing information.

### Sections to Include/Exclude

| Always Include | Include If Applicable | Skip If Not Relevant |
|----------------|----------------------|---------------------|
| Overview | Docker | Acknowledgments |
| Quick Start | API | Badges |
| Usage | Contributing | Screenshots |
| Development | Troubleshooting | |
| Deployment | License | |

---

## Source Attribution

Based on shpigford readme skill with "absurd thoroughness" principle.
