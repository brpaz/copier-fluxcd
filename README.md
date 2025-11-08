# Copier FluxCD

<p align="center">

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-black.json&style=for-the-badge)](https://github.com/copier-org/copier)
[![Build Status](https://img.shields.io/github/actions/workflow/status/brpaz/copier-fluxcd/ci.yml?branch=main&style=for-the-badge)](https://github.com/brpaz/copier-fluxcd/actions)

</p>

> A copier template to scaffold a FluxCD Repository.

## 📦 What is included?

- [Devenv](https://devenv.sh/) to provision a consistent development environment
- [Lefthook](https://github.com/evilmartians/lefthook) for Git hooks management
- GitHub Actions for CI/CD
- Pre-configured [FluxCD](https://fluxcd.io/) manifests, based on the [flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example) repository
- [Taskfile](https://taskfile.dev/) to manage common tasks
- [Sops](https://github.com/mozilla/sops) for secrets management.

## 🚀 Getting Started

### Pre-Requisites

This template is built with [Copier](https://copier.readthedocs.io/en/stable/), a Python based project templating tool.

To install copier on your system, follow the instructions at [Copier Website](https://copier.readthedocs.io/en/stable/#installation)

### Usage

To create a new project using this template, run the following command:

```bash
copier copy gh:brpaz/copier-fluxcd /path/to/your/new/project
```

And answer the prompts to customize your new project.

## 🗒️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.