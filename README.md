# Xconfig

If you're like me, when working with .xcconfig files or building your shell script to include in a "Run Script" phase, you'll keep running to the Terminal to run this:

```xcodebuild -project <Project>.xcodeproj -target <Target> -showBuildSettings```

But this means, opening the terminal, cd'ing to your project's folder, remembering and typing all of that, and then piping that to a grep to figure out which build setting you want.

Xconfig is simple Mac app to display build settings for the currently open Xcode projects. 

