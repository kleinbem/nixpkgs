{
  lib,
  bambu-studio,
}:

# nixpkgs-update: no auto update
(bambu-studio.override { withOpenNetworking = true; }).overrideAttrs (oldAttrs: {
  strictDeps = true;
  __structuredAttrs = true;

  # wx-config has to run at build time
  nativeBuildInputs =
    oldAttrs.nativeBuildInputs ++ lib.filter (p: (p.pname or "") == "wxwidgets") oldAttrs.buildInputs;

  meta = oldAttrs.meta // {
    # Defined here so meta.position points at this file and nixpkgs-update sees the opt-out above.
    description = "PC Software for BambuLab's 3D printers, with the open-source network plugin";
    longDescription = ''
      Bambu Studio with open-bamboo-networking in place of the proprietary
      network plugin that `bambu-studio` downloads at first launch.

      Not a full replacement: the printer has to be in LAN Only and Developer
      mode, so printing through the Bambu cloud (remote printing, Bambu Handy,
      cloud print history) is not available. Use `bambu-studio` for those.
    '';
    maintainers = oldAttrs.meta.maintainers ++ [ lib.maintainers.mio ];
  };
})
