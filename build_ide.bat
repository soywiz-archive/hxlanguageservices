@ECHO OFF
CALL runtests.bat
PUSHD sampleide
CALL build.bat -debug %*
POPD