{
  lib,
  stdenv,
  zig_0_15,
  installSymlinks ? true,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ziptools";
  version = lib.trim (builtins.readFile ../.version);

  src = ../.;

  nativeBuildInputs = [
    zig_0_15
    zig_0_15.hook
  ];

  postInstall = lib.optionalString installSymlinks ''
    ln -s $out/bin/ziptools $out/bin/zip
    ln -s $out/bin/ziptools $out/bin/unzip
  '';

  setupHook = ./setup-hook.sh;

  meta = {
    description = "Modern zip & unzip replacements";
    license = lib.licenses.lgpl21Only;
    homepage = "https://github.com/RossComputerGuy/ziptools";
 };
})
