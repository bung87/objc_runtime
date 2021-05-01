# objc_runtime  

objective-c runtime bindings provide macro `objcr` allow you write message sending style code  

``` nim

var NSApp {.importc.}: ID

proc main() =
  func createMenuItem(title: ID | NSString, action: string, key: string): ID =
    result = objc_msgSend(getClass("NSMenuItem").ID, registerName("alloc"))
    objc_msgSend(result, registerName("initWithTitle:action:keyEquivalent:"),
                title, if action != "": registerName(action) else: nil, get_nsstring(key))
    objc_msgSend(result, registerName("autorelease"))

  objcr:
    [NSApplication sharedApplication]

    if NSApp.isNil:
      echo "Failed to initialized NSApplication...  terminating..."
      return
    [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular]

    var menuBar = [[NSMenu alloc]init]
    var appMenuItem = [[NSMenuItem alloc]init]
    var appMenu = [[NSMenu alloc]init]

    var quitTitle = @"Quit"
    var quitMenuItem = createMenuItem(quitTitle, "terminate:", "q")
    [appMenu addItem: quitMenuItem]
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