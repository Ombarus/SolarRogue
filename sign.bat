pushd %~dp0

copy SolarRogue%1.apk F:\Dev\Projects\GooglePlay
cd F:\Dev\Projects\GooglePlay
"C:\Program Files\Java\jdk1.8.0_181\bin\jarsigner.exe" -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore android.keystore SolarRogue%1.apk android-app-key
"C:\Program Files (x86)\Android\android-sdk\build-tools\23.0.1\zipalign.exe" -v 4 SolarRogue%1.apk SolarRogue%1-signed.apk
move SolarRogue%1-signed.apk "%~dp0\SolarRogue%1-signed.apk"

del SolarRogue%1.apk

popd