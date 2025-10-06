{
  edk2-platform,
  applyPatches,
  fetchFromGitHub,
  openssl,
  acpica-tools,
  armTrustedFirmwareTools,
}:
(edk2-platform.override {
  extraWorkspaceSources = {
    edk2 = fetchFromGitHub {
      owner = "tianocore";
      repo = "edk2";
      rev = "5cf1be671b6869677fe22bebb38ac8519a53089e";
      fetchSubmodules = true;
      hash = "sha256-FAxOXEZ0QWSru9GKegXZsw5ph2iJxg2cVqsMRIPB5ho=";
    };
    edk2-platforms = applyPatches {
      name = "edk2-platforms";

      src = fetchFromGitHub {
        owner = "tianocore";
        repo = "edk2-platforms";
        rev = "2f2a1233cac5af8860c98ff53a941672e295fda8";
        fetchSubmodules = true;
        hash = "sha256-KmTx/7qQNINZI6GWTV4OuJGFaa+pxyBz8ondRATLZHg=";
      };

      patches = [
        ./fix-smbios.patch
      ];
    };
    edk2-non-osi = fetchFromGitHub {
      owner = "tianocore";
      repo = "edk2-non-osi";
      rev = "94d048981116e2e3eda52dad1a89958ee404098d";
      hash = "sha256-6yuvVvmGn4yaEksbbvGDX1ZcKpdWBKnwaNjLGvgAWyk=";
    };
    edk2-ampere-tools = fetchFromGitHub {
      owner = "AmpereComputing";
      repo = "edk2-ampere-tools";
      rev = "880dfffd2a32f30883a7e25f9755facbdce74297";
      hash = "sha256-XyYFSOXdGaUL2ywRTMw9evmQm3D5ifSukv1dwqXZIo4=";
    };
  };
}).mkDerivation
  "Platform/ASRockRack/Altra1L2TPkg/Altra1L2T.dsc"
  {
    pname = "edk2-altrad8ud-1l2t";
    version = "2025-09-03";

    nativeBuildInputs = [
      openssl
      acpica-tools
      armTrustedFirmwareTools
    ];

    NIX_CFLAGS_COMPILE = toString [
      "-I${edk2-platform.src}/edk2/MdePkg/Include/AArch64"
      "-Wno-error=overflow"
      "-Wno-error=format-security"
    ];

    prePatch = ''
      patchShebangs edk2-platforms/Platform/Ampere/Tools/GenerateSecureBootKeys.sh
    '';

    preConfigure = ''
      export MANUFACTURER=ASRockRack
      export BOARD_NAME=Altra1L2T
      export PACKAGES_PATH=$PACKAGES_PATH:$PWD/edk2-platforms/Features/Intel/Debugging:$PWD/edk2-platforms/Features:$PWD/edk2-platforms/Features/Intel

      echo "#define CURRENT_FIRMWARE_VERSION 0x0" > "''${WORKSPACE}/edk2-platforms/Platform/''${MANUFACTURER}/''${BOARD_NAME}Pkg/Capsule/SystemFirmwareDescriptor/HostFwInfo.h"
      echo "#define CURRENT_FIRMWARE_VERSION_STRING L\"\"" >> "''${WORKSPACE}/edk2-platforms/Platform/''${MANUFACTURER}/''${BOARD_NAME}Pkg/Capsule/SystemFirmwareDescriptor/HostFwInfo.h"
      echo "#define LOWEST_SUPPORTED_FIRMWARE_VERSION 0x00000000" >> "''${WORKSPACE}/edk2-platforms/Platform/''${MANUFACTURER}/''${BOARD_NAME}Pkg/Capsule/SystemFirmwareDescriptor/HostFwInfo.h"
    '';

    postConfigure = ''
      export SECUREBOOT_DIR="''${WORKSPACE}/secureboot_objects/"
      mkdir -p $SECUREBOOT_DIR/certs
      touch $SECUREBOOT_DIR/certs/ms_{kek{1,2},db{1,2,3,4,5}}.der

      "''${WORKSPACE}/edk2-platforms/Platform/Ampere/Tools/GenerateSecureBootKeys.sh"

      rm $SECUREBOOT_DIR/certs/ms_{kek{1,2},db{1,2,3,4,5}}.der
    '';

    postInstall = ''
      python3 "''${WORKSPACE}/edk2-ampere-tools/nvparam.py" \
        -f edk2-platforms/Platform/''${MANUFACTURER}/''${BOARD_NAME}Pkg/''${BOARD_NAME}BoardSetting.cfg \
        -o $out/board_cfg.bin
    '';
  }
