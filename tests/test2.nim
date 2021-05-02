import objc_runtime
import darwin / [ app_kit, foundation]

when isMainModule:
  let BaseClass = allocateClassPair(getClass("NSObject"), "BaseClass", 0)
  discard addIvar(BaseClass, "num", sizeof(int), 1 shl sizeof(int), "i")
  let NumIvar: Ivar = getIvar(BaseClass, "num")
  proc setNum(self: ID; cmd: SEL;) {.cdecl.} =
    objcr:
      var i = [NSNumber numberWithInt:2]
      setIvar(self, NumIvar, i)
  discard BaseClass.addMethod($$"setNum", cast[IMP](setNum), "v@")
  BaseClass.registerClassPair()

  let ChildClass = allocateClassPair(getClass("BaseClass"), "ChildClass", 0)
  discard addIvar(ChildClass, "num", sizeof(int), 1 shl sizeof(int), "i")

  proc setNum2(self: ID; cmd: SEL;) {.cdecl.} =
    objcr:
      var super = ObjcSuper(receiver: self, superClass: self.getClass().getSuperclass())
      discard objc_msgSendSuper(super, $$"setNum")
  discard ChildClass.replaceMethod($$"setNum", cast[IMP](setNum2), "v@")
  ChildClass.registerClassPair()
  
  objcr:
    var base = [[BaseClass alloc] init]
    [base setNum]
    var v = base.getIvar(NumIvar)
    var n = cast[NSNumber](v)
    doAssert n.intValue() == 2

    var child = [[ChildClass alloc] init]
    [child setNum]
    var v2 = child.getIvar(NumIvar)
    var n2 = cast[NSNumber](v2)
    doAssert n2.intValue() == 2