# objc_runtime  ![Build Status](https://github.com/bung87/objc_runtime/workflows/build/badge.svg)  

objective-c runtime bindings provide macro `objcr` allow you write message sending style code  

NOTICE: This library works fine on x86, If you are using this library on an ARM64 architecture (such as Apple Silicon), please be aware that `objc_msgSend` requires properly typed signatures. On x86, this function works without strict type conversion, but on ARM64, failing to cast the function correctly will lead to runtime crashes.

``` nim

proc main() =

  objcr:
    [NSApplication sharedApplication]

    if NSApp.isNil:
      echo "Failed to initialized NSApplication...  terminating..."
      return
    [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular]

    var menuBar = [[NSMenu alloc]init]
    var appMenuItem = [[NSMenuItem alloc]init]
    var appMenu = [[NSMenu alloc]init]

    [appMenu addItemWithTitle: @"Quit", action: "terminate:", keyEquivalent: @"q"]
    [appMenuItem setSubmenu: appMenu]
    
    [menuBar addItem: appMenuItem]
    [NSApp setMainMenu: menuBar]

    var mainWindow = [NSWindow alloc]
    var rect = NSMakeRect(0, 0, 200, 200)
    [mainWindow initWithContentRect: rect, styleMask:  NSWindowStyleMaskTitled or NSWindowStyleMaskClosable or NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable, backing: NSBackingStoreBuffered,
        `defer`: false]

    var pos = NSMakePoint(20,20)
    [mainWindow cascadeTopLeftFromPoint: pos]
    [mainWindow setTitle: "Hello"]
    [mainWindow makeKeyAndOrderFront: NSApp]
    [NSApp activateIgnoringOtherApps: true]
    [NSApp run]


when isMainModule:
  main()
```