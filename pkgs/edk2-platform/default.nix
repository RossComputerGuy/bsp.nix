{
  lib,
  stdenv,
  buildPackages,
  edk2,
  runCommandNoCC,
  fetchFromGitHub,
  extraWorkspaceSources ? { },
}:
let
  workspaceSources = {
    edk2 = edk2.src;
    edk2-platforms = fetchFromGitHub {
      owner = "tianocore";
      repo = "edk2-platforms";
      rev = "2f2a1233cac5af8860c98ff53a941672e295fda8";
      fetchSubmodules = true;
      hash = "sha256-KmTx/7qQNINZI6GWTV4OuJGFaa+pxyBz8ondRATLZHg=";
    };
  }
  // extraWorkspaceSources;

  targetArch =
    if stdenv.hostPlatform.isi686 then
      "IA32"
    else if stdenv.hostPlatform.isx86_64 then
      "X64"
    else if stdenv.hostPlatform.isAarch32 then
      "ARM"
    else if stdenv.hostPlatform.isAarch64 then
      "AARCH64"
    else if stdenv.hostPlatform.isRiscV64 then
      "RISCV64"
    else if stdenv.hostPlatform.isLoongArch64 then
      "LOONGARCH64"
    else
      throw "Unsupported architecture";
in
edk2.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "edk2-platform";

    src = runCommandNoCC "edk2-workspace" { } ''
      mkdir -p $out
      ${lib.concatMapAttrsStringSep "\n" (name: source: ''
        echo "Copying ${source} to $out/${name}"
        cp -r ${source} $out/${name}
        chmod -R u+w $out/${name}
      '') workspaceSources}
    '';

    postPatch = ''
      for i in edk2/BaseTools/BinWrappers/PosixLike/*; do
        chmod +x "$i"
        patchShebangs --build "$i"
      done
    '';

    installPhase = ''
      runHook preInstall

      mkdir -vp $out
      mv -v edk2/BaseTools $out
      mv -v edk2/edksetup.sh $out
      # patchShebangs fails to see these when cross compiling
      for i in $out/BaseTools/BinWrappers/PosixLike/*; do
        chmod +x "$i"
        patchShebangs --build "$i"
      done

      runHook postInstall
    '';

    makeFlags = [ "-C edk2/BaseTools" ];

    passthru = prevAttrs.passthru // {
      mkDerivation =
        projectDscPath: attrsOrFun:
        prevAttrs.passthru.mkDerivation projectDscPath (
          finalAttrsInner:
          let
            attrs = lib.toFunction attrsOrFun finalAttrsInner;
            buildType = attrs.buildType or (if stdenv.hostPlatform.isDarwin then "CLANGPDB" else "GCC5");
          in
          {
            postPatch = ''
              rm -rf edk2/BaseTools
              cp -r ${buildPackages.edk2-platform}/BaseTools edk2/BaseTools
              chmod -R u+w edk2/BaseTools
            ''
            + lib.optionalString (builtins.hasAttr "postPatch" attrs) attrs.postPatch;

            preConfigure = ''
              export WORKSPACE="$PWD"
              export PACKAGES_PATH="${lib.concatMapAttrsStringSep ":" (name: _: "$PWD/${name}") workspaceSources}"
            ''
            + lib.optionalString (builtins.hasAttr "preConfigure" attrs) attrs.preConfigure;

            configurePhase = ''
              runHook preConfigure

              . ${buildPackages.edk2-platform}/edksetup.sh BaseTools

              runHook postConfigure
            '';

            buildPhase = ''
              runHook preBuild
              build -a ${targetArch} -b ${attrs.buildConfig or "RELEASE"} -t ${buildType} -p ${projectDscPath} -n $NIX_BUILD_CORES $buildFlags
              runHook postBuild
            '';
          }
          // builtins.removeAttrs attrs [
            "preConfigure"
            "postPatch"
          ]
        );
    };
  }
)
