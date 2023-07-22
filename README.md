# objc_runtime  ![Build Status](https://github.com/bung87/objc_runtime/workflows/build/badge.svg)  

objective-c runtime bindings provide macro `objcr` allow you write message sending style code  

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