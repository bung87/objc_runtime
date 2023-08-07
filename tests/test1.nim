import objc_runtime
import darwin / [ app_kit, foundation]

proc main() {.objcr.} =

  [NSApplication sharedApplication]
  if NSApp.isNil:
    echo "Failed to initialized NSApplication...  terminating..."
    return

  [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular]

  var menuBar = [[NSMenu alloc]init]
  var appMenuItem = [[NSMenuItem alloc]init]
  var appMenu = [[NSMenu alloc]init]
  [appMenu addItemWithTitle: @"Quit", action: $$"terminate:", keyEquivalent: @"q"]
  [appMenuItem setSubmenu: appMenu]

  [menuBar addItem: appMenuItem]
  [NSApp setMainMenu: menuBar]
  var mainWindow = [NSWindow alloc]
  var rect = NSMakeRect(0, 0, 200, 200)
  [mainWindow initWithContentRect: rect, styleMask:  NSWindowStyleMaskTitled or NSWindowStyleMaskClosable or NSWindowStyleMaskMiniaturizable or NSWindowStyleMaskResizable, backing: NSBackingStoreBuffered,
      `defer`: false]

  var pos = NSMakePoint(20,20)
  [mainWindow cascadeTopLeftFromPoint: pos]
  [mainWindow setTitle: @"Hello"]
  [mainWindow makeKeyAndOrderFront: NSApp]
  [NSApp activateIgnoringOtherApps: true]
  [NSApp run]
  [NSApp stop]


when isMainModule:
  main()
