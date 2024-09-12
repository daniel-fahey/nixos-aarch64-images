{ stdenv, fetchurl, zstd }:
let
  src = (fetchurl {
    # unfortunally there is no easy way right now to reproduce the same evaluation
    # as hydra, since `pkgs.path` is embedded in the binary
    # To get a new url use:
    # $ curl -s -L -I -o /dev/null -w '%{url_effective}' "https://hydra.nixos.org/job/nixos/trunk-combined/nixos.sd_image.aarch64-linux/latest/download/1"
    url = "https://hydra.nixos.org/build/272559770/download/1/nixos-sd-image-24.11pre680062.4f807e894028-aarch64-linux.img.zst";
    hash = "sha256-ThCT9wSq94VrPSyNqYU2oDMR/LIJzXfj1nLy0W7TMQE=";
  }).overrideAttrs (final: prev: {
    __structuredAttrs = true;
    unsafeDiscardReferences.out = true;
  });
in
stdenv.mkDerivation {
  name = "aarch64-image";
  inherit src;
  preferLocalBuild = true;
  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  # Performance
  dontPatchELF = true;
  dontStrip = true;
  noAuditTmpdir = true;
  dontPatchShebangs = true;

  nativeBuildInputs = [
    zstd
  ];

  installPhase = ''
    zstdcat $src > $out
  '';
}
