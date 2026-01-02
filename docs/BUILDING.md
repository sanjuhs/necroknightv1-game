# Building Your Love2D Game for All Platforms

This guide explains how to package your Love2D game as a standalone application for Windows, macOS, iOS, and Android.

## Table of Contents

1. [How Love2D Packaging Works](#how-love2d-packaging-works)
2. [Step 1: Create a .love File](#step-1-create-a-love-file)
3. [Building for Windows](#building-for-windows)
4. [Building for macOS](#building-for-macos)
5. [Building for iOS](#building-for-ios)
6. [Building for Android](#building-for-android)
7. [Automated Build Tools](#automated-build-tools)
8. [Distribution Tips](#distribution-tips)

---

## How Love2D Packaging Works

Love2D games are distributed by combining your game files with the Love2D runtime:

```
Your Game Files (.lua, images, sounds)
            ↓
      Package as .love file (just a .zip renamed)
            ↓
    Fuse with Love2D runtime for each platform
            ↓
   Standalone executables for each OS
```

**The .love file** is the universal format - it's just a ZIP file containing your game that can run on any platform with Love2D installed.

**Fusing** means combining your .love file with the Love2D executable to create a standalone app that doesn't require Love2D to be installed.

---

## Step 1: Create a .love File

This is the foundation for all platform builds.

### macOS / Linux

```bash
cd /Users/sanjayprasads/Desktop/Coding/lua/first-proj

# Create .love file (ZIP your game files)
zip -9 -r autobattler.love . -x "*.git*" -x "docs/*" -x "*.love" -x ".DS_Store"
```

### Windows (PowerShell)

```powershell
Compress-Archive -Path main.lua, conf.lua -DestinationPath autobattler.zip
Rename-Item autobattler.zip autobattler.love
```

### Test Your .love File

```bash
love autobattler.love
```

If it runs, you're ready to build for platforms!

---

## Building for Windows

### Requirements

- Download Love2D for Windows (64-bit): https://love2d.org/
- Extract the zip (you'll get love.exe and supporting DLLs)

### Steps

1. **Download Love2D Windows zip** (not the installer):

   ```
   https://github.com/love2d/love/releases
   → love-11.4-win64.zip
   ```

2. **Fuse your game with love.exe**:

   ```cmd
   # In Command Prompt (Windows)
   copy /b love.exe+autobattler.love autobattler.exe
   ```

3. **Create distribution folder**:

   ```
   autobattler-windows/
   ├── autobattler.exe      (your fused executable)
   ├── love.dll
   ├── lua51.dll
   ├── mpg123.dll
   ├── msvcp120.dll
   ├── msvcr120.dll
   ├── OpenAL32.dll
   ├── SDL2.dll
   └── license.txt
   ```

4. **Distribute**: Zip this folder and share it!

### Running on Windows

Users just double-click `autobattler.exe` - no installation needed!

---

## Building for macOS

### Requirements

- Love2D.app from https://love2d.org/
- macOS for building

### Steps

1. **Copy Love2D.app**:

   ```bash
   cp -R /Applications/love.app ./Autobattler.app
   ```

2. **Place your .love file inside**:

   ```bash
   cp autobattler.love ./Autobattler.app/Contents/Resources/
   ```

3. **Edit Info.plist** (optional but recommended):

   ```bash
   nano ./Autobattler.app/Contents/Info.plist
   ```

   Change these values:

   ```xml
   <key>CFBundleIdentifier</key>
   <string>com.yourname.autobattler</string>

   <key>CFBundleName</key>
   <string>Autobattler</string>
   ```

4. **Remove the Love2D file associations** (optional):
   Delete the `CFBundleDocumentTypes` section from Info.plist

### Running on macOS

Users double-click `Autobattler.app` to play!

### Code Signing (for distribution)

```bash
codesign --force --deep --sign - Autobattler.app
```

For App Store distribution, you'll need an Apple Developer account ($99/year).

---

## Building for iOS

### Requirements

- Mac with Xcode installed
- Apple Developer account ($99/year for App Store, free for personal devices)
- Love2D iOS source: https://github.com/love2d/love-ios

### Steps

1. **Clone the Love2D iOS project**:

   ```bash
   git clone https://github.com/love2d/love-ios.git
   cd love-ios
   ```

2. **Add your game files**:

   - Open the Xcode project
   - Drag your game files (main.lua, conf.lua, assets) into the project
   - Or place them in the `game` folder

3. **Configure your project**:

   - Set Bundle Identifier: `com.yourname.autobattler`
   - Set Display Name: `Autobattler`
   - Add app icons (required for App Store)

4. **Update conf.lua for mobile**:

   ```lua
   function love.conf(t)
       t.title = "Autobattler"
       t.identity = "autobattler"
       t.window.width = 0  -- Use device resolution
       t.window.height = 0
       t.window.fullscreen = true
       t.modules.joystick = false  -- Not needed on mobile
   end
   ```

5. **Build and run**:
   - Connect your iPhone/iPad
   - Select your device in Xcode
   - Click Run (⌘R)

### Touch Controls

You'll need to add touch input! See the [Mobile Input](#mobile-input-code) section below.

---

## Building for Android

### Requirements

- Android Studio: https://developer.android.com/studio
- Java JDK 11+
- Love2D Android project: https://github.com/love2d/love-android

### Steps

1. **Clone the Love2D Android project**:

   ```bash
   git clone https://github.com/love2d/love-android.git
   cd love-android
   ```

2. **Open in Android Studio**:

   - File → Open → select the love-android folder
   - Let Gradle sync complete

3. **Add your game**:

   - Create folder: `app/src/main/assets/game/`
   - Copy your game files there:
     ```bash
     cp main.lua conf.lua app/src/main/assets/game/
     ```

4. **Configure the app**:
   Edit `app/build.gradle`:

   ```gradle
   android {
       defaultConfig {
           applicationId "com.yourname.autobattler"
           versionCode 1
           versionName "1.0"
       }
   }
   ```

5. **Add app icon**:

   - Right-click `app/src/main/res` → New → Image Asset
   - Follow the wizard to add your icon

6. **Build APK**:

   - Build → Build Bundle(s) / APK(s) → Build APK(s)
   - Find it in: `app/build/outputs/apk/debug/app-debug.apk`

7. **Build for Release** (for Google Play):
   - Build → Generate Signed Bundle / APK
   - Create a keystore (keep it safe!)
   - Build as Android App Bundle (.aab)

### Installing on Android

**Debug APK**:

```bash
adb install app-debug.apk
```

**Or enable "Install from Unknown Sources"** in Android settings and open the APK file.

---

## Mobile Input Code

Add this to your `main.lua` to support touch controls:

```lua
-- Virtual joystick for mobile
local touch = {
    active = false,
    startX = 0,
    startY = 0,
    currentX = 0,
    currentY = 0
}

function love.touchpressed(id, x, y)
    touch.active = true
    touch.startX = x
    touch.startY = y
    touch.currentX = x
    touch.currentY = y
end

function love.touchmoved(id, x, y)
    touch.currentX = x
    touch.currentY = y
end

function love.touchreleased(id, x, y)
    touch.active = false
end

-- In love.update(dt), add:
function getMobileInput()
    if not touch.active then
        return 0, 0
    end

    local dx = touch.currentX - touch.startX
    local dy = touch.currentY - touch.startY
    local distance = math.sqrt(dx*dx + dy*dy)

    if distance < 10 then
        return 0, 0
    end

    -- Normalize
    return dx / distance, dy / distance
end
```

---

## Automated Build Tools

### makelove (Recommended!)

A Python tool that automates building for all platforms:

```bash
# Install
pip install makelove

# Create config file
makelove --init

# Build for all platforms
makelove
```

**makelove.toml** example:

```toml
name = "Autobattler"
default_targets = ["win64", "macos", "appimage"]

[build]
source = "."
love_version = "11.4"

[win64]
icon = "icon.ico"

[macos]
icon = "icon.icns"
```

### love-release

Another option using Lua:

```bash
# Install via LuaRocks
luarocks install love-release

# Build
love-release -W -M -L  # Windows, Mac, Linux
```

---

## Distribution Tips

### File Sizes

- Windows build: ~30-40 MB
- macOS build: ~40-50 MB
- Android APK: ~30-40 MB
- iOS: ~40-50 MB

### Where to Distribute

| Platform | Distribution Method                             |
| -------- | ----------------------------------------------- |
| Windows  | itch.io, Steam, direct download                 |
| macOS    | itch.io, Steam, Mac App Store                   |
| iOS      | App Store (requires $99/year Apple Developer)   |
| Android  | Google Play ($25 one-time), itch.io, APK direct |

### itch.io (Easiest!)

1. Create account at https://itch.io
2. Create new project
3. Upload your builds (zip files)
4. Set pricing (can be free or paid)
5. Publish!

### Steam

1. Sign up for Steamworks ($100 one-time)
2. Create app
3. Upload builds via Steam SDK
4. Go through review process

---

## Quick Reference

```bash
# Create .love file
zip -9 -r autobattler.love . -x "*.git*" -x "docs/*"

# Test it
love autobattler.love

# Windows (in Windows)
copy /b love.exe+autobattler.love autobattler.exe

# macOS
cp -R /Applications/love.app Autobattler.app
cp autobattler.love Autobattler.app/Contents/Resources/

# Use makelove for automation
pip install makelove
makelove --init
makelove
```

---

## Troubleshooting

### "Game doesn't start"

- Make sure `main.lua` is at the root of your .love file, not in a subfolder
- Check: `unzip -l autobattler.love` should show `main.lua` at top level

### "Black screen on mobile"

- Set window size to 0,0 in conf.lua for mobile
- Make sure touch controls are implemented

### "App crashes on Android"

- Check logcat: `adb logcat | grep -i love`
- Ensure all file paths use forward slashes

### "Can't install on iOS"

- Need Apple Developer account for distribution
- For personal testing, use your Apple ID in Xcode

---

## Need Help?

- Love2D Forums: https://love2d.org/forums/
- Love2D Wiki: https://love2d.org/wiki/
- Love2D Discord: https://discord.gg/rhUets9
- r/love2d: https://reddit.com/r/love2d
