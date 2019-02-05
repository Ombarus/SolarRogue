"C:\Program Files\Java\jdk1.8.0_181\bin\jarsigner.exe" -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ..\..\GooglePlay\android.keystore %1 android-app-key
adb install %1
