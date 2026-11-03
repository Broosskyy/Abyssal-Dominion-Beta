#!/usr/bin/env python3
"""Add our reviewed native updater to the generated official Godot template."""
from pathlib import Path
import shutil,sys

project=Path(sys.argv[1]).resolve()
source=Path(__file__).resolve().parent
app=project/'src/main'
manifest=app/'AndroidManifest.xml'
assert manifest.is_file()
text=manifest.read_text()
assert 'org.godotengine.plugin.v2.AbyssalApkInstaller' not in text
java=app/'java/com/abyssal/updater';java.mkdir(parents=True,exist_ok=True)
for name in ['AbyssalApkInstaller.java','AbyssalFileProvider.java']:
    shutil.copyfile(source/name,java/name)
xml=app/'res/xml';xml.mkdir(parents=True,exist_ok=True)
shutil.copyfile(source/'abyssal_apk_paths.xml',xml/'abyssal_apk_paths.xml')
text=text.replace('<application','<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />\n    <application',1)
provider='''<meta-data android:name="org.godotengine.plugin.v2.AbyssalApkInstaller" android:value="com.abyssal.updater.AbyssalApkInstaller" />
        <provider android:name="com.abyssal.updater.AbyssalFileProvider" android:authorities="${applicationId}.abyssalupdater.files" android:exported="false" android:grantUriPermissions="true">
          <meta-data android:name="android.support.FILE_PROVIDER_PATHS" android:resource="@xml/abyssal_apk_paths" />
        </provider>'''
text=text.replace('</application>',provider+'\n    </application>',1)
manifest.write_text(text)
gradle=project/'build.gradle';text=gradle.read_text()
assert 'dependencies {' in text
gradle.write_text(text.replace('dependencies {',"dependencies {\n    implementation 'androidx.core:core:1.15.0'",1))
print('ABYSSAL_NATIVE_UPDATER_ADDED')
