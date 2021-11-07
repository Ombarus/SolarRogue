pushd %~dp0

copy SolarRogue%1.aab D:\Dev\Projects\GooglePlay
cd D:\Dev\Projects\GooglePlay
"C:\Program Files\Java\jdk-17\bin\jarsigner.exe" -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore android.keystore SolarRogue%1.aab android-app-key
"C:\Users\match\AppData\Local\Android\Sdk\build-tools\31.0.0\zipalign.exe" -v 4 SolarRogue%1.aab SolarRogue%1-signed.aab
move SolarRogue%1-signed.aab "%~dp0\SolarRogue%1-signed.aab"

del SolarRogue%1.aab

popd