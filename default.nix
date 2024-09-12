{ pkgs ? import <nixpkgs> {} }:

let
  unfreePkgs = import pkgs.path {
    config.allowUnfree = true;
    inherit (pkgs) system;
  };
  aarch64Pkgs = unfreePkgs.pkgsCross.aarch64-multiplatform;

  buildImage = pkgs.callPackage ./pkgs/build-image {};
  aarch64Image = pkgs.callPackage ./pkgs/aarch64-image {};
  rockchip = uboot: pkgs.callPackage ./images/rockchip.nix {
    inherit uboot;
    inherit aarch64Image buildImage;
  };

  ubootHelios64 = aarch64Pkgs.buildUBoot rec {
    version = "2022.07";
    src = pkgs.fetchurl {
      url = "https://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2";
      hash = "sha256-krCOtJwk2hTBrb9wpxro83zFPutCMOhZrYtnM9E9z14=";
    };
    patches = [
      ./0001-rk3399-update-memory-layout-for-larger-modern-kernels.patch
    ] ++ extraPatches;
    extraPatches = [
      (pkgs.fetchpatch {
        url = "https://raw.githubusercontent.com/armbian/build/main/patch/u-boot/u-boot-rockchip64/add-board-helios64.patch";
        hash = "sha256-REwp1F7ni/PXXMzuLxjO3PonCuyAxqIjVaqABTORuHY=";
      })
    ];
    postPatch = ''
      cat include/configs/rk3399_common.h
      patchShebangs tools
      patchShebangs scripts
      patchShebangs arch/arm/mach-rockchip
    '';
    defconfig = "helios64-rk3399_defconfig";
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${aarch64Pkgs.armTrustedFirmwareRK3399}/bl31.elf";
    filesToInstall = [ "u-boot.itb" "idbloader.img" ".config" ];
  };

in {
  inherit aarch64Image;

  rock64 = rockchip aarch64Pkgs.ubootRock64;
  rockPro64 = rockchip aarch64Pkgs.ubootRockPro64;
  roc-pc-rk3399 = rockchip aarch64Pkgs.ubootROCPCRK3399;
  pinebookPro = rockchip aarch64Pkgs.ubootPinebookPro;
  rock4cPlus = rockchip aarch64Pkgs.ubootRock4CPlus;
  helios64 = rockchip ubootHelios64;
}