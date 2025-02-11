{ stdenv
, lib
, fetchurl
, substituteAll
, meson
, ninja
, nixosTests
, pkg-config
, glib
, gettext
, makeWrapper
, gnutls
, p11-kit
, libproxy
, gnome
, gsettings-desktop-schemas
}:

stdenv.mkDerivation rec {
  pname = "glib-networking";
  version = "2.74.0";

  outputs = [ "out" "installedTests" ];

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "HxharvCUEj+OJdj6VWYbP9cQIBY6AXSts1o3aFzaYTs=";
  };

  patches = [
    (substituteAll {
      src = ./hardcode-gsettings.patch;
      gds_gsettings_path = glib.getSchemaPath gsettings-desktop-schemas;
    })

    ./installed-tests-path.patch
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gettext
    makeWrapper
  ];

  buildInputs = [
    glib
    gnutls
    p11-kit
    libproxy
    gsettings-desktop-schemas
  ];

  doCheck = false; # tests need to access the certificates (among other things)

  mesonFlags = [
    "-Dinstalled_tests=true"
    "-Dinstalled_test_prefix=${placeholder "installedTests"}"
  ];

  postFixup = ''
    find "$installedTests/libexec" "$out/libexec" -type f -executable -print0 \
      | while IFS= read -r -d "" file; do
      echo "Wrapping program '$file'"
      wrapProgram "$file" --prefix GIO_EXTRA_MODULES : "$out/lib/gio/modules"
    done
  '';

  passthru = {
    updateScript = gnome.updateScript {
      packageName = pname;
      versionPolicy = "odd-unstable";
    };

    tests = {
      installedTests = nixosTests.installed-tests.glib-networking;
    };
  };

  meta = with lib; {
    description = "Network-related giomodules for glib";
    homepage = "https://gitlab.gnome.org/GNOME/glib-networking";
    license = licenses.lgpl21Plus;
    maintainers = teams.gnome.members;
    platforms = platforms.unix;
  };
}
