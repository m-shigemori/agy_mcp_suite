# Agy MCP Automation Suite

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]

[JA](README.md) | [EN](README.en.md)

A tool suite for automating the setup of Google Antigravity CLI (`agy`) and MCP servers.

## Requirements

- OS: Ubuntu
- curl, git

## Installation

```bash
bash setup.sh
source ~/.bashrc
```

## Usage

### Launch Agy CLI
```bash
agy
```

### Using Skills
After installation, the following custom global skills will be registered and can be executed via slash commands within `agy`:
- `/git-push`: Autonomously handles Git staging, committing, and pushing.

## License

[MIT License](LICENSE)

[contributors-shield]: https://img.shields.io/github/contributors/m-shigemori/gemini_mcp_suite?style=for-the-badge
[contributors-url]: https://github.com/m-shigemori/gemini_mcp_suite/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/m-shigemori/gemini_mcp_suite?style=for-the-badge
[forks-url]: https://github.com/m-shigemori/gemini_mcp_suite/network/members
[stars-shield]: https://img.shields.io/github/stars/m-shigemori/gemini_mcp_suite?style=for-the-badge
[stars-url]: https://github.com/m-shigemori/gemini_mcp_suite/stargazers
[issues-shield]: https://img.shields.io/github/issues/m-shigemori/gemini_mcp_suite?style=for-the-badge
[issues-url]: https://github.com/m-shigemori/gemini_mcp_suite/issues
[license-shield]: https://img.shields.io/github/license/m-shigemori/gemini_mcp_suite?style=for-the-badge
[license-url]: https://github.com/m-shigemori/gemini_mcp_suite/blob/main/LICENSE
