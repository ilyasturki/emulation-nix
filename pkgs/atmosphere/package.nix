{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "atmosphere";
  version = "1.11.2";

  # The asset name carries the bundled hbl and hbmenu versions and a commit
  # abbreviation, none of which follow from the release tag.
  asset = "atmosphere-1.11.2-master-5388824be+hbl-2.4.5+hbmenu-3.6.1.zip";

  src = fetchurl {
    url = "https://github.com/Atmosphere-NX/Atmosphere/releases/download/${finalAttrs.version}/${finalAttrs.asset}";
    hash = "sha256-Kc5ZriN75ZzSDBX/9GzR9eEn7CtgfmWjQS45Z5dEhkk=";
  };

  fusee = fetchurl {
    url = "https://github.com/Atmosphere-NX/Atmosphere/releases/download/${finalAttrs.version}/fusee.bin";
    hash = "sha256-ymLhd+D14wXja0VdN/JrhT++k4/S/x51ONTjc84goYM=";
  };

  nativeBuildInputs = [ unzip ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/atmosphere
    unzip -q $src -d $out/share/atmosphere
    install -Dm444 ${finalAttrs.fusee} $out/share/atmosphere/fusee.bin

    runHook postInstall
  '';

  meta = {
    description = "Customized firmware for the Nintendo Switch";
    longDescription = ''
      SD card payload, not a Linux program: the archive unpacks to the card root
      and fusee.bin is injected over USB. Nothing lands in $out/bin.
    '';
    homepage = "https://github.com/Atmosphere-NX/Atmosphere";
    changelog = "https://github.com/Atmosphere-NX/Atmosphere/releases/tag/${finalAttrs.version}";
    license = lib.licenses.gpl2Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.all;
  };
})
