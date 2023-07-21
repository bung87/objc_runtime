# Package

version       = "0.1.6"
author        = "bung87"
description   = "objective-c runtime bindings"
license       = "LGPL-2.1-or-later"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.4"
requires "darwin"
requires "regex"

task test, "basic":
  exec "nimble c tests/test1.nim"
  exec "nimble c -r tests/test2.nim"
