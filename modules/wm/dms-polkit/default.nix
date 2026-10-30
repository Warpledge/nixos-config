#=====================================================================#
# DMS PATCHES
#=====================================================================#
#- The one override of DMS's package, so every patch to it lives here.
#- Password prompt: DMS is the polkit agent, so it asks for every admin password (NixOS
#- Settings, pkexec, nixm via nix/nh.nix). This swaps upstream's floating
#- window, which other windows can take the keyboard from, for DMS's
#- full-screen modal: it dims the screen and keeps the keyboard until it
#- closes. PolkitScreenBlockers.qml covers the other monitors. A DMS update
#- that changes these lines fails the build (--replace-fail).
{options, ...}: {
  programs.dank-material-shell.package = options.programs.dank-material-shell.package.default.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        qml=$out/share/quickshell/dms
        control=$qml/Modules/ControlCenter/ControlCenterPopout.qml
        chmod u+w $qml/DMSShell.qml $control $qml/Modals
        install -m644 ${./PolkitScreenBlockers.qml} $qml/Modals/PolkitScreenBlockers.qml
        substituteInPlace $qml/DMSShell.qml \
          --replace-fail \
            'readonly property PolkitAuthModal loadedModal: item as PolkitAuthModal' \
            'readonly property PolkitAuthSurfaceModal loadedModal: item as PolkitAuthSurfaceModal' \
          --replace-fail '        PolkitAuthModal {' '        PolkitAuthSurfaceModal {
          useOverlayLayer: true
          closeOnEscapeKey: false

          PolkitScreenBlockers {
              prompt: polkitAuthModal
          }' \
          --replace-fail 'polkitAuthModalLoader.loadedModal.show();' \
            'polkitAuthModalLoader.loadedModal.open();'
        # Escape still cancels: the prompt's own handler cancels the request.
        # A DankModal is always `visible`; it's open while shouldBeVisible is set.
        substituteInPlace $control \
          --replace-fail 'polkitAuthModal?.visible ?? false' \
            'polkitAuthModal?.shouldBeVisible ?? false'

        # Side rail: the workspace switcher hides the rail's side-rail-* stash
        # workspaces (niri/home/dms/plugins/side-rail/SideRail.qml)
        switcher=$qml/Widgets/WorkspaceSwitcherModel.qml
        chmod u+w $qml/Widgets $switcher
        substituteInPlace $switcher \
          --replace-fail 'const baseList = CompositorService.workspacesForScreen(' \
            'const shownList = CompositorService.workspacesForScreen(' \
          --replace-fail 'if (CompositorService.ephemeralWorkspaces)' \
            'const baseList = shownList.filter(ws => !String(ws?.name ?? "").startsWith("side-rail-")); if (CompositorService.ephemeralWorkspaces)'
      '';
  });
}
