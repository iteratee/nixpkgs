{ lib, buildPythonPackage, fetchPypi, python, coverage, lsof, glibcLocales, coreutils }:

buildPythonPackage rec {
  pname = "sh";
  version = "1.14.3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-5ARbbHMtnOddVxx59awiNO3Zrk9fqdWbCXBQgr3KGMc=";
  };

  patches = [
    # Disable tests that fail on Darwin sandbox
    ./disable-broken-tests-darwin.patch
  ];

  postPatch = ''
    sed -i 's#/usr/bin/env python#${python.interpreter}#' test.py
    sed -i 's#/bin/sleep#${coreutils.outPath}/bin/sleep#' test.py
  '';

  checkInputs = [ coverage lsof glibcLocales ];

  # A test needs the HOME directory to be different from $TMPDIR.
  preCheck = ''
    export LC_ALL="en_US.UTF-8"
    HOME=$(mktemp -d)
  '';

  meta = with lib; {
    description = "Python subprocess interface";
    homepage = "https://pypi.python.org/pypi/sh/";
    license = licenses.mit;
    maintainers = with maintainers; [ siriobalmelli ];
  };
}
