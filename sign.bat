pushd %~dp0

copy SolarRogue%1.apk D:\Dev\Projects\GooglePlay
cd D:\Dev\Projects\GooglePlay
"C:\Users\match\AppData\Local\Android\Sdk\build-tools\31.0.0\zipalign.exe" -v 4 SolarRogue%1.apk SolarRogue%1-aligned.apk
call "C:\Users\match\AppData\Local\Android\Sdk\build-tools\34.0.0\apksigner.bat" sign --ks android.keystore --ks-key-alias android-app-key --out SolarRogue%1-signed.apk SolarRogue%1-aligned.apk
move SolarRogue%1-signed.apk "%~dp0\SolarRogue%1-signed.apk"

del SolarRogue%1.apk
del SolarRogue%1-aligned.apk

popd
