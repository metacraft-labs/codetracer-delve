{
  description = "Patched Delve debugger for CodeTracer (extends When() with tick counts)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        {
          self',
          pkgs,
          lib,
          ...
        }:
        let
          delve = pkgs.buildGoModule {
            pname = "delve";
            version = "1.26.0-codetracer";

            src = ./.;

            vendorHash = null;

            subPackages = [ "cmd/dlv" ];

            nativeBuildInputs = [ pkgs.makeWrapper ];

            # Delve compiles with -O0; fortify breaks the build.
            hardeningDisable = [ "fortify" ];

            # Tests require ptrace and local networking, unavailable in Nix sandbox.
            doCheck = false;

            postInstall = ''
              # Wrap binary to disable fortify at runtime.
              wrapProgram $out/bin/dlv \
                --prefix disableHardening " " fortify

              # Symlink for VS Code Go extension.
              # https://github.com/golang/vscode-go/blob/master/docs/debugging.md#manually-installing-dlv-dap
              ln $out/bin/dlv $out/bin/dlv-dap
            '';

            meta = with lib; {
              description = "Patched Delve debugger for CodeTracer (with rr tick count support)";
              homepage = "https://github.com/metacraft-labs/codetracer-delve";
              license = licenses.mit;
              mainProgram = "dlv";
            };
          };
        in
        {
          packages.delve = delve;
          packages.default = delve;
        };
    };
}
