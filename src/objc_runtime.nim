import macros, regex, sequtils, strutils
import darwin / objc / runtime

export runtime

proc replaceBracket(node: NimNode): NimNode

template isIDCheck(a: untyped): untyped = (when declared(a): a is ID else: false)

proc transformNode(node: NimNode): NimNode =
  let isIDCheck = bindSym("isIDCheck", brClosed)
  if node.kind == nnkIdent:
    var m: RegexMatch
    if node.strVal.match(re"^[A-Z]+\w+", m):
      let declaredCall = nnkCall.newTree(isIDCheck, node)
      return nnkStmtListExpr.newTree(
        nnkWhenStmt.newTree(
          nnkElifExpr.newTree(
            declaredCall,
            node
        ),
        nnkElseExpr.newTree(nnkCall.newTree(ident"getClass", node.toStrLit))
      )
      )
    else:
      return node
  elif node.kind == nnkStrLit:
    return nnkPrefix.newTree(ident"@", node)
  elif node.kind == nnkBracket:
    return replaceBracket(node)
  else:
    return node

proc extractSelf(self: NimNode, args: var seq[NimNode]): NimNode =
  case self.kind
  of nnkExprColonExpr:
    case self[0].kind
    of nnkCommand:
      let sel = self[0][1]
      let v = self[1]
      let ce = nnkExprColonExpr.newTree(sel, v)
      args.insert(ce)
      return self[0][0]
    else:
      discard
  of nnkCommand:
    if self[1].kind == nnkIdent:
      args.insert(nnkCall.newTree(ident"registerName", self[1].toStrLit))
    else:
      args.insert(self[1])
    return self[0]
  else:
    discard
  return self

proc replaceBracket(node: NimNode): NimNode =
  if node.kind != nnkBracket:
    return node
  var newnode = newCall(bindSym"objc_msgSend")
  var child = toSeq(node.children)
  var self = child[0]
  var args = child[1 .. ^1]
  self = extractSelf(self, args)
  if self.kind == nnkIdent and self.strVal == "super":
    newnode = newCall(bindSym"objc_msgSendSuper")
  newnode.add transformNode(self)
  var positionalArgs = args.filterIt(it.kind != nnkExprColonExpr)
  for pa in positionalArgs:
    newnode.add transformNode(pa)
  var namedArgs = args.filterIt(it.kind == nnkExprColonExpr)
  if namedArgs.len > 0:
    var names = namedArgs.mapIt(if it[0].kind != nnkAccQuoted : it[0].strVal() else: it[0][0].strVal())
    let name = names.join(":") & ":"
    newnode.add nnkCall.newTree(ident"registerName", newStrLitNode(name))
    for a in namedArgs:
      newnode.add transformNode(a[1])
  return newnode

proc replaceOne(one:NimNode):NimNode = 
  case one.kind
    of nnkBracket:
      result = replaceBracket(one)
    else:
      var b = copyNimNode(one)
      copyChildrenTo(one, b)
      var i = 0
      for a in b:
        b[i] = replaceOne(a)
        inc i
      result = b

macro objcr*(arg: untyped): untyped =
  if arg.kind == nnkStmtList:
    result = newStmtList()
    for one in arg:
      result.add replaceOne(one)
  elif arg.kind in {nnkProcDef, nnkLambda, nnkMethodDef}:
    result = arg
    var code = arg.body
    result.body = nnkStmtList.newTree()
    result.addPragma ident"cdecl"
    result.addPragma ident"gcsafe"
    var self = arg.params[1][0]
    var superVal = nnkObjConstr.newTree(
    ident("ObjcSuper"),
      nnkExprColonExpr.newTree(
        ident("receiver"),
        self
      ),
      nnkExprColonExpr.newTree(
        ident("superClass"),
        nnkCall.newTree(
          nnkDotExpr.newTree(
            nnkCall.newTree(
              nnkDotExpr.newTree(
                self,
                ident("getClass")
              )
            ),
            ident("getSuperclass")
          )
        )
      )
    )
    result.body.add nnkVarSection.newTree(nnkIdentDefs.newTree(ident"super",newEmptyNode(),superVal))
    for one in code:
      result.body.add replaceOne(one)
  else:
    result = replaceOne(arg)
