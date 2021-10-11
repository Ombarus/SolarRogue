pushd %~dp0

copy SolarRogue%1.apk D:\Dev\Projects\GooglePlay
cd D:\Dev\Projects\GooglePlay
"C:\Program Files\Java\jdk-17\bin\jarsigner.exe" -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore android.keystore SolarRogue%1.apk android-app-key
"C:\Users\match\AppData\Local\Android\Sdk\build-tools\31.0.0\zipalign.exe" -v 4 SolarRogue%1.apk SolarRogue%1-signed.apk
move SolarRogue%1-signed.apk "%~dp0\SolarRogue%1-signed.apk"

del SolarRogue%1.apk

popd