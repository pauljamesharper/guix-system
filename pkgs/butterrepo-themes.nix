# The GTK template and icon themes Debian gets from butterrepo: prebuilt
# selections of vinceliuice's Orchis and Colloid (CSS and SVG only).
# mangobutter's gtk-theme recolours Orchis-Nord-Template on every
# wallpaper pick, so it must be this exact build.
{ stdenvNoCC, fetchurl, dpkg }:
let
  fromDeb =
    {
      pname,
      version,
      hash,
      subdir,
    }:
    stdenvNoCC.mkDerivation {
      inherit pname version;
      src = fetchurl {
        url = "https://apt.justaguy.dev/pool/main/${pname}_${version}_all.deb";
        inherit hash;
      };
      nativeBuildInputs = [ dpkg ];
      unpackPhase = "dpkg-deb -x $src .";
      installPhase = ''
        mkdir -p $out/share
        cp -r usr/share/${subdir} $out/share/
      '';
      dontFixup = true;
      meta.homepage = "https://justaguy.dev/butter";
    };
in
{
  orchis-nord-template = fromDeb {
    pname = "orchis-gtk-theme-butter";
    version = "2026.07.07-1";
    hash = "sha256-bNvhf/HVVS8Y1abVxc7tbNm4p/BmcNJUl8IodkyYcxM=";
    subdir = "themes";
  };

  colloid-icon-theme-butter = fromDeb {
    pname = "colloid-icon-theme-butter";
    version = "2026.08.10-7";
    hash = "sha256-6Xxuph9UKzXjhMEHS0uf5oHC9mx25a/3OGPkZomXsf8=";
    subdir = "icons";
  };
}
