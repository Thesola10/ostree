{
  stdenv,
  lib,
  pkg-config,
  gtk-doc,
  curl,
  glib,
  xz,
  which,
  autoconf,
  automake,
  libtool,
  libsodium,
  libarchive,
  bzip2,
  bison,
  libxslt,
  buildPackages,
  withComposefs ? false,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  gobject-introspection,
  python311, python311Packages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ostree";
  version = "2025.4";

  outputs = [
    "out"
    "dev"
    "man"
    "installedTests"
  ];

  src = ./.;

  nativeBuildInputs = [
    autoconf
    automake
    libtool
    pkg-config
    glib
    gtk-doc
    which
    bison
    libxslt
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
  ];

  buildInputs = [
    curl
    (glib.override { python3 = python311; python3Packages = python311Packages; })
    libsodium
    libarchive
    bzip2
    xz
  ];

  enableParallelBuilding = true;

  configureFlags = [
    "--with-curl"
    "--without-composefs"
    "--without-libmount"
    "--without-gpgme"
    "--without-selinux"
    "--disable-rofiles-fuse"
    "--disable-admin"
    "--enable-installed-tests"
    "--with-ed25519-libsodium"
  ]
  ++ lib.optionals withComposefs [
    "--with-composefs"
  ];

  makeFlags = [
    "installed_testdir=${placeholder "installedTests"}/libexec/installed-tests/libostree"
    "installed_test_metadir=${placeholder "installedTests"}/share/installed-tests/libostree"
    # Setting this flag was required as workaround for a clang bug, but seems not relevant anymore.
    # https://github.com/ostreedev/ostree/commit/fd8795f3874d623db7a82bec56904648fe2c1eb7
    # See also Makefile-libostree.am
    "INTROSPECTION_SCANNER_ENV="
  ];

  preConfigure = ''
    env NOCONFIGURE=1 ./autogen.sh
  '';

  meta = with lib; {
    description = "Git for operating system binaries";
    homepage = "https://ostreedev.github.io/ostree/";
    license = licenses.lgpl2Plus;
    platforms = platforms.all;
    maintainers = [ ];
  };
})
