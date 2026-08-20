{
  description = "Automatically toggle Num Lock when a USB keyboard is connected";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          autonumlock = pkgs.stdenvNoCC.mkDerivation {
            pname = "autonumlock";
            version = "1.2.4";
            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            postPatch = ''
              substituteInPlace autonumlock \
                --replace-fail '$IYellow$(basename $0)' '$IYellow""autonumlock'
            '';

            installPhase = ''
              runHook preInstall

              install -Dm755 autonumlock "$out/libexec/autonumlock/autonumlock"
              install -Dm644 default_config "$out/libexec/autonumlock/default_config"
              mkdir -p "$out/bin"
              ln -s "$out/libexec/autonumlock/autonumlock" "$out/bin/autonumlock"

              wrapProgram "$out/libexec/autonumlock/autonumlock" \
                --prefix PATH : ${
                  pkgs.lib.makeBinPath [
                    pkgs.coreutils
                    pkgs.gnugrep
                    pkgs.gnused
                    pkgs.numlockx
                    pkgs.usbutils
                  ]
                }

              runHook postInstall
            '';

            meta = {
              description = "Toggle Num Lock based on USB keyboard presence";
              homepage = "https://github.com/wsinned/autonumlock";
              license = pkgs.lib.licenses.mit;
              mainProgram = "autonumlock";
              platforms = pkgs.lib.platforms.linux;
            };
          };

          default = autonumlock;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
