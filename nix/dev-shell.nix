{ ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = [
        pkgs.moonbit-bin.latest
        pkgs.nodejs_22
        (pkgs.python312.withPackages (ps: [
          ps.onnx
          ps.pyyaml
          ps.torch
        ]))
      ];
    };
  };
}
