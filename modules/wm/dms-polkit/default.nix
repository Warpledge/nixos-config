#=====================================================================#
# DMS PASSWORD PROMPT
#=====================================================================#
#- DMS is the session's polkit agent, so it asks for every admin password:
#- NixOS Settings, pkexec, and nixm through NH_ELEVATION_STRATEGY (nix/nh.nix).
#- Upstream asks in a floating window that other windows can take the keyboard
#- from. This swaps in DMS's full-screen modal (upstream uses it only inside
#- its updater popout): the screen dims, clicks outside the prompt are caught,
#- and it keeps the keyboard until it closes. PolkitScreenBlockers.qml does the
#- same for the other monitors. A DMS update that changes these lines fails the
#- build here (--replace-fail).
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
      '';
  });
}
