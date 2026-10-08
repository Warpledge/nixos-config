{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      android-tools
      flutter
      gradle
    ];

    sessionVariables = {
      ANDROID_HOME = "${builtins.getEnv "HOME"}/Android/Sdk";
      ANDROID_SDK_ROOT = "${builtins.getEnv "HOME"}/Android/Sdk";
    };

    sessionPath = [
      "${builtins.getEnv "HOME"}/Android/Sdk/cmdline-tools/latest/bin"
      "${builtins.getEnv "HOME"}/Android/Sdk/platform-tools"
      "${pkgs.gradle}/bin"
    ];
  };
}
