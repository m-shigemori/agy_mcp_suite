# Agy MCP Automation Suite

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]

[JA](README.md) | [EN](README.en.md)

Google Antigravity CLI (`agy`) と MCP サーバーの環境構築を自動化するツール

## 必要条件

- OS: Ubuntu

## インストール

```bash
bash setup.sh
source ~/.bashrc
```

## 使用方法

### Agy CLI の起動
```bash
agy
```

### スキルの使用方法
インストールすると、以下のカスタムグローバルスキルが登録され、`agy` 内でスラッシュコマンドとして呼び出せるようになります。
- `/git-push`: Gitのコミットとプッシュを自律的に行います。

## ライセンス

[MIT License](LICENSE)

[contributors-shield]: https://img.shields.io/github/contributors/m-shigemori/agy_mcp_suite?style=for-the-badge
[contributors-url]: https://github.com/m-shigemori/agy_mcp_suite/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/m-shigemori/agy_mcp_suite?style=for-the-badge
[forks-url]: https://github.com/m-shigemori/agy_mcp_suite/network/members
[stars-shield]: https://img.shields.io/github/stars/m-shigemori/agy_mcp_suite?style=for-the-badge
[stars-url]: https://github.com/m-shigemori/agy_mcp_suite/stargazers
[issues-shield]: https://img.shields.io/github/issues/m-shigemori/agy_mcp_suite?style=for-the-badge
[issues-url]: https://github.com/m-shigemori/agy_mcp_suite/issues
[license-shield]: https://img.shields.io/github/license/m-shigemori/agy_mcp_suite?style=for-the-badge
[license-url]: https://github.com/m-shigemori/agy_mcp_suite/blob/main/LICENSE
