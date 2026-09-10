{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  qt6Packages,
  SDL2,
  glslang,
  libGL,
  alsa-lib,
  libpulseaudio,
  libx11,
  pipewire,
  spirv-tools,
  vulkan-headers,
  vulkan-loader,
  wayland,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "panda3ds";
  version = "0.9-unstable-2026-08-11";

  src = fetchFromGitHub {
    owner = "wheremyfoodat";
    repo = "Panda3DS";
    rev = "5aaa1d26565c834a6f1999026260e559f54aacf1";
    hash = "sha256-ZZ296lsjeFQM6mY6ERGe2WOPjTDMgPf+mCpeA2XmyfM=";
    # 27 submodules and no FetchContent, CPM or file(DOWNLOAD) anywhere in the
    # CMake tree: this is the whole dependency graph.
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6Packages.qttools
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    SDL2
    glslang
    libGL
    libx11
    qt6Packages.qtbase
    qt6Packages.qtwayland
    spirv-tools
    vulkan-headers
    vulkan-loader
    wayland
  ];

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_QT_GUI" true)
    (lib.cmakeBool "ENABLE_USER_BUILD" true)
    (lib.cmakeBool "ENABLE_VULKAN" true)
    (lib.cmakeBool "ENABLE_WAYLAND" true)
    (lib.cmakeBool "ENABLE_TESTS" false)
    (lib.cmakeBool "ENABLE_HTTP_SERVER" false)
    # Would shell out to git against a .git that fetchFromGitHub strips.
    (lib.cmakeBool "ENABLE_GIT_VERSIONING" false)
    # Otherwise third_party/SDL2 is built static against whatever headers happen
    # to be visible at configure time, silently dropping backends.
    (lib.cmakeBool "USE_SYSTEM_SDL2" true)
  ];

  # Upstream ships no install() rules; the AppImage script scrapes the build dir.
  installPhase = ''
    runHook preInstall

    install -Dm755 Alber -t $out/bin
    install -Dm644 $src/.github/Alber.desktop -t $out/share/applications
    install -Dm644 $src/docs/img/Alber.png $out/share/icons/hicolor/512x512/apps/Alber.png

    runHook postInstall
  '';

  # miniaudio is the audio device and reaches ALSA, PulseAudio and PipeWire
  # through dlopen by soname, so they resolve against this and nothing else.
  qtWrapperArgs = [
    "--prefix LD_LIBRARY_PATH : ${
      lib.makeLibraryPath [
        alsa-lib
        libpulseaudio
        pipewire
        vulkan-loader
      ]
    }"
  ];

  meta = {
    description = "HLE Nintendo 3DS emulator";
    homepage = "https://github.com/wheremyfoodat/Panda3DS";
    license = lib.licenses.gpl3Only;
    mainProgram = "Alber";
    platforms = [ "x86_64-linux" ];
  };
})
