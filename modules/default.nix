{
  config,
  lib,
  pkgs,
  ...
}:

let
  emulator = name: description: {
    options.programs.${name} = {
      enable = lib.mkEnableOption description;

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.${name};
        defaultText = lib.literalExpression "pkgs.${name}";
        description = "The ${name} package to use.";
      };
    };

    config = lib.mkIf config.programs.${name}.enable {
      environment.systemPackages = [ config.programs.${name}.package ];
      # Gamepad hotplug access, for the packages that ship rules.
      services.udev.packages = [ config.programs.${name}.package ];
    };
  };
in
{
  imports = [
    (emulator "citron-neo" "Citron NEO, a Nintendo Switch emulator")
    (emulator "panda3ds" "Panda3DS, a Nintendo 3DS emulator")
    (emulator "pcsx2" "PCSX2, a PlayStation 2 emulator")
    (emulator "ryujinx-canary" "Ryujinx canary, a Nintendo Switch emulator")
  ];
}
