# Omarchy's themes for the mangobutter desktop: each theme's colors.toml
# turned into a mangobutter theme (scripts/themes reads
# share/butter-themes/*.conf), its wallpapers from omarchy-themes-backgrounds
# (WebP made JPEG, which the wallpaper picker and butterpal read), and its
# preview image for the theme picker. Both repos are MIT.
#
#   share/butter-themes/omarchy.conf      one [theme] section each
#   share/wallpapers/omarchy-<theme>-<name>.jpg
#   share/omarchy-themes/<theme>/preview.png
#
# The terminal colors follow Omarchy's own kitty template
# (default/themed/kitty.conf.tpl).
{
  stdenvNoCC,
  fetchFromGitHub,
  python3,
  imagemagick,
}:
let
  omarchy = fetchFromGitHub {
    owner = "basecamp";
    repo = "omarchy";
    rev = "cafb6981b6ebfbac8fc7164b32f94f20397f731c";
    sparseCheckout = [ "themes" ];
    hash = "sha256-TT2/drE/Gc1CDphcrJFcYLFhFtX6GBWZnknOhrQSQC0=";
  };
  backgrounds = fetchFromGitHub {
    owner = "omacom";
    repo = "omarchy-themes-backgrounds";
    rev = "1bdb4aac72e5c3a834e1687624e05f311859e1b4";
    hash = "sha256-GiscUmhCROLqXAd4swQj/z22/Ct+HyCXq9Pd94LNDb4=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "omarchy-themes";
  version = "0-unstable-2026-11-27";
  dontUnpack = true;
  nativeBuildInputs = [
    python3
    imagemagick
  ];
  buildPhase = ''
    runHook preBuild
    python3 ${./omarchy-themes.py} ${omarchy}/themes ${backgrounds} $out
    runHook postBuild
  '';
  dontInstall = true;
  dontFixup = true;
  meta = {
    description = "Omarchy's themes and wallpapers as mangobutter themes";
    homepage = "https://github.com/basecamp/omarchy";
  };
}
