{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  dotenv.enable = true;

  packages = [
    pkgs.go-task
    pkgs.lefthook
    pkgs.kubeconform
    pkgs.kubectl
    pkgs.yq-go
    pkgs.fluxcd
    pkgs.shellcheck
    pkgs.kind
    pkgs.sops
    pkgs.commitlint-rs
    pkgs.cilium-cli
  ];

  enterShell = ''
    if [ ! -f .env ]; then
      cp .env.example .env
    fi

    lefthook install
  '';
}
