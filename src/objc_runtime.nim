import macros, regex, sequtils, strutils
import darwin / objc / runtime

export runtime

type TransKind = enum
  kSelf,
  kArg,

proc replaceBracket(node: NimNode): NimNode

# template isIDCheck(a: untyped): untyped = (when declared(a): a is ID else: false)
template getClassByIdent(a: untyped, s: string): untyped = (when declared(a) and a is ID: a else: getClass(s))

proc transformNode(node: NimNode, kind: TransKind): NimNode =
  let getClassByIdent = bindSym("getClassByIdent", brClosed)
  if node.kind == nnkIdent:
    var m: RegexMatch
    if node.strVal.match(re"^[A-Z]+\w+", m):
      if kind == kSelf:
        result = nnkCall.newTree(getClassByIdent, node, node.toStrLit)
      else:
        return node
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
      return
  of nnkCommand:
    if self[1].kind == nnkIdent:
      args.insert(nnkCall.newTree(ident"registerName", self[1].toStrLit))
    else:
      args.insert(self[1])
    return self[0]
  else:
    return
  return self

proc replaceBracket(node: NimNode): NimNode =
  if node.kind != nnkBracket:
    return node
  var newnode = newCall(bindSym"objc_msgSend")
  var child = toSeq(node.children)
  var self = child[0]
  var args = child[1 .. ^1]
  self = extractSelf(self, args)
  if self == nil:
    return node
  if self.kind == nnkIdent and self.strVal == "super":
    newnode = newCall(bindSym"objc_msgSendSuper")
  newnode.add transformNode(self, kSelf)
  var positionalArgs = args.filterIt(it.kind != nnkExprColonExpr)
  for pa in positionalArgs:
    newnode.add transformNode(pa, kArg)
  var namedArgs = args.filterIt(it.kind == nnkExprColonExpr)
  if namedArgs.len > 0:
    var names = namedArgs.mapIt(if it[0].kind != nnkAccQuoted : it[0].strVal() else: it[0][0].strVal())
    let name = names.join(":") & ":"
    newnode.add nnkCall.newTree(ident"registerName", newStrLitNode(name))
    for a in namedArgs:
      newnode.add transformNode(a[1], kArg)
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
    let argLen = arg.params.len
    if argLen >= 2: 
      var self = arg.params[1][0]
      if $self == "self":
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
