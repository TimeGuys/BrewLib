###
P R O C E S S I N G . J S - 1.4.1
a port of the Processing visualization language

Processing.js is licensed under the MIT License, see LICENSE.
For a list of copyright holders, please refer to AUTHORS.

http://processingjs.org
###
((window, document, Math, undef) ->
  setupTypedArray = (name, fallback) ->
    return window[name]  if name of window
    return window[fallback]  if typeof window[fallback] is "function"
    (obj) ->
      return obj  if obj instanceof Array
      if typeof obj is "number"
        arr = []
        arr.length = obj
        arr
  virtHashCode = (obj) ->
    if typeof obj is "string"
      hash = 0
      i = 0

      while i < obj.length
        hash = hash * 31 + obj.charCodeAt(i) & 4294967295
        ++i
      return hash
    return obj & 4294967295  if typeof obj isnt "object"
    return obj.hashCode()  if obj.hashCode instanceof Function
    obj.$id = Math.floor(Math.random() * 65536) - 32768 << 16 | Math.floor(Math.random() * 65536)  if obj.$id is undef
    obj.$id
  virtEquals = (obj, other) ->
    return obj is null and other is null  if obj is null or other is null
    return obj is other  if typeof obj is "string"
    return obj is other  if typeof obj isnt "object"
    return obj.equals(other)  if obj.equals instanceof Function
    obj is other
  DefaultScope = ->
  overloadBaseClassFunction = (object, name, basefn) ->
    if not object.hasOwnProperty(name) or typeof object[name] isnt "function"
      object[name] = basefn
      return
    fn = object[name]
    if "$overloads" of fn
      fn.$defaultOverload = basefn
      return
    return  if ("$overloads" not of basefn) and fn.length is basefn.length
    overloads = undefined
    defaultOverload = undefined
    if "$overloads" of basefn
      overloads = basefn.$overloads.slice(0)
      overloads[fn.length] = fn
      defaultOverload = basefn.$defaultOverload
    else
      overloads = []
      overloads[basefn.length] = basefn
      overloads[fn.length] = fn
      defaultOverload = fn
    hubfn = ->
      fn = hubfn.$overloads[arguments.length] or ((if "$methodArgsIndex" of hubfn and arguments.length > hubfn.$methodArgsIndex then hubfn.$overloads[hubfn.$methodArgsIndex] else null)) or hubfn.$defaultOverload
      fn.apply this, arguments

    hubfn.$overloads = overloads
    hubfn.$methodArgsIndex = basefn.$methodArgsIndex  if "$methodArgsIndex" of basefn
    hubfn.$defaultOverload = defaultOverload
    hubfn.name = name
    object[name] = hubfn
  extendClass = (subClass, baseClass) ->
    extendGetterSetter = (propertyName) ->
      defaultScope.defineProperty subClass, propertyName,
        get: ->
          baseClass[propertyName]

        set: (v) ->
          baseClass[propertyName] = v

        enumerable: true

    properties = []
    for propertyName of baseClass
      if typeof baseClass[propertyName] is "function"
        overloadBaseClassFunction subClass, propertyName, baseClass[propertyName]
      else properties.push propertyName  if propertyName.charAt(0) isnt "$" and (propertyName not of subClass)
    extendGetterSetter properties.shift()  while properties.length > 0
    subClass.$super = baseClass
  isNumericalJavaType = (type) ->
    return false  if typeof type isnt "string"
    [ "byte", "int", "char", "color", "float", "long", "double" ].indexOf(type) isnt -1
  computeFontMetrics = (pfont) ->
    emQuad = 250
    correctionFactor = pfont.size / emQuad
    canvas = document.createElement("canvas")
    canvas.width = 2 * emQuad
    canvas.height = 2 * emQuad
    canvas.style.opacity = 0
    cfmFont = pfont.getCSSDefinition(emQuad + "px", "normal")
    ctx = canvas.getContext("2d")
    ctx.font = cfmFont
    protrusions = "dbflkhyjqpg"
    canvas.width = ctx.measureText(protrusions).width
    ctx.font = cfmFont
    leadDiv = document.createElement("div")
    leadDiv.style.position = "absolute"
    leadDiv.style.opacity = 0
    leadDiv.style.fontFamily = "\"" + pfont.name + "\""
    leadDiv.style.fontSize = emQuad + "px"
    leadDiv.innerHTML = protrusions + "<br/>" + protrusions
    document.body.appendChild leadDiv
    w = canvas.width
    h = canvas.height
    baseline = h / 2
    ctx.fillStyle = "white"
    ctx.fillRect 0, 0, w, h
    ctx.fillStyle = "black"
    ctx.fillText protrusions, 0, baseline
    pixelData = ctx.getImageData(0, 0, w, h).data
    i = 0
    w4 = w * 4
    len = pixelData.length
    nop()  while ++i < len and pixelData[i] is 255
    ascent = Math.round(i / w4)
    i = len - 1
    nop()  while --i > 0 and pixelData[i] is 255
    descent = Math.round(i / w4)
    pfont.ascent = correctionFactor * (baseline - ascent)
    pfont.descent = correctionFactor * (descent - baseline)
    if document.defaultView.getComputedStyle
      leadDivHeight = document.defaultView.getComputedStyle(leadDiv, null).getPropertyValue("height")
      leadDivHeight = correctionFactor * leadDivHeight.replace("px", "")
      pfont.leading = Math.round(leadDivHeight / 2)  if leadDivHeight >= pfont.size * 2
    document.body.removeChild leadDiv
    ctx  if pfont.caching
  PFont = (name, size) ->
    name = ""  if name is undef
    @name = name
    size = 0  if size is undef
    @size = size
    @glyph = false
    @ascent = 0
    @descent = 0
    @leading = 1.2 * size
    illegalIndicator = name.indexOf(" Italic Bold")
    name = name.substring(0, illegalIndicator)  if illegalIndicator isnt -1
    @style = "normal"
    italicsIndicator = name.indexOf(" Italic")
    if italicsIndicator isnt -1
      name = name.substring(0, italicsIndicator)
      @style = "italic"
    @weight = "normal"
    boldIndicator = name.indexOf(" Bold")
    if boldIndicator isnt -1
      name = name.substring(0, boldIndicator)
      @weight = "bold"
    @family = "sans-serif"
    if name isnt undef
      switch name
        when "sans-serif", "serif"
      , "monospace"
      , "fantasy"
      , "cursive"
          @family = name
        else
          @family = "\"" + name + "\", sans-serif"
    @context2d = computeFontMetrics(this)
    @css = @getCSSDefinition()
    @context2d.font = @css  if @context2d
  getGlobalMembers = ->
    names = [ "abs", "acos", "alpha", "ambient", "ambientLight", "append", "applyMatrix", "arc", "arrayCopy", "asin", "atan", "atan2", "background", "beginCamera", "beginDraw", "beginShape", "bezier", "bezierDetail", "bezierPoint", "bezierTangent", "bezierVertex", "binary", "blend", "blendColor", "blit_resize", "blue", "box", "breakShape", "brightness", "camera", "ceil", "Character", "color", "colorMode", "concat", "constrain", "copy", "cos", "createFont", "createGraphics", "createImage", "cursor", "curve", "curveDetail", "curvePoint", "curveTangent", "curveTightness", "curveVertex", "day", "degrees", "directionalLight", "disableContextMenu", "dist", "draw", "ellipse", "ellipseMode", "emissive", "enableContextMenu", "endCamera", "endDraw", "endShape", "exit", "exp", "expand", "externals", "fill", "filter", "floor", "focused", "frameCount", "frameRate", "frustum", "get", "glyphLook", "glyphTable", "green", "height", "hex", "hint", "hour", "hue", "image", "imageMode", "intersect", "join", "key", "keyCode", "keyPressed", "keyReleased", "keyTyped", "lerp", "lerpColor", "lightFalloff", "lights", "lightSpecular", "line", "link", "loadBytes", "loadFont", "loadGlyphs", "loadImage", "loadPixels", "loadShape", "loadXML", "loadStrings", "log", "loop", "mag", "map", "match", "matchAll", "max", "millis", "min", "minute", "mix", "modelX", "modelY", "modelZ", "modes", "month", "mouseButton", "mouseClicked", "mouseDragged", "mouseMoved", "mouseOut", "mouseOver", "mousePressed", "mouseReleased", "mouseScroll", "mouseScrolled", "mouseX", "mouseY", "name", "nf", "nfc", "nfp", "nfs", "noCursor", "noFill", "noise", "noiseDetail", "noiseSeed", "noLights", "noLoop", "norm", "normal", "noSmooth", "noStroke", "noTint", "ortho", "param", "parseBoolean", "parseByte", "parseChar", "parseFloat", "parseInt", "peg", "perspective", "PImage", "pixels", "PMatrix2D", "PMatrix3D", "PMatrixStack", "pmouseX", "pmouseY", "point", "pointLight", "popMatrix", "popStyle", "pow", "print", "printCamera", "println", "printMatrix", "printProjection", "PShape", "PShapeSVG", "pushMatrix", "pushStyle", "quad", "radians", "random", "Random", "randomSeed", "rect", "rectMode", "red", "redraw", "requestImage", "resetMatrix", "reverse", "rotate", "rotateX", "rotateY", "rotateZ", "round", "saturation", "save", "saveFrame", "saveStrings", "scale", "screenX", "screenY", "screenZ", "second", "set", "setup", "shape", "shapeMode", "shared", "shearX", "shearY", "shininess", "shorten", "sin", "size", "smooth", "sort", "specular", "sphere", "sphereDetail", "splice", "split", "splitTokens", "spotLight", "sq", "sqrt", "status", "str", "stroke", "strokeCap", "strokeJoin", "strokeWeight", "subset", "tan", "text", "textAlign", "textAscent", "textDescent", "textFont", "textLeading", "textMode", "textSize", "texture", "textureMode", "textWidth", "tint", "toImageData", "touchCancel", "touchEnd", "touchMove", "touchStart", "translate", "transform", "triangle", "trim", "unbinary", "unhex", "updatePixels", "use3DContext", "vertex", "width", "XMLElement", "XML", "year", "__contains", "__equals", "__equalsIgnoreCase", "__frameRate", "__hashCode", "__int_cast", "__instanceof", "__keyPressed", "__mousePressed", "__printStackTrace", "__replace", "__replaceAll", "__replaceFirst", "__toCharArray", "__split", "__codePointAt", "__startsWith", "__endsWith", "__matches" ]
    members = {}
    i = undefined
    l = undefined
    i = 0
    l = names.length

    while i < l
      members[names[i]] = null
      ++i
    for lib of Processing.lib
      if Processing.lib.hasOwnProperty(lib)
        if Processing.lib[lib].exports
          exportedNames = Processing.lib[lib].exports
          i = 0
          l = exportedNames.length

          while i < l
            members[exportedNames[i]] = null
            ++i
    members
  parseProcessing = (code) ->
    splitToAtoms = (code) ->
      atoms = []
      items = code.split(/([\{\[\(\)\]\}])/)
      result = items[0]
      stack = []
      i = 1

      while i < items.length
        item = items[i]
        if item is "[" or item is "{" or item is "("
          stack.push result
          result = item
        else if item is "]" or item is "}" or item is ")"
          kind = (if item is "}" then "A" else (if item is ")" then "B" else "C"))
          index = atoms.length
          atoms.push result + item
          result = stack.pop() + "\"" + kind + (index + 1) + "\""
        result += items[i + 1]
        i += 2
      atoms.unshift result
      atoms
    injectStrings = (code, strings) ->
      code.replace /'(\d+)'/g, (all, index) ->
        val = strings[index]
        return val  if val.charAt(0) is "/"
        (if /^'((?:[^'\\\n])|(?:\\.[0-9A-Fa-f]*))'$/.test(val) then "(new $p.Character(" + val + "))" else val)

    trimSpaces = (string) ->
      m1 = /^\s*/.exec(string)
      result = undefined
      unless m1[0].length is string.length
        m2 = /\s*$/.exec(string)
        result =
          left: m1[0]
          middle: string.substring(m1[0].length, m2.index)
          right: m2[0]
      result.untrim = (t) ->
        @left + t + @right

      result
    trim = (string) ->
      string.replace(/^\s+/, "").replace /\s+$/, ""
    appendToLookupTable = (table, array) ->
      i = 0
      l = array.length

      while i < l
        table[array[i]] = null
        ++i
      table
    isLookupTableEmpty = (table) ->
      for i of table
        return false  if table.hasOwnProperty(i)
      true
    getAtomIndex = (templ) ->
      templ.substring 2, templ.length - 1
    addAtom = (text, type) ->
      lastIndex = atoms.length
      atoms.push text
      "\"" + type + lastIndex + "\""
    generateClassId = ->
      "class" + ++classIdSeed
    appendClass = (class_, classId, scopeId) ->
      class_.classId = classId
      class_.scopeId = scopeId
      declaredClasses[classId] = class_
    extractClassesAndMethods = (code) ->
      s = code
      s = s.replace(classesRegex, (all) ->
        addAtom all, "E"
      )
      s = s.replace(methodsRegex, (all) ->
        addAtom all, "D"
      )
      s = s.replace(functionsRegex, (all) ->
        addAtom all, "H"
      )
      s
    extractConstructors = (code, className) ->
      result = code.replace(cstrsRegex, (all, attr, name, params, throws_, body) ->
        return all  if name isnt className
        addAtom all, "G"
      )
      result
    AstParam = (name) ->
      @name = name
    AstParams = (params, methodArgsParam) ->
      @params = params
      @methodArgsParam = methodArgsParam
    transformParams = (params) ->
      paramsWoPars = trim(params.substring(1, params.length - 1))
      result = []
      methodArgsParam = null
      if paramsWoPars isnt ""
        paramList = paramsWoPars.split(",")
        i = 0

        while i < paramList.length
          param = /\b([A-Za-z_$][\w$]*\b)(\s*"[ABC][\d]*")*\s*$/.exec(paramList[i])
          if i is paramList.length - 1 and paramList[i].indexOf("...") >= 0
            methodArgsParam = new AstParam(param[1])
            break
          result.push new AstParam(param[1])
          ++i
      new AstParams(result, methodArgsParam)
    preExpressionTransform = (expr) ->
      replacePrototypeMethods = (all, subject, method, atomIndex) ->
        atom = atoms[atomIndex]
        repeatJavaReplacement = true
        trimmed = trimSpaces(atom.substring(1, atom.length - 1))
        "__" + method + ((if trimmed.middle is "" then addAtom("(" + subject.replace(/\.\s*$/, "") + ")", "B") else addAtom("(" + subject.replace(/\.\s*$/, "") + "," + trimmed.middle + ")", "B")))
      replaceInstanceof = (all, subject, type) ->
        repeatJavaReplacement = true
        "__instanceof" + addAtom("(" + subject + ", " + type + ")", "B")
      s = expr
      s = s.replace(/\bnew\s+([A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)(?:\s*"C\d+")+\s*("A\d+")/g, (all, type, init) ->
        init
      )
      s = s.replace(/\bnew\s+([A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)(?:\s*"B\d+")\s*("A\d+")/g, (all, type, init) ->
        addAtom all, "F"
      )
      s = s.replace(functionsRegex, (all) ->
        addAtom all, "H"
      )
      s = s.replace(/\bnew\s+([A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)\s*("C\d+"(?:\s*"C\d+")*)/g, (all, type, index) ->
        args = index.replace(/"C(\d+)"/g, (all, j) ->
          atoms[j]
        ).replace(/\[\s*\]/g, "[null]").replace(/\s*\]\s*\[\s*/g, ", ")
        arrayInitializer = "{" + args.substring(1, args.length - 1) + "}"
        createArrayArgs = "('" + type + "', " + addAtom(arrayInitializer, "A") + ")"
        "$p.createJavaArray" + addAtom(createArrayArgs, "B")
      )
      s = s.replace(/(\.\s*length)\s*"B\d+"/g, "$1")
      s = s.replace(/#([0-9A-Fa-f]{6})\b/g, (all, digits) ->
        "0xFF" + digits
      )
      s = s.replace(/"B(\d+)"(\s*(?:[\w$']|"B))/g, (all, index, next) ->
        atom = atoms[index]
        return all  unless /^\(\s*[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*\s*(?:"C\d+"\s*)*\)$/.test(atom)
        return "(int)" + next  if /^\(\s*int\s*\)$/.test(atom)
        indexParts = atom.split(/"C(\d+)"/g)
        return all  unless /^\[\s*\]$/.test(atoms[indexParts[1]])  if indexParts.length > 1
        "" + next
      )
      s = s.replace(/\(int\)([^,\]\)\}\?\:\*\+\-\/\^\|\%\&\~<\>\=]+)/g, (all, arg) ->
        trimmed = trimSpaces(arg)
        trimmed.untrim "__int_cast(" + trimmed.middle + ")"
      )
      s = s.replace(/\bsuper(\s*"B\d+")/g, "$$superCstr$1").replace(/\bsuper(\s*\.)/g, "$$super$1")
      s = s.replace(/\b0+((\d*)(?:\.[\d*])?(?:[eE][\-\+]?\d+)?[fF]?)\b/, (all, numberWo0, intPart) ->
        return all  if numberWo0 is intPart
        (if intPart is "" then "0" + numberWo0 else numberWo0)
      )
      s = s.replace(/\b(\.?\d+\.?)[fF]\b/g, "$1")
      s = s.replace(/([^\s])%([^=\s])/g, "$1 % $2")
      s = s.replace(/\b(frameRate|keyPressed|mousePressed)\b(?!\s*"B)/g, "__$1")
      s = s.replace(/\b(boolean|byte|char|float|int)\s*"B/g, (all, name) ->
        "parse" + name.substring(0, 1).toUpperCase() + name.substring(1) + "\"B"
      )
      s = s.replace(/\bpixels\b\s*(("C(\d+)")|\.length)?(\s*=(?!=)([^,\]\)\}]+))?/g, (all, indexOrLength, index, atomIndex, equalsPart, rightSide) ->
        if index
          atom = atoms[atomIndex]
          return "pixels.setPixel" + addAtom("(" + atom.substring(1, atom.length - 1) + "," + rightSide + ")", "B")  if equalsPart
          return "pixels.getPixel" + addAtom("(" + atom.substring(1, atom.length - 1) + ")", "B")
        return "pixels.getLength" + addAtom("()", "B")  if indexOrLength
        return "pixels.set" + addAtom("(" + rightSide + ")", "B")  if equalsPart
        "pixels.toArray" + addAtom("()", "B")
      )
      repeatJavaReplacement = undefined
      loop
        repeatJavaReplacement = false
        s = s.replace(/((?:'\d+'|\b[A-Za-z_$][\w$]*\s*(?:"[BC]\d+")*)\s*\.\s*(?:[A-Za-z_$][\w$]*\s*(?:"[BC]\d+"\s*)*\.\s*)*)(replace|replaceAll|replaceFirst|contains|equals|equalsIgnoreCase|hashCode|toCharArray|printStackTrace|split|startsWith|endsWith|codePointAt|matches)\s*"B(\d+)"/g, replacePrototypeMethods)
        break unless repeatJavaReplacement
      loop
        repeatJavaReplacement = false
        s = s.replace(/((?:'\d+'|\b[A-Za-z_$][\w$]*\s*(?:"[BC]\d+")*)\s*(?:\.\s*[A-Za-z_$][\w$]*\s*(?:"[BC]\d+"\s*)*)*)instanceof\s+([A-Za-z_$][\w$]*\s*(?:\.\s*[A-Za-z_$][\w$]*)*)/g, replaceInstanceof)
        break unless repeatJavaReplacement
      s = s.replace(/\bthis(\s*"B\d+")/g, "$$constr$1")
      s
    AstInlineClass = (baseInterfaceName, body) ->
      @baseInterfaceName = baseInterfaceName
      @body = body
      body.owner = this
    transformInlineClass = (class_) ->
      m = (new RegExp(/\bnew\s*([A-Za-z_$][\w$]*\s*(?:\.\s*[A-Za-z_$][\w$]*)*)\s*"B\d+"\s*"A(\d+)"/)).exec(class_)
      oldClassId = currentClassId
      newClassId = generateClassId()
      currentClassId = newClassId
      uniqueClassName = m[1] + "$" + newClassId
      inlineClass = new AstInlineClass(uniqueClassName, transformClassBody(atoms[m[2]], uniqueClassName, "", "implements " + m[1]))
      appendClass inlineClass, newClassId, oldClassId
      currentClassId = oldClassId
      inlineClass
    AstFunction = (name, params, body) ->
      @name = name
      @params = params
      @body = body
    transformFunction = (class_) ->
      m = (new RegExp(/\b([A-Za-z_$][\w$]*)\s*"B(\d+)"\s*"A(\d+)"/)).exec(class_)
      new AstFunction((if m[1] isnt "function" then m[1] else null), transformParams(atoms[m[2]]), transformStatementsBlock(atoms[m[3]]))
    AstInlineObject = (members) ->
      @members = members
    transformInlineObject = (obj) ->
      members = obj.split(",")
      i = 0

      while i < members.length
        label = members[i].indexOf(":")
        if label < 0
          members[i] = value: transformExpression(members[i])
        else
          members[i] =
            label: trim(members[i].substring(0, label))
            value: transformExpression(trim(members[i].substring(label + 1)))
        ++i
      new AstInlineObject(members)
    expandExpression = (expr) ->
      return expr.charAt(0) + expandExpression(expr.substring(1, expr.length - 1)) + expr.charAt(expr.length - 1)  if expr.charAt(0) is "(" or expr.charAt(0) is "["
      if expr.charAt(0) is "{"
        return "{" + addAtom(expr.substring(1, expr.length - 1), "I") + "}"  if /^\{\s*(?:[A-Za-z_$][\w$]*|'\d+')\s*:/.test(expr)
        return "[" + expandExpression(expr.substring(1, expr.length - 1)) + "]"
      trimmed = trimSpaces(expr)
      result = preExpressionTransform(trimmed.middle)
      result = result.replace(/"[ABC](\d+)"/g, (all, index) ->
        expandExpression atoms[index]
      )
      trimmed.untrim result
    replaceContextInVars = (expr) ->
      expr.replace /(\.\s*)?((?:\b[A-Za-z_]|\$)[\w$]*)(\s*\.\s*([A-Za-z_$][\w$]*)(\s*\()?)?/g, (all, memberAccessSign, identifier, suffix, subMember, callSign) ->
        return all  if memberAccessSign
        subject =
          name: identifier
          member: subMember
          callSign: !!callSign

        replaceContext(subject) + ((if suffix is undef then "" else suffix))

    AstExpression = (expr, transforms) ->
      @expr = expr
      @transforms = transforms
    AstVarDefinition = (name, value, isDefault) ->
      @name = name
      @value = value
      @isDefault = isDefault
    transformVarDefinition = (def, defaultTypeValue) ->
      eqIndex = def.indexOf("=")
      name = undefined
      value = undefined
      isDefault = undefined
      if eqIndex < 0
        name = def
        value = defaultTypeValue
        isDefault = true
      else
        name = def.substring(0, eqIndex)
        value = transformExpression(def.substring(eqIndex + 1))
        isDefault = false
      new AstVarDefinition(trim(name.replace(/(\s*"C\d+")+/g, "")), value, isDefault)
    getDefaultValueForType = (type) ->
      return "0"  if type is "int" or type is "float"
      return "false"  if type is "boolean"
      return "0x00000000"  if type is "color"
      "null"
    AstVar = (definitions, varType) ->
      @definitions = definitions
      @varType = varType
    AstStatement = (expression) ->
      @expression = expression
    transformStatement = (statement) ->
      if fieldTest.test(statement)
        attrAndType = attrAndTypeRegex.exec(statement)
        definitions = statement.substring(attrAndType[0].length).split(",")
        defaultTypeValue = getDefaultValueForType(attrAndType[2])
        i = 0

        while i < definitions.length
          definitions[i] = transformVarDefinition(definitions[i], defaultTypeValue)
          ++i
        return new AstVar(definitions, attrAndType[2])
      new AstStatement(transformExpression(statement))
    AstForExpression = (initStatement, condition, step) ->
      @initStatement = initStatement
      @condition = condition
      @step = step
    AstForInExpression = (initStatement, container) ->
      @initStatement = initStatement
      @container = container
    AstForEachExpression = (initStatement, container) ->
      @initStatement = initStatement
      @container = container
    transformForExpression = (expr) ->
      content = undefined
      if /\bin\b/.test(expr)
        content = expr.substring(1, expr.length - 1).split(/\bin\b/g)
        return new AstForInExpression(transformStatement(trim(content[0])), transformExpression(content[1]))
      if expr.indexOf(":") >= 0 and expr.indexOf(";") < 0
        content = expr.substring(1, expr.length - 1).split(":")
        return new AstForEachExpression(transformStatement(trim(content[0])), transformExpression(content[1]))
      content = expr.substring(1, expr.length - 1).split(";")
      new AstForExpression(transformStatement(trim(content[0])), transformExpression(content[1]), transformExpression(content[2]))
    sortByWeight = (array) ->
      array.sort (a, b) ->
        b.weight - a.weight

    AstInnerInterface = (name, body, isStatic) ->
      @name = name
      @body = body
      @isStatic = isStatic
      body.owner = this
    AstInnerClass = (name, body, isStatic) ->
      @name = name
      @body = body
      @isStatic = isStatic
      body.owner = this
    transformInnerClass = (class_) ->
      m = classesRegex.exec(class_)
      classesRegex.lastIndex = 0
      isStatic = m[1].indexOf("static") >= 0
      body = atoms[getAtomIndex(m[6])]
      innerClass = undefined
      oldClassId = currentClassId
      newClassId = generateClassId()
      currentClassId = newClassId
      if m[2] is "interface"
        innerClass = new AstInnerInterface(m[3], transformInterfaceBody(body, m[3], m[4]), isStatic)
      else
        innerClass = new AstInnerClass(m[3], transformClassBody(body, m[3], m[4], m[5]), isStatic)
      appendClass innerClass, newClassId, oldClassId
      currentClassId = oldClassId
      innerClass
    AstClassMethod = (name, params, body, isStatic) ->
      @name = name
      @params = params
      @body = body
      @isStatic = isStatic
    transformClassMethod = (method) ->
      m = methodsRegex.exec(method)
      methodsRegex.lastIndex = 0
      isStatic = m[1].indexOf("static") >= 0
      body = (if m[6] isnt ";" then atoms[getAtomIndex(m[6])] else "{}")
      new AstClassMethod(m[3], transformParams(atoms[getAtomIndex(m[4])]), transformStatementsBlock(body), isStatic)
    AstClassField = (definitions, fieldType, isStatic) ->
      @definitions = definitions
      @fieldType = fieldType
      @isStatic = isStatic
    transformClassField = (statement) ->
      attrAndType = attrAndTypeRegex.exec(statement)
      isStatic = attrAndType[1].indexOf("static") >= 0
      definitions = statement.substring(attrAndType[0].length).split(/,\s*/g)
      defaultTypeValue = getDefaultValueForType(attrAndType[2])
      i = 0

      while i < definitions.length
        definitions[i] = transformVarDefinition(definitions[i], defaultTypeValue)
        ++i
      new AstClassField(definitions, attrAndType[2], isStatic)
    AstConstructor = (params, body) ->
      @params = params
      @body = body
    transformConstructor = (cstr) ->
      m = (new RegExp(/"B(\d+)"\s*"A(\d+)"/)).exec(cstr)
      params = transformParams(atoms[m[1]])
      new AstConstructor(params, transformStatementsBlock(atoms[m[2]]))
    AstInterfaceBody = (name, interfacesNames, methodsNames, fields, innerClasses, misc) ->
      i = undefined
      l = undefined
      @name = name
      @interfacesNames = interfacesNames
      @methodsNames = methodsNames
      @fields = fields
      @innerClasses = innerClasses
      @misc = misc
      i = 0
      l = fields.length

      while i < l
        fields[i].owner = this
        ++i
    AstClassBody = (name, baseClassName, interfacesNames, functions, methods, fields, cstrs, innerClasses, misc) ->
      i = undefined
      l = undefined
      @name = name
      @baseClassName = baseClassName
      @interfacesNames = interfacesNames
      @functions = functions
      @methods = methods
      @fields = fields
      @cstrs = cstrs
      @innerClasses = innerClasses
      @misc = misc
      i = 0
      l = fields.length

      while i < l
        fields[i].owner = this
        ++i
    AstInterface = (name, body) ->
      @name = name
      @body = body
      body.owner = this
    AstClass = (name, body) ->
      @name = name
      @body = body
      body.owner = this
    transformGlobalClass = (class_) ->
      m = classesRegex.exec(class_)
      classesRegex.lastIndex = 0
      body = atoms[getAtomIndex(m[6])]
      oldClassId = currentClassId
      newClassId = generateClassId()
      currentClassId = newClassId
      globalClass = undefined
      if m[2] is "interface"
        globalClass = new AstInterface(m[3], transformInterfaceBody(body, m[3], m[4]))
      else
        globalClass = new AstClass(m[3], transformClassBody(body, m[3], m[4], m[5]))
      appendClass globalClass, newClassId, oldClassId
      currentClassId = oldClassId
      globalClass
    AstMethod = (name, params, body) ->
      @name = name
      @params = params
      @body = body
    transformGlobalMethod = (method) ->
      m = methodsRegex.exec(method)
      result = methodsRegex.lastIndex = 0
      new AstMethod(m[3], transformParams(atoms[getAtomIndex(m[4])]), transformStatementsBlock(atoms[getAtomIndex(m[6])]))
    preStatementsTransform = (statements) ->
      s = statements
      s = s.replace(/\b(catch\s*"B\d+"\s*"A\d+")(\s*catch\s*"B\d+"\s*"A\d+")+/g, "$1")
      s
    AstForStatement = (argument, misc) ->
      @argument = argument
      @misc = misc
    AstCatchStatement = (argument, misc) ->
      @argument = argument
      @misc = misc
    AstPrefixStatement = (name, argument, misc) ->
      @name = name
      @argument = argument
      @misc = misc
    AstSwitchCase = (expr) ->
      @expr = expr
    AstLabel = (label) ->
      @label = label
    getLocalNames = (statements) ->
      localNames = []
      i = 0
      l = statements.length

      while i < l
        statement = statements[i]
        if statement instanceof AstVar
          localNames = localNames.concat(statement.getNames())
        else if statement instanceof AstForStatement and statement.argument.initStatement instanceof AstVar
          localNames = localNames.concat(statement.argument.initStatement.getNames())
        else localNames.push statement.name  if statement instanceof AstInnerInterface or statement instanceof AstInnerClass or statement instanceof AstInterface or statement instanceof AstClass or statement instanceof AstMethod or statement instanceof AstFunction
        ++i
      appendToLookupTable {}, localNames
    AstStatementsBlock = (statements) ->
      @statements = statements
    AstRoot = (statements) ->
      @statements = statements
    generateMetadata = (ast) ->
      findInScopes = (class_, name) ->
        parts = name.split(".")
        currentScope = class_.scope
        found = undefined
        while currentScope
          if currentScope.hasOwnProperty(parts[0])
            found = currentScope[parts[0]]
            break
          currentScope = currentScope.scope
        found = globalScope[parts[0]]  if found is undef
        i = 1
        l = parts.length

        while i < l and found
          found = found.inScope[parts[i]]
          ++i
        found
      globalScope = {}
      id = undefined
      class_ = undefined
      for id of declaredClasses
        if declaredClasses.hasOwnProperty(id)
          class_ = declaredClasses[id]
          scopeId = class_.scopeId
          name = class_.name
          if scopeId
            scope = declaredClasses[scopeId]
            class_.scope = scope
            scope.inScope = {}  if scope.inScope is undef
            scope.inScope[name] = class_
          else
            globalScope[name] = class_
      for id of declaredClasses
        if declaredClasses.hasOwnProperty(id)
          class_ = declaredClasses[id]
          baseClassName = class_.body.baseClassName
          if baseClassName
            parent = findInScopes(class_, baseClassName)
            if parent
              class_.base = parent
              parent.derived = []  unless parent.derived
              parent.derived.push class_
          interfacesNames = class_.body.interfacesNames
          interfaces = []
          i = undefined
          l = undefined
          if interfacesNames and interfacesNames.length > 0
            i = 0
            l = interfacesNames.length

            while i < l
              interface_ = findInScopes(class_, interfacesNames[i])
              interfaces.push interface_
              continue  unless interface_
              interface_.derived = []  unless interface_.derived
              interface_.derived.push class_
              ++i
            class_.interfaces = interfaces  if interfaces.length > 0
    setWeight = (ast) ->
      removeDependentAndCheck = (targetId, from) ->
        dependsOn = tocheck[targetId]
        return false  unless dependsOn
        i = dependsOn.indexOf(from)
        return false  if i < 0
        dependsOn.splice i, 1
        return false  if dependsOn.length > 0
        delete tocheck[targetId]

        true
      queue = []
      tocheck = {}
      id = undefined
      scopeId = undefined
      class_ = undefined
      for id of declaredClasses
        if declaredClasses.hasOwnProperty(id)
          class_ = declaredClasses[id]
          if not class_.inScope and not class_.derived
            queue.push id
            class_.weight = 0
          else
            dependsOn = []
            if class_.inScope
              for scopeId of class_.inScope
                dependsOn.push class_.inScope[scopeId]  if class_.inScope.hasOwnProperty(scopeId)
            dependsOn = dependsOn.concat(class_.derived)  if class_.derived
            tocheck[id] = dependsOn
      while queue.length > 0
        id = queue.shift()
        class_ = declaredClasses[id]
        if class_.scopeId and removeDependentAndCheck(class_.scopeId, class_)
          queue.push class_.scopeId
          declaredClasses[class_.scopeId].weight = class_.weight + 1
        if class_.base and removeDependentAndCheck(class_.base.classId, class_)
          queue.push class_.base.classId
          class_.base.weight = class_.weight + 1
        if class_.interfaces
          i = undefined
          l = undefined
          i = 0
          l = class_.interfaces.length

          while i < l
            continue  if not class_.interfaces[i] or not removeDependentAndCheck(class_.interfaces[i].classId, class_)
            queue.push class_.interfaces[i].classId
            class_.interfaces[i].weight = class_.weight + 1
            ++i
    globalMembers = getGlobalMembers()
    codeWoExtraCr = code.replace(/\r\n?|\n\r/g, "\n")
    strings = []
    codeWoStrings = codeWoExtraCr.replace(/("(?:[^"\\\n]|\\.)*")|('(?:[^'\\\n]|\\.)*')|(([\[\(=|&!\^:?]\s*)(\/(?![*\/])(?:[^\/\\\n]|\\.)*\/[gim]*)\b)|(\/\/[^\n]*\n)|(\/\*(?:(?!\*\/)(?:.|\n))*\*\/)/g, (all, quoted, aposed, regexCtx, prefix, regex, singleComment, comment) ->
      index = undefined
      if quoted or aposed
        index = strings.length
        strings.push all
        return "'" + index + "'"
      if regexCtx
        index = strings.length
        strings.push regex
        return prefix + "'" + index + "'"
      (if comment isnt "" then " " else "\n")
    )
    codeWoStrings = codeWoStrings.replace(/__x([0-9A-F]{4})/g, (all, hexCode) ->
      "__x005F_x" + hexCode
    )
    codeWoStrings = codeWoStrings.replace(/\$/g, "__x0024")
    genericsWereRemoved = undefined
    codeWoGenerics = codeWoStrings
    replaceFunc = (all, before, types, after) ->
      return all  if !!before or !!after
      genericsWereRemoved = true
      ""

    loop
      genericsWereRemoved = false
      codeWoGenerics = codeWoGenerics.replace(/([<]?)<\s*((?:\?|[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)(?:\[\])*(?:\s+(?:extends|super)\s+[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)?(?:\s*,\s*(?:\?|[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)(?:\[\])*(?:\s+(?:extends|super)\s+[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)?)*)\s*>([=]?)/g, replaceFunc)
      break unless genericsWereRemoved
    atoms = splitToAtoms(codeWoGenerics)
    replaceContext = undefined
    declaredClasses = {}
    currentClassId = undefined
    classIdSeed = 0
    transformClassBody = undefined
    transformInterfaceBody = undefined
    transformStatementsBlock = undefined
    transformStatements = undefined
    transformMain = undefined
    transformExpression = undefined
    classesRegex = /\b((?:(?:public|private|final|protected|static|abstract)\s+)*)(class|interface)\s+([A-Za-z_$][\w$]*\b)(\s+extends\s+[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*(?:\s*,\s*[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*\b)*)?(\s+implements\s+[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*(?:\s*,\s*[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*\b)*)?\s*("A\d+")/g
    methodsRegex = /\b((?:(?:public|private|final|protected|static|abstract|synchronized)\s+)*)((?!(?:else|new|return|throw|function|public|private|protected)\b)[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*(?:\s*"C\d+")*)\s*([A-Za-z_$][\w$]*\b)\s*("B\d+")(\s*throws\s+[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*(?:\s*,\s*[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)*)?\s*("A\d+"|;)/g
    fieldTest = /^((?:(?:public|private|final|protected|static)\s+)*)((?!(?:else|new|return|throw)\b)[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*(?:\s*"C\d+")*)\s*([A-Za-z_$][\w$]*\b)\s*(?:"C\d+"\s*)*([=,]|$)/
    cstrsRegex = /\b((?:(?:public|private|final|protected|static|abstract)\s+)*)((?!(?:new|return|throw)\b)[A-Za-z_$][\w$]*\b)\s*("B\d+")(\s*throws\s+[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*(?:\s*,\s*[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)*)?\s*("A\d+")/g
    attrAndTypeRegex = /^((?:(?:public|private|final|protected|static)\s+)*)((?!(?:new|return|throw)\b)[A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*(?:\s*"C\d+")*)\s*/
    functionsRegex = /\bfunction(?:\s+([A-Za-z_$][\w$]*))?\s*("B\d+")\s*("A\d+")/g
    AstParam::toString = ->
      @name

    AstParams::getNames = ->
      names = []
      i = 0
      l = @params.length

      while i < l
        names.push @params[i].name
        ++i
      names

    AstParams::prependMethodArgs = (body) ->
      return body  unless @methodArgsParam
      "{\nvar " + @methodArgsParam.name + " = Array.prototype.slice.call(arguments, " + @params.length + ");\n" + body.substring(1)

    AstParams::toString = ->
      return "()"  if @params.length is 0
      result = "("
      i = 0
      l = @params.length

      while i < l
        result += @params[i] + ", "
        ++i
      result.substring(0, result.length - 2) + ")"

    AstInlineClass::toString = ->
      "new (" + @body + ")"

    AstFunction::toString = ->
      oldContext = replaceContext
      names = appendToLookupTable(
        this: null
      , @params.getNames())
      replaceContext = (subject) ->
        (if names.hasOwnProperty(subject.name) then subject.name else oldContext(subject))

      result = "function"
      result += " " + @name  if @name
      body = @params.prependMethodArgs(@body.toString())
      result += @params + " " + body
      replaceContext = oldContext
      result

    AstInlineObject::toString = ->
      oldContext = replaceContext
      replaceContext = (subject) ->
        (if subject.name is "this" then "this" else oldContext(subject))

      result = ""
      i = 0
      l = @members.length

      while i < l
        result += @members[i].label + ": "  if @members[i].label
        result += @members[i].value.toString() + ", "
        ++i
      replaceContext = oldContext
      result.substring 0, result.length - 2

    AstExpression::toString = ->
      transforms = @transforms
      expr = replaceContextInVars(@expr)
      expr.replace /"!(\d+)"/g, (all, index) ->
        transforms[index].toString()


    transformExpression = (expr) ->
      transforms = []
      s = expandExpression(expr)
      s = s.replace(/"H(\d+)"/g, (all, index) ->
        transforms.push transformFunction(atoms[index])
        "\"!" + (transforms.length - 1) + "\""
      )
      s = s.replace(/"F(\d+)"/g, (all, index) ->
        transforms.push transformInlineClass(atoms[index])
        "\"!" + (transforms.length - 1) + "\""
      )
      s = s.replace(/"I(\d+)"/g, (all, index) ->
        transforms.push transformInlineObject(atoms[index])
        "\"!" + (transforms.length - 1) + "\""
      )
      new AstExpression(s, transforms)

    AstVarDefinition::toString = ->
      @name + " = " + @value

    AstVar::getNames = ->
      names = []
      i = 0
      l = @definitions.length

      while i < l
        names.push @definitions[i].name
        ++i
      names

    AstVar::toString = ->
      "var " + @definitions.join(",")

    AstStatement::toString = ->
      @expression.toString()

    AstForExpression::toString = ->
      "(" + @initStatement + "; " + @condition + "; " + @step + ")"

    AstForInExpression::toString = ->
      init = @initStatement.toString()
      init = init.substring(0, init.indexOf("="))  if init.indexOf("=") >= 0
      "(" + init + " in " + @container + ")"

    AstForEachExpression.iteratorId = 0
    AstForEachExpression::toString = ->
      init = @initStatement.toString()
      iterator = "$it" + AstForEachExpression.iteratorId++
      variableName = init.replace(/^\s*var\s*/, "").split("=")[0]
      initIteratorAndVariable = "var " + iterator + " = new $p.ObjectIterator(" + @container + "), " + variableName + " = void(0)"
      nextIterationCondition = iterator + ".hasNext() && ((" + variableName + " = " + iterator + ".next()) || true)"
      "(" + initIteratorAndVariable + "; " + nextIterationCondition + ";)"

    AstInnerInterface::toString = ->
      "" + @body

    AstInnerClass::toString = ->
      "" + @body

    AstClassMethod::toString = ->
      paramNames = appendToLookupTable({}, @params.getNames())
      oldContext = replaceContext
      replaceContext = (subject) ->
        (if paramNames.hasOwnProperty(subject.name) then subject.name else oldContext(subject))

      body = @params.prependMethodArgs(@body.toString())
      result = "function " + @methodId + @params + " " + body + "\n"
      replaceContext = oldContext
      result

    AstClassField::getNames = ->
      names = []
      i = 0
      l = @definitions.length

      while i < l
        names.push @definitions[i].name
        ++i
      names

    AstClassField::toString = ->
      thisPrefix = replaceContext(name: "[this]")
      if @isStatic
        className = @owner.name
        staticDeclarations = []
        i = 0
        l = @definitions.length

        while i < l
          definition = @definitions[i]
          name = definition.name
          staticName = className + "." + name
          declaration = "if(" + staticName + " === void(0)) {\n" + " " + staticName + " = " + definition.value + "; }\n" + "$p.defineProperty(" + thisPrefix + ", " + "'" + name + "', { get: function(){return " + staticName + ";}, " + "set: function(val){" + staticName + " = val;} });\n"
          staticDeclarations.push declaration
          ++i
        return staticDeclarations.join("")
      thisPrefix + "." + @definitions.join("; " + thisPrefix + ".")

    AstConstructor::toString = ->
      paramNames = appendToLookupTable({}, @params.getNames())
      oldContext = replaceContext
      replaceContext = (subject) ->
        (if paramNames.hasOwnProperty(subject.name) then subject.name else oldContext(subject))

      prefix = "function $constr_" + @params.params.length + @params.toString()
      body = @params.prependMethodArgs(@body.toString())
      body = "{\n$superCstr();\n" + body.substring(1)  unless /\$(superCstr|constr)\b/.test(body)
      replaceContext = oldContext
      prefix + body + "\n"

    AstInterfaceBody::getMembers = (classFields, classMethods, classInners) ->
      @owner.base.body.getMembers classFields, classMethods, classInners  if @owner.base
      i = undefined
      j = undefined
      l = undefined
      m = undefined
      i = 0
      l = @fields.length

      while i < l
        fieldNames = @fields[i].getNames()
        j = 0
        m = fieldNames.length

        while j < m
          classFields[fieldNames[j]] = @fields[i]
          ++j
        ++i
      i = 0
      l = @methodsNames.length

      while i < l
        methodName = @methodsNames[i]
        classMethods[methodName] = true
        ++i
      i = 0
      l = @innerClasses.length

      while i < l
        innerClass = @innerClasses[i]
        classInners[innerClass.name] = innerClass
        ++i

    AstInterfaceBody::toString = ->
      getScopeLevel = (p) ->
        i = 0
        while p
          ++i
          p = p.scope
        i
      scopeLevel = getScopeLevel(@owner)
      className = @name
      staticDefinitions = ""
      metadata = ""
      thisClassFields = {}
      thisClassMethods = {}
      thisClassInners = {}
      @getMembers thisClassFields, thisClassMethods, thisClassInners
      i = undefined
      l = undefined
      j = undefined
      m = undefined
      if @owner.interfaces
        resolvedInterfaces = []
        resolvedInterface = undefined
        i = 0
        l = @interfacesNames.length

        while i < l
          continue  unless @owner.interfaces[i]
          resolvedInterface = replaceContext(name: @interfacesNames[i])
          resolvedInterfaces.push resolvedInterface
          staticDefinitions += "$p.extendInterfaceMembers(" + className + ", " + resolvedInterface + ");\n"
          ++i
        metadata += className + ".$interfaces = [" + resolvedInterfaces.join(", ") + "];\n"
      metadata += className + ".$isInterface = true;\n"
      metadata += className + ".$methods = ['" + @methodsNames.join("', '") + "'];\n"
      sortByWeight @innerClasses
      i = 0
      l = @innerClasses.length

      while i < l
        innerClass = @innerClasses[i]
        staticDefinitions += className + "." + innerClass.name + " = " + innerClass + ";\n"  if innerClass.isStatic
        ++i
      i = 0
      l = @fields.length

      while i < l
        field = @fields[i]
        staticDefinitions += className + "." + field.definitions.join(";\n" + className + ".") + ";\n"  if field.isStatic
        ++i
      "(function() {\n" + "function " + className + "() { throw 'Unable to create the interface'; }\n" + staticDefinitions + metadata + "return " + className + ";\n" + "})()"

    transformInterfaceBody = (body, name, baseInterfaces) ->
      declarations = body.substring(1, body.length - 1)
      declarations = extractClassesAndMethods(declarations)
      declarations = extractConstructors(declarations, name)
      methodsNames = []
      classes = []
      declarations = declarations.replace(/"([DE])(\d+)"/g, (all, type, index) ->
        if type is "D"
          methodsNames.push index
        else classes.push index  if type is "E"
        ""
      )
      fields = declarations.split(/;(?:\s*;)*/g)
      baseInterfaceNames = undefined
      i = undefined
      l = undefined
      baseInterfaceNames = baseInterfaces.replace(/^\s*extends\s+(.+?)\s*$/g, "$1").split(/\s*,\s*/g)  if baseInterfaces isnt undef
      i = 0
      l = methodsNames.length

      while i < l
        method = transformClassMethod(atoms[methodsNames[i]])
        methodsNames[i] = method.name
        ++i
      i = 0
      l = fields.length - 1

      while i < l
        field = trimSpaces(fields[i])
        fields[i] = transformClassField(field.middle)
        ++i
      tail = fields.pop()
      i = 0
      l = classes.length

      while i < l
        classes[i] = transformInnerClass(atoms[classes[i]])
        ++i
      new AstInterfaceBody(name, baseInterfaceNames, methodsNames, fields, classes,
        tail: tail
      )

    AstClassBody::getMembers = (classFields, classMethods, classInners) ->
      @owner.base.body.getMembers classFields, classMethods, classInners  if @owner.base
      i = undefined
      j = undefined
      l = undefined
      m = undefined
      i = 0
      l = @fields.length

      while i < l
        fieldNames = @fields[i].getNames()
        j = 0
        m = fieldNames.length

        while j < m
          classFields[fieldNames[j]] = @fields[i]
          ++j
        ++i
      i = 0
      l = @methods.length

      while i < l
        method = @methods[i]
        classMethods[method.name] = method
        ++i
      i = 0
      l = @innerClasses.length

      while i < l
        innerClass = @innerClasses[i]
        classInners[innerClass.name] = innerClass
        ++i

    AstClassBody::toString = ->
      getScopeLevel = (p) ->
        i = 0
        while p
          ++i
          p = p.scope
        i
      scopeLevel = getScopeLevel(@owner)
      selfId = "$this_" + scopeLevel
      className = @name
      result = "var " + selfId + " = this;\n"
      staticDefinitions = ""
      metadata = ""
      thisClassFields = {}
      thisClassMethods = {}
      thisClassInners = {}
      @getMembers thisClassFields, thisClassMethods, thisClassInners
      oldContext = replaceContext
      replaceContext = (subject) ->
        name = subject.name
        return (if subject.callSign or not subject.member then selfId + ".$self" else selfId)  if name is "this"
        return (if thisClassFields[name].isStatic then className + "." + name else selfId + "." + name)  if thisClassFields.hasOwnProperty(name)
        return selfId + "." + name  if thisClassInners.hasOwnProperty(name)
        return (if thisClassMethods[name].isStatic then className + "." + name else selfId + ".$self." + name)  if thisClassMethods.hasOwnProperty(name)
        oldContext subject

      resolvedBaseClassName = undefined
      if @baseClassName
        resolvedBaseClassName = oldContext(name: @baseClassName)
        result += "var $super = { $upcast: " + selfId + " };\n"
        result += "function $superCstr(){" + resolvedBaseClassName + ".apply($super,arguments);if(!('$self' in $super)) $p.extendClassChain($super)}\n"
        metadata += className + ".$base = " + resolvedBaseClassName + ";\n"
      else
        result += "function $superCstr(){$p.extendClassChain(" + selfId + ")}\n"
      staticDefinitions += "$p.extendStaticMembers(" + className + ", " + resolvedBaseClassName + ");\n"  if @owner.base
      i = undefined
      l = undefined
      j = undefined
      m = undefined
      if @owner.interfaces
        resolvedInterfaces = []
        resolvedInterface = undefined
        i = 0
        l = @interfacesNames.length

        while i < l
          continue  unless @owner.interfaces[i]
          resolvedInterface = oldContext(name: @interfacesNames[i])
          resolvedInterfaces.push resolvedInterface
          staticDefinitions += "$p.extendInterfaceMembers(" + className + ", " + resolvedInterface + ");\n"
          ++i
        metadata += className + ".$interfaces = [" + resolvedInterfaces.join(", ") + "];\n"
      result += @functions.join("\n") + "\n"  if @functions.length > 0
      sortByWeight @innerClasses
      i = 0
      l = @innerClasses.length

      while i < l
        innerClass = @innerClasses[i]
        if innerClass.isStatic
          staticDefinitions += className + "." + innerClass.name + " = " + innerClass + ";\n"
          result += selfId + "." + innerClass.name + " = " + className + "." + innerClass.name + ";\n"
        else
          result += selfId + "." + innerClass.name + " = " + innerClass + ";\n"
        ++i
      i = 0
      l = @fields.length

      while i < l
        field = @fields[i]
        if field.isStatic
          staticDefinitions += className + "." + field.definitions.join(";\n" + className + ".") + ";\n"
          j = 0
          m = field.definitions.length

          while j < m
            fieldName = field.definitions[j].name
            staticName = className + "." + fieldName
            result += "$p.defineProperty(" + selfId + ", '" + fieldName + "', {" + "get: function(){return " + staticName + "}, " + "set: function(val){" + staticName + " = val}});\n"
            ++j
        else
          result += selfId + "." + field.definitions.join(";\n" + selfId + ".") + ";\n"
        ++i
      methodOverloads = {}
      i = 0
      l = @methods.length

      while i < l
        method = @methods[i]
        overload = methodOverloads[method.name]
        methodId = method.name + "$" + method.params.params.length
        hasMethodArgs = !!method.params.methodArgsParam
        if overload
          ++overload
          methodId += "_" + overload
        else
          overload = 1
        method.methodId = methodId
        methodOverloads[method.name] = overload
        if method.isStatic
          staticDefinitions += method
          staticDefinitions += "$p.addMethod(" + className + ", '" + method.name + "', " + methodId + ", " + hasMethodArgs + ");\n"
          result += "$p.addMethod(" + selfId + ", '" + method.name + "', " + methodId + ", " + hasMethodArgs + ");\n"
        else
          result += method
          result += "$p.addMethod(" + selfId + ", '" + method.name + "', " + methodId + ", " + hasMethodArgs + ");\n"
        ++i
      result += trim(@misc.tail)
      result += @cstrs.join("\n") + "\n"  if @cstrs.length > 0
      result += "function $constr() {\n"
      cstrsIfs = []
      i = 0
      l = @cstrs.length

      while i < l
        paramsLength = @cstrs[i].params.params.length
        methodArgsPresent = !!@cstrs[i].params.methodArgsParam
        cstrsIfs.push "if(arguments.length " + ((if methodArgsPresent then ">=" else "===")) + " " + paramsLength + ") { " + "$constr_" + paramsLength + ".apply(" + selfId + ", arguments); }"
        ++i
      result += cstrsIfs.join(" else ") + " else "  if cstrsIfs.length > 0
      result += "$superCstr();\n}\n"
      result += "$constr.apply(null, arguments);\n"
      replaceContext = oldContext
      "(function() {\n" + "function " + className + "() {\n" + result + "}\n" + staticDefinitions + metadata + "return " + className + ";\n" + "})()"

    transformClassBody = (body, name, baseName, interfaces) ->
      declarations = body.substring(1, body.length - 1)
      declarations = extractClassesAndMethods(declarations)
      declarations = extractConstructors(declarations, name)
      methods = []
      classes = []
      cstrs = []
      functions = []
      declarations = declarations.replace(/"([DEGH])(\d+)"/g, (all, type, index) ->
        if type is "D"
          methods.push index
        else if type is "E"
          classes.push index
        else if type is "H"
          functions.push index
        else
          cstrs.push index
        ""
      )
      fields = declarations.replace(/^(?:\s*;)+/, "").split(/;(?:\s*;)*/g)
      baseClassName = undefined
      interfacesNames = undefined
      i = undefined
      baseClassName = baseName.replace(/^\s*extends\s+([A-Za-z_$][\w$]*\b(?:\s*\.\s*[A-Za-z_$][\w$]*\b)*)\s*$/g, "$1")  if baseName isnt undef
      interfacesNames = interfaces.replace(/^\s*implements\s+(.+?)\s*$/g, "$1").split(/\s*,\s*/g)  if interfaces isnt undef
      i = 0
      while i < functions.length
        functions[i] = transformFunction(atoms[functions[i]])
        ++i
      i = 0
      while i < methods.length
        methods[i] = transformClassMethod(atoms[methods[i]])
        ++i
      i = 0
      while i < fields.length - 1
        field = trimSpaces(fields[i])
        fields[i] = transformClassField(field.middle)
        ++i
      tail = fields.pop()
      i = 0
      while i < cstrs.length
        cstrs[i] = transformConstructor(atoms[cstrs[i]])
        ++i
      i = 0
      while i < classes.length
        classes[i] = transformInnerClass(atoms[classes[i]])
        ++i
      new AstClassBody(name, baseClassName, interfacesNames, functions, methods, fields, cstrs, classes,
        tail: tail
      )

    AstInterface::toString = ->
      "var " + @name + " = " + @body + ";\n" + "$p." + @name + " = " + @name + ";\n"

    AstClass::toString = ->
      "var " + @name + " = " + @body + ";\n" + "$p." + @name + " = " + @name + ";\n"

    AstMethod::toString = ->
      paramNames = appendToLookupTable({}, @params.getNames())
      oldContext = replaceContext
      replaceContext = (subject) ->
        (if paramNames.hasOwnProperty(subject.name) then subject.name else oldContext(subject))

      body = @params.prependMethodArgs(@body.toString())
      result = "function " + @name + @params + " " + body + "\n" + "$p." + @name + " = " + @name + ";"
      replaceContext = oldContext
      result

    AstForStatement::toString = ->
      @misc.prefix + @argument.toString()

    AstCatchStatement::toString = ->
      @misc.prefix + @argument.toString()

    AstPrefixStatement::toString = ->
      result = @misc.prefix
      result += @argument.toString()  if @argument isnt undef
      result

    AstSwitchCase::toString = ->
      "case " + @expr + ":"

    AstLabel::toString = ->
      @label

    transformStatements = (statements, transformMethod, transformClass) ->
      nextStatement = new RegExp(/\b(catch|for|if|switch|while|with)\s*"B(\d+)"|\b(do|else|finally|return|throw|try|break|continue)\b|("[ADEH](\d+)")|\b(case)\s+([^:]+):|\b([A-Za-z_$][\w$]*\s*:)|(;)/g)
      res = []
      statements = preStatementsTransform(statements)
      lastIndex = 0
      m = undefined
      space = undefined
      while (m = nextStatement.exec(statements)) isnt null
        if m[1] isnt undef
          i = statements.lastIndexOf("\"B", nextStatement.lastIndex)
          statementsPrefix = statements.substring(lastIndex, i)
          if m[1] is "for"
            res.push new AstForStatement(transformForExpression(atoms[m[2]]),
              prefix: statementsPrefix
            )
          else if m[1] is "catch"
            res.push new AstCatchStatement(transformParams(atoms[m[2]]),
              prefix: statementsPrefix
            )
          else
            res.push new AstPrefixStatement(m[1], transformExpression(atoms[m[2]]),
              prefix: statementsPrefix
            )
        else if m[3] isnt undef
          res.push new AstPrefixStatement(m[3], undef,
            prefix: statements.substring(lastIndex, nextStatement.lastIndex)
          )
        else if m[4] isnt undef
          space = statements.substring(lastIndex, nextStatement.lastIndex - m[4].length)
          continue  if trim(space).length isnt 0
          res.push space
          kind = m[4].charAt(1)
          atomIndex = m[5]
          if kind is "D"
            res.push transformMethod(atoms[atomIndex])
          else if kind is "E"
            res.push transformClass(atoms[atomIndex])
          else if kind is "H"
            res.push transformFunction(atoms[atomIndex])
          else
            res.push transformStatementsBlock(atoms[atomIndex])
        else if m[6] isnt undef
          res.push new AstSwitchCase(transformExpression(trim(m[7])))
        else if m[8] isnt undef
          space = statements.substring(lastIndex, nextStatement.lastIndex - m[8].length)
          continue  if trim(space).length isnt 0
          res.push new AstLabel(statements.substring(lastIndex, nextStatement.lastIndex))
        else
          statement = trimSpaces(statements.substring(lastIndex, nextStatement.lastIndex - 1))
          res.push statement.left
          res.push transformStatement(statement.middle)
          res.push statement.right + ";"
        lastIndex = nextStatement.lastIndex
      statementsTail = trimSpaces(statements.substring(lastIndex))
      res.push statementsTail.left
      if statementsTail.middle isnt ""
        res.push transformStatement(statementsTail.middle)
        res.push ";" + statementsTail.right
      res

    AstStatementsBlock::toString = ->
      localNames = getLocalNames(@statements)
      oldContext = replaceContext
      unless isLookupTableEmpty(localNames)
        replaceContext = (subject) ->
          (if localNames.hasOwnProperty(subject.name) then subject.name else oldContext(subject))
      result = "{\n" + @statements.join("") + "\n}"
      replaceContext = oldContext
      result

    transformStatementsBlock = (block) ->
      content = trimSpaces(block.substring(1, block.length - 1))
      new AstStatementsBlock(transformStatements(content.middle))

    AstRoot::toString = ->
      classes = []
      otherStatements = []
      statement = undefined
      i = 0
      len = @statements.length

      while i < len
        statement = @statements[i]
        if statement instanceof AstClass or statement instanceof AstInterface
          classes.push statement
        else
          otherStatements.push statement
        ++i
      sortByWeight classes
      localNames = getLocalNames(@statements)
      replaceContext = (subject) ->
        name = subject.name
        return name  if localNames.hasOwnProperty(name)
        return "$p." + name  if globalMembers.hasOwnProperty(name) or PConstants.hasOwnProperty(name) or defaultScope.hasOwnProperty(name)
        name

      result = "// this code was autogenerated from PJS\n" + "(function($p) {\n" + classes.join("") + "\n" + otherStatements.join("") + "\n})"
      replaceContext = null
      result

    transformMain = ->
      statements = extractClassesAndMethods(atoms[0])
      statements = statements.replace(/\bimport\s+[^;]+;/g, "")
      new AstRoot(transformStatements(statements, transformGlobalMethod, transformGlobalClass))

    transformed = transformMain()
    generateMetadata transformed
    setWeight transformed
    redendered = transformed.toString()
    redendered = redendered.replace(/\s*\n(?:[\t ]*\n)+/g, "\n\n")
    redendered = redendered.replace(/__x([0-9A-F]{4})/g, (all, hexCode) ->
      String.fromCharCode parseInt(hexCode, 16)
    )
    injectStrings redendered, strings
  preprocessCode = (aCode, sketch) ->
    dm = (new RegExp(/\/\*\s*@pjs\s+((?:[^\*]|\*+[^\*\/])*)\*\//g)).exec(aCode)
    if dm and dm.length is 2
      jsonItems = []
      directives = dm.splice(1, 2)[0].replace(/\{([\s\S]*?)\}/g, ->
        (all, item) ->
          jsonItems.push item
          "{" + (jsonItems.length - 1) + "}"
      ()).replace("\n", "").replace("\r", "").split(";")
      clean = (s) ->
        s.replace(/^\s*["']?/, "").replace /["']?\s*$/, ""

      i = 0
      dl = directives.length

      while i < dl
        pair = directives[i].split("=")
        if pair and pair.length is 2
          key = clean(pair[0])
          value = clean(pair[1])
          list = []
          if key is "preload"
            list = value.split(",")
            j = 0
            jl = list.length

            while j < jl
              imageName = clean(list[j])
              sketch.imageCache.add imageName
              j++
          else if key is "font"
            list = value.split(",")
            x = 0
            xl = list.length

            while x < xl
              fontName = clean(list[x])
              index = /^\{(\d*?)\}$/.exec(fontName)
              PFont.preloading.add (if index then JSON.parse("{" + jsonItems[index[1]] + "}") else fontName)
              x++
          else if key is "pauseOnBlur"
            sketch.options.pauseOnBlur = value is "true"
          else if key is "globalKeyEvents"
            sketch.options.globalKeyEvents = value is "true"
          else if key.substring(0, 6) is "param-"
            sketch.params[key.substring(6)] = value
          else
            sketch.options[key] = value
        i++
    aCode
  nop = ->

  debug = ->
    if "console" of window
      return (msg) ->
        window.console.log "Processing.js: " + msg
    nop
  ()
  ajax = (url) ->
    xhr = new XMLHttpRequest
    xhr.open "GET", url, false
    xhr.overrideMimeType "text/plain"  if xhr.overrideMimeType
    xhr.setRequestHeader "If-Modified-Since", "Fri, 01 Jan 1960 00:00:00 GMT"
    xhr.send null
    throw "XMLHttpRequest failed, status code " + xhr.status  if xhr.status isnt 200 and xhr.status isnt 0
    xhr.responseText

  isDOMPresent = "document" of this and ("fake" not of @document)
  document.head = document.head or document.getElementsByTagName("head")[0]
  throw "The doctype directive is missing. The recommended doctype in Internet Explorer is the HTML5 doctype: <!DOCTYPE html>"  if document.documentMode >= 9 and not document.doctype
  Float32Array = setupTypedArray("Float32Array", "WebGLFloatArray")
  Int32Array = setupTypedArray("Int32Array", "WebGLIntArray")
  Uint16Array = setupTypedArray("Uint16Array", "WebGLUnsignedShortArray")
  Uint8Array = setupTypedArray("Uint8Array", "WebGLUnsignedByteArray")
  PConstants =
    X: 0
    Y: 1
    Z: 2
    R: 3
    G: 4
    B: 5
    A: 6
    U: 7
    V: 8
    NX: 9
    NY: 10
    NZ: 11
    EDGE: 12
    SR: 13
    SG: 14
    SB: 15
    SA: 16
    SW: 17
    TX: 18
    TY: 19
    TZ: 20
    VX: 21
    VY: 22
    VZ: 23
    VW: 24
    AR: 25
    AG: 26
    AB: 27
    DR: 3
    DG: 4
    DB: 5
    DA: 6
    SPR: 28
    SPG: 29
    SPB: 30
    SHINE: 31
    ER: 32
    EG: 33
    EB: 34
    BEEN_LIT: 35
    VERTEX_FIELD_COUNT: 36
    P2D: 1
    JAVA2D: 1
    WEBGL: 2
    P3D: 2
    OPENGL: 2
    PDF: 0
    DXF: 0
    OTHER: 0
    WINDOWS: 1
    MAXOSX: 2
    LINUX: 3
    EPSILON: 1.0E-4
    MAX_FLOAT: 3.4028235E38
    MIN_FLOAT: -3.4028235E38
    MAX_INT: 2147483647
    MIN_INT: -2147483648
    PI: Math.PI
    TWO_PI: 2 * Math.PI
    HALF_PI: Math.PI / 2
    THIRD_PI: Math.PI / 3
    QUARTER_PI: Math.PI / 4
    DEG_TO_RAD: Math.PI / 180
    RAD_TO_DEG: 180 / Math.PI
    WHITESPACE: " \t\n\r\f "
    RGB: 1
    ARGB: 2
    HSB: 3
    ALPHA: 4
    CMYK: 5
    TIFF: 0
    TARGA: 1
    JPEG: 2
    GIF: 3
    BLUR: 11
    GRAY: 12
    INVERT: 13
    OPAQUE: 14
    POSTERIZE: 15
    THRESHOLD: 16
    ERODE: 17
    DILATE: 18
    REPLACE: 0
    BLEND: 1 << 0
    ADD: 1 << 1
    SUBTRACT: 1 << 2
    LIGHTEST: 1 << 3
    DARKEST: 1 << 4
    DIFFERENCE: 1 << 5
    EXCLUSION: 1 << 6
    MULTIPLY: 1 << 7
    SCREEN: 1 << 8
    OVERLAY: 1 << 9
    HARD_LIGHT: 1 << 10
    SOFT_LIGHT: 1 << 11
    DODGE: 1 << 12
    BURN: 1 << 13
    ALPHA_MASK: 4278190080
    RED_MASK: 16711680
    GREEN_MASK: 65280
    BLUE_MASK: 255
    CUSTOM: 0
    ORTHOGRAPHIC: 2
    PERSPECTIVE: 3
    POINT: 2
    POINTS: 2
    LINE: 4
    LINES: 4
    TRIANGLE: 8
    TRIANGLES: 9
    TRIANGLE_STRIP: 10
    TRIANGLE_FAN: 11
    QUAD: 16
    QUADS: 16
    QUAD_STRIP: 17
    POLYGON: 20
    PATH: 21
    RECT: 30
    ELLIPSE: 31
    ARC: 32
    SPHERE: 40
    BOX: 41
    GROUP: 0
    PRIMITIVE: 1
    GEOMETRY: 3
    VERTEX: 0
    BEZIER_VERTEX: 1
    CURVE_VERTEX: 2
    BREAK: 3
    CLOSESHAPE: 4
    OPEN: 1
    CLOSE: 2
    CORNER: 0
    CORNERS: 1
    RADIUS: 2
    CENTER_RADIUS: 2
    CENTER: 3
    DIAMETER: 3
    CENTER_DIAMETER: 3
    BASELINE: 0
    TOP: 101
    BOTTOM: 102
    NORMAL: 1
    NORMALIZED: 1
    IMAGE: 2
    MODEL: 4
    SHAPE: 5
    SQUARE: "butt"
    ROUND: "round"
    PROJECT: "square"
    MITER: "miter"
    BEVEL: "bevel"
    AMBIENT: 0
    DIRECTIONAL: 1
    SPOT: 3
    BACKSPACE: 8
    TAB: 9
    ENTER: 10
    RETURN: 13
    ESC: 27
    DELETE: 127
    CODED: 65535
    SHIFT: 16
    CONTROL: 17
    ALT: 18
    CAPSLK: 20
    PGUP: 33
    PGDN: 34
    END: 35
    HOME: 36
    LEFT: 37
    UP: 38
    RIGHT: 39
    DOWN: 40
    F1: 112
    F2: 113
    F3: 114
    F4: 115
    F5: 116
    F6: 117
    F7: 118
    F8: 119
    F9: 120
    F10: 121
    F11: 122
    F12: 123
    NUMLK: 144
    META: 157
    INSERT: 155
    ARROW: "default"
    CROSS: "crosshair"
    HAND: "pointer"
    MOVE: "move"
    TEXT: "text"
    WAIT: "wait"
    NOCURSOR: "url('data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=='), auto"
    DISABLE_OPENGL_2X_SMOOTH: 1
    ENABLE_OPENGL_2X_SMOOTH: -1
    ENABLE_OPENGL_4X_SMOOTH: 2
    ENABLE_NATIVE_FONTS: 3
    DISABLE_DEPTH_TEST: 4
    ENABLE_DEPTH_TEST: -4
    ENABLE_DEPTH_SORT: 5
    DISABLE_DEPTH_SORT: -5
    DISABLE_OPENGL_ERROR_REPORT: 6
    ENABLE_OPENGL_ERROR_REPORT: -6
    ENABLE_ACCURATE_TEXTURES: 7
    DISABLE_ACCURATE_TEXTURES: -7
    HINT_COUNT: 10
    SINCOS_LENGTH: 720
    PRECISIONB: 15
    PRECISIONF: 1 << 15
    PREC_MAXVAL: (1 << 15) - 1
    PREC_ALPHA_SHIFT: 24 - 15
    PREC_RED_SHIFT: 16 - 15
    NORMAL_MODE_AUTO: 0
    NORMAL_MODE_SHAPE: 1
    NORMAL_MODE_VERTEX: 2
    MAX_LIGHTS: 8

  ObjectIterator = (obj) ->
    return obj.iterator()  if obj.iterator instanceof Function
    if obj instanceof Array
      index = -1
      @hasNext = ->
        ++index < obj.length

      @next = ->
        obj[index]
    else
      throw "Unable to iterate: " + obj

  ArrayList = ->
    Iterator = (array) ->
      index = 0
      @hasNext = ->
        index < array.length

      @next = ->
        array[index++]

      @remove = ->
        array.splice index, 1
    ArrayList = (a) ->
      array = undefined
      unless a instanceof ArrayList
        array = []
        array.length = (if a > 0 then a else 0)  if typeof a is "number"
      @get = (i) ->
        array[i]

      @contains = (item) ->
        @indexOf(item) > -1

      @indexOf = (item) ->
        i = 0
        len = array.length

        while i < len
          return i  if virtEquals(item, array[i])
          ++i
        -1

      @lastIndexOf = (item) ->
        i = array.length - 1

        while i >= 0
          return i  if virtEquals(item, array[i])
          --i
        -1

      @add = ->
        if arguments.length is 1
          array.push arguments[0]
        else if arguments.length is 2
          arg0 = arguments[0]
          if typeof arg0 is "number"
            if arg0 >= 0 and arg0 <= array.length
              array.splice arg0, 0, arguments[1]
            else
              throw arg0 + " is not a valid index"
          else
            throw typeof arg0 + " is not a number"
        else
          throw "Please use the proper number of parameters."

      @addAll = (arg1, arg2) ->
        it = undefined
        if typeof arg1 is "number"
          throw "Index out of bounds for addAll: " + arg1 + " greater or equal than " + array.length  if arg1 < 0 or arg1 > array.length
          it = new ObjectIterator(arg2)
          array.splice arg1++, 0, it.next()  while it.hasNext()
        else
          it = new ObjectIterator(arg1)
          array.push it.next()  while it.hasNext()

      @set = ->
        if arguments.length is 2
          arg0 = arguments[0]
          if typeof arg0 is "number"
            if arg0 >= 0 and arg0 < array.length
              array.splice arg0, 1, arguments[1]
            else
              throw arg0 + " is not a valid index."
          else
            throw typeof arg0 + " is not a number"
        else
          throw "Please use the proper number of parameters."

      @size = ->
        array.length

      @clear = ->
        array.length = 0

      @remove = (item) ->
        return array.splice(item, 1)[0]  if typeof item is "number"
        item = @indexOf(item)
        if item > -1
          array.splice item, 1
          return true
        false

      @removeAll = (c) ->
        i = undefined
        x = undefined
        item = undefined
        newList = new ArrayList
        newList.addAll this
        @clear()
        i = 0
        x = 0

        while i < newList.size()
          item = newList.get(i)
          @add x++, item  unless c.contains(item)
          i++
        return true  if @size() < newList.size()
        false

      @isEmpty = ->
        not array.length

      @clone = ->
        new ArrayList(this)

      @toArray = ->
        array.slice 0

      @iterator = ->
        new Iterator(array)
    ArrayList
  ()
  HashMap = ->
    HashMap = ->
      getBucketIndex = (key) ->
        index = virtHashCode(key) % buckets.length
        (if index < 0 then buckets.length + index else index)
      ensureLoad = ->
        return  if count <= loadFactor * buckets.length
        allEntries = []
        i = 0

        while i < buckets.length
          allEntries = allEntries.concat(buckets[i])  if buckets[i] isnt undef
          ++i
        newBucketsLength = buckets.length * 2
        buckets = []
        buckets.length = newBucketsLength
        j = 0

        while j < allEntries.length
          index = getBucketIndex(allEntries[j].key)
          bucket = buckets[index]
          buckets[index] = bucket = []  if bucket is undef
          bucket.push allEntries[j]
          ++j
      Iterator = (conversion, removeItem) ->
        findNext = ->
          until endOfBuckets
            ++itemIndex
            if bucketIndex >= buckets.length
              endOfBuckets = true
            else if buckets[bucketIndex] is undef or itemIndex >= buckets[bucketIndex].length
              itemIndex = -1
              ++bucketIndex
            else
              return
        bucketIndex = 0
        itemIndex = -1
        endOfBuckets = false
        currentItem = undefined
        @hasNext = ->
          not endOfBuckets

        @next = ->
          currentItem = conversion(buckets[bucketIndex][itemIndex])
          findNext()
          currentItem

        @remove = ->
          if currentItem isnt undef
            removeItem currentItem
            --itemIndex
            findNext()

        findNext()
      Set = (conversion, isIn, removeItem) ->
        @clear = ->
          hashMap.clear()

        @contains = (o) ->
          isIn o

        @containsAll = (o) ->
          it = o.iterator()
          return false  unless @contains(it.next())  while it.hasNext()
          true

        @isEmpty = ->
          hashMap.isEmpty()

        @iterator = ->
          new Iterator(conversion, removeItem)

        @remove = (o) ->
          if @contains(o)
            removeItem o
            return true
          false

        @removeAll = (c) ->
          it = c.iterator()
          changed = false
          while it.hasNext()
            item = it.next()
            if @contains(item)
              removeItem item
              changed = true
          true

        @retainAll = (c) ->
          it = @iterator()
          toRemove = []
          while it.hasNext()
            entry = it.next()
            toRemove.push entry  unless c.contains(entry)
          i = 0

          while i < toRemove.length
            removeItem toRemove[i]
            ++i
          toRemove.length > 0

        @size = ->
          hashMap.size()

        @toArray = ->
          result = []
          it = @iterator()
          result.push it.next()  while it.hasNext()
          result
      Entry = (pair) ->
        @_isIn = (map) ->
          map is hashMap and pair.removed is undef

        @equals = (o) ->
          virtEquals pair.key, o.getKey()

        @getKey = ->
          pair.key

        @getValue = ->
          pair.value

        @hashCode = (o) ->
          virtHashCode pair.key

        @setValue = (value) ->
          old = pair.value
          pair.value = value
          old
      return arguments[0].clone()  if arguments.length is 1 and arguments[0] instanceof HashMap
      initialCapacity = (if arguments.length > 0 then arguments[0] else 16)
      loadFactor = (if arguments.length > 1 then arguments[1] else 0.75)
      buckets = []
      buckets.length = initialCapacity
      count = 0
      hashMap = this
      @clear = ->
        count = 0
        buckets = []
        buckets.length = initialCapacity

      @clone = ->
        map = new HashMap
        map.putAll this
        map

      @containsKey = (key) ->
        index = getBucketIndex(key)
        bucket = buckets[index]
        return false  if bucket is undef
        i = 0

        while i < bucket.length
          return true  if virtEquals(bucket[i].key, key)
          ++i
        false

      @containsValue = (value) ->
        i = 0

        while i < buckets.length
          bucket = buckets[i]
          continue  if bucket is undef
          j = 0

          while j < bucket.length
            return true  if virtEquals(bucket[j].value, value)
            ++j
          ++i
        false

      @entrySet = ->
        new Set((pair) ->
          new Entry(pair)
        , (pair) ->
          pair instanceof Entry and pair._isIn(hashMap)
        , (pair) ->
          hashMap.remove pair.getKey()
        )

      @get = (key) ->
        index = getBucketIndex(key)
        bucket = buckets[index]
        return null  if bucket is undef
        i = 0

        while i < bucket.length
          return bucket[i].value  if virtEquals(bucket[i].key, key)
          ++i
        null

      @isEmpty = ->
        count is 0

      @keySet = ->
        new Set((pair) ->
          pair.key
        , (key) ->
          hashMap.containsKey key
        , (key) ->
          hashMap.remove key
        )

      @values = ->
        new Set((pair) ->
          pair.value
        , (value) ->
          hashMap.containsValue value
        , (value) ->
          hashMap.removeByValue value
        )

      @put = (key, value) ->
        index = getBucketIndex(key)
        bucket = buckets[index]
        if bucket is undef
          ++count
          buckets[index] = [
            key: key
            value: value
           ]
          ensureLoad()
          return null
        i = 0

        while i < bucket.length
          if virtEquals(bucket[i].key, key)
            previous = bucket[i].value
            bucket[i].value = value
            return previous
          ++i
        ++count
        bucket.push
          key: key
          value: value

        ensureLoad()
        null

      @putAll = (m) ->
        it = m.entrySet().iterator()
        while it.hasNext()
          entry = it.next()
          @put entry.getKey(), entry.getValue()

      @remove = (key) ->
        index = getBucketIndex(key)
        bucket = buckets[index]
        return null  if bucket is undef
        i = 0

        while i < bucket.length
          if virtEquals(bucket[i].key, key)
            --count
            previous = bucket[i].value
            bucket[i].removed = true
            if bucket.length > 1
              bucket.splice i, 1
            else
              buckets[index] = undef
            return previous
          ++i
        null

      @removeByValue = (value) ->
        bucket = undefined
        i = undefined
        ilen = undefined
        pair = undefined
        for bucket of buckets
          if buckets.hasOwnProperty(bucket)
            i = 0
            ilen = buckets[bucket].length

            while i < ilen
              pair = buckets[bucket][i]
              if pair.value is value
                buckets[bucket].splice i, 1
                return true
              i++
        false

      @size = ->
        count
    HashMap
  ()
  PVector = ->
    PVector = (x, y, z) ->
      @x = x or 0
      @y = y or 0
      @z = z or 0
    createPVectorMethod = (method) ->
      (v1, v2) ->
        v = v1.get()
        v[method] v2
        v
    PVector.dist = (v1, v2) ->
      v1.dist v2

    PVector.dot = (v1, v2) ->
      v1.dot v2

    PVector.cross = (v1, v2) ->
      v1.cross v2

    PVector.angleBetween = (v1, v2) ->
      Math.acos v1.dot(v2) / (v1.mag() * v2.mag())

    PVector:: =
      set: (v, y, z) ->
        unless arguments.length is 1
          @x = v
          @y = y
          @z = z

      get: ->
        new PVector(@x, @y, @z)

      mag: ->
        x = @x
        y = @y
        z = @z
        Math.sqrt x * x + y * y + z * z

      add: (v, y, z) ->
        if arguments.length is 1
          @x += v.x
          @y += v.y
          @z += v.z
        else
          @x += v
          @y += y
          @z += z

      sub: (v, y, z) ->
        if arguments.length is 1
          @x -= v.x
          @y -= v.y
          @z -= v.z
        else
          @x -= v
          @y -= y
          @z -= z

      mult: (v) ->
        if typeof v is "number"
          @x *= v
          @y *= v
          @z *= v
        else
          @x *= v.x
          @y *= v.y
          @z *= v.z

      div: (v) ->
        if typeof v is "number"
          @x /= v
          @y /= v
          @z /= v
        else
          @x /= v.x
          @y /= v.y
          @z /= v.z

      dist: (v) ->
        dx = @x - v.x
        dy = @y - v.y
        dz = @z - v.z
        Math.sqrt dx * dx + dy * dy + dz * dz

      dot: (v, y, z) ->
        return @x * v.x + @y * v.y + @z * v.z  if arguments.length is 1
        @x * v + @y * y + @z * z

      cross: (v) ->
        x = @x
        y = @y
        z = @z
        new PVector(y * v.z - v.y * z, z * v.x - v.z * x, x * v.y - v.x * y)

      normalize: ->
        m = @mag()
        @div m  if m > 0

      limit: (high) ->
        if @mag() > high
          @normalize()
          @mult high

      heading2D: ->
        -Math.atan2(-@y, @x)

      toString: ->
        "[" + @x + ", " + @y + ", " + @z + "]"

      array: ->
        [ @x, @y, @z ]

    for method of PVector::
      PVector[method] = createPVectorMethod(method)  if PVector::hasOwnProperty(method) and not PVector.hasOwnProperty(method)
    PVector
  ()
  DefaultScope:: = PConstants
  defaultScope = new DefaultScope
  defaultScope.ArrayList = ArrayList
  defaultScope.HashMap = HashMap
  defaultScope.PVector = PVector
  defaultScope.ObjectIterator = ObjectIterator
  defaultScope.PConstants = PConstants
  defaultScope.defineProperty = (obj, name, desc) ->
    unless "defineProperty" of Object
      obj.__defineGetter__ name, desc.get  if desc.hasOwnProperty("get")
      obj.__defineSetter__ name, desc.set  if desc.hasOwnProperty("set")

  defaultScope.extendClassChain = (base) ->
    path = [ base ]
    self = base.$upcast

    while self
      extendClass self, base
      path.push self
      base = self
      self = self.$upcast
    path.pop().$self = base  while path.length > 0

  defaultScope.extendStaticMembers = (derived, base) ->
    extendClass derived, base

  defaultScope.extendInterfaceMembers = (derived, base) ->
    extendClass derived, base

  defaultScope.addMethod = (object, name, fn, hasMethodArgs) ->
    existingfn = object[name]
    if existingfn or hasMethodArgs
      args = fn.length
      unless "$overloads" of existingfn
        hubfn = ->
          fn = hubfn.$overloads[arguments.length] or ((if "$methodArgsIndex" of hubfn and arguments.length > hubfn.$methodArgsIndex then hubfn.$overloads[hubfn.$methodArgsIndex] else null)) or hubfn.$defaultOverload
          fn.apply this, arguments

        overloads = []
        overloads[existingfn.length] = existingfn  if existingfn
        overloads[args] = fn
        hubfn.$overloads = overloads
        hubfn.$defaultOverload = existingfn or fn
        hubfn.$methodArgsIndex = args  if hasMethodArgs
        hubfn.name = name
        object[name] = hubfn
    else
      object[name] = fn

  defaultScope.createJavaArray = (type, bounds) ->
    result = null
    defaultValue = null
    if typeof type is "string"
      if type is "boolean"
        defaultValue = false
      else defaultValue = 0  if isNumericalJavaType(type)
    if typeof bounds[0] is "number"
      itemsCount = 0 | bounds[0]
      if bounds.length <= 1
        result = []
        result.length = itemsCount
        i = 0

        while i < itemsCount
          result[i] = defaultValue
          ++i
      else
        result = []
        newBounds = bounds.slice(1)
        j = 0

        while j < itemsCount
          result.push defaultScope.createJavaArray(type, newBounds)
          ++j
    result

  colors =
    aliceblue: "#f0f8ff"
    antiquewhite: "#faebd7"
    aqua: "#00ffff"
    aquamarine: "#7fffd4"
    azure: "#f0ffff"
    beige: "#f5f5dc"
    bisque: "#ffe4c4"
    black: "#000000"
    blanchedalmond: "#ffebcd"
    blue: "#0000ff"
    blueviolet: "#8a2be2"
    brown: "#a52a2a"
    burlywood: "#deb887"
    cadetblue: "#5f9ea0"
    chartreuse: "#7fff00"
    chocolate: "#d2691e"
    coral: "#ff7f50"
    cornflowerblue: "#6495ed"
    cornsilk: "#fff8dc"
    crimson: "#dc143c"
    cyan: "#00ffff"
    darkblue: "#00008b"
    darkcyan: "#008b8b"
    darkgoldenrod: "#b8860b"
    darkgray: "#a9a9a9"
    darkgreen: "#006400"
    darkkhaki: "#bdb76b"
    darkmagenta: "#8b008b"
    darkolivegreen: "#556b2f"
    darkorange: "#ff8c00"
    darkorchid: "#9932cc"
    darkred: "#8b0000"
    darksalmon: "#e9967a"
    darkseagreen: "#8fbc8f"
    darkslateblue: "#483d8b"
    darkslategray: "#2f4f4f"
    darkturquoise: "#00ced1"
    darkviolet: "#9400d3"
    deeppink: "#ff1493"
    deepskyblue: "#00bfff"
    dimgray: "#696969"
    dodgerblue: "#1e90ff"
    firebrick: "#b22222"
    floralwhite: "#fffaf0"
    forestgreen: "#228b22"
    fuchsia: "#ff00ff"
    gainsboro: "#dcdcdc"
    ghostwhite: "#f8f8ff"
    gold: "#ffd700"
    goldenrod: "#daa520"
    gray: "#808080"
    green: "#008000"
    greenyellow: "#adff2f"
    honeydew: "#f0fff0"
    hotpink: "#ff69b4"
    indianred: "#cd5c5c"
    indigo: "#4b0082"
    ivory: "#fffff0"
    khaki: "#f0e68c"
    lavender: "#e6e6fa"
    lavenderblush: "#fff0f5"
    lawngreen: "#7cfc00"
    lemonchiffon: "#fffacd"
    lightblue: "#add8e6"
    lightcoral: "#f08080"
    lightcyan: "#e0ffff"
    lightgoldenrodyellow: "#fafad2"
    lightgrey: "#d3d3d3"
    lightgreen: "#90ee90"
    lightpink: "#ffb6c1"
    lightsalmon: "#ffa07a"
    lightseagreen: "#20b2aa"
    lightskyblue: "#87cefa"
    lightslategray: "#778899"
    lightsteelblue: "#b0c4de"
    lightyellow: "#ffffe0"
    lime: "#00ff00"
    limegreen: "#32cd32"
    linen: "#faf0e6"
    magenta: "#ff00ff"
    maroon: "#800000"
    mediumaquamarine: "#66cdaa"
    mediumblue: "#0000cd"
    mediumorchid: "#ba55d3"
    mediumpurple: "#9370d8"
    mediumseagreen: "#3cb371"
    mediumslateblue: "#7b68ee"
    mediumspringgreen: "#00fa9a"
    mediumturquoise: "#48d1cc"
    mediumvioletred: "#c71585"
    midnightblue: "#191970"
    mintcream: "#f5fffa"
    mistyrose: "#ffe4e1"
    moccasin: "#ffe4b5"
    navajowhite: "#ffdead"
    navy: "#000080"
    oldlace: "#fdf5e6"
    olive: "#808000"
    olivedrab: "#6b8e23"
    orange: "#ffa500"
    orangered: "#ff4500"
    orchid: "#da70d6"
    palegoldenrod: "#eee8aa"
    palegreen: "#98fb98"
    paleturquoise: "#afeeee"
    palevioletred: "#d87093"
    papayawhip: "#ffefd5"
    peachpuff: "#ffdab9"
    peru: "#cd853f"
    pink: "#ffc0cb"
    plum: "#dda0dd"
    powderblue: "#b0e0e6"
    purple: "#800080"
    red: "#ff0000"
    rosybrown: "#bc8f8f"
    royalblue: "#4169e1"
    saddlebrown: "#8b4513"
    salmon: "#fa8072"
    sandybrown: "#f4a460"
    seagreen: "#2e8b57"
    seashell: "#fff5ee"
    sienna: "#a0522d"
    silver: "#c0c0c0"
    skyblue: "#87ceeb"
    slateblue: "#6a5acd"
    slategray: "#708090"
    snow: "#fffafa"
    springgreen: "#00ff7f"
    steelblue: "#4682b4"
    tan: "#d2b48c"
    teal: "#008080"
    thistle: "#d8bfd8"
    tomato: "#ff6347"
    turquoise: "#40e0d0"
    violet: "#ee82ee"
    wheat: "#f5deb3"
    white: "#ffffff"
    whitesmoke: "#f5f5f5"
    yellow: "#ffff00"
    yellowgreen: "#9acd32"

  ((Processing) ->
    createUnsupportedFunc = (n) ->
      ->
        throw "Processing.js does not support " + n + "."
    unsupportedP5 = ("open() createOutput() createInput() BufferedReader selectFolder() " + "dataPath() createWriter() selectOutput() beginRecord() " + "saveStream() endRecord() selectInput() saveBytes() createReader() " + "beginRaw() endRaw() PrintWriter delay()").split(" ")
    count = unsupportedP5.length
    prettyName = undefined
    p5Name = undefined
    while count--
      prettyName = unsupportedP5[count]
      p5Name = prettyName.replace("()", "")
      Processing[p5Name] = createUnsupportedFunc(prettyName)
  ) defaultScope
  defaultScope.defineProperty defaultScope, "screenWidth",
    get: ->
      window.innerWidth

  defaultScope.defineProperty defaultScope, "screenHeight",
    get: ->
      window.innerHeight

  defaultScope.defineProperty defaultScope, "online",
    get: ->
      true

  processingInstances = []
  processingInstanceIds = {}
  removeInstance = (id) ->
    processingInstances.splice processingInstanceIds[id], 1
    delete processingInstanceIds[id]

  addInstance = (processing) ->
    processing.externals.canvas.id = "__processing" + processingInstances.length  if processing.externals.canvas.id is undef or not processing.externals.canvas.id.length
    processingInstanceIds[processing.externals.canvas.id] = processingInstances.length
    processingInstances.push processing

  PFont::caching = true
  PFont::getCSSDefinition = (fontSize, lineHeight) ->
    fontSize = @size + "px"  if fontSize is undef
    lineHeight = @leading + "px"  if lineHeight is undef
    components = [ @style, "normal", @weight, fontSize + "/" + lineHeight, @family ]
    components.join " "

  PFont::measureTextWidth = (string) ->
    @context2d.measureText(string).width

  PFont::measureTextWidthFallback = (string) ->
    canvas = document.createElement("canvas")
    ctx = canvas.getContext("2d")
    ctx.font = @css
    ctx.measureText(string).width

  PFont.PFontCache = length: 0
  PFont.get = (fontName, fontSize) ->
    fontSize = (fontSize * 10 + 0.5 | 0) / 10
    cache = PFont.PFontCache
    idx = fontName + "/" + fontSize
    unless cache[idx]
      cache[idx] = new PFont(fontName, fontSize)
      cache.length++
      if cache.length is 50
        PFont::measureTextWidth = PFont::measureTextWidthFallback
        PFont::caching = false
        entry = undefined
        for entry of cache
          cache[entry].context2d = null  if entry isnt "length"
        return new PFont(fontName, fontSize)
      if cache.length is 400
        PFont.PFontCache = {}
        PFont.get = PFont.getFallback
        return new PFont(fontName, fontSize)
    cache[idx]

  PFont.getFallback = (fontName, fontSize) ->
    new PFont(fontName, fontSize)

  PFont.list = ->
    [ "sans-serif", "serif", "monospace", "fantasy", "cursive" ]

  PFont.preloading =
    template: {}
    initialized: false
    initialize: ->
      generateTinyFont = ->
        encoded = "#E3KAI2wAgT1MvMg7Eo3VmNtYX7ABi3CxnbHlm" + "7Abw3kaGVhZ7ACs3OGhoZWE7A53CRobXR47AY3" + "AGbG9jYQ7G03Bm1heH7ABC3CBuYW1l7Ae3AgcG" + "9zd7AI3AE#B3AQ2kgTY18PPPUACwAg3ALSRoo3" + "#yld0xg32QAB77#E777773B#E3C#I#Q77773E#" + "Q7777777772CMAIw7AB77732B#M#Q3wAB#g3B#" + "E#E2BB//82BB////w#B7#gAEg3E77x2B32B#E#" + "Q#MTcBAQ32gAe#M#QQJ#E32M#QQJ#I#g32Q77#"
        expand = (input) ->
          "AAAAAAAA".substr (if ~~input then 7 - input else 6)

        encoded.replace /[#237]/g, expand

      fontface = document.createElement("style")
      fontface.setAttribute "type", "text/css"
      fontface.innerHTML = "@font-face {\n" + "  font-family: \"PjsEmptyFont\";" + "\n" + "  src: url('data:application/x-font-ttf;base64," + generateTinyFont() + "')\n" + "       format('truetype');\n" + "}"
      document.head.appendChild fontface
      element = document.createElement("span")
      element.style.cssText = "position: absolute; top: 0; left: 0; opacity: 0; font-family: \"PjsEmptyFont\", fantasy;"
      element.innerHTML = "AAAAAAAA"
      document.body.appendChild element
      @template = element
      @initialized = true

    getElementWidth: (element) ->
      document.defaultView.getComputedStyle(element, "").getPropertyValue "width"

    timeAttempted: 0
    pending: (intervallength) ->
      @initialize()  unless @initialized
      element = undefined
      computedWidthFont = undefined
      computedWidthRef = @getElementWidth(@template)
      i = 0

      while i < @fontList.length
        element = @fontList[i]
        computedWidthFont = @getElementWidth(element)
        if @timeAttempted < 4E3 and computedWidthFont is computedWidthRef
          @timeAttempted += intervallength
          return true
        else
          document.body.removeChild element
          @fontList.splice i--, 1
          @timeAttempted = 0
        i++
      return false  if @fontList.length is 0
      true

    fontList: []
    addedList: {}
    add: (fontSrc) ->
      @initialize()  unless @initialized
      fontName = (if typeof fontSrc is "object" then fontSrc.fontFace else fontSrc)
      fontUrl = (if typeof fontSrc is "object" then fontSrc.url else fontSrc)
      return  if @addedList[fontName]
      style = document.createElement("style")
      style.setAttribute "type", "text/css"
      style.innerHTML = "@font-face{\n  font-family: '" + fontName + "';\n  src:  url('" + fontUrl + "');\n}\n"
      document.head.appendChild style
      @addedList[fontName] = true
      element = document.createElement("span")
      element.style.cssText = "position: absolute; top: 0; left: 0; opacity: 0;"
      element.style.fontFamily = "\"" + fontName + "\", \"PjsEmptyFont\", fantasy"
      element.innerHTML = "AAAAAAAA"
      document.body.appendChild element
      @fontList.push element

  defaultScope.PFont = PFont
  Processing = @Processing = (aCanvas, aCode) ->
    unimplemented = (s) ->
      Processing.debug "Unimplemented - " + s
    uniformf = (cacheId, programObj, varName, varValue) ->
      varLocation = curContextCache.locations[cacheId]
      if varLocation is undef
        varLocation = curContext.getUniformLocation(programObj, varName)
        curContextCache.locations[cacheId] = varLocation
      if varLocation isnt null
        if varValue.length is 4
          curContext.uniform4fv varLocation, varValue
        else if varValue.length is 3
          curContext.uniform3fv varLocation, varValue
        else if varValue.length is 2
          curContext.uniform2fv varLocation, varValue
        else
          curContext.uniform1f varLocation, varValue
    uniformi = (cacheId, programObj, varName, varValue) ->
      varLocation = curContextCache.locations[cacheId]
      if varLocation is undef
        varLocation = curContext.getUniformLocation(programObj, varName)
        curContextCache.locations[cacheId] = varLocation
      if varLocation isnt null
        if varValue.length is 4
          curContext.uniform4iv varLocation, varValue
        else if varValue.length is 3
          curContext.uniform3iv varLocation, varValue
        else if varValue.length is 2
          curContext.uniform2iv varLocation, varValue
        else
          curContext.uniform1i varLocation, varValue
    uniformMatrix = (cacheId, programObj, varName, transpose, matrix) ->
      varLocation = curContextCache.locations[cacheId]
      if varLocation is undef
        varLocation = curContext.getUniformLocation(programObj, varName)
        curContextCache.locations[cacheId] = varLocation
      if varLocation isnt -1
        if matrix.length is 16
          curContext.uniformMatrix4fv varLocation, transpose, matrix
        else if matrix.length is 9
          curContext.uniformMatrix3fv varLocation, transpose, matrix
        else
          curContext.uniformMatrix2fv varLocation, transpose, matrix
    vertexAttribPointer = (cacheId, programObj, varName, size, VBO) ->
      varLocation = curContextCache.attributes[cacheId]
      if varLocation is undef
        varLocation = curContext.getAttribLocation(programObj, varName)
        curContextCache.attributes[cacheId] = varLocation
      if varLocation isnt -1
        curContext.bindBuffer curContext.ARRAY_BUFFER, VBO
        curContext.vertexAttribPointer varLocation, size, curContext.FLOAT, false, 0, 0
        curContext.enableVertexAttribArray varLocation
    disableVertexAttribPointer = (cacheId, programObj, varName) ->
      varLocation = curContextCache.attributes[cacheId]
      if varLocation is undef
        varLocation = curContext.getAttribLocation(programObj, varName)
        curContextCache.attributes[cacheId] = varLocation
      curContext.disableVertexAttribArray varLocation  if varLocation isnt -1
    color$4 = (aValue1, aValue2, aValue3, aValue4) ->
      r = undefined
      g = undefined
      b = undefined
      a = undefined
      if curColorMode is 3
        rgb = p.color.toRGB(aValue1, aValue2, aValue3)
        r = rgb[0]
        g = rgb[1]
        b = rgb[2]
      else
        r = Math.round(255 * (aValue1 / colorModeX))
        g = Math.round(255 * (aValue2 / colorModeY))
        b = Math.round(255 * (aValue3 / colorModeZ))
      a = Math.round(255 * (aValue4 / colorModeA))
      r = (if r < 0 then 0 else r)
      g = (if g < 0 then 0 else g)
      b = (if b < 0 then 0 else b)
      a = (if a < 0 then 0 else a)
      r = (if r > 255 then 255 else r)
      g = (if g > 255 then 255 else g)
      b = (if b > 255 then 255 else b)
      a = (if a > 255 then 255 else a)
      a << 24 & 4278190080 | r << 16 & 16711680 | g << 8 & 65280 | b & 255
    color$2 = (aValue1, aValue2) ->
      a = undefined
      if aValue1 & 4278190080
        a = Math.round(255 * (aValue2 / colorModeA))
        a = (if a > 255 then 255 else a)
        a = (if a < 0 then 0 else a)
        return aValue1 - (aValue1 & 4278190080) + (a << 24 & 4278190080)
      return color$4(aValue1, aValue1, aValue1, aValue2)  if curColorMode is 1
      color$4 0, 0, aValue1 / colorModeX * colorModeZ, aValue2  if curColorMode is 3
    color$1 = (aValue1) ->
      if aValue1 <= colorModeX and aValue1 >= 0
        return color$4(aValue1, aValue1, aValue1, colorModeA)  if curColorMode is 1
        return color$4(0, 0, aValue1 / colorModeX * colorModeZ, colorModeA)  if curColorMode is 3
      if aValue1
        aValue1 -= 4294967296  if aValue1 > 2147483647
        aValue1
    colorToHSB = (colorInt) ->
      red = undefined
      green = undefined
      blue = undefined
      red = ((colorInt >> 16) & 255) / 255
      green = ((colorInt >> 8) & 255) / 255
      blue = (colorInt & 255) / 255
      max = p.max(p.max(red, green), blue)
      min = p.min(p.min(red, green), blue)
      hue = undefined
      saturation = undefined
      return [ 0, 0, max * colorModeZ ]  if min is max
      saturation = (max - min) / max
      if red is max
        hue = (green - blue) / (max - min)
      else if green is max
        hue = 2 + (blue - red) / (max - min)
      else
        hue = 4 + (red - green) / (max - min)
      hue /= 6
      if hue < 0
        hue += 1
      else hue -= 1  if hue > 1
      [ hue * colorModeX, saturation * colorModeY, max * colorModeZ ]
    saveContext = ->
      curContext.save()
    restoreContext = ->
      curContext.restore()
      isStrokeDirty = true
      isFillDirty = true
    redrawHelper = ->
      sec = (Date.now() - timeSinceLastFPS) / 1E3
      framesSinceLastFPS++
      fps = framesSinceLastFPS / sec
      if sec > 0.5
        timeSinceLastFPS = Date.now()
        framesSinceLastFPS = 0
        p.__frameRate = fps
      p.frameCount++
    attachEventHandler = (elem, type, fn) ->
      if elem.addEventListener
        elem.addEventListener type, fn, false
      else
        elem.attachEvent "on" + type, fn
      eventHandlers.push
        elem: elem
        type: type
        fn: fn

    detachEventHandler = (eventHandler) ->
      elem = eventHandler.elem
      type = eventHandler.type
      fn = eventHandler.fn
      if elem.removeEventListener
        elem.removeEventListener type, fn, false
      else elem.detachEvent "on" + type, fn  if elem.detachEvent
    nfCoreScalar = (value, plus, minus, leftDigits, rightDigits, group) ->
      sign = (if value < 0 then minus else plus)
      autoDetectDecimals = rightDigits is 0
      rightDigitsOfDefault = (if rightDigits is undef or rightDigits < 0 then 0 else rightDigits)
      absValue = Math.abs(value)
      if autoDetectDecimals
        rightDigitsOfDefault = 1
        absValue *= 10
        while Math.abs(Math.round(absValue) - absValue) > 1.0E-6 and rightDigitsOfDefault < 7
          ++rightDigitsOfDefault
          absValue *= 10
      else absValue *= Math.pow(10, rightDigitsOfDefault)  if rightDigitsOfDefault isnt 0
      number = undefined
      doubled = absValue * 2
      if Math.floor(absValue) is absValue
        number = absValue
      else if Math.floor(doubled) is doubled
        floored = Math.floor(absValue)
        number = floored + floored % 2
      else
        number = Math.round(absValue)
      buffer = ""
      totalDigits = leftDigits + rightDigitsOfDefault
      while totalDigits > 0 or number > 0
        totalDigits--
        buffer = "" + number % 10 + buffer
        number = Math.floor(number / 10)
      if group isnt undef
        i = buffer.length - 3 - rightDigitsOfDefault
        while i > 0
          buffer = buffer.substring(0, i) + group + buffer.substring(i)
          i -= 3
      return sign + buffer.substring(0, buffer.length - rightDigitsOfDefault) + "." + buffer.substring(buffer.length - rightDigitsOfDefault, buffer.length)  if rightDigitsOfDefault > 0
      sign + buffer
    nfCore = (value, plus, minus, leftDigits, rightDigits, group) ->
      if value instanceof Array
        arr = []
        i = 0
        len = value.length

        while i < len
          arr.push nfCoreScalar(value[i], plus, minus, leftDigits, rightDigits, group)
          i++
        return arr
      nfCoreScalar value, plus, minus, leftDigits, rightDigits, group
    unhexScalar = (hex) ->
      value = parseInt("0x" + hex, 16)
      value -= 4294967296  if value > 2147483647
      value
    removeFirstArgument = (args) ->
      Array::slice.call args, 1
    booleanScalar = (val) ->
      return val isnt 0  if typeof val is "number"
      return val  if typeof val is "boolean"
      return val.toLowerCase() is "true"  if typeof val is "string"
      val.code is 49 or val.code is 84 or val.code is 116  if val instanceof Char
    floatScalar = (val) ->
      return val  if typeof val is "number"
      return (if val then 1 else 0)  if typeof val is "boolean"
      return parseFloat(val)  if typeof val is "string"
      val.code  if val instanceof Char
    intScalar = (val, radix) ->
      return val & 4294967295  if typeof val is "number"
      return (if val then 1 else 0)  if typeof val is "boolean"
      if typeof val is "string"
        number = parseInt(val, radix or 10)
        return number & 4294967295
      val.code  if val instanceof Char
    Marsaglia = (i1, i2) ->
      z = i1 or 362436069
      w = i2 or 521288629
      nextInt = ->
        z = 36969 * (z & 65535) + (z >>> 16) & 4294967295
        w = 18E3 * (w & 65535) + (w >>> 16) & 4294967295
        ((z & 65535) << 16 | w & 65535) & 4294967295

      @nextDouble = ->
        i = nextInt() / 4294967296
        (if i < 0 then 1 + i else i)

      @nextInt = nextInt
    PerlinNoise = (seed) ->
      grad3d = (i, x, y, z) ->
        h = i & 15
        u = (if h < 8 then x else y)
        v = (if h < 4 then y else (if h is 12 or h is 14 then x else z))
        ((if (h & 1) is 0 then u else -u)) + ((if (h & 2) is 0 then v else -v))
      grad2d = (i, x, y) ->
        v = (if (i & 1) is 0 then x else y)
        (if (i & 2) is 0 then -v else v)
      grad1d = (i, x) ->
        (if (i & 1) is 0 then -x else x)
      lerp = (t, a, b) ->
        a + t * (b - a)
      rnd = (if seed isnt undef then new Marsaglia(seed) else Marsaglia.createRandomized())
      i = undefined
      j = undefined
      perm = new Uint8Array(512)
      i = 0
      while i < 256
        perm[i] = i
        ++i
      i = 0
      while i < 256
        t = perm[j = rnd.nextInt() & 255]
        perm[j] = perm[i]
        perm[i] = t
        ++i
      i = 0
      while i < 256
        perm[i + 256] = perm[i]
        ++i
      @noise3d = (x, y, z) ->
        X = Math.floor(x) & 255
        Y = Math.floor(y) & 255
        Z = Math.floor(z) & 255
        x -= Math.floor(x)
        y -= Math.floor(y)
        z -= Math.floor(z)
        fx = (3 - 2 * x) * x * x
        fy = (3 - 2 * y) * y * y
        fz = (3 - 2 * z) * z * z
        p0 = perm[X] + Y
        p00 = perm[p0] + Z
        p01 = perm[p0 + 1] + Z
        p1 = perm[X + 1] + Y
        p10 = perm[p1] + Z
        p11 = perm[p1 + 1] + Z
        lerp fz, lerp(fy, lerp(fx, grad3d(perm[p00], x, y, z), grad3d(perm[p10], x - 1, y, z)), lerp(fx, grad3d(perm[p01], x, y - 1, z), grad3d(perm[p11], x - 1, y - 1, z))), lerp(fy, lerp(fx, grad3d(perm[p00 + 1], x, y, z - 1), grad3d(perm[p10 + 1], x - 1, y, z - 1)), lerp(fx, grad3d(perm[p01 + 1], x, y - 1, z - 1), grad3d(perm[p11 + 1], x - 1, y - 1, z - 1)))

      @noise2d = (x, y) ->
        X = Math.floor(x) & 255
        Y = Math.floor(y) & 255
        x -= Math.floor(x)
        y -= Math.floor(y)
        fx = (3 - 2 * x) * x * x
        fy = (3 - 2 * y) * y * y
        p0 = perm[X] + Y
        p1 = perm[X + 1] + Y
        lerp fy, lerp(fx, grad2d(perm[p0], x, y), grad2d(perm[p1], x - 1, y)), lerp(fx, grad2d(perm[p0 + 1], x, y - 1), grad2d(perm[p1 + 1], x - 1, y - 1))

      @noise1d = (x) ->
        X = Math.floor(x) & 255
        x -= Math.floor(x)
        fx = (3 - 2 * x) * x * x
        lerp fx, grad1d(perm[X], x), grad1d(perm[X + 1], x - 1)
    executeContextFill = ->
      if doFill
        if isFillDirty
          curContext.fillStyle = p.color.toString(currentFillColor)
          isFillDirty = false
        curContext.fill()
    executeContextStroke = ->
      if doStroke
        if isStrokeDirty
          curContext.strokeStyle = p.color.toString(currentStrokeColor)
          isStrokeDirty = false
        curContext.stroke()
    fillStrokeClose = ->
      executeContextFill()
      executeContextStroke()
      curContext.closePath()
    getCanvasData = (obj, w, h) ->
      canvasData = canvasDataCache.shift()
      if canvasData is undef
        canvasData = {}
        canvasData.canvas = document.createElement("canvas")
        canvasData.context = canvasData.canvas.getContext("2d")
      canvasDataCache.push canvasData
      canvas = canvasData.canvas
      context = canvasData.context
      width = w or obj.width
      height = h or obj.height
      canvas.width = width
      canvas.height = height
      unless obj
        context.clearRect 0, 0, width, height
      else unless "data" of obj
        context.clearRect 0, 0, width, height
        context.drawImage obj, 0, 0, width, height
      canvasData
    buildPixelsObject = (pImage) ->
      getLength: (aImg) ->
        ->
          if aImg.isRemote
            throw "Image is loaded remotely. Cannot get length."
          else
            (if aImg.imageData.data.length then aImg.imageData.data.length / 4 else 0)
      (pImage)
      getPixel: (aImg) ->
        (i) ->
          offset = i * 4
          data = aImg.imageData.data
          throw "Image is loaded remotely. Cannot get pixels."  if aImg.isRemote
          (data[offset + 3] & 255) << 24 | (data[offset] & 255) << 16 | (data[offset + 1] & 255) << 8 | data[offset + 2] & 255
      (pImage)
      setPixel: (aImg) ->
        (i, c) ->
          offset = i * 4
          data = aImg.imageData.data
          throw "Image is loaded remotely. Cannot set pixel."  if aImg.isRemote
          data[offset + 0] = (c >> 16) & 255
          data[offset + 1] = (c >> 8) & 255
          data[offset + 2] = c & 255
          data[offset + 3] = (c >> 24) & 255
          aImg.__isDirty = true
      (pImage)
      toArray: (aImg) ->
        ->
          arr = []
          data = aImg.imageData.data
          length = aImg.width * aImg.height
          throw "Image is loaded remotely. Cannot get pixels."  if aImg.isRemote
          i = 0
          offset = 0

          while i < length
            arr.push (data[offset + 3] & 255) << 24 | (data[offset] & 255) << 16 | (data[offset + 1] & 255) << 8 | data[offset + 2] & 255
            i++
            offset += 4
          arr
      (pImage)
      set: (aImg) ->
        (arr) ->
          offset = undefined
          data = undefined
          c = undefined
          throw "Image is loaded remotely. Cannot set pixels."  if @isRemote
          data = aImg.imageData.data
          i = 0
          aL = arr.length

          while i < aL
            c = arr[i]
            offset = i * 4
            data[offset + 0] = (c >> 16) & 255
            data[offset + 1] = (c >> 8) & 255
            data[offset + 2] = c & 255
            data[offset + 3] = (c >> 24) & 255
            i++
          aImg.__isDirty = true
      (pImage)
    get$2 = (x, y) ->
      data = undefined
      return 0  if x >= p.width or x < 0 or y < 0 or y >= p.height
      if isContextReplaced
        offset = ((0 | x) + p.width * (0 | y)) * 4
        data = p.imageData.data
        return (data[offset + 3] & 255) << 24 | (data[offset] & 255) << 16 | (data[offset + 1] & 255) << 8 | data[offset + 2] & 255
      data = p.toImageData(0 | x, 0 | y, 1, 1).data
      (data[3] & 255) << 24 | (data[0] & 255) << 16 | (data[1] & 255) << 8 | data[2] & 255
    get$3 = (x, y, img) ->
      throw "Image is loaded remotely. Cannot get x,y."  if img.isRemote
      offset = y * img.width * 4 + x * 4
      data = img.imageData.data
      (data[offset + 3] & 255) << 24 | (data[offset] & 255) << 16 | (data[offset + 1] & 255) << 8 | data[offset + 2] & 255
    get$4 = (x, y, w, h) ->
      c = new PImage(w, h, 2)
      c.fromImageData p.toImageData(x, y, w, h)
      c
    get$5 = (x, y, w, h, img) ->
      throw "Image is loaded remotely. Cannot get x,y,w,h."  if img.isRemote
      c = new PImage(w, h, 2)
      cData = c.imageData.data
      imgWidth = img.width
      imgHeight = img.height
      imgData = img.imageData.data
      startRow = Math.max(0, -y)
      startColumn = Math.max(0, -x)
      stopRow = Math.min(h, imgHeight - y)
      stopColumn = Math.min(w, imgWidth - x)
      i = startRow

      while i < stopRow
        sourceOffset = ((y + i) * imgWidth + (x + startColumn)) * 4
        targetOffset = (i * w + startColumn) * 4
        j = startColumn

        while j < stopColumn
          cData[targetOffset++] = imgData[sourceOffset++]
          cData[targetOffset++] = imgData[sourceOffset++]
          cData[targetOffset++] = imgData[sourceOffset++]
          cData[targetOffset++] = imgData[sourceOffset++]
          ++j
        ++i
      c.__isDirty = true
      c
    resetContext = ->
      if isContextReplaced
        curContext = originalContext
        isContextReplaced = false
        p.updatePixels()
    SetPixelContextWrapper = ->
      wrapFunction = (newContext, name) ->
        wrapper = ->
          resetContext()
          curContext[name].apply curContext, arguments
        newContext[name] = wrapper
      wrapProperty = (newContext, name) ->
        getter = ->
          resetContext()
          curContext[name]
        setter = (value) ->
          resetContext()
          curContext[name] = value
        p.defineProperty newContext, name,
          get: getter
          set: setter

      for n of curContext
        if typeof curContext[n] is "function"
          wrapFunction this, n
        else
          wrapProperty this, n
    replaceContext = ->
      return  if isContextReplaced
      p.loadPixels()
      if proxyContext is null
        originalContext = curContext
        proxyContext = new SetPixelContextWrapper
      isContextReplaced = true
      curContext = proxyContext
      setPixelsCached = 0
    set$3 = (x, y, c) ->
      if x < p.width and x >= 0 and y >= 0 and y < p.height
        replaceContext()
        p.pixels.setPixel (0 | x) + p.width * (0 | y), c
        resetContext()  if ++setPixelsCached > maxPixelsCached
    set$4 = (x, y, obj, img) ->
      throw "Image is loaded remotely. Cannot set x,y."  if img.isRemote
      c = p.color.toArray(obj)
      offset = y * img.width * 4 + x * 4
      data = img.imageData.data
      data[offset] = c[0]
      data[offset + 1] = c[1]
      data[offset + 2] = c[2]
      data[offset + 3] = c[3]
    toP5String = (obj) ->
      return obj  if obj instanceof String
      if typeof obj is "number"
        return obj.toString()  if obj is (0 | obj)
        return p.nf(obj, 0, 3)
      return ""  if obj is null or obj is undef
      obj.toString()
    text$4 = (str, x, y, z) ->
      lines = undefined
      linesCount = undefined
      if str.indexOf("\n") < 0
        lines = [ str ]
        linesCount = 1
      else
        lines = str.split(/\r?\n/g)
        linesCount = lines.length
      yOffset = 0
      if verticalTextAlignment is 101
        yOffset = curTextAscent + curTextDescent
      else if verticalTextAlignment is 3
        yOffset = curTextAscent / 2 - (linesCount - 1) * curTextLeading / 2
      else yOffset = -(curTextDescent + (linesCount - 1) * curTextLeading)  if verticalTextAlignment is 102
      i = 0

      while i < linesCount
        line = lines[i]
        drawing.text$line line, x, y + yOffset, z, horizontalTextAlignment
        yOffset += curTextLeading
        ++i
    text$6 = (str, x, y, width, height, z) ->
      return  if str.length is 0 or width is 0 or height is 0
      return  if curTextSize > height
      spaceMark = -1
      start = 0
      lineWidth = 0
      drawCommands = []
      charPos = 0
      len = str.length

      while charPos < len
        currentChar = str[charPos]
        spaceChar = currentChar is " "
        letterWidth = curTextFont.measureTextWidth(currentChar)
        if currentChar isnt "\n" and lineWidth + letterWidth <= width
          spaceMark = charPos  if spaceChar
          lineWidth += letterWidth
        else
          if spaceMark + 1 is start
            if charPos > 0
              spaceMark = charPos
            else
              return
          if currentChar is "\n"
            drawCommands.push
              text: str.substring(start, charPos)
              width: lineWidth

            start = charPos + 1
          else
            drawCommands.push
              text: str.substring(start, spaceMark + 1)
              width: lineWidth

            start = spaceMark + 1
          lineWidth = 0
          charPos = start - 1
        charPos++
      if start < len
        drawCommands.push
          text: str.substring(start)
          width: lineWidth

      xOffset = 1
      yOffset = curTextAscent
      if horizontalTextAlignment is 3
        xOffset = width / 2
      else xOffset = width  if horizontalTextAlignment is 39
      linesCount = drawCommands.length
      visibleLines = Math.min(linesCount, Math.floor(height / curTextLeading))
      if verticalTextAlignment is 101
        yOffset = curTextAscent + curTextDescent
      else if verticalTextAlignment is 3
        yOffset = height / 2 - curTextLeading * (visibleLines / 2 - 1)
      else yOffset = curTextDescent + curTextLeading  if verticalTextAlignment is 102
      command = undefined
      drawCommand = undefined
      leading = undefined
      command = 0
      while command < linesCount
        leading = command * curTextLeading
        break  if yOffset + leading > height - curTextDescent
        drawCommand = drawCommands[command]
        drawing.text$line drawCommand.text, x + xOffset, y + yOffset + leading, z, horizontalTextAlignment
        command++
    wireDimensionalFunctions = (mode) ->
      if mode is "3D"
        drawing = new Drawing3D
      else if mode is "2D"
        drawing = new Drawing2D
      else
        drawing = new DrawingPre
      for i of DrawingPre::
        p[i] = drawing[i]  if DrawingPre::hasOwnProperty(i) and i.indexOf("$") < 0
      drawing.$init()
    createDrawingPreFunction = (name) ->
      ->
        wireDimensionalFunctions "2D"
        drawing[name].apply this, arguments
    calculateOffset = (curElement, event) ->
      element = curElement
      offsetX = 0
      offsetY = 0
      p.pmouseX = p.mouseX
      p.pmouseY = p.mouseY
      if element.offsetParent
        loop
          offsetX += element.offsetLeft
          offsetY += element.offsetTop
          break unless !!(element = element.offsetParent)
      element = curElement
      loop
        offsetX -= element.scrollLeft or 0
        offsetY -= element.scrollTop or 0
        break unless !!(element = element.parentNode)
      offsetX += stylePaddingLeft
      offsetY += stylePaddingTop
      offsetX += styleBorderLeft
      offsetY += styleBorderTop
      offsetX += window.pageXOffset
      offsetY += window.pageYOffset
      X: offsetX
      Y: offsetY
    updateMousePosition = (curElement, event) ->
      offset = calculateOffset(curElement, event)
      p.mouseX = event.pageX - offset.X
      p.mouseY = event.pageY - offset.Y
    addTouchEventOffset = (t) ->
      offset = calculateOffset(t.changedTouches[0].target, t.changedTouches[0])
      i = undefined
      i = 0
      while i < t.touches.length
        touch = t.touches[i]
        touch.offsetX = touch.pageX - offset.X
        touch.offsetY = touch.pageY - offset.Y
        i++
      i = 0
      while i < t.targetTouches.length
        targetTouch = t.targetTouches[i]
        targetTouch.offsetX = targetTouch.pageX - offset.X
        targetTouch.offsetY = targetTouch.pageY - offset.Y
        i++
      i = 0
      while i < t.changedTouches.length
        changedTouch = t.changedTouches[i]
        changedTouch.offsetX = changedTouch.pageX - offset.X
        changedTouch.offsetY = changedTouch.pageY - offset.Y
        i++
      t
    getKeyCode = (e) ->
      code = e.which or e.keyCode
      switch code
        when 13
          return 10
        when 91, 93
      , 224
          return 157
        when 57392
          return 17
        when 46
          return 127
        when 45
          return 155
      code
    getKeyChar = (e) ->
      c = e.which or e.keyCode
      anyShiftPressed = e.shiftKey or e.ctrlKey or e.altKey or e.metaKey
      switch c
        when 13
          c = (if anyShiftPressed then 13 else 10)
        when 8
          c = (if anyShiftPressed then 127 else 8)
      new Char(c)
    suppressKeyEvent = (e) ->
      if typeof e.preventDefault is "function"
        e.preventDefault()
      else e.stopPropagation()  if typeof e.stopPropagation is "function"
      false
    updateKeyPressed = ->
      ch = undefined
      for ch of pressedKeysMap
        if pressedKeysMap.hasOwnProperty(ch)
          p.__keyPressed = true
          return
      p.__keyPressed = false
    resetKeyPressed = ->
      p.__keyPressed = false
      pressedKeysMap = []
      lastPressedKeyCode = null
    simulateKeyTyped = (code, c) ->
      pressedKeysMap[code] = c
      lastPressedKeyCode = null
      p.key = c
      p.keyCode = code
      p.keyPressed()
      p.keyCode = 0
      p.keyTyped()
      updateKeyPressed()
    handleKeydown = (e) ->
      code = getKeyCode(e)
      if code is 127
        simulateKeyTyped code, new Char(127)
        return
      if codedKeys.indexOf(code) < 0
        lastPressedKeyCode = code
        return
      c = new Char(65535)
      p.key = c
      p.keyCode = code
      pressedKeysMap[code] = c
      p.keyPressed()
      lastPressedKeyCode = null
      updateKeyPressed()
      suppressKeyEvent e
    handleKeypress = (e) ->
      return  if lastPressedKeyCode is null
      code = lastPressedKeyCode
      c = getKeyChar(e)
      simulateKeyTyped code, c
      suppressKeyEvent e
    handleKeyup = (e) ->
      code = getKeyCode(e)
      c = pressedKeysMap[code]
      return  if c is undef
      p.key = c
      p.keyCode = code
      p.keyReleased()
      delete pressedKeysMap[code]

      updateKeyPressed()
    throw "called Processing constructor as if it were a function: missing 'new'."  unless this instanceof Processing
    curElement = undefined
    pgraphicsMode = aCanvas is undef and aCode is undef
    if pgraphicsMode
      curElement = document.createElement("canvas")
    else
      curElement = (if typeof aCanvas is "string" then document.getElementById(aCanvas) else aCanvas)
    throw "called Processing constructor without passing canvas element reference or id."  unless curElement instanceof HTMLCanvasElement
    p = this
    p.externals =
      canvas: curElement
      context: undef
      sketch: undef

    p.name = "Processing.js Instance"
    p.use3DContext = false
    p.focused = false
    p.breakShape = false
    p.glyphTable = {}
    p.pmouseX = 0
    p.pmouseY = 0
    p.mouseX = 0
    p.mouseY = 0
    p.mouseButton = 0
    p.mouseScroll = 0
    p.mouseClicked = undef
    p.mouseDragged = undef
    p.mouseMoved = undef
    p.mousePressed = undef
    p.mouseReleased = undef
    p.mouseScrolled = undef
    p.mouseOver = undef
    p.mouseOut = undef
    p.touchStart = undef
    p.touchEnd = undef
    p.touchMove = undef
    p.touchCancel = undef
    p.key = undef
    p.keyCode = undef
    p.keyPressed = nop
    p.keyReleased = nop
    p.keyTyped = nop
    p.draw = undef
    p.setup = undef
    p.__mousePressed = false
    p.__keyPressed = false
    p.__frameRate = 60
    p.frameCount = 0
    p.width = 100
    p.height = 100
    curContext = undefined
    curSketch = undefined
    drawing = undefined
    online = true
    doFill = true
    fillStyle = [ 1, 1, 1, 1 ]
    currentFillColor = 4294967295
    isFillDirty = true
    doStroke = true
    strokeStyle = [ 0, 0, 0, 1 ]
    currentStrokeColor = 4278190080
    isStrokeDirty = true
    lineWidth = 1
    loopStarted = false
    renderSmooth = false
    doLoop = true
    looping = 0
    curRectMode = 0
    curEllipseMode = 3
    normalX = 0
    normalY = 0
    normalZ = 0
    normalMode = 0
    curFrameRate = 60
    curMsPerFrame = 1E3 / curFrameRate
    curCursor = "default"
    oldCursor = curElement.style.cursor
    curShape = 20
    curShapeCount = 0
    curvePoints = []
    curTightness = 0
    curveDet = 20
    curveInited = false
    backgroundObj = -3355444
    bezDetail = 20
    colorModeA = 255
    colorModeX = 255
    colorModeY = 255
    colorModeZ = 255
    pathOpen = false
    mouseDragging = false
    pmouseXLastFrame = 0
    pmouseYLastFrame = 0
    curColorMode = 1
    curTint = null
    curTint3d = null
    getLoaded = false
    start = Date.now()
    timeSinceLastFPS = start
    framesSinceLastFPS = 0
    textcanvas = undefined
    curveBasisMatrix = undefined
    curveToBezierMatrix = undefined
    curveDrawMatrix = undefined
    bezierDrawMatrix = undefined
    bezierBasisInverse = undefined
    bezierBasisMatrix = undefined
    curContextCache =
      attributes: {}
      locations: {}

    programObject3D = undefined
    programObject2D = undefined
    programObjectUnlitShape = undefined
    boxBuffer = undefined
    boxNormBuffer = undefined
    boxOutlineBuffer = undefined
    rectBuffer = undefined
    rectNormBuffer = undefined
    sphereBuffer = undefined
    lineBuffer = undefined
    fillBuffer = undefined
    fillColorBuffer = undefined
    strokeColorBuffer = undefined
    pointBuffer = undefined
    shapeTexVBO = undefined
    canTex = undefined
    textTex = undefined
    curTexture =
      width: 0
      height: 0

    curTextureMode = 2
    usingTexture = false
    textBuffer = undefined
    textureBuffer = undefined
    indexBuffer = undefined
    horizontalTextAlignment = 37
    verticalTextAlignment = 0
    textMode = 4
    curFontName = "Arial"
    curTextSize = 12
    curTextAscent = 9
    curTextDescent = 2
    curTextLeading = 14
    curTextFont = PFont.get(curFontName, curTextSize)
    originalContext = undefined
    proxyContext = null
    isContextReplaced = false
    setPixelsCached = undefined
    maxPixelsCached = 1E3
    pressedKeysMap = []
    lastPressedKeyCode = null
    codedKeys = [ 16, 17, 18, 20, 33, 34, 35, 36, 37, 38, 39, 40, 144, 155, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 157 ]
    stylePaddingLeft = undefined
    stylePaddingTop = undefined
    styleBorderLeft = undefined
    styleBorderTop = undefined
    if document.defaultView and document.defaultView.getComputedStyle
      stylePaddingLeft = parseInt(document.defaultView.getComputedStyle(curElement, null)["paddingLeft"], 10) or 0
      stylePaddingTop = parseInt(document.defaultView.getComputedStyle(curElement, null)["paddingTop"], 10) or 0
      styleBorderLeft = parseInt(document.defaultView.getComputedStyle(curElement, null)["borderLeftWidth"], 10) or 0
      styleBorderTop = parseInt(document.defaultView.getComputedStyle(curElement, null)["borderTopWidth"], 10) or 0
    lightCount = 0
    sphereDetailV = 0
    sphereDetailU = 0
    sphereX = []
    sphereY = []
    sphereZ = []
    sinLUT = new Float32Array(720)
    cosLUT = new Float32Array(720)
    sphereVerts = undefined
    sphereNorms = undefined
    cam = undefined
    cameraInv = undefined
    modelView = undefined
    modelViewInv = undefined
    userMatrixStack = undefined
    userReverseMatrixStack = undefined
    inverseCopy = undefined
    projection = undefined
    manipulatingCamera = false
    frustumMode = false
    cameraFOV = 60 * (Math.PI / 180)
    cameraX = p.width / 2
    cameraY = p.height / 2
    cameraZ = cameraY / Math.tan(cameraFOV / 2)
    cameraNear = cameraZ / 10
    cameraFar = cameraZ * 10
    cameraAspect = p.width / p.height
    vertArray = []
    curveVertArray = []
    curveVertCount = 0
    isCurve = false
    isBezier = false
    firstVert = true
    curShapeMode = 0
    styleArray = []
    boxVerts = new Float32Array([ 0.5, 0.5, -0.5, 0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, -0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, 0.5, -0.5, 0.5, -0.5, -0.5, 0.5, -0.5, 0.5, -0.5, -0.5, 0.5, -0.5, -0.5, 0.5, -0.5, -0.5, -0.5, 0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5, -0.5, -0.5, -0.5, -0.5, 0.5, 0.5, 0.5, 0.5, 0.5, -0.5, -0.5, 0.5, -0.5, -0.5, 0.5, -0.5, -0.5, 0.5, 0.5, 0.5, 0.5, 0.5 ])
    boxOutlineVerts = new Float32Array([ 0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, -0.5, 0.5, -0.5, -0.5, -0.5, 0.5, -0.5, -0.5, -0.5, -0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, -0.5, -0.5, 0.5, -0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, 0.5, -0.5, -0.5, 0.5, 0.5, -0.5, 0.5 ])
    boxNorms = new Float32Array([ 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0 ])
    rectVerts = new Float32Array([ 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0 ])
    rectNorms = new Float32Array([ 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1 ])
    vertexShaderSrcUnlitShape = "varying vec4 vFrontColor;" + "attribute vec3 aVertex;" + "attribute vec4 aColor;" + "uniform mat4 uView;" + "uniform mat4 uProjection;" + "uniform float uPointSize;" + "void main(void) {" + "  vFrontColor = aColor;" + "  gl_PointSize = uPointSize;" + "  gl_Position = uProjection * uView * vec4(aVertex, 1.0);" + "}"
    fragmentShaderSrcUnlitShape = "#ifdef GL_ES\n" + "precision highp float;\n" + "#endif\n" + "varying vec4 vFrontColor;" + "uniform bool uSmooth;" + "void main(void){" + "  if(uSmooth == true){" + "    float dist = distance(gl_PointCoord, vec2(0.5));" + "    if(dist > 0.5){" + "      discard;" + "    }" + "  }" + "  gl_FragColor = vFrontColor;" + "}"
    vertexShaderSrc2D = "varying vec4 vFrontColor;" + "attribute vec3 aVertex;" + "attribute vec2 aTextureCoord;" + "uniform vec4 uColor;" + "uniform mat4 uModel;" + "uniform mat4 uView;" + "uniform mat4 uProjection;" + "uniform float uPointSize;" + "varying vec2 vTextureCoord;" + "void main(void) {" + "  gl_PointSize = uPointSize;" + "  vFrontColor = uColor;" + "  gl_Position = uProjection * uView * uModel * vec4(aVertex, 1.0);" + "  vTextureCoord = aTextureCoord;" + "}"
    fragmentShaderSrc2D = "#ifdef GL_ES\n" + "precision highp float;\n" + "#endif\n" + "varying vec4 vFrontColor;" + "varying vec2 vTextureCoord;" + "uniform sampler2D uSampler;" + "uniform int uIsDrawingText;" + "uniform bool uSmooth;" + "void main(void){" + "  if(uSmooth == true){" + "    float dist = distance(gl_PointCoord, vec2(0.5));" + "    if(dist > 0.5){" + "      discard;" + "    }" + "  }" + "  if(uIsDrawingText == 1){" + "    float alpha = texture2D(uSampler, vTextureCoord).a;" + "    gl_FragColor = vec4(vFrontColor.rgb * alpha, alpha);" + "  }" + "  else{" + "    gl_FragColor = vFrontColor;" + "  }" + "}"
    webglMaxTempsWorkaround = /Windows/.test(navigator.userAgent)
    vertexShaderSrc3D = "varying vec4 vFrontColor;" + "attribute vec3 aVertex;" + "attribute vec3 aNormal;" + "attribute vec4 aColor;" + "attribute vec2 aTexture;" + "varying   vec2 vTexture;" + "uniform vec4 uColor;" + "uniform bool uUsingMat;" + "uniform vec3 uSpecular;" + "uniform vec3 uMaterialEmissive;" + "uniform vec3 uMaterialAmbient;" + "uniform vec3 uMaterialSpecular;" + "uniform float uShininess;" + "uniform mat4 uModel;" + "uniform mat4 uView;" + "uniform mat4 uProjection;" + "uniform mat4 uNormalTransform;" + "uniform int uLightCount;" + "uniform vec3 uFalloff;" + "struct Light {" + "  int type;" + "  vec3 color;" + "  vec3 position;" + "  vec3 direction;" + "  float angle;" + "  vec3 halfVector;" + "  float concentration;" + "};" + "uniform Light uLights0;" + "uniform Light uLights1;" + "uniform Light uLights2;" + "uniform Light uLights3;" + "uniform Light uLights4;" + "uniform Light uLights5;" + "uniform Light uLights6;" + "uniform Light uLights7;" + "Light getLight(int index){" + "  if(index == 0) return uLights0;" + "  if(index == 1) return uLights1;" + "  if(index == 2) return uLights2;" + "  if(index == 3) return uLights3;" + "  if(index == 4) return uLights4;" + "  if(index == 5) return uLights5;" + "  if(index == 6) return uLights6;" + "  return uLights7;" + "}" + "void AmbientLight( inout vec3 totalAmbient, in vec3 ecPos, in Light light ) {" + "  float d = length( light.position - ecPos );" + "  float attenuation = 1.0 / ( uFalloff[0] + ( uFalloff[1] * d ) + ( uFalloff[2] * d * d ));" + "  totalAmbient += light.color * attenuation;" + "}" + "void DirectionalLight( inout vec3 col, inout vec3 spec, in vec3 vertNormal, in vec3 ecPos, in Light light ) {" + "  float powerFactor = 0.0;" + "  float nDotVP = max(0.0, dot( vertNormal, normalize(-light.position) ));" + "  float nDotVH = max(0.0, dot( vertNormal, normalize(-light.position-normalize(ecPos) )));" + "  if( nDotVP != 0.0 ){" + "    powerFactor = pow( nDotVH, uShininess );" + "  }" + "  col += light.color * nDotVP;" + "  spec += uSpecular * powerFactor;" + "}" + "void PointLight( inout vec3 col, inout vec3 spec, in vec3 vertNormal, in vec3 ecPos, in Light light ) {" + "  float powerFactor;" + "   vec3 VP = light.position - ecPos;" + "  float d = length( VP ); " + "  VP = normalize( VP );" + "  float attenuation = 1.0 / ( uFalloff[0] + ( uFalloff[1] * d ) + ( uFalloff[2] * d * d ));" + "  float nDotVP = max( 0.0, dot( vertNormal, VP ));" + "  vec3 halfVector = normalize( VP - normalize(ecPos) );" + "  float nDotHV = max( 0.0, dot( vertNormal, halfVector ));" + "  if( nDotVP == 0.0 ) {" + "    powerFactor = 0.0;" + "  }" + "  else {" + "    powerFactor = pow( nDotHV, uShininess );" + "  }" + "  spec += uSpecular * powerFactor * attenuation;" + "  col += light.color * nDotVP * attenuation;" + "}" + "void SpotLight( inout vec3 col, inout vec3 spec, in vec3 vertNormal, in vec3 ecPos, in Light light ) {" + "  float spotAttenuation;" + "  float powerFactor = 0.0;" + "  vec3 VP = light.position - ecPos;" + "  vec3 ldir = normalize( -light.direction );" + "  float d = length( VP );" + "  VP = normalize( VP );" + "  float attenuation = 1.0 / ( uFalloff[0] + ( uFalloff[1] * d ) + ( uFalloff[2] * d * d ) );" + "  float spotDot = dot( VP, ldir );" + ((if webglMaxTempsWorkaround then "  spotAttenuation = 1.0; " else "  if( spotDot > cos( light.angle ) ) {" + "    spotAttenuation = pow( spotDot, light.concentration );" + "  }" + "  else{" + "    spotAttenuation = 0.0;" + "  }" + "  attenuation *= spotAttenuation;" + "")) + "  float nDotVP = max( 0.0, dot( vertNormal, VP ) );" + "  vec3 halfVector = normalize( VP - normalize(ecPos) );" + "  float nDotHV = max( 0.0, dot( vertNormal, halfVector ) );" + "  if( nDotVP != 0.0 ) {" + "    powerFactor = pow( nDotHV, uShininess );" + "  }" + "  spec += uSpecular * powerFactor * attenuation;" + "  col += light.color * nDotVP * attenuation;" + "}" + "void main(void) {" + "  vec3 finalAmbient = vec3( 0.0 );" + "  vec3 finalDiffuse = vec3( 0.0 );" + "  vec3 finalSpecular = vec3( 0.0 );" + "  vec4 col = uColor;" + "  if ( uColor[0] == -1.0 ){" + "    col = aColor;" + "  }" + "  vec3 norm = normalize(vec3( uNormalTransform * vec4( aNormal, 0.0 ) ));" + "  vec4 ecPos4 = uView * uModel * vec4(aVertex, 1.0);" + "  vec3 ecPos = (vec3(ecPos4))/ecPos4.w;" + "  if( uLightCount == 0 ) {" + "    vFrontColor = col + vec4(uMaterialSpecular, 1.0);" + "  }" + "  else {" + "    for( int i = 0; i < 8; i++ ) {" + "      Light l = getLight(i);" + "      if( i >= uLightCount ){" + "        break;" + "      }" + "      if( l.type == 0 ) {" + "        AmbientLight( finalAmbient, ecPos, l );" + "      }" + "      else if( l.type == 1 ) {" + "        DirectionalLight( finalDiffuse, finalSpecular, norm, ecPos, l );" + "      }" + "      else if( l.type == 2 ) {" + "        PointLight( finalDiffuse, finalSpecular, norm, ecPos, l );" + "      }" + "      else {" + "        SpotLight( finalDiffuse, finalSpecular, norm, ecPos, l );" + "      }" + "    }" + "   if( uUsingMat == false ) {" + "     vFrontColor = vec4(" + "       vec3( col ) * finalAmbient +" + "       vec3( col ) * finalDiffuse +" + "       vec3( col ) * finalSpecular," + "       col[3] );" + "   }" + "   else{" + "     vFrontColor = vec4( " + "       uMaterialEmissive + " + "       (vec3(col) * uMaterialAmbient * finalAmbient ) + " + "       (vec3(col) * finalDiffuse) + " + "       (uMaterialSpecular * finalSpecular), " + "       col[3] );" + "    }" + "  }" + "  vTexture.xy = aTexture.xy;" + "  gl_Position = uProjection * uView * uModel * vec4( aVertex, 1.0 );" + "}"
    fragmentShaderSrc3D = "#ifdef GL_ES\n" + "precision highp float;\n" + "#endif\n" + "varying vec4 vFrontColor;" + "uniform sampler2D uSampler;" + "uniform bool uUsingTexture;" + "varying vec2 vTexture;" + "void main(void){" + "  if( uUsingTexture ){" + "    gl_FragColor = vec4(texture2D(uSampler, vTexture.xy)) * vFrontColor;" + "  }" + "  else{" + "    gl_FragColor = vFrontColor;" + "  }" + "}"
    createProgramObject = (curContext, vetexShaderSource, fragmentShaderSource) ->
      vertexShaderObject = curContext.createShader(curContext.VERTEX_SHADER)
      curContext.shaderSource vertexShaderObject, vetexShaderSource
      curContext.compileShader vertexShaderObject
      throw curContext.getShaderInfoLog(vertexShaderObject)  unless curContext.getShaderParameter(vertexShaderObject, curContext.COMPILE_STATUS)
      fragmentShaderObject = curContext.createShader(curContext.FRAGMENT_SHADER)
      curContext.shaderSource fragmentShaderObject, fragmentShaderSource
      curContext.compileShader fragmentShaderObject
      throw curContext.getShaderInfoLog(fragmentShaderObject)  unless curContext.getShaderParameter(fragmentShaderObject, curContext.COMPILE_STATUS)
      programObject = curContext.createProgram()
      curContext.attachShader programObject, vertexShaderObject
      curContext.attachShader programObject, fragmentShaderObject
      curContext.linkProgram programObject
      throw "Error linking shaders."  unless curContext.getProgramParameter(programObject, curContext.LINK_STATUS)
      programObject

    imageModeCorner = (x, y, w, h, whAreSizes) ->
      x: x
      y: y
      w: w
      h: h

    imageModeConvert = imageModeCorner
    imageModeCorners = (x, y, w, h, whAreSizes) ->
      x: x
      y: y
      w: (if whAreSizes then w else w - x)
      h: (if whAreSizes then h else h - y)

    imageModeCenter = (x, y, w, h, whAreSizes) ->
      x: x - w / 2
      y: y - h / 2
      w: w
      h: h

    DrawingShared = ->

    Drawing2D = ->

    Drawing3D = ->

    DrawingPre = ->

    Drawing2D:: = new DrawingShared
    Drawing2D::constructor = Drawing2D
    Drawing3D:: = new DrawingShared
    Drawing3D::constructor = Drawing3D
    DrawingPre:: = new DrawingShared
    DrawingPre::constructor = DrawingPre
    DrawingShared::a3DOnlyFunction = nop
    charMap = {}
    Char = p.Character = (chr) ->
      if typeof chr is "string" and chr.length is 1
        @code = chr.charCodeAt(0)
      else if typeof chr is "number"
        @code = chr
      else if chr instanceof Char
        @code = chr
      else
        @code = NaN
      (if charMap[@code] is undef then charMap[@code] = this else charMap[@code])

    Char::toString = ->
      String.fromCharCode @code

    Char::valueOf = ->
      @code

    PShape = p.PShape = (family) ->
      @family = family or 0
      @visible = true
      @style = true
      @children = []
      @nameTable = []
      @params = []
      @name = ""
      @image = null
      @matrix = null
      @kind = null
      @close = null
      @width = null
      @height = null
      @parent = null

    PShape:: =
      isVisible: ->
        @visible

      setVisible: (visible) ->
        @visible = visible

      disableStyle: ->
        @style = false
        i = 0
        j = @children.length

        while i < j
          @children[i].disableStyle()
          i++

      enableStyle: ->
        @style = true
        i = 0
        j = @children.length

        while i < j
          @children[i].enableStyle()
          i++

      getFamily: ->
        @family

      getWidth: ->
        @width

      getHeight: ->
        @height

      setName: (name) ->
        @name = name

      getName: ->
        @name

      draw: (renderContext) ->
        renderContext = renderContext or p
        if @visible
          @pre renderContext
          @drawImpl renderContext
          @post renderContext

      drawImpl: (renderContext) ->
        if @family is 0
          @drawGroup renderContext
        else if @family is 1
          @drawPrimitive renderContext
        else if @family is 3
          @drawGeometry renderContext
        else @drawPath renderContext  if @family is 21

      drawPath: (renderContext) ->
        i = undefined
        j = undefined
        return  if @vertices.length is 0
        renderContext.beginShape()
        unless @vertexCodes.length is 0
          index = 0
          if @vertices[0].length is 2
            i = 0
            j = @vertexCodes.length

            while i < j
              if @vertexCodes[i] is 0
                renderContext.vertex @vertices[index][0], @vertices[index][1], @vertices[index]["moveTo"]
                renderContext.breakShape = false
                index++
              else if @vertexCodes[i] is 1
                renderContext.bezierVertex @vertices[index + 0][0], @vertices[index + 0][1], @vertices[index + 1][0], @vertices[index + 1][1], @vertices[index + 2][0], @vertices[index + 2][1]
                index += 3
              else if @vertexCodes[i] is 2
                renderContext.curveVertex @vertices[index][0], @vertices[index][1]
                index++
              else
                renderContext.breakShape = true  if @vertexCodes[i] is 3
              i++
          else
            i = 0
            j = @vertexCodes.length

            while i < j
              if @vertexCodes[i] is 0
                renderContext.vertex @vertices[index][0], @vertices[index][1], @vertices[index][2]
                if @vertices[index]["moveTo"] is true
                  vertArray[vertArray.length - 1]["moveTo"] = true
                else vertArray[vertArray.length - 1]["moveTo"] = false  if @vertices[index]["moveTo"] is false
                renderContext.breakShape = false
              else if @vertexCodes[i] is 1
                renderContext.bezierVertex @vertices[index + 0][0], @vertices[index + 0][1], @vertices[index + 0][2], @vertices[index + 1][0], @vertices[index + 1][1], @vertices[index + 1][2], @vertices[index + 2][0], @vertices[index + 2][1], @vertices[index + 2][2]
                index += 3
              else if @vertexCodes[i] is 2
                renderContext.curveVertex @vertices[index][0], @vertices[index][1], @vertices[index][2]
                index++
              else renderContext.breakShape = true  if @vertexCodes[i] is 3
              i++
        renderContext.endShape (if @close then 2 else 1)

      drawGeometry: (renderContext) ->
        i = undefined
        j = undefined
        renderContext.beginShape @kind
        if @style
          i = 0
          j = @vertices.length

          while i < j
            renderContext.vertex @vertices[i]
            i++
        else
          i = 0
          j = @vertices.length

          while i < j
            vert = @vertices[i]
            if vert[2] is 0
              renderContext.vertex vert[0], vert[1]
            else
              renderContext.vertex vert[0], vert[1], vert[2]
            i++
        renderContext.endShape()

      drawGroup: (renderContext) ->
        i = 0
        j = @children.length

        while i < j
          @children[i].draw renderContext
          i++

      drawPrimitive: (renderContext) ->
        if @kind is 2
          renderContext.point @params[0], @params[1]
        else if @kind is 4
          if @params.length is 4
            renderContext.line @params[0], @params[1], @params[2], @params[3]
          else
            renderContext.line @params[0], @params[1], @params[2], @params[3], @params[4], @params[5]
        else if @kind is 8
          renderContext.triangle @params[0], @params[1], @params[2], @params[3], @params[4], @params[5]
        else if @kind is 16
          renderContext.quad @params[0], @params[1], @params[2], @params[3], @params[4], @params[5], @params[6], @params[7]
        else if @kind is 30
          if @image isnt null
            imMode = imageModeConvert
            renderContext.imageMode 0
            renderContext.image @image, @params[0], @params[1], @params[2], @params[3]
            imageModeConvert = imMode
          else
            rcMode = curRectMode
            renderContext.rectMode 0
            renderContext.rect @params[0], @params[1], @params[2], @params[3]
            curRectMode = rcMode
        else if @kind is 31
          elMode = curEllipseMode
          renderContext.ellipseMode 0
          renderContext.ellipse @params[0], @params[1], @params[2], @params[3]
          curEllipseMode = elMode
        else if @kind is 32
          eMode = curEllipseMode
          renderContext.ellipseMode 0
          renderContext.arc @params[0], @params[1], @params[2], @params[3], @params[4], @params[5]
          curEllipseMode = eMode
        else if @kind is 41
          if @params.length is 1
            renderContext.box @params[0]
          else
            renderContext.box @params[0], @params[1], @params[2]
        else renderContext.sphere @params[0]  if @kind is 40

      pre: (renderContext) ->
        if @matrix
          renderContext.pushMatrix()
          renderContext.transform @matrix
        if @style
          renderContext.pushStyle()
          @styles renderContext

      post: (renderContext) ->
        renderContext.popMatrix()  if @matrix
        renderContext.popStyle()  if @style

      styles: (renderContext) ->
        if @stroke
          renderContext.stroke @strokeColor
          renderContext.strokeWeight @strokeWeight
          renderContext.strokeCap @strokeCap
          renderContext.strokeJoin @strokeJoin
        else
          renderContext.noStroke()
        if @fill
          renderContext.fill @fillColor
        else
          renderContext.noFill()

      getChild: (child) ->
        i = undefined
        j = undefined
        return @children[child]  if typeof child is "number"
        found = undefined
        return this  if child is "" or @name is child
        if @nameTable.length > 0
          i = 0
          j = @nameTable.length

          while i < j or found
            if @nameTable[i].getName is child
              found = @nameTable[i]
              break
            i++
          return found  if found
        i = 0
        j = @children.length

        while i < j
          found = @children[i].getChild(child)
          return found  if found
          i++
        null

      getChildCount: ->
        @children.length

      addChild: (child) ->
        @children.push child
        child.parent = this
        @addName child.getName(), child  if child.getName() isnt null

      addName: (name, shape) ->
        if @parent isnt null
          @parent.addName name, shape
        else
          @nameTable.push [ name, shape ]

      translate: ->
        if arguments.length is 2
          @checkMatrix 2
          @matrix.translate arguments[0], arguments[1]
        else
          @checkMatrix 3
          @matrix.translate arguments[0], arguments[1], 0

      checkMatrix: (dimensions) ->
        if @matrix is null
          if dimensions is 2
            @matrix = new p.PMatrix2D
          else
            @matrix = new p.PMatrix3D
        else @matrix = new p.PMatrix3D  if dimensions is 3 and @matrix instanceof p.PMatrix2D

      rotateX: (angle) ->
        @rotate angle, 1, 0, 0

      rotateY: (angle) ->
        @rotate angle, 0, 1, 0

      rotateZ: (angle) ->
        @rotate angle, 0, 0, 1

      rotate: ->
        if arguments.length is 1
          @checkMatrix 2
          @matrix.rotate arguments[0]
        else
          @checkMatrix 3
          @matrix.rotate arguments[0], arguments[1], arguments[2], arguments[3]

      scale: ->
        if arguments.length is 2
          @checkMatrix 2
          @matrix.scale arguments[0], arguments[1]
        else if arguments.length is 3
          @checkMatrix 2
          @matrix.scale arguments[0], arguments[1], arguments[2]
        else
          @checkMatrix 2
          @matrix.scale arguments[0]

      resetMatrix: ->
        @checkMatrix 2
        @matrix.reset()

      applyMatrix: (matrix) ->
        if arguments.length is 1
          @applyMatrix matrix.elements[0], matrix.elements[1], 0, matrix.elements[2], matrix.elements[3], matrix.elements[4], 0, matrix.elements[5], 0, 0, 1, 0, 0, 0, 0, 1
        else if arguments.length is 6
          @checkMatrix 2
          @matrix.apply arguments[0], arguments[1], arguments[2], 0, arguments[3], arguments[4], arguments[5], 0, 0, 0, 1, 0, 0, 0, 0, 1
        else if arguments.length is 16
          @checkMatrix 3
          @matrix.apply arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6], arguments[7], arguments[8], arguments[9], arguments[10], arguments[11], arguments[12], arguments[13], arguments[14], arguments[15]

    PShapeSVG = p.PShapeSVG = ->
      p.PShape.call this
      if arguments.length is 1
        @element = arguments[0]
        @vertexCodes = []
        @vertices = []
        @opacity = 1
        @stroke = false
        @strokeColor = 4278190080
        @strokeWeight = 1
        @strokeCap = "butt"
        @strokeJoin = "miter"
        @strokeGradient = null
        @strokeGradientPaint = null
        @strokeName = null
        @strokeOpacity = 1
        @fill = true
        @fillColor = 4278190080
        @fillGradient = null
        @fillGradientPaint = null
        @fillName = null
        @fillOpacity = 1
        throw "root is not <svg>, it's <" + @element.getName() + ">"  if @element.getName() isnt "svg"
      else if arguments.length is 2
        if typeof arguments[1] is "string"
          if arguments[1].indexOf(".svg") > -1
            @element = new p.XMLElement(p, arguments[1])
            @vertexCodes = []
            @vertices = []
            @opacity = 1
            @stroke = false
            @strokeColor = 4278190080
            @strokeWeight = 1
            @strokeCap = "butt"
            @strokeJoin = "miter"
            @strokeGradient = ""
            @strokeGradientPaint = ""
            @strokeName = ""
            @strokeOpacity = 1
            @fill = true
            @fillColor = 4278190080
            @fillGradient = null
            @fillGradientPaint = null
            @fillOpacity = 1
        else if arguments[0]
          @element = arguments[1]
          @vertexCodes = arguments[0].vertexCodes.slice()
          @vertices = arguments[0].vertices.slice()
          @stroke = arguments[0].stroke
          @strokeColor = arguments[0].strokeColor
          @strokeWeight = arguments[0].strokeWeight
          @strokeCap = arguments[0].strokeCap
          @strokeJoin = arguments[0].strokeJoin
          @strokeGradient = arguments[0].strokeGradient
          @strokeGradientPaint = arguments[0].strokeGradientPaint
          @strokeName = arguments[0].strokeName
          @fill = arguments[0].fill
          @fillColor = arguments[0].fillColor
          @fillGradient = arguments[0].fillGradient
          @fillGradientPaint = arguments[0].fillGradientPaint
          @fillName = arguments[0].fillName
          @strokeOpacity = arguments[0].strokeOpacity
          @fillOpacity = arguments[0].fillOpacity
          @opacity = arguments[0].opacity
      @name = @element.getStringAttribute("id")
      displayStr = @element.getStringAttribute("display", "inline")
      @visible = displayStr isnt "none"
      str = @element.getAttribute("transform")
      @matrix = @parseMatrix(str)  if str
      viewBoxStr = @element.getStringAttribute("viewBox")
      if viewBoxStr isnt null
        viewBox = viewBoxStr.split(" ")
        @width = viewBox[2]
        @height = viewBox[3]
      unitWidth = @element.getStringAttribute("width")
      unitHeight = @element.getStringAttribute("height")
      if unitWidth isnt null
        @width = @parseUnitSize(unitWidth)
        @height = @parseUnitSize(unitHeight)
      else if @width is 0 or @height is 0
        @width = 1
        @height = 1
        throw "The width and/or height is not " + "readable in the <svg> tag of this file."
      @parseColors @element
      @parseChildren @element

    PShapeSVG:: = new PShape
    PShapeSVG::parseMatrix = ->
      getCoords = (s) ->
        m = []
        s.replace /\((.*?)\)/, ->
          (all, params) ->
            m = params.replace(/,+/g, " ").split(/\s+/)
        ()
        m
      (str) ->
        @checkMatrix 2
        pieces = []
        str.replace /\s*(\w+)\((.*?)\)/g, (all) ->
          pieces.push p.trim(all)

        return null  if pieces.length is 0
        i = 0
        j = pieces.length

        while i < j
          m = getCoords(pieces[i])
          if pieces[i].indexOf("matrix") isnt -1
            @matrix.set m[0], m[2], m[4], m[1], m[3], m[5]
          else if pieces[i].indexOf("translate") isnt -1
            tx = m[0]
            ty = (if m.length is 2 then m[1] else 0)
            @matrix.translate tx, ty
          else if pieces[i].indexOf("scale") isnt -1
            sx = m[0]
            sy = (if m.length is 2 then m[1] else m[0])
            @matrix.scale sx, sy
          else if pieces[i].indexOf("rotate") isnt -1
            angle = m[0]
            if m.length is 1
              @matrix.rotate p.radians(angle)
            else if m.length is 3
              @matrix.translate m[1], m[2]
              @matrix.rotate p.radians(m[0])
              @matrix.translate -m[1], -m[2]
          else if pieces[i].indexOf("skewX") isnt -1
            @matrix.skewX parseFloat(m[0])
          else if pieces[i].indexOf("skewY") isnt -1
            @matrix.skewY m[0]
          else if pieces[i].indexOf("shearX") isnt -1
            @matrix.shearX m[0]
          else @matrix.shearY m[0]  if pieces[i].indexOf("shearY") isnt -1
          i++
        @matrix
    ()
    PShapeSVG::parseChildren = (element) ->
      newelement = element.getChildren()
      children = new p.PShape
      i = 0
      j = newelement.length

      while i < j
        kid = @parseChild(newelement[i])
        children.addChild kid  if kid
        i++
      @children.push children

    PShapeSVG::getName = ->
      @name

    PShapeSVG::parseChild = (elem) ->
      name = elem.getName()
      shape = undefined
      if name is "g"
        shape = new PShapeSVG(this, elem)
      else if name is "defs"
        shape = new PShapeSVG(this, elem)
      else if name is "line"
        shape = new PShapeSVG(this, elem)
        shape.parseLine()
      else if name is "circle"
        shape = new PShapeSVG(this, elem)
        shape.parseEllipse true
      else if name is "ellipse"
        shape = new PShapeSVG(this, elem)
        shape.parseEllipse false
      else if name is "rect"
        shape = new PShapeSVG(this, elem)
        shape.parseRect()
      else if name is "polygon"
        shape = new PShapeSVG(this, elem)
        shape.parsePoly true
      else if name is "polyline"
        shape = new PShapeSVG(this, elem)
        shape.parsePoly false
      else if name is "path"
        shape = new PShapeSVG(this, elem)
        shape.parsePath()
      else if name is "radialGradient"
        unimplemented "PShapeSVG.prototype.parseChild, name = radialGradient"
      else if name is "linearGradient"
        unimplemented "PShapeSVG.prototype.parseChild, name = linearGradient"
      else if name is "text"
        unimplemented "PShapeSVG.prototype.parseChild, name = text"
      else if name is "filter"
        unimplemented "PShapeSVG.prototype.parseChild, name = filter"
      else if name is "mask"
        unimplemented "PShapeSVG.prototype.parseChild, name = mask"
      else
        nop()
      shape

    PShapeSVG::parsePath = ->
      @family = 21
      @kind = 0
      pathDataChars = []
      c = undefined
      pathData = p.trim(@element.getStringAttribute("d").replace(/[\s,]+/g, " "))
      return  if pathData is null
      pathData = p.__toCharArray(pathData)
      cx = 0
      cy = 0
      ctrlX = 0
      ctrlY = 0
      ctrlX1 = 0
      ctrlX2 = 0
      ctrlY1 = 0
      ctrlY2 = 0
      endX = 0
      endY = 0
      ppx = 0
      ppy = 0
      px = 0
      py = 0
      i = 0
      valOf = 0
      str = ""
      tmpArray = []
      flag = false
      lastInstruction = undefined
      command = undefined
      j = undefined
      k = undefined
      while i < pathData.length
        valOf = pathData[i].valueOf()
        if valOf >= 65 and valOf <= 90 or valOf >= 97 and valOf <= 122
          j = i
          i++
          if i < pathData.length
            tmpArray = []
            valOf = pathData[i].valueOf()
            while not (valOf >= 65 and valOf <= 90 or valOf >= 97 and valOf <= 100 or valOf >= 102 and valOf <= 122) and flag is false
              if valOf is 32
                if str isnt ""
                  tmpArray.push parseFloat(str)
                  str = ""
                i++
              else unless valOf is 45
                str += pathData[i].toString()
                i++
              if i is pathData.length
                flag = true
              else
                valOf = pathData[i].valueOf()
          if str isnt ""
            tmpArray.push parseFloat(str)
            str = ""
          command = pathData[j]
          valOf = command.valueOf()
          if valOf is 77
            if tmpArray.length >= 2 and tmpArray.length % 2 is 0
              cx = tmpArray[0]
              cy = tmpArray[1]
              @parsePathMoveto cx, cy
              if tmpArray.length > 2
                j = 2
                k = tmpArray.length

                while j < k
                  cx = tmpArray[j]
                  cy = tmpArray[j + 1]
                  @parsePathLineto cx, cy
                  j += 2
          else if valOf is 109
            if tmpArray.length >= 2 and tmpArray.length % 2 is 0
              cx += tmpArray[0]
              cy += tmpArray[1]
              @parsePathMoveto cx, cy
              if tmpArray.length > 2
                j = 2
                k = tmpArray.length

                while j < k
                  cx += tmpArray[j]
                  cy += tmpArray[j + 1]
                  @parsePathLineto cx, cy
                  j += 2
          else if valOf is 76
            if tmpArray.length >= 2 and tmpArray.length % 2 is 0
              j = 0
              k = tmpArray.length

              while j < k
                cx = tmpArray[j]
                cy = tmpArray[j + 1]
                @parsePathLineto cx, cy
                j += 2
          else if valOf is 108
            if tmpArray.length >= 2 and tmpArray.length % 2 is 0
              j = 0
              k = tmpArray.length

              while j < k
                cx += tmpArray[j]
                cy += tmpArray[j + 1]
                @parsePathLineto cx, cy
                j += 2
          else if valOf is 72
            j = 0
            k = tmpArray.length

            while j < k
              cx = tmpArray[j]
              @parsePathLineto cx, cy
              j++
          else if valOf is 104
            j = 0
            k = tmpArray.length

            while j < k
              cx += tmpArray[j]
              @parsePathLineto cx, cy
              j++
          else if valOf is 86
            j = 0
            k = tmpArray.length

            while j < k
              cy = tmpArray[j]
              @parsePathLineto cx, cy
              j++
          else if valOf is 118
            j = 0
            k = tmpArray.length

            while j < k
              cy += tmpArray[j]
              @parsePathLineto cx, cy
              j++
          else if valOf is 67
            if tmpArray.length >= 6 and tmpArray.length % 6 is 0
              j = 0
              k = tmpArray.length

              while j < k
                ctrlX1 = tmpArray[j]
                ctrlY1 = tmpArray[j + 1]
                ctrlX2 = tmpArray[j + 2]
                ctrlY2 = tmpArray[j + 3]
                endX = tmpArray[j + 4]
                endY = tmpArray[j + 5]
                @parsePathCurveto ctrlX1, ctrlY1, ctrlX2, ctrlY2, endX, endY
                cx = endX
                cy = endY
                j += 6
          else if valOf is 99
            if tmpArray.length >= 6 and tmpArray.length % 6 is 0
              j = 0
              k = tmpArray.length

              while j < k
                ctrlX1 = cx + tmpArray[j]
                ctrlY1 = cy + tmpArray[j + 1]
                ctrlX2 = cx + tmpArray[j + 2]
                ctrlY2 = cy + tmpArray[j + 3]
                endX = cx + tmpArray[j + 4]
                endY = cy + tmpArray[j + 5]
                @parsePathCurveto ctrlX1, ctrlY1, ctrlX2, ctrlY2, endX, endY
                cx = endX
                cy = endY
                j += 6
          else if valOf is 83
            if tmpArray.length >= 4 and tmpArray.length % 4 is 0
              j = 0
              k = tmpArray.length

              while j < k
                if lastInstruction.toLowerCase() is "c" or lastInstruction.toLowerCase() is "s"
                  ppx = @vertices[@vertices.length - 2][0]
                  ppy = @vertices[@vertices.length - 2][1]
                  px = @vertices[@vertices.length - 1][0]
                  py = @vertices[@vertices.length - 1][1]
                  ctrlX1 = px + (px - ppx)
                  ctrlY1 = py + (py - ppy)
                else
                  ctrlX1 = @vertices[@vertices.length - 1][0]
                  ctrlY1 = @vertices[@vertices.length - 1][1]
                ctrlX2 = tmpArray[j]
                ctrlY2 = tmpArray[j + 1]
                endX = tmpArray[j + 2]
                endY = tmpArray[j + 3]
                @parsePathCurveto ctrlX1, ctrlY1, ctrlX2, ctrlY2, endX, endY
                cx = endX
                cy = endY
                j += 4
          else if valOf is 115
            if tmpArray.length >= 4 and tmpArray.length % 4 is 0
              j = 0
              k = tmpArray.length

              while j < k
                if lastInstruction.toLowerCase() is "c" or lastInstruction.toLowerCase() is "s"
                  ppx = @vertices[@vertices.length - 2][0]
                  ppy = @vertices[@vertices.length - 2][1]
                  px = @vertices[@vertices.length - 1][0]
                  py = @vertices[@vertices.length - 1][1]
                  ctrlX1 = px + (px - ppx)
                  ctrlY1 = py + (py - ppy)
                else
                  ctrlX1 = @vertices[@vertices.length - 1][0]
                  ctrlY1 = @vertices[@vertices.length - 1][1]
                ctrlX2 = cx + tmpArray[j]
                ctrlY2 = cy + tmpArray[j + 1]
                endX = cx + tmpArray[j + 2]
                endY = cy + tmpArray[j + 3]
                @parsePathCurveto ctrlX1, ctrlY1, ctrlX2, ctrlY2, endX, endY
                cx = endX
                cy = endY
                j += 4
          else if valOf is 81
            if tmpArray.length >= 4 and tmpArray.length % 4 is 0
              j = 0
              k = tmpArray.length

              while j < k
                ctrlX = tmpArray[j]
                ctrlY = tmpArray[j + 1]
                endX = tmpArray[j + 2]
                endY = tmpArray[j + 3]
                @parsePathQuadto cx, cy, ctrlX, ctrlY, endX, endY
                cx = endX
                cy = endY
                j += 4
          else if valOf is 113
            if tmpArray.length >= 4 and tmpArray.length % 4 is 0
              j = 0
              k = tmpArray.length

              while j < k
                ctrlX = cx + tmpArray[j]
                ctrlY = cy + tmpArray[j + 1]
                endX = cx + tmpArray[j + 2]
                endY = cy + tmpArray[j + 3]
                @parsePathQuadto cx, cy, ctrlX, ctrlY, endX, endY
                cx = endX
                cy = endY
                j += 4
          else if valOf is 84
            if tmpArray.length >= 2 and tmpArray.length % 2 is 0
              j = 0
              k = tmpArray.length

              while j < k
                if lastInstruction.toLowerCase() is "q" or lastInstruction.toLowerCase() is "t"
                  ppx = @vertices[@vertices.length - 2][0]
                  ppy = @vertices[@vertices.length - 2][1]
                  px = @vertices[@vertices.length - 1][0]
                  py = @vertices[@vertices.length - 1][1]
                  ctrlX = px + (px - ppx)
                  ctrlY = py + (py - ppy)
                else
                  ctrlX = cx
                  ctrlY = cy
                endX = tmpArray[j]
                endY = tmpArray[j + 1]
                @parsePathQuadto cx, cy, ctrlX, ctrlY, endX, endY
                cx = endX
                cy = endY
                j += 2
          else if valOf is 116
            if tmpArray.length >= 2 and tmpArray.length % 2 is 0
              j = 0
              k = tmpArray.length

              while j < k
                if lastInstruction.toLowerCase() is "q" or lastInstruction.toLowerCase() is "t"
                  ppx = @vertices[@vertices.length - 2][0]
                  ppy = @vertices[@vertices.length - 2][1]
                  px = @vertices[@vertices.length - 1][0]
                  py = @vertices[@vertices.length - 1][1]
                  ctrlX = px + (px - ppx)
                  ctrlY = py + (py - ppy)
                else
                  ctrlX = cx
                  ctrlY = cy
                endX = cx + tmpArray[j]
                endY = cy + tmpArray[j + 1]
                @parsePathQuadto cx, cy, ctrlX, ctrlY, endX, endY
                cx = endX
                cy = endY
                j += 2
          else @close = true  if valOf is 90 or valOf is 122
          lastInstruction = command.toString()
        else
          i++

    PShapeSVG::parsePathQuadto = (x1, y1, cx, cy, x2, y2) ->
      if @vertices.length > 0
        @parsePathCode 1
        @parsePathVertex x1 + (cx - x1) * 2 / 3, y1 + (cy - y1) * 2 / 3
        @parsePathVertex x2 + (cx - x2) * 2 / 3, y2 + (cy - y2) * 2 / 3
        @parsePathVertex x2, y2
      else
        throw "Path must start with M/m"

    PShapeSVG::parsePathCurveto = (x1, y1, x2, y2, x3, y3) ->
      if @vertices.length > 0
        @parsePathCode 1
        @parsePathVertex x1, y1
        @parsePathVertex x2, y2
        @parsePathVertex x3, y3
      else
        throw "Path must start with M/m"

    PShapeSVG::parsePathLineto = (px, py) ->
      if @vertices.length > 0
        @parsePathCode 0
        @parsePathVertex px, py
        @vertices[@vertices.length - 1]["moveTo"] = false
      else
        throw "Path must start with M/m"

    PShapeSVG::parsePathMoveto = (px, py) ->
      @parsePathCode 3  if @vertices.length > 0
      @parsePathCode 0
      @parsePathVertex px, py
      @vertices[@vertices.length - 1]["moveTo"] = true

    PShapeSVG::parsePathVertex = (x, y) ->
      verts = []
      verts[0] = x
      verts[1] = y
      @vertices.push verts

    PShapeSVG::parsePathCode = (what) ->
      @vertexCodes.push what

    PShapeSVG::parsePoly = (val) ->
      @family = 21
      @close = val
      pointsAttr = p.trim(@element.getStringAttribute("points").replace(/[,\s]+/g, " "))
      if pointsAttr isnt null
        pointsBuffer = pointsAttr.split(" ")
        if pointsBuffer.length % 2 is 0
          i = 0
          j = pointsBuffer.length

          while i < j
            verts = []
            verts[0] = pointsBuffer[i]
            verts[1] = pointsBuffer[++i]
            @vertices.push verts
            i++
        else
          throw "Error parsing polygon points: odd number of coordinates provided"

    PShapeSVG::parseRect = ->
      @kind = 30
      @family = 1
      @params = []
      @params[0] = @element.getFloatAttribute("x")
      @params[1] = @element.getFloatAttribute("y")
      @params[2] = @element.getFloatAttribute("width")
      @params[3] = @element.getFloatAttribute("height")
      throw "svg error: negative width or height found while parsing <rect>"  if @params[2] < 0 or @params[3] < 0

    PShapeSVG::parseEllipse = (val) ->
      @kind = 31
      @family = 1
      @params = []
      @params[0] = @element.getFloatAttribute("cx") | 0
      @params[1] = @element.getFloatAttribute("cy") | 0
      rx = undefined
      ry = undefined
      if val
        rx = ry = @element.getFloatAttribute("r")
        throw "svg error: negative radius found while parsing <circle>"  if rx < 0
      else
        rx = @element.getFloatAttribute("rx")
        ry = @element.getFloatAttribute("ry")
        throw "svg error: negative x-axis radius or y-axis radius found while parsing <ellipse>"  if rx < 0 or ry < 0
      @params[0] -= rx
      @params[1] -= ry
      @params[2] = rx * 2
      @params[3] = ry * 2

    PShapeSVG::parseLine = ->
      @kind = 4
      @family = 1
      @params = []
      @params[0] = @element.getFloatAttribute("x1")
      @params[1] = @element.getFloatAttribute("y1")
      @params[2] = @element.getFloatAttribute("x2")
      @params[3] = @element.getFloatAttribute("y2")

    PShapeSVG::parseColors = (element) ->
      @setOpacity element.getAttribute("opacity")  if element.hasAttribute("opacity")
      @setStroke element.getAttribute("stroke")  if element.hasAttribute("stroke")
      @setStrokeWeight element.getAttribute("stroke-width")  if element.hasAttribute("stroke-width")
      @setStrokeJoin element.getAttribute("stroke-linejoin")  if element.hasAttribute("stroke-linejoin")
      @setStrokeCap element.getStringAttribute("stroke-linecap")  if element.hasAttribute("stroke-linecap")
      @setFill element.getStringAttribute("fill")  if element.hasAttribute("fill")
      if element.hasAttribute("style")
        styleText = element.getStringAttribute("style")
        styleTokens = styleText.toString().split(";")
        i = 0
        j = styleTokens.length

        while i < j
          tokens = p.trim(styleTokens[i].split(":"))
          if tokens[0] is "fill"
            @setFill tokens[1]
          else if tokens[0] is "fill-opacity"
            @setFillOpacity tokens[1]
          else if tokens[0] is "stroke"
            @setStroke tokens[1]
          else if tokens[0] is "stroke-width"
            @setStrokeWeight tokens[1]
          else if tokens[0] is "stroke-linecap"
            @setStrokeCap tokens[1]
          else if tokens[0] is "stroke-linejoin"
            @setStrokeJoin tokens[1]
          else if tokens[0] is "stroke-opacity"
            @setStrokeOpacity tokens[1]
          else @setOpacity tokens[1]  if tokens[0] is "opacity"
          i++

    PShapeSVG::setFillOpacity = (opacityText) ->
      @fillOpacity = parseFloat(opacityText)
      @fillColor = @fillOpacity * 255 << 24 | @fillColor & 16777215

    PShapeSVG::setFill = (fillText) ->
      opacityMask = @fillColor & 4278190080
      if fillText is "none"
        @fill = false
      else if fillText.indexOf("#") is 0
        @fill = true
        fillText = fillText.replace(/#(.)(.)(.)/, "#$1$1$2$2$3$3")  if fillText.length is 4
        @fillColor = opacityMask | parseInt(fillText.substring(1), 16) & 16777215
      else if fillText.indexOf("rgb") is 0
        @fill = true
        @fillColor = opacityMask | @parseRGB(fillText)
      else if fillText.indexOf("url(#") is 0
        @fillName = fillText.substring(5, fillText.length - 1)
      else if colors[fillText]
        @fill = true
        @fillColor = opacityMask | parseInt(colors[fillText].substring(1), 16) & 16777215

    PShapeSVG::setOpacity = (opacity) ->
      @strokeColor = parseFloat(opacity) * 255 << 24 | @strokeColor & 16777215
      @fillColor = parseFloat(opacity) * 255 << 24 | @fillColor & 16777215

    PShapeSVG::setStroke = (strokeText) ->
      opacityMask = @strokeColor & 4278190080
      if strokeText is "none"
        @stroke = false
      else if strokeText.charAt(0) is "#"
        @stroke = true
        strokeText = strokeText.replace(/#(.)(.)(.)/, "#$1$1$2$2$3$3")  if strokeText.length is 4
        @strokeColor = opacityMask | parseInt(strokeText.substring(1), 16) & 16777215
      else if strokeText.indexOf("rgb") is 0
        @stroke = true
        @strokeColor = opacityMask | @parseRGB(strokeText)
      else if strokeText.indexOf("url(#") is 0
        @strokeName = strokeText.substring(5, strokeText.length - 1)
      else if colors[strokeText]
        @stroke = true
        @strokeColor = opacityMask | parseInt(colors[strokeText].substring(1), 16) & 16777215

    PShapeSVG::setStrokeWeight = (weight) ->
      @strokeWeight = @parseUnitSize(weight)

    PShapeSVG::setStrokeJoin = (linejoin) ->
      if linejoin is "miter"
        @strokeJoin = "miter"
      else if linejoin is "round"
        @strokeJoin = "round"
      else @strokeJoin = "bevel"  if linejoin is "bevel"

    PShapeSVG::setStrokeCap = (linecap) ->
      if linecap is "butt"
        @strokeCap = "butt"
      else if linecap is "round"
        @strokeCap = "round"
      else @strokeCap = "square"  if linecap is "square"

    PShapeSVG::setStrokeOpacity = (opacityText) ->
      @strokeOpacity = parseFloat(opacityText)
      @strokeColor = @strokeOpacity * 255 << 24 | @strokeColor & 16777215

    PShapeSVG::parseRGB = (color) ->
      sub = color.substring(color.indexOf("(") + 1, color.indexOf(")"))
      values = sub.split(", ")
      values[0] << 16 | values[1] << 8 | values[2]

    PShapeSVG::parseUnitSize = (text) ->
      len = text.length - 2
      return text  if len < 0
      return parseFloat(text.substring(0, len)) * 1.25  if text.indexOf("pt") is len
      return parseFloat(text.substring(0, len)) * 15  if text.indexOf("pc") is len
      return parseFloat(text.substring(0, len)) * 3.543307  if text.indexOf("mm") is len
      return parseFloat(text.substring(0, len)) * 35.43307  if text.indexOf("cm") is len
      return parseFloat(text.substring(0, len)) * 90  if text.indexOf("in") is len
      return parseFloat(text.substring(0, len))  if text.indexOf("px") is len
      parseFloat text

    p.shape = (shape, x, y, width, height) ->
      if arguments.length >= 1 and arguments[0] isnt null
        if shape.isVisible()
          p.pushMatrix()
          if curShapeMode is 3
            if arguments.length is 5
              p.translate x - width / 2, y - height / 2
              p.scale width / shape.getWidth(), height / shape.getHeight()
            else if arguments.length is 3
              p.translate x - shape.getWidth() / 2, -shape.getHeight() / 2
            else
              p.translate -shape.getWidth() / 2, -shape.getHeight() / 2
          else if curShapeMode is 0
            if arguments.length is 5
              p.translate x, y
              p.scale width / shape.getWidth(), height / shape.getHeight()
            else
              p.translate x, y  if arguments.length is 3
          else if curShapeMode is 1
            if arguments.length is 5
              width -= x
              height -= y
              p.translate x, y
              p.scale width / shape.getWidth(), height / shape.getHeight()
            else p.translate x, y  if arguments.length is 3
          shape.draw p
          p.popMatrix()  if arguments.length is 1 and curShapeMode is 3 or arguments.length > 1

    p.shapeMode = (mode) ->
      curShapeMode = mode

    p.loadShape = (filename) ->
      return new PShapeSVG(null, filename)  if filename.indexOf(".svg") > -1  if arguments.length is 1
      null

    XMLAttribute = (fname, n, nameSpace, v, t) ->
      @fullName = fname or ""
      @name = n or ""
      @namespace = nameSpace or ""
      @value = v
      @type = t

    XMLAttribute:: =
      getName: ->
        @name

      getFullName: ->
        @fullName

      getNamespace: ->
        @namespace

      getValue: ->
        @value

      getType: ->
        @type

      setValue: (newval) ->
        @value = newval

    XMLElement = p.XMLElement = (selector, uri, sysid, line) ->
      @attributes = []
      @children = []
      @fullName = null
      @name = null
      @namespace = ""
      @content = null
      @parent = null
      @lineNr = ""
      @systemID = ""
      @type = "ELEMENT"
      if selector
        if typeof selector is "string"
          unless uri is undef and selector.indexOf("<") > -1
            @fullName = selector
            @namespace = uri
            @systemId = sysid
            @lineNr = line
        else
          @parse uri

    XMLElement:: =
      parse: (textstring) ->
        xmlDoc = undefined
        try
          extension = textstring.substring(textstring.length - 4)
          textstring = ajax(textstring)  if extension is ".xml" or extension is ".svg"
          xmlDoc = (new DOMParser).parseFromString(textstring, "text/xml")
          elements = xmlDoc.documentElement
          if elements
            @parseChildrenRecursive null, elements
          else
            throw "Error loading document"
          return this
        catch e
          throw e

      parseChildrenRecursive: (parent, elementpath) ->
        xmlelement = undefined
        xmlattribute = undefined
        tmpattrib = undefined
        l = undefined
        m = undefined
        child = undefined
        unless parent
          @fullName = elementpath.localName
          @name = elementpath.nodeName
          xmlelement = this
        else
          xmlelement = new XMLElement(elementpath.nodeName)
          xmlelement.parent = parent
        return @createPCDataElement(elementpath.textContent)  if elementpath.nodeType is 3 and elementpath.textContent isnt ""
        return @createCDataElement(elementpath.textContent)  if elementpath.nodeType is 4
        if elementpath.attributes
          l = 0
          m = elementpath.attributes.length

          while l < m
            tmpattrib = elementpath.attributes[l]
            xmlattribute = new XMLAttribute(tmpattrib.getname, tmpattrib.nodeName, tmpattrib.namespaceURI, tmpattrib.nodeValue, tmpattrib.nodeType)
            xmlelement.attributes.push xmlattribute
            l++
        if elementpath.childNodes
          l = 0
          m = elementpath.childNodes.length

          while l < m
            node = elementpath.childNodes[l]
            child = xmlelement.parseChildrenRecursive(xmlelement, node)
            xmlelement.children.push child  if child isnt null
            l++
        xmlelement

      createElement: (fullname, namespaceuri, sysid, line) ->
        return new XMLElement(fullname, namespaceuri)  if sysid is undef
        new XMLElement(fullname, namespaceuri, sysid, line)

      createPCDataElement: (content, isCDATA) ->
        return null  if content.replace(/^\s+$/g, "") is ""
        pcdata = new XMLElement
        pcdata.type = "TEXT"
        pcdata.content = content
        pcdata

      createCDataElement: (content) ->
        cdata = @createPCDataElement(content)
        return null  if cdata is null
        cdata.type = "CDATA"
        htmlentities =
          "<": "&lt;"
          ">": "&gt;"
          "'": "&apos;"
          "\"": "&quot;"

        entity = undefined
        for entity of htmlentities
          content = content.replace(new RegExp(entity, "g"), htmlentities[entity])  unless Object.hasOwnProperty(htmlentities, entity)
        cdata.cdata = content
        cdata

      hasAttribute: ->
        return @getAttribute(arguments[0]) isnt null  if arguments.length is 1
        @getAttribute(arguments[0], arguments[1]) isnt null  if arguments.length is 2

      equals: (other) ->
        return false  unless other instanceof XMLElement
        i = undefined
        j = undefined
        return false  if @fullName isnt other.fullName
        return false  if @attributes.length isnt other.getAttributeCount()
        return false  if @attributes.length isnt other.attributes.length
        attr_name = undefined
        attr_ns = undefined
        attr_value = undefined
        attr_type = undefined
        attr_other = undefined
        i = 0
        j = @attributes.length

        while i < j
          attr_name = @attributes[i].getName()
          attr_ns = @attributes[i].getNamespace()
          attr_other = other.findAttribute(attr_name, attr_ns)
          return false  if attr_other is null
          return false  if @attributes[i].getValue() isnt attr_other.getValue()
          return false  if @attributes[i].getType() isnt attr_other.getType()
          i++
        return false  if @children.length isnt other.getChildCount()
        if @children.length > 0
          child1 = undefined
          child2 = undefined
          i = 0
          j = @children.length

          while i < j
            child1 = @getChild(i)
            child2 = other.getChild(i)
            return false  unless child1.equals(child2)
            i++
          return true
        @content is other.content

      getContent: ->
        return @content  if @type is "TEXT" or @type is "CDATA"
        children = @children
        return children[0].content  if children.length is 1 and (children[0].type is "TEXT" or children[0].type is "CDATA")
        null

      getAttribute: ->
        attribute = undefined
        if arguments.length is 2
          attribute = @findAttribute(arguments[0])
          return attribute.getValue()  if attribute
          arguments[1]
        else if arguments.length is 1
          attribute = @findAttribute(arguments[0])
          return attribute.getValue()  if attribute
          null
        else if arguments.length is 3
          attribute = @findAttribute(arguments[0], arguments[1])
          return attribute.getValue()  if attribute
          arguments[2]

      getStringAttribute: ->
        return @getAttribute(arguments[0])  if arguments.length is 1
        return @getAttribute(arguments[0], arguments[1])  if arguments.length is 2
        @getAttribute arguments[0], arguments[1], arguments[2]

      getString: (attributeName) ->
        @getStringAttribute attributeName

      getFloatAttribute: ->
        return parseFloat(@getAttribute(arguments[0], 0))  if arguments.length is 1
        return @getAttribute(arguments[0], arguments[1])  if arguments.length is 2
        @getAttribute arguments[0], arguments[1], arguments[2]

      getFloat: (attributeName) ->
        @getFloatAttribute attributeName

      getIntAttribute: ->
        return @getAttribute(arguments[0], 0)  if arguments.length is 1
        return @getAttribute(arguments[0], arguments[1])  if arguments.length is 2
        @getAttribute arguments[0], arguments[1], arguments[2]

      getInt: (attributeName) ->
        @getIntAttribute attributeName

      hasChildren: ->
        @children.length > 0

      addChild: (child) ->
        if child isnt null
          child.parent = this
          @children.push child

      insertChild: (child, index) ->
        if child
          if child.getLocalName() is null and not @hasChildren()
            lastChild = @children[@children.length - 1]
            if lastChild.getLocalName() is null
              lastChild.setContent lastChild.getContent() + child.getContent()
              return
          child.parent = this
          @children.splice index, 0, child

      getChild: (selector) ->
        return @children[selector]  if typeof selector is "number"
        return @getChildRecursive(selector.split("/"), 0)  if selector.indexOf("/") isnt -1
        kid = undefined
        kidName = undefined
        i = 0
        j = @getChildCount()

        while i < j
          kid = @getChild(i)
          kidName = kid.getName()
          return kid  if kidName isnt null and kidName is selector
          i++
        null

      getChildren: ->
        if arguments.length is 1
          return @getChild(arguments[0])  if typeof arguments[0] is "number"
          return @getChildrenRecursive(arguments[0].split("/"), 0)  if arguments[0].indexOf("/") isnt -1
          matches = []
          kid = undefined
          kidName = undefined
          i = 0
          j = @getChildCount()

          while i < j
            kid = @getChild(i)
            kidName = kid.getName()
            matches.push kid  if kidName isnt null and kidName is arguments[0]
            i++
          return matches
        @children

      getChildCount: ->
        @children.length

      getChildRecursive: (items, offset) ->
        return this  if offset is items.length
        kid = undefined
        kidName = undefined
        matchName = items[offset]
        i = 0
        j = @getChildCount()

        while i < j
          kid = @getChild(i)
          kidName = kid.getName()
          return kid.getChildRecursive(items, offset + 1)  if kidName isnt null and kidName is matchName
          i++
        null

      getChildrenRecursive: (items, offset) ->
        return @getChildren(items[offset])  if offset is items.length - 1
        matches = @getChildren(items[offset])
        kidMatches = []
        i = 0

        while i < matches.length
          kidMatches = kidMatches.concat(matches[i].getChildrenRecursive(items, offset + 1))
          i++
        kidMatches

      isLeaf: ->
        not @hasChildren()

      listChildren: ->
        arr = []
        i = 0
        j = @children.length

        while i < j
          arr.push @getChild(i).getName()
          i++
        arr

      removeAttribute: (name, namespace) ->
        @namespace = namespace or ""
        i = 0
        j = @attributes.length

        while i < j
          if @attributes[i].getName() is name and @attributes[i].getNamespace() is @namespace
            @attributes.splice i, 1
            break
          i++

      removeChild: (child) ->
        if child
          i = 0
          j = @children.length

          while i < j
            if @children[i].equals(child)
              @children.splice i, 1
              break
            i++

      removeChildAtIndex: (index) ->
        @children.splice index, 1  if @children.length > index

      findAttribute: (name, namespace) ->
        @namespace = namespace or ""
        i = 0
        j = @attributes.length

        while i < j
          return @attributes[i]  if @attributes[i].getName() is name and @attributes[i].getNamespace() is @namespace
          i++
        null

      setAttribute: ->
        attr = undefined
        if arguments.length is 3
          index = arguments[0].indexOf(":")
          name = arguments[0].substring(index + 1)
          attr = @findAttribute(name, arguments[1])
          unless attr
            attr = new XMLAttribute(arguments[0], name, arguments[1], arguments[2], "CDATA")
            @attributes.push attr
        else
          attr = @findAttribute(arguments[0])
          unless attr
            attr = new XMLAttribute(arguments[0], arguments[0], null, arguments[1], "CDATA")
            @attributes.push attr

      setString: (attribute, value) ->
        @setAttribute attribute, value

      setInt: (attribute, value) ->
        @setAttribute attribute, value

      setFloat: (attribute, value) ->
        @setAttribute attribute, value

      setContent: (content) ->
        Processing.debug "Tried to set content for XMLElement with children"  if @children.length > 0
        @content = content

      setName: ->
        if arguments.length is 1
          @name = arguments[0]
          @fullName = arguments[0]
          @namespace = null
        else
          index = arguments[0].indexOf(":")
          if arguments[1] is null or index < 0
            @name = arguments[0]
          else
            @name = arguments[0].substring(index + 1)
          @fullName = arguments[0]
          @namespace = arguments[1]

      getName: ->
        @fullName

      getLocalName: ->
        @name

      getAttributeCount: ->
        @attributes.length

      toString: ->
        return @content  if @type is "TEXT"
        return @cdata  if @type is "CDATA"
        tagstring = @fullName
        xmlstring = "<" + tagstring
        a = undefined
        c = undefined
        a = 0
        while a < @attributes.length
          attr = @attributes[a]
          xmlstring += " " + attr.getName() + "=" + "\"" + attr.getValue() + "\""
          a++
        unless @children.length is 0
          xmlstring += ">"
          c = 0
          while c < @children.length
            xmlstring += @children[c].toString()
            c++
          xmlstring += "</" + tagstring + ">"
        xmlstring

    XMLElement.parse = (xmlstring) ->
      element = new XMLElement
      element.parse xmlstring
      element

    XML = p.XML = p.XMLElement
    p.loadXML = (uri) ->
      new XML(p, uri)

    printMatrixHelper = (elements) ->
      big = 0
      i = 0

      while i < elements.length
        if i isnt 0
          big = Math.max(big, Math.abs(elements[i]))
        else
          big = Math.abs(elements[i])
        i++
      digits = (big + "").indexOf(".")
      if digits is 0
        digits = 1
      else digits = (big + "").length  if digits is -1
      digits

    PMatrix2D = p.PMatrix2D = ->
      if arguments.length is 0
        @reset()
      else if arguments.length is 1 and arguments[0] instanceof PMatrix2D
        @set arguments[0].array()
      else @set arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5]  if arguments.length is 6

    PMatrix2D:: =
      set: ->
        if arguments.length is 6
          a = arguments
          @set [ a[0], a[1], a[2], a[3], a[4], a[5] ]
        else if arguments.length is 1 and arguments[0] instanceof PMatrix2D
          @elements = arguments[0].array()
        else @elements = arguments[0].slice()  if arguments.length is 1 and arguments[0] instanceof Array

      get: ->
        outgoing = new PMatrix2D
        outgoing.set @elements
        outgoing

      reset: ->
        @set [ 1, 0, 0, 0, 1, 0 ]

      array: array = ->
        @elements.slice()

      translate: (tx, ty) ->
        @elements[2] = tx * @elements[0] + ty * @elements[1] + @elements[2]
        @elements[5] = tx * @elements[3] + ty * @elements[4] + @elements[5]

      invTranslate: (tx, ty) ->
        @translate -tx, -ty

      transpose: ->

      mult: (source, target) ->
        x = undefined
        y = undefined
        if source instanceof PVector
          x = source.x
          y = source.y
          target = new PVector  unless target
        else if source instanceof Array
          x = source[0]
          y = source[1]
          target = []  unless target
        if target instanceof Array
          target[0] = @elements[0] * x + @elements[1] * y + @elements[2]
          target[1] = @elements[3] * x + @elements[4] * y + @elements[5]
        else if target instanceof PVector
          target.x = @elements[0] * x + @elements[1] * y + @elements[2]
          target.y = @elements[3] * x + @elements[4] * y + @elements[5]
          target.z = 0
        target

      multX: (x, y) ->
        x * @elements[0] + y * @elements[1] + @elements[2]

      multY: (x, y) ->
        x * @elements[3] + y * @elements[4] + @elements[5]

      skewX: (angle) ->
        @apply 1, 0, 1, angle, 0, 0

      skewY: (angle) ->
        @apply 1, 0, 1, 0, angle, 0

      shearX: (angle) ->
        @apply 1, 0, 1, Math.tan(angle), 0, 0

      shearY: (angle) ->
        @apply 1, 0, 1, 0, Math.tan(angle), 0

      determinant: ->
        @elements[0] * @elements[4] - @elements[1] * @elements[3]

      invert: ->
        d = @determinant()
        if Math.abs(d) > -2147483648
          old00 = @elements[0]
          old01 = @elements[1]
          old02 = @elements[2]
          old10 = @elements[3]
          old11 = @elements[4]
          old12 = @elements[5]
          @elements[0] = old11 / d
          @elements[3] = -old10 / d
          @elements[1] = -old01 / d
          @elements[4] = old00 / d
          @elements[2] = (old01 * old12 - old11 * old02) / d
          @elements[5] = (old10 * old02 - old00 * old12) / d
          return true
        false

      scale: (sx, sy) ->
        sy = sx  if sx and not sy
        if sx and sy
          @elements[0] *= sx
          @elements[1] *= sy
          @elements[3] *= sx
          @elements[4] *= sy

      invScale: (sx, sy) ->
        sy = sx  if sx and not sy
        @scale 1 / sx, 1 / sy

      apply: ->
        source = undefined
        if arguments.length is 1 and arguments[0] instanceof PMatrix2D
          source = arguments[0].array()
        else if arguments.length is 6
          source = Array::slice.call(arguments)
        else source = arguments[0]  if arguments.length is 1 and arguments[0] instanceof Array
        result = [ 0, 0, @elements[2], 0, 0, @elements[5] ]
        e = 0
        row = 0

        while row < 2
          col = 0

          while col < 3
            result[e] += @elements[row * 3 + 0] * source[col + 0] + @elements[row * 3 + 1] * source[col + 3]
            col++
            e++
          row++
        @elements = result.slice()

      preApply: ->
        source = undefined
        if arguments.length is 1 and arguments[0] instanceof PMatrix2D
          source = arguments[0].array()
        else if arguments.length is 6
          source = Array::slice.call(arguments)
        else source = arguments[0]  if arguments.length is 1 and arguments[0] instanceof Array
        result = [ 0, 0, source[2], 0, 0, source[5] ]
        result[2] = source[2] + @elements[2] * source[0] + @elements[5] * source[1]
        result[5] = source[5] + @elements[2] * source[3] + @elements[5] * source[4]
        result[0] = @elements[0] * source[0] + @elements[3] * source[1]
        result[3] = @elements[0] * source[3] + @elements[3] * source[4]
        result[1] = @elements[1] * source[0] + @elements[4] * source[1]
        result[4] = @elements[1] * source[3] + @elements[4] * source[4]
        @elements = result.slice()

      rotate: (angle) ->
        c = Math.cos(angle)
        s = Math.sin(angle)
        temp1 = @elements[0]
        temp2 = @elements[1]
        @elements[0] = c * temp1 + s * temp2
        @elements[1] = -s * temp1 + c * temp2
        temp1 = @elements[3]
        temp2 = @elements[4]
        @elements[3] = c * temp1 + s * temp2
        @elements[4] = -s * temp1 + c * temp2

      rotateZ: (angle) ->
        @rotate angle

      invRotateZ: (angle) ->
        @rotateZ angle - Math.PI

      print: ->
        digits = printMatrixHelper(@elements)
        output = "" + p.nfs(@elements[0], digits, 4) + " " + p.nfs(@elements[1], digits, 4) + " " + p.nfs(@elements[2], digits, 4) + "\n" + p.nfs(@elements[3], digits, 4) + " " + p.nfs(@elements[4], digits, 4) + " " + p.nfs(@elements[5], digits, 4) + "\n\n"
        p.println output

    PMatrix3D = p.PMatrix3D = ->
      @reset()

    PMatrix3D:: =
      set: ->
        if arguments.length is 16
          @elements = Array::slice.call(arguments)
        else if arguments.length is 1 and arguments[0] instanceof PMatrix3D
          @elements = arguments[0].array()
        else @elements = arguments[0].slice()  if arguments.length is 1 and arguments[0] instanceof Array

      get: ->
        outgoing = new PMatrix3D
        outgoing.set @elements
        outgoing

      reset: ->
        @elements = [ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ]

      array: array = ->
        @elements.slice()

      translate: (tx, ty, tz) ->
        tz = 0  if tz is undef
        @elements[3] += tx * @elements[0] + ty * @elements[1] + tz * @elements[2]
        @elements[7] += tx * @elements[4] + ty * @elements[5] + tz * @elements[6]
        @elements[11] += tx * @elements[8] + ty * @elements[9] + tz * @elements[10]
        @elements[15] += tx * @elements[12] + ty * @elements[13] + tz * @elements[14]

      transpose: ->
        temp = @elements[4]
        @elements[4] = @elements[1]
        @elements[1] = temp
        temp = @elements[8]
        @elements[8] = @elements[2]
        @elements[2] = temp
        temp = @elements[6]
        @elements[6] = @elements[9]
        @elements[9] = temp
        temp = @elements[3]
        @elements[3] = @elements[12]
        @elements[12] = temp
        temp = @elements[7]
        @elements[7] = @elements[13]
        @elements[13] = temp
        temp = @elements[11]
        @elements[11] = @elements[14]
        @elements[14] = temp

      mult: (source, target) ->
        x = undefined
        y = undefined
        z = undefined
        w = undefined
        if source instanceof PVector
          x = source.x
          y = source.y
          z = source.z
          w = 1
          target = new PVector  unless target
        else if source instanceof Array
          x = source[0]
          y = source[1]
          z = source[2]
          w = source[3] or 1
          target = [ 0, 0, 0 ]  if not target or target.length isnt 3 and target.length isnt 4
        if target instanceof Array
          if target.length is 3
            target[0] = @elements[0] * x + @elements[1] * y + @elements[2] * z + @elements[3]
            target[1] = @elements[4] * x + @elements[5] * y + @elements[6] * z + @elements[7]
            target[2] = @elements[8] * x + @elements[9] * y + @elements[10] * z + @elements[11]
          else if target.length is 4
            target[0] = @elements[0] * x + @elements[1] * y + @elements[2] * z + @elements[3] * w
            target[1] = @elements[4] * x + @elements[5] * y + @elements[6] * z + @elements[7] * w
            target[2] = @elements[8] * x + @elements[9] * y + @elements[10] * z + @elements[11] * w
            target[3] = @elements[12] * x + @elements[13] * y + @elements[14] * z + @elements[15] * w
        if target instanceof PVector
          target.x = @elements[0] * x + @elements[1] * y + @elements[2] * z + @elements[3]
          target.y = @elements[4] * x + @elements[5] * y + @elements[6] * z + @elements[7]
          target.z = @elements[8] * x + @elements[9] * y + @elements[10] * z + @elements[11]
        target

      preApply: ->
        source = undefined
        if arguments.length is 1 and arguments[0] instanceof PMatrix3D
          source = arguments[0].array()
        else if arguments.length is 16
          source = Array::slice.call(arguments)
        else source = arguments[0]  if arguments.length is 1 and arguments[0] instanceof Array
        result = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
        e = 0
        row = 0

        while row < 4
          col = 0

          while col < 4
            result[e] += @elements[col + 0] * source[row * 4 + 0] + @elements[col + 4] * source[row * 4 + 1] + @elements[col + 8] * source[row * 4 + 2] + @elements[col + 12] * source[row * 4 + 3]
            col++
            e++
          row++
        @elements = result.slice()

      apply: ->
        source = undefined
        if arguments.length is 1 and arguments[0] instanceof PMatrix3D
          source = arguments[0].array()
        else if arguments.length is 16
          source = Array::slice.call(arguments)
        else source = arguments[0]  if arguments.length is 1 and arguments[0] instanceof Array
        result = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
        e = 0
        row = 0

        while row < 4
          col = 0

          while col < 4
            result[e] += @elements[row * 4 + 0] * source[col + 0] + @elements[row * 4 + 1] * source[col + 4] + @elements[row * 4 + 2] * source[col + 8] + @elements[row * 4 + 3] * source[col + 12]
            col++
            e++
          row++
        @elements = result.slice()

      rotate: (angle, v0, v1, v2) ->
        if v1
          c = p.cos(angle)
          s = p.sin(angle)
          t = 1 - c
          @apply t * v0 * v0 + c, t * v0 * v1 - s * v2, t * v0 * v2 + s * v1, 0, t * v0 * v1 + s * v2, t * v1 * v1 + c, t * v1 * v2 - s * v0, 0, t * v0 * v2 - s * v1, t * v1 * v2 + s * v0, t * v2 * v2 + c, 0, 0, 0, 0, 1

      invApply: ->
        inverseCopy = new PMatrix3D  if inverseCopy is undef
        a = arguments
        inverseCopy.set a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12], a[13], a[14], a[15]
        return false  unless inverseCopy.invert()
        @preApply inverseCopy
        true

      rotateX: (angle) ->
        c = p.cos(angle)
        s = p.sin(angle)
        @apply [ 1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1 ]

      rotateY: (angle) ->
        c = p.cos(angle)
        s = p.sin(angle)
        @apply [ c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1 ]

      rotateZ: (angle) ->
        c = Math.cos(angle)
        s = Math.sin(angle)
        @apply [ c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ]

      scale: (sx, sy, sz) ->
        if sx and not sy and not sz
          sy = sz = sx
        else sz = 1  if sx and sy and not sz
        if sx and sy and sz
          @elements[0] *= sx
          @elements[1] *= sy
          @elements[2] *= sz
          @elements[4] *= sx
          @elements[5] *= sy
          @elements[6] *= sz
          @elements[8] *= sx
          @elements[9] *= sy
          @elements[10] *= sz
          @elements[12] *= sx
          @elements[13] *= sy
          @elements[14] *= sz

      skewX: (angle) ->
        t = Math.tan(angle)
        @apply 1, t, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1

      skewY: (angle) ->
        t = Math.tan(angle)
        @apply 1, 0, 0, 0, t, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1

      shearX: (angle) ->
        t = Math.tan(angle)
        @apply 1, t, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1

      shearY: (angle) ->
        t = Math.tan(angle)
        @apply 1, 0, 0, 0, t, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1

      multX: (x, y, z, w) ->
        return @elements[0] * x + @elements[1] * y + @elements[3]  unless z
        return @elements[0] * x + @elements[1] * y + @elements[2] * z + @elements[3]  unless w
        @elements[0] * x + @elements[1] * y + @elements[2] * z + @elements[3] * w

      multY: (x, y, z, w) ->
        return @elements[4] * x + @elements[5] * y + @elements[7]  unless z
        return @elements[4] * x + @elements[5] * y + @elements[6] * z + @elements[7]  unless w
        @elements[4] * x + @elements[5] * y + @elements[6] * z + @elements[7] * w

      multZ: (x, y, z, w) ->
        return @elements[8] * x + @elements[9] * y + @elements[10] * z + @elements[11]  unless w
        @elements[8] * x + @elements[9] * y + @elements[10] * z + @elements[11] * w

      multW: (x, y, z, w) ->
        return @elements[12] * x + @elements[13] * y + @elements[14] * z + @elements[15]  unless w
        @elements[12] * x + @elements[13] * y + @elements[14] * z + @elements[15] * w

      invert: ->
        fA0 = @elements[0] * @elements[5] - @elements[1] * @elements[4]
        fA1 = @elements[0] * @elements[6] - @elements[2] * @elements[4]
        fA2 = @elements[0] * @elements[7] - @elements[3] * @elements[4]
        fA3 = @elements[1] * @elements[6] - @elements[2] * @elements[5]
        fA4 = @elements[1] * @elements[7] - @elements[3] * @elements[5]
        fA5 = @elements[2] * @elements[7] - @elements[3] * @elements[6]
        fB0 = @elements[8] * @elements[13] - @elements[9] * @elements[12]
        fB1 = @elements[8] * @elements[14] - @elements[10] * @elements[12]
        fB2 = @elements[8] * @elements[15] - @elements[11] * @elements[12]
        fB3 = @elements[9] * @elements[14] - @elements[10] * @elements[13]
        fB4 = @elements[9] * @elements[15] - @elements[11] * @elements[13]
        fB5 = @elements[10] * @elements[15] - @elements[11] * @elements[14]
        fDet = fA0 * fB5 - fA1 * fB4 + fA2 * fB3 + fA3 * fB2 - fA4 * fB1 + fA5 * fB0
        return false  if Math.abs(fDet) <= 1.0E-9
        kInv = []
        kInv[0] = +@elements[5] * fB5 - @elements[6] * fB4 + @elements[7] * fB3
        kInv[4] = -@elements[4] * fB5 + @elements[6] * fB2 - @elements[7] * fB1
        kInv[8] = +@elements[4] * fB4 - @elements[5] * fB2 + @elements[7] * fB0
        kInv[12] = -@elements[4] * fB3 + @elements[5] * fB1 - @elements[6] * fB0
        kInv[1] = -@elements[1] * fB5 + @elements[2] * fB4 - @elements[3] * fB3
        kInv[5] = +@elements[0] * fB5 - @elements[2] * fB2 + @elements[3] * fB1
        kInv[9] = -@elements[0] * fB4 + @elements[1] * fB2 - @elements[3] * fB0
        kInv[13] = +@elements[0] * fB3 - @elements[1] * fB1 + @elements[2] * fB0
        kInv[2] = +@elements[13] * fA5 - @elements[14] * fA4 + @elements[15] * fA3
        kInv[6] = -@elements[12] * fA5 + @elements[14] * fA2 - @elements[15] * fA1
        kInv[10] = +@elements[12] * fA4 - @elements[13] * fA2 + @elements[15] * fA0
        kInv[14] = -@elements[12] * fA3 + @elements[13] * fA1 - @elements[14] * fA0
        kInv[3] = -@elements[9] * fA5 + @elements[10] * fA4 - @elements[11] * fA3
        kInv[7] = +@elements[8] * fA5 - @elements[10] * fA2 + @elements[11] * fA1
        kInv[11] = -@elements[8] * fA4 + @elements[9] * fA2 - @elements[11] * fA0
        kInv[15] = +@elements[8] * fA3 - @elements[9] * fA1 + @elements[10] * fA0
        fInvDet = 1 / fDet
        kInv[0] *= fInvDet
        kInv[1] *= fInvDet
        kInv[2] *= fInvDet
        kInv[3] *= fInvDet
        kInv[4] *= fInvDet
        kInv[5] *= fInvDet
        kInv[6] *= fInvDet
        kInv[7] *= fInvDet
        kInv[8] *= fInvDet
        kInv[9] *= fInvDet
        kInv[10] *= fInvDet
        kInv[11] *= fInvDet
        kInv[12] *= fInvDet
        kInv[13] *= fInvDet
        kInv[14] *= fInvDet
        kInv[15] *= fInvDet
        @elements = kInv.slice()
        true

      toString: ->
        str = ""
        i = 0

        while i < 15
          str += @elements[i] + ", "
          i++
        str += @elements[15]
        str

      print: ->
        digits = printMatrixHelper(@elements)
        output = "" + p.nfs(@elements[0], digits, 4) + " " + p.nfs(@elements[1], digits, 4) + " " + p.nfs(@elements[2], digits, 4) + " " + p.nfs(@elements[3], digits, 4) + "\n" + p.nfs(@elements[4], digits, 4) + " " + p.nfs(@elements[5], digits, 4) + " " + p.nfs(@elements[6], digits, 4) + " " + p.nfs(@elements[7], digits, 4) + "\n" + p.nfs(@elements[8], digits, 4) + " " + p.nfs(@elements[9], digits, 4) + " " + p.nfs(@elements[10], digits, 4) + " " + p.nfs(@elements[11], digits, 4) + "\n" + p.nfs(@elements[12], digits, 4) + " " + p.nfs(@elements[13], digits, 4) + " " + p.nfs(@elements[14], digits, 4) + " " + p.nfs(@elements[15], digits, 4) + "\n\n"
        p.println output

      invTranslate: (tx, ty, tz) ->
        @preApply 1, 0, 0, -tx, 0, 1, 0, -ty, 0, 0, 1, -tz, 0, 0, 0, 1

      invRotateX: (angle) ->
        c = Math.cos(-angle)
        s = Math.sin(-angle)
        @preApply [ 1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1 ]

      invRotateY: (angle) ->
        c = Math.cos(-angle)
        s = Math.sin(-angle)
        @preApply [ c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1 ]

      invRotateZ: (angle) ->
        c = Math.cos(-angle)
        s = Math.sin(-angle)
        @preApply [ c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ]

      invScale: (x, y, z) ->
        @preApply [ 1 / x, 0, 0, 0, 0, 1 / y, 0, 0, 0, 0, 1 / z, 0, 0, 0, 0, 1 ]

    PMatrixStack = p.PMatrixStack = ->
      @matrixStack = []

    PMatrixStack::load = ->
      tmpMatrix = drawing.$newPMatrix()
      if arguments.length is 1
        tmpMatrix.set arguments[0]
      else
        tmpMatrix.set arguments
      @matrixStack.push tmpMatrix

    Drawing2D::$newPMatrix = ->
      new PMatrix2D

    Drawing3D::$newPMatrix = ->
      new PMatrix3D

    PMatrixStack::push = ->
      @matrixStack.push @peek()

    PMatrixStack::pop = ->
      @matrixStack.pop()

    PMatrixStack::peek = ->
      tmpMatrix = drawing.$newPMatrix()
      tmpMatrix.set @matrixStack[@matrixStack.length - 1]
      tmpMatrix

    PMatrixStack::mult = (matrix) ->
      @matrixStack[@matrixStack.length - 1].apply matrix

    p.split = (str, delim) ->
      str.split delim

    p.splitTokens = (str, tokens) ->
      return str.split(/\s+/g)  if tokens is undef
      chars = tokens.split(/()/g)
      buffer = ""
      len = str.length
      i = undefined
      c = undefined
      tokenized = []
      i = 0
      while i < len
        c = str[i]
        if chars.indexOf(c) > -1
          tokenized.push buffer  if buffer isnt ""
          buffer = ""
        else
          buffer += c
        i++
      tokenized.push buffer  if buffer isnt ""
      tokenized

    p.append = (array, element) ->
      array[array.length] = element
      array

    p.concat = (array1, array2) ->
      array1.concat array2

    p.sort = (array, numElem) ->
      ret = []
      if array.length > 0
        elemsToCopy = (if numElem > 0 then numElem else array.length)
        i = 0

        while i < elemsToCopy
          ret.push array[i]
          i++
        if typeof array[0] is "string"
          ret.sort()
        else
          ret.sort (a, b) ->
            a - b

        if numElem > 0
          j = ret.length

          while j < array.length
            ret.push array[j]
            j++
      ret

    p.splice = (array, value, index) ->
      return array  if value.length is 0
      if value instanceof Array
        i = 0
        j = index

        while i < value.length
          array.splice j, 0, value[i]
          j++
          i++
      else
        array.splice index, 0, value
      array

    p.subset = (array, offset, length) ->
      end = (if length isnt undef then offset + length else array.length)
      array.slice offset, end

    p.join = (array, seperator) ->
      array.join seperator

    p.shorten = (ary) ->
      newary = []
      len = ary.length
      i = 0

      while i < len
        newary[i] = ary[i]
        i++
      newary.pop()
      newary

    p.expand = (ary, targetSize) ->
      temp = ary.slice(0)
      newSize = targetSize or ary.length * 2
      temp.length = newSize
      temp

    p.arrayCopy = ->
      src = undefined
      srcPos = 0
      dest = undefined
      destPos = 0
      length = undefined
      if arguments.length is 2
        src = arguments[0]
        dest = arguments[1]
        length = src.length
      else if arguments.length is 3
        src = arguments[0]
        dest = arguments[1]
        length = arguments[2]
      else if arguments.length is 5
        src = arguments[0]
        srcPos = arguments[1]
        dest = arguments[2]
        destPos = arguments[3]
        length = arguments[4]
      i = srcPos
      j = destPos

      while i < length + srcPos
        if dest[j] isnt undef
          dest[j] = src[i]
        else
          throw "array index out of bounds exception"
        i++
        j++

    p.reverse = (array) ->
      array.reverse()

    p.mix = (a, b, f) ->
      a + ((b - a) * f >> 8)

    p.peg = (n) ->
      (if n < 0 then 0 else (if n > 255 then 255 else n))

    p.modes = ->
      applyMode = (c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb) ->
        a = min(((c1 & 4278190080) >>> 24) + f, 255) << 24
        r = ar + ((cr - ar) * f >> 8)
        r = ((if r < 0 then 0 else (if r > 255 then 255 else r))) << 16
        g = ag + ((cg - ag) * f >> 8)
        g = ((if g < 0 then 0 else (if g > 255 then 255 else g))) << 8
        b = ab + ((cb - ab) * f >> 8)
        b = (if b < 0 then 0 else (if b > 255 then 255 else b))
        a | r | g | b
      ALPHA_MASK = 4278190080
      RED_MASK = 16711680
      GREEN_MASK = 65280
      BLUE_MASK = 255
      min = Math.min
      max = Math.max
      replace: (c1, c2) ->
        c2

      blend: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = c1 & RED_MASK
        ag = c1 & GREEN_MASK
        ab = c1 & BLUE_MASK
        br = c2 & RED_MASK
        bg = c2 & GREEN_MASK
        bb = c2 & BLUE_MASK
        min(((c1 & ALPHA_MASK) >>> 24) + f, 255) << 24 | ar + ((br - ar) * f >> 8) & RED_MASK | ag + ((bg - ag) * f >> 8) & GREEN_MASK | ab + ((bb - ab) * f >> 8) & BLUE_MASK

      add: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        min(((c1 & ALPHA_MASK) >>> 24) + f, 255) << 24 | min((c1 & RED_MASK) + ((c2 & RED_MASK) >> 8) * f, RED_MASK) & RED_MASK | min((c1 & GREEN_MASK) + ((c2 & GREEN_MASK) >> 8) * f, GREEN_MASK) & GREEN_MASK | min((c1 & BLUE_MASK) + ((c2 & BLUE_MASK) * f >> 8), BLUE_MASK)

      subtract: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        min(((c1 & ALPHA_MASK) >>> 24) + f, 255) << 24 | max((c1 & RED_MASK) - ((c2 & RED_MASK) >> 8) * f, GREEN_MASK) & RED_MASK | max((c1 & GREEN_MASK) - ((c2 & GREEN_MASK) >> 8) * f, BLUE_MASK) & GREEN_MASK | max((c1 & BLUE_MASK) - ((c2 & BLUE_MASK) * f >> 8), 0)

      lightest: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        min(((c1 & ALPHA_MASK) >>> 24) + f, 255) << 24 | max(c1 & RED_MASK, ((c2 & RED_MASK) >> 8) * f) & RED_MASK | max(c1 & GREEN_MASK, ((c2 & GREEN_MASK) >> 8) * f) & GREEN_MASK | max(c1 & BLUE_MASK, (c2 & BLUE_MASK) * f >> 8)

      darkest: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = c1 & RED_MASK
        ag = c1 & GREEN_MASK
        ab = c1 & BLUE_MASK
        br = min(c1 & RED_MASK, ((c2 & RED_MASK) >> 8) * f)
        bg = min(c1 & GREEN_MASK, ((c2 & GREEN_MASK) >> 8) * f)
        bb = min(c1 & BLUE_MASK, (c2 & BLUE_MASK) * f >> 8)
        min(((c1 & ALPHA_MASK) >>> 24) + f, 255) << 24 | ar + ((br - ar) * f >> 8) & RED_MASK | ag + ((bg - ag) * f >> 8) & GREEN_MASK | ab + ((bb - ab) * f >> 8) & BLUE_MASK

      difference: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = (c1 & RED_MASK) >> 16
        ag = (c1 & GREEN_MASK) >> 8
        ab = c1 & BLUE_MASK
        br = (c2 & RED_MASK) >> 16
        bg = (c2 & GREEN_MASK) >> 8
        bb = c2 & BLUE_MASK
        cr = (if ar > br then ar - br else br - ar)
        cg = (if ag > bg then ag - bg else bg - ag)
        cb = (if ab > bb then ab - bb else bb - ab)
        applyMode c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb

      exclusion: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = (c1 & RED_MASK) >> 16
        ag = (c1 & GREEN_MASK) >> 8
        ab = c1 & BLUE_MASK
        br = (c2 & RED_MASK) >> 16
        bg = (c2 & GREEN_MASK) >> 8
        bb = c2 & BLUE_MASK
        cr = ar + br - (ar * br >> 7)
        cg = ag + bg - (ag * bg >> 7)
        cb = ab + bb - (ab * bb >> 7)
        applyMode c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb

      multiply: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = (c1 & RED_MASK) >> 16
        ag = (c1 & GREEN_MASK) >> 8
        ab = c1 & BLUE_MASK
        br = (c2 & RED_MASK) >> 16
        bg = (c2 & GREEN_MASK) >> 8
        bb = c2 & BLUE_MASK
        cr = ar * br >> 8
        cg = ag * bg >> 8
        cb = ab * bb >> 8
        applyMode c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb

      screen: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = (c1 & RED_MASK) >> 16
        ag = (c1 & GREEN_MASK) >> 8
        ab = c1 & BLUE_MASK
        br = (c2 & RED_MASK) >> 16
        bg = (c2 & GREEN_MASK) >> 8
        bb = c2 & BLUE_MASK
        cr = 255 - ((255 - ar) * (255 - br) >> 8)
        cg = 255 - ((255 - ag) * (255 - bg) >> 8)
        cb = 255 - ((255 - ab) * (255 - bb) >> 8)
        applyMode c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb

      hard_light: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = (c1 & RED_MASK) >> 16
        ag = (c1 & GREEN_MASK) >> 8
        ab = c1 & BLUE_MASK
        br = (c2 & RED_MASK) >> 16
        bg = (c2 & GREEN_MASK) >> 8
        bb = c2 & BLUE_MASK
        cr = (if br < 128 then ar * br >> 7 else 255 - ((255 - ar) * (255 - br) >> 7))
        cg = (if bg < 128 then ag * bg >> 7 else 255 - ((255 - ag) * (255 - bg) >> 7))
        cb = (if bb < 128 then ab * bb >> 7 else 255 - ((255 - ab) * (255 - bb) >> 7))
        applyMode c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb

      soft_light: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = (c1 & RED_MASK) >> 16
        ag = (c1 & GREEN_MASK) >> 8
        ab = c1 & BLUE_MASK
        br = (c2 & RED_MASK) >> 16
        bg = (c2 & GREEN_MASK) >> 8
        bb = c2 & BLUE_MASK
        cr = (ar * br >> 7) + (ar * ar >> 8) - (ar * ar * br >> 15)
        cg = (ag * bg >> 7) + (ag * ag >> 8) - (ag * ag * bg >> 15)
        cb = (ab * bb >> 7) + (ab * ab >> 8) - (ab * ab * bb >> 15)
        applyMode c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb

      overlay: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = (c1 & RED_MASK) >> 16
        ag = (c1 & GREEN_MASK) >> 8
        ab = c1 & BLUE_MASK
        br = (c2 & RED_MASK) >> 16
        bg = (c2 & GREEN_MASK) >> 8
        bb = c2 & BLUE_MASK
        cr = (if ar < 128 then ar * br >> 7 else 255 - ((255 - ar) * (255 - br) >> 7))
        cg = (if ag < 128 then ag * bg >> 7 else 255 - ((255 - ag) * (255 - bg) >> 7))
        cb = (if ab < 128 then ab * bb >> 7 else 255 - ((255 - ab) * (255 - bb) >> 7))
        applyMode c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb

      dodge: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = (c1 & RED_MASK) >> 16
        ag = (c1 & GREEN_MASK) >> 8
        ab = c1 & BLUE_MASK
        br = (c2 & RED_MASK) >> 16
        bg = (c2 & GREEN_MASK) >> 8
        bb = c2 & BLUE_MASK
        cr = 255
        if br isnt 255
          cr = (ar << 8) / (255 - br)
          cr = (if cr < 0 then 0 else (if cr > 255 then 255 else cr))
        cg = 255
        if bg isnt 255
          cg = (ag << 8) / (255 - bg)
          cg = (if cg < 0 then 0 else (if cg > 255 then 255 else cg))
        cb = 255
        if bb isnt 255
          cb = (ab << 8) / (255 - bb)
          cb = (if cb < 0 then 0 else (if cb > 255 then 255 else cb))
        applyMode c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb

      burn: (c1, c2) ->
        f = (c2 & ALPHA_MASK) >>> 24
        ar = (c1 & RED_MASK) >> 16
        ag = (c1 & GREEN_MASK) >> 8
        ab = c1 & BLUE_MASK
        br = (c2 & RED_MASK) >> 16
        bg = (c2 & GREEN_MASK) >> 8
        bb = c2 & BLUE_MASK
        cr = 0
        if br isnt 0
          cr = (255 - ar << 8) / br
          cr = 255 - ((if cr < 0 then 0 else (if cr > 255 then 255 else cr)))
        cg = 0
        if bg isnt 0
          cg = (255 - ag << 8) / bg
          cg = 255 - ((if cg < 0 then 0 else (if cg > 255 then 255 else cg)))
        cb = 0
        if bb isnt 0
          cb = (255 - ab << 8) / bb
          cb = 255 - ((if cb < 0 then 0 else (if cb > 255 then 255 else cb)))
        applyMode c1, f, ar, ag, ab, br, bg, bb, cr, cg, cb
    ()
    p.color = (aValue1, aValue2, aValue3, aValue4) ->
      return color$4(aValue1, aValue2, aValue3, aValue4)  if aValue1 isnt undef and aValue2 isnt undef and aValue3 isnt undef and aValue4 isnt undef
      return color$4(aValue1, aValue2, aValue3, colorModeA)  if aValue1 isnt undef and aValue2 isnt undef and aValue3 isnt undef
      return color$2(aValue1, aValue2)  if aValue1 isnt undef and aValue2 isnt undef
      return color$1(aValue1)  if typeof aValue1 is "number"
      color$4 colorModeX, colorModeY, colorModeZ, colorModeA

    p.color.toString = (colorInt) ->
      "rgba(" + ((colorInt >> 16) & 255) + "," + ((colorInt >> 8) & 255) + "," + (colorInt & 255) + "," + ((colorInt >> 24) & 255) / 255 + ")"

    p.color.toInt = (r, g, b, a) ->
      a << 24 & 4278190080 | r << 16 & 16711680 | g << 8 & 65280 | b & 255

    p.color.toArray = (colorInt) ->
      [ (colorInt >> 16) & 255, (colorInt >> 8) & 255, colorInt & 255, (colorInt >> 24) & 255 ]

    p.color.toGLArray = (colorInt) ->
      [ ((colorInt & 16711680) >>> 16) / 255, ((colorInt >> 8) & 255) / 255, (colorInt & 255) / 255, ((colorInt >> 24) & 255) / 255 ]

    p.color.toRGB = (h, s, b) ->
      h = (if h > colorModeX then colorModeX else h)
      s = (if s > colorModeY then colorModeY else s)
      b = (if b > colorModeZ then colorModeZ else b)
      h = h / colorModeX * 360
      s = s / colorModeY * 100
      b = b / colorModeZ * 100
      br = Math.round(b / 100 * 255)
      return [ br, br, br ]  if s is 0
      hue = h % 360
      f = hue % 60
      p = Math.round(b * (100 - s) / 1E4 * 255)
      q = Math.round(b * (6E3 - s * f) / 6E5 * 255)
      t = Math.round(b * (6E3 - s * (60 - f)) / 6E5 * 255)
      switch Math.floor(hue / 60)
        when 0
          [ br, t, p ]
        when 1
          [ q, br, p ]
        when 2
          [ p, br, t ]
        when 3
          [ p, q, br ]
        when 4
          [ t, p, br ]
        when 5
          [ br, p, q ]

    p.brightness = (colInt) ->
      colorToHSB(colInt)[2]

    p.saturation = (colInt) ->
      colorToHSB(colInt)[1]

    p.hue = (colInt) ->
      colorToHSB(colInt)[0]

    p.red = (aColor) ->
      ((aColor >> 16) & 255) / 255 * colorModeX

    p.green = (aColor) ->
      ((aColor & 65280) >>> 8) / 255 * colorModeY

    p.blue = (aColor) ->
      (aColor & 255) / 255 * colorModeZ

    p.alpha = (aColor) ->
      ((aColor >> 24) & 255) / 255 * colorModeA

    p.lerpColor = (c1, c2, amt) ->
      r = undefined
      g = undefined
      b = undefined
      a = undefined
      r1 = undefined
      g1 = undefined
      b1 = undefined
      a1 = undefined
      r2 = undefined
      g2 = undefined
      b2 = undefined
      a2 = undefined
      hsb1 = undefined
      hsb2 = undefined
      rgb = undefined
      h = undefined
      s = undefined
      colorBits1 = p.color(c1)
      colorBits2 = p.color(c2)
      if curColorMode is 3
        hsb1 = colorToHSB(colorBits1)
        a1 = ((colorBits1 >> 24) & 255) / colorModeA
        hsb2 = colorToHSB(colorBits2)
        a2 = ((colorBits2 & 4278190080) >>> 24) / colorModeA
        h = p.lerp(hsb1[0], hsb2[0], amt)
        s = p.lerp(hsb1[1], hsb2[1], amt)
        b = p.lerp(hsb1[2], hsb2[2], amt)
        rgb = p.color.toRGB(h, s, b)
        a = p.lerp(a1, a2, amt) * colorModeA
        return a << 24 & 4278190080 | (rgb[0] & 255) << 16 | (rgb[1] & 255) << 8 | rgb[2] & 255
      r1 = (colorBits1 >> 16) & 255
      g1 = (colorBits1 >> 8) & 255
      b1 = colorBits1 & 255
      a1 = ((colorBits1 >> 24) & 255) / colorModeA
      r2 = (colorBits2 & 16711680) >>> 16
      g2 = (colorBits2 >> 8) & 255
      b2 = colorBits2 & 255
      a2 = ((colorBits2 >> 24) & 255) / colorModeA
      r = p.lerp(r1, r2, amt) | 0
      g = p.lerp(g1, g2, amt) | 0
      b = p.lerp(b1, b2, amt) | 0
      a = p.lerp(a1, a2, amt) * colorModeA
      a << 24 & 4278190080 | r << 16 & 16711680 | g << 8 & 65280 | b & 255

    p.colorMode = ->
      curColorMode = arguments[0]
      if arguments.length > 1
        colorModeX = arguments[1]
        colorModeY = arguments[2] or arguments[1]
        colorModeZ = arguments[3] or arguments[1]
        colorModeA = arguments[4] or arguments[1]

    p.blendColor = (c1, c2, mode) ->
      if mode is 0
        p.modes.replace c1, c2
      else if mode is 1
        p.modes.blend c1, c2
      else if mode is 2
        p.modes.add c1, c2
      else if mode is 4
        p.modes.subtract c1, c2
      else if mode is 8
        p.modes.lightest c1, c2
      else if mode is 16
        p.modes.darkest c1, c2
      else if mode is 32
        p.modes.difference c1, c2
      else if mode is 64
        p.modes.exclusion c1, c2
      else if mode is 128
        p.modes.multiply c1, c2
      else if mode is 256
        p.modes.screen c1, c2
      else if mode is 1024
        p.modes.hard_light c1, c2
      else if mode is 2048
        p.modes.soft_light c1, c2
      else if mode is 512
        p.modes.overlay c1, c2
      else if mode is 4096
        p.modes.dodge c1, c2
      else p.modes.burn c1, c2  if mode is 8192

    p.printMatrix = ->
      modelView.print()

    Drawing2D::translate = (x, y) ->
      modelView.translate x, y
      modelViewInv.invTranslate x, y
      curContext.translate x, y

    Drawing3D::translate = (x, y, z) ->
      modelView.translate x, y, z
      modelViewInv.invTranslate x, y, z

    Drawing2D::scale = (x, y) ->
      modelView.scale x, y
      modelViewInv.invScale x, y
      curContext.scale x, y or x

    Drawing3D::scale = (x, y, z) ->
      modelView.scale x, y, z
      modelViewInv.invScale x, y, z

    Drawing2D::transform = (pmatrix) ->
      e = pmatrix.array()
      curContext.transform e[0], e[3], e[1], e[4], e[2], e[5]

    Drawing3D::transformm = (pmatrix3d) ->
      throw "p.transform is currently not supported in 3D mode"

    Drawing2D::pushMatrix = ->
      userMatrixStack.load modelView
      userReverseMatrixStack.load modelViewInv
      saveContext()

    Drawing3D::pushMatrix = ->
      userMatrixStack.load modelView
      userReverseMatrixStack.load modelViewInv

    Drawing2D::popMatrix = ->
      modelView.set userMatrixStack.pop()
      modelViewInv.set userReverseMatrixStack.pop()
      restoreContext()

    Drawing3D::popMatrix = ->
      modelView.set userMatrixStack.pop()
      modelViewInv.set userReverseMatrixStack.pop()

    Drawing2D::resetMatrix = ->
      modelView.reset()
      modelViewInv.reset()
      curContext.setTransform 1, 0, 0, 1, 0, 0

    Drawing3D::resetMatrix = ->
      modelView.reset()
      modelViewInv.reset()

    DrawingShared::applyMatrix = ->
      a = arguments
      modelView.apply a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12], a[13], a[14], a[15]
      modelViewInv.invApply a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12], a[13], a[14], a[15]

    Drawing2D::applyMatrix = ->
      a = arguments
      cnt = a.length

      while cnt < 16
        a[cnt] = 0
        cnt++
      a[10] = a[15] = 1
      DrawingShared::applyMatrix.apply this, a

    p.rotateX = (angleInRadians) ->
      modelView.rotateX angleInRadians
      modelViewInv.invRotateX angleInRadians

    Drawing2D::rotateZ = ->
      throw "rotateZ() is not supported in 2D mode. Use rotate(float) instead."

    Drawing3D::rotateZ = (angleInRadians) ->
      modelView.rotateZ angleInRadians
      modelViewInv.invRotateZ angleInRadians

    p.rotateY = (angleInRadians) ->
      modelView.rotateY angleInRadians
      modelViewInv.invRotateY angleInRadians

    Drawing2D::rotate = (angleInRadians) ->
      modelView.rotateZ angleInRadians
      modelViewInv.invRotateZ angleInRadians
      curContext.rotate angleInRadians

    Drawing3D::rotate = (angleInRadians) ->
      p.rotateZ angleInRadians

    Drawing2D::shearX = (angleInRadians) ->
      modelView.shearX angleInRadians
      curContext.transform 1, 0, angleInRadians, 1, 0, 0

    Drawing3D::shearX = (angleInRadians) ->
      modelView.shearX angleInRadians

    Drawing2D::shearY = (angleInRadians) ->
      modelView.shearY angleInRadians
      curContext.transform 1, angleInRadians, 0, 1, 0, 0

    Drawing3D::shearY = (angleInRadians) ->
      modelView.shearY angleInRadians

    p.pushStyle = ->
      saveContext()
      p.pushMatrix()
      newState =
        doFill: doFill
        currentFillColor: currentFillColor
        doStroke: doStroke
        currentStrokeColor: currentStrokeColor
        curTint: curTint
        curRectMode: curRectMode
        curColorMode: curColorMode
        colorModeX: colorModeX
        colorModeZ: colorModeZ
        colorModeY: colorModeY
        colorModeA: colorModeA
        curTextFont: curTextFont
        horizontalTextAlignment: horizontalTextAlignment
        verticalTextAlignment: verticalTextAlignment
        textMode: textMode
        curFontName: curFontName
        curTextSize: curTextSize
        curTextAscent: curTextAscent
        curTextDescent: curTextDescent
        curTextLeading: curTextLeading

      styleArray.push newState

    p.popStyle = ->
      oldState = styleArray.pop()
      if oldState
        restoreContext()
        p.popMatrix()
        doFill = oldState.doFill
        currentFillColor = oldState.currentFillColor
        doStroke = oldState.doStroke
        currentStrokeColor = oldState.currentStrokeColor
        curTint = oldState.curTint
        curRectMode = oldState.curRectMode
        curColorMode = oldState.curColorMode
        colorModeX = oldState.colorModeX
        colorModeZ = oldState.colorModeZ
        colorModeY = oldState.colorModeY
        colorModeA = oldState.colorModeA
        curTextFont = oldState.curTextFont
        curFontName = oldState.curFontName
        curTextSize = oldState.curTextSize
        horizontalTextAlignment = oldState.horizontalTextAlignment
        verticalTextAlignment = oldState.verticalTextAlignment
        textMode = oldState.textMode
        curTextAscent = oldState.curTextAscent
        curTextDescent = oldState.curTextDescent
        curTextLeading = oldState.curTextLeading
      else
        throw "Too many popStyle() without enough pushStyle()"

    p.year = ->
      (new Date).getFullYear()

    p.month = ->
      (new Date).getMonth() + 1

    p.day = ->
      (new Date).getDate()

    p.hour = ->
      (new Date).getHours()

    p.minute = ->
      (new Date).getMinutes()

    p.second = ->
      (new Date).getSeconds()

    p.millis = ->
      Date.now() - start

    Drawing2D::redraw = ->
      redrawHelper()
      curContext.lineWidth = lineWidth
      pmouseXLastEvent = p.pmouseX
      pmouseYLastEvent = p.pmouseY
      p.pmouseX = pmouseXLastFrame
      p.pmouseY = pmouseYLastFrame
      saveContext()
      p.draw()
      restoreContext()
      pmouseXLastFrame = p.mouseX
      pmouseYLastFrame = p.mouseY
      p.pmouseX = pmouseXLastEvent
      p.pmouseY = pmouseYLastEvent

    Drawing3D::redraw = ->
      redrawHelper()
      pmouseXLastEvent = p.pmouseX
      pmouseYLastEvent = p.pmouseY
      p.pmouseX = pmouseXLastFrame
      p.pmouseY = pmouseYLastFrame
      curContext.clear curContext.DEPTH_BUFFER_BIT
      curContextCache =
        attributes: {}
        locations: {}

      p.noLights()
      p.lightFalloff 1, 0, 0
      p.shininess 1
      p.ambient 255, 255, 255
      p.specular 0, 0, 0
      p.emissive 0, 0, 0
      p.camera()
      p.draw()
      pmouseXLastFrame = p.mouseX
      pmouseYLastFrame = p.mouseY
      p.pmouseX = pmouseXLastEvent
      p.pmouseY = pmouseYLastEvent

    p.noLoop = ->
      doLoop = false
      loopStarted = false
      clearInterval looping
      curSketch.onPause()

    p.loop = ->
      return  if loopStarted
      timeSinceLastFPS = Date.now()
      framesSinceLastFPS = 0
      looping = window.setInterval(->
        try
          curSketch.onFrameStart()
          p.redraw()
          curSketch.onFrameEnd()
        catch e_loop
          window.clearInterval looping
          throw e_loop
      , curMsPerFrame)
      doLoop = true
      loopStarted = true
      curSketch.onLoop()

    p.frameRate = (aRate) ->
      curFrameRate = aRate
      curMsPerFrame = 1E3 / curFrameRate
      if doLoop
        p.noLoop()
        p.loop()

    eventHandlers = []
    p.exit = ->
      window.clearInterval looping
      removeInstance p.externals.canvas.id
      delete curElement.onmousedown

      for lib of Processing.lib
        Processing.lib[lib].detach p  if Processing.lib[lib].hasOwnProperty("detach")  if Processing.lib.hasOwnProperty(lib)
      i = eventHandlers.length
      detachEventHandler eventHandlers[i]  while i--
      curSketch.onExit()

    p.cursor = ->
      if arguments.length > 1 or arguments.length is 1 and arguments[0] instanceof p.PImage
        image = arguments[0]
        x = undefined
        y = undefined
        if arguments.length >= 3
          x = arguments[1]
          y = arguments[2]
          throw "x and y must be non-negative and less than the dimensions of the image"  if x < 0 or y < 0 or y >= image.height or x >= image.width
        else
          x = image.width >>> 1
          y = image.height >>> 1
        imageDataURL = image.toDataURL()
        style = "url(\"" + imageDataURL + "\") " + x + " " + y + ", default"
        curCursor = curElement.style.cursor = style
      else if arguments.length is 1
        mode = arguments[0]
        curCursor = curElement.style.cursor = mode
      else
        curCursor = curElement.style.cursor = oldCursor

    p.noCursor = ->
      curCursor = curElement.style.cursor = PConstants.NOCURSOR

    p.link = (href, target) ->
      if target isnt undef
        window.open href, target
      else
        window.location = href

    p.beginDraw = nop
    p.endDraw = nop
    Drawing2D::toImageData = (x, y, w, h) ->
      x = (if x isnt undef then x else 0)
      y = (if y isnt undef then y else 0)
      w = (if w isnt undef then w else p.width)
      h = (if h isnt undef then h else p.height)
      curContext.getImageData x, y, w, h

    Drawing3D::toImageData = (x, y, w, h) ->
      x = (if x isnt undef then x else 0)
      y = (if y isnt undef then y else 0)
      w = (if w isnt undef then w else p.width)
      h = (if h isnt undef then h else p.height)
      c = document.createElement("canvas")
      ctx = c.getContext("2d")
      obj = ctx.createImageData(w, h)
      uBuff = new Uint8Array(w * h * 4)
      curContext.readPixels x, y, w, h, curContext.RGBA, curContext.UNSIGNED_BYTE, uBuff
      i = 0
      ul = uBuff.length
      obj_data = obj.data

      while i < ul
        obj_data[i] = uBuff[(h - 1 - Math.floor(i / 4 / w)) * w * 4 + i % (w * 4)]
        i++
      obj

    p.status = (text) ->
      window.status = text

    p.binary = (num, numBits) ->
      bit = undefined
      if numBits > 0
        bit = numBits
      else if num instanceof Char
        bit = 16
        num |= 0
      else
        bit = 32
        bit--  while bit > 1 and not (num >>> bit - 1 & 1)
      result = ""
      result += (if num >>> --bit & 1 then "1" else "0")  while bit > 0
      result

    p.unbinary = (binaryString) ->
      i = binaryString.length - 1
      mask = 1
      result = 0
      while i >= 0
        ch = binaryString[i--]
        throw "the value passed into unbinary was not an 8 bit binary number"  if ch isnt "0" and ch isnt "1"
        result += mask  if ch is "1"
        mask <<= 1
      result

    p.nf = (value, leftDigits, rightDigits) ->
      nfCore value, "", "-", leftDigits, rightDigits

    p.nfs = (value, leftDigits, rightDigits) ->
      nfCore value, " ", "-", leftDigits, rightDigits

    p.nfp = (value, leftDigits, rightDigits) ->
      nfCore value, "+", "-", leftDigits, rightDigits

    p.nfc = (value, leftDigits, rightDigits) ->
      nfCore value, "", "-", leftDigits, rightDigits, ","

    decimalToHex = (d, padding) ->
      padding = (if padding is undef or padding is null then padding = 8 else padding)
      d = 4294967295 + d + 1  if d < 0
      hex = Number(d).toString(16).toUpperCase()
      hex = "0" + hex  while hex.length < padding
      hex = hex.substring(hex.length - padding, hex.length)  if hex.length >= padding
      hex

    p.hex = (value, len) ->
      if arguments.length is 1
        if value instanceof Char
          len = 4
        else
          len = 8
      decimalToHex value, len

    p.unhex = (hex) ->
      if hex instanceof Array
        arr = []
        i = 0

        while i < hex.length
          arr.push unhexScalar(hex[i])
          i++
        return arr
      unhexScalar hex

    p.loadStrings = (filename) ->
      return localStorage[filename].split("\n")  if localStorage[filename]
      filecontent = ajax(filename)
      return []  if typeof filecontent isnt "string" or filecontent is ""
      filecontent = filecontent.replace(/(\r\n?)/g, "\n").replace(/\n$/, "")
      filecontent.split "\n"

    p.saveStrings = (filename, strings) ->
      localStorage[filename] = strings.join("\n")

    p.loadBytes = (url) ->
      string = ajax(url)
      ret = []
      i = 0

      while i < string.length
        ret.push string.charCodeAt(i)
        i++
      ret

    p.matchAll = (aString, aRegExp) ->
      results = []
      latest = undefined
      regexp = new RegExp(aRegExp, "g")
      while (latest = regexp.exec(aString)) isnt null
        results.push latest
        ++regexp.lastIndex  if latest[0].length is 0
      (if results.length > 0 then results else null)

    p.__contains = (subject, subStr) ->
      return subject.contains.apply(subject, removeFirstArgument(arguments))  if typeof subject isnt "string"
      subject isnt null and subStr isnt null and typeof subStr is "string" and subject.indexOf(subStr) > -1

    p.__replaceAll = (subject, regex, replacement) ->
      return subject.replaceAll.apply(subject, removeFirstArgument(arguments))  if typeof subject isnt "string"
      subject.replace new RegExp(regex, "g"), replacement

    p.__replaceFirst = (subject, regex, replacement) ->
      return subject.replaceFirst.apply(subject, removeFirstArgument(arguments))  if typeof subject isnt "string"
      subject.replace new RegExp(regex, ""), replacement

    p.__replace = (subject, what, replacement) ->
      return subject.replace.apply(subject, removeFirstArgument(arguments))  if typeof subject isnt "string"
      return subject.replace(what, replacement)  if what instanceof RegExp
      what = what.toString()  if typeof what isnt "string"
      return subject  if what is ""
      i = subject.indexOf(what)
      return subject  if i < 0
      j = 0
      result = ""
      loop
        result += subject.substring(j, i) + replacement
        j = i + what.length
        break unless (i = subject.indexOf(what, j)) >= 0
      result + subject.substring(j)

    p.__equals = (subject, other) ->
      return subject.equals.apply(subject, removeFirstArgument(arguments))  if subject.equals instanceof Function
      subject.valueOf() is other.valueOf()

    p.__equalsIgnoreCase = (subject, other) ->
      return subject.equalsIgnoreCase.apply(subject, removeFirstArgument(arguments))  if typeof subject isnt "string"
      subject.toLowerCase() is other.toLowerCase()

    p.__toCharArray = (subject) ->
      return subject.toCharArray.apply(subject, removeFirstArgument(arguments))  if typeof subject isnt "string"
      chars = []
      i = 0
      len = subject.length

      while i < len
        chars[i] = new Char(subject.charAt(i))
        ++i
      chars

    p.__split = (subject, regex, limit) ->
      return subject.split.apply(subject, removeFirstArgument(arguments))  if typeof subject isnt "string"
      pattern = new RegExp(regex)
      return subject.split(pattern)  if limit is undef or limit < 1
      result = []
      currSubject = subject
      pos = undefined
      while (pos = currSubject.search(pattern)) isnt -1 and result.length < limit - 1
        match = pattern.exec(currSubject).toString()
        result.push currSubject.substring(0, pos)
        currSubject = currSubject.substring(pos + match.length)
      result.push currSubject  if pos isnt -1 or currSubject isnt ""
      result

    p.__codePointAt = (subject, idx) ->
      code = subject.charCodeAt(idx)
      hi = undefined
      low = undefined
      if 55296 <= code and code <= 56319
        hi = code
        low = subject.charCodeAt(idx + 1)
        return (hi - 55296) * 1024 + (low - 56320) + 65536
      code

    p.match = (str, regexp) ->
      str.match regexp

    p.__matches = (str, regexp) ->
      (new RegExp(regexp)).test str

    p.__startsWith = (subject, prefix, toffset) ->
      return subject.startsWith.apply(subject, removeFirstArgument(arguments))  if typeof subject isnt "string"
      toffset = toffset or 0
      return false  if toffset < 0 or toffset > subject.length
      (if prefix is "" or prefix is subject then true else subject.indexOf(prefix) is toffset)

    p.__endsWith = (subject, suffix) ->
      return subject.endsWith.apply(subject, removeFirstArgument(arguments))  if typeof subject isnt "string"
      suffixLen = (if suffix then suffix.length else 0)
      (if suffix is "" or suffix is subject then true else subject.indexOf(suffix) is subject.length - suffixLen)

    p.__hashCode = (subject) ->
      return subject.hashCode.apply(subject, removeFirstArgument(arguments))  if subject.hashCode instanceof Function
      virtHashCode subject

    p.__printStackTrace = (subject) ->
      p.println "Exception: " + subject.toString()

    logBuffer = []
    p.println = (message) ->
      bufferLen = logBuffer.length
      if bufferLen
        Processing.logger.log logBuffer.join("")
        logBuffer.length = 0
      if arguments.length is 0 and bufferLen is 0
        Processing.logger.log ""
      else Processing.logger.log message  if arguments.length isnt 0

    p.print = (message) ->
      logBuffer.push message

    p.str = (val) ->
      if val instanceof Array
        arr = []
        i = 0

        while i < val.length
          arr.push val[i].toString() + ""
          i++
        return arr
      val.toString() + ""

    p.trim = (str) ->
      if str instanceof Array
        arr = []
        i = 0

        while i < str.length
          arr.push str[i].replace(/^\s*/, "").replace(/\s*$/, "").replace(/\r*$/, "")
          i++
        return arr
      str.replace(/^\s*/, "").replace(/\s*$/, "").replace /\r*$/, ""

    p.parseBoolean = (val) ->
      if val instanceof Array
        ret = []
        i = 0

        while i < val.length
          ret.push booleanScalar(val[i])
          i++
        return ret
      booleanScalar val

    p.parseByte = (what) ->
      if what instanceof Array
        bytes = []
        i = 0

        while i < what.length
          bytes.push 0 - (what[i] & 128) | what[i] & 127
          i++
        return bytes
      0 - (what & 128) | what & 127

    p.parseChar = (key) ->
      return new Char(String.fromCharCode(key & 65535))  if typeof key is "number"
      if key instanceof Array
        ret = []
        i = 0

        while i < key.length
          ret.push new Char(String.fromCharCode(key[i] & 65535))
          i++
        return ret
      throw "char() may receive only one argument of type int, byte, int[], or byte[]."

    p.parseFloat = (val) ->
      if val instanceof Array
        ret = []
        i = 0

        while i < val.length
          ret.push floatScalar(val[i])
          i++
        return ret
      floatScalar val

    p.parseInt = (val, radix) ->
      if val instanceof Array
        ret = []
        i = 0

        while i < val.length
          if typeof val[i] is "string" and not /^\s*[+\-]?\d+\s*$/.test(val[i])
            ret.push 0
          else
            ret.push intScalar(val[i], radix)
          i++
        return ret
      intScalar val, radix

    p.__int_cast = (val) ->
      0 | val

    p.__instanceof = (obj, type) ->
      throw "Function is expected as type argument for instanceof operator"  if typeof type isnt "function"
      return type is Object or type is String  if typeof obj is "string"
      return true  if obj instanceof type
      return false  if typeof obj isnt "object" or obj is null
      objType = obj.constructor
      if type.$isInterface
        interfaces = []
        while objType
          interfaces = interfaces.concat(objType.$interfaces)  if objType.$interfaces
          objType = objType.$base
        while interfaces.length > 0
          i = interfaces.shift()
          return true  if i is type
          interfaces = interfaces.concat(i.$interfaces)  if i.$interfaces
        return false
      while objType.hasOwnProperty("$base")
        objType = objType.$base
        return true  if objType is type
      false

    p.abs = Math.abs
    p.ceil = Math.ceil
    p.constrain = (aNumber, aMin, aMax) ->
      (if aNumber > aMax then aMax else (if aNumber < aMin then aMin else aNumber))

    p.dist = ->
      dx = undefined
      dy = undefined
      dz = undefined
      if arguments.length is 4
        dx = arguments[0] - arguments[2]
        dy = arguments[1] - arguments[3]
        return Math.sqrt(dx * dx + dy * dy)
      if arguments.length is 6
        dx = arguments[0] - arguments[3]
        dy = arguments[1] - arguments[4]
        dz = arguments[2] - arguments[5]
        Math.sqrt dx * dx + dy * dy + dz * dz

    p.exp = Math.exp
    p.floor = Math.floor
    p.lerp = (value1, value2, amt) ->
      (value2 - value1) * amt + value1

    p.log = Math.log
    p.mag = (a, b, c) ->
      return Math.sqrt(a * a + b * b + c * c)  if c
      Math.sqrt a * a + b * b

    p.map = (value, istart, istop, ostart, ostop) ->
      ostart + (ostop - ostart) * ((value - istart) / (istop - istart))

    p.max = ->
      return (if arguments[0] < arguments[1] then arguments[1] else arguments[0])  if arguments.length is 2
      numbers = (if arguments.length is 1 then arguments[0] else arguments)
      throw "Non-empty array is expected"  unless "length" of numbers and numbers.length > 0
      max = numbers[0]
      count = numbers.length
      i = 1

      while i < count
        max = numbers[i]  if max < numbers[i]
        ++i
      max

    p.min = ->
      return (if arguments[0] < arguments[1] then arguments[0] else arguments[1])  if arguments.length is 2
      numbers = (if arguments.length is 1 then arguments[0] else arguments)
      throw "Non-empty array is expected"  unless "length" of numbers and numbers.length > 0
      min = numbers[0]
      count = numbers.length
      i = 1

      while i < count
        min = numbers[i]  if min > numbers[i]
        ++i
      min

    p.norm = (aNumber, low, high) ->
      (aNumber - low) / (high - low)

    p.pow = Math.pow
    p.round = Math.round
    p.sq = (aNumber) ->
      aNumber * aNumber

    p.sqrt = Math.sqrt
    p.acos = Math.acos
    p.asin = Math.asin
    p.atan = Math.atan
    p.atan2 = Math.atan2
    p.cos = Math.cos
    p.degrees = (aAngle) ->
      aAngle * 180 / Math.PI

    p.radians = (aAngle) ->
      aAngle / 180 * Math.PI

    p.sin = Math.sin
    p.tan = Math.tan
    currentRandom = Math.random
    p.random = ->
      return currentRandom()  if arguments.length is 0
      return currentRandom() * arguments[0]  if arguments.length is 1
      aMin = arguments[0]
      aMax = arguments[1]
      currentRandom() * (aMax - aMin) + aMin

    Marsaglia.createRandomized = ->
      now = new Date
      new Marsaglia(now / 6E4 & 4294967295, now & 4294967295)

    p.randomSeed = (seed) ->
      currentRandom = (new Marsaglia(seed)).nextDouble

    p.Random = (seed) ->
      haveNextNextGaussian = false
      nextNextGaussian = undefined
      random = undefined
      @nextGaussian = ->
        if haveNextNextGaussian
          haveNextNextGaussian = false
          return nextNextGaussian
        v1 = undefined
        v2 = undefined
        s = undefined
        loop
          v1 = 2 * random() - 1
          v2 = 2 * random() - 1
          s = v1 * v1 + v2 * v2
          break unless s >= 1 or s is 0
        multiplier = Math.sqrt(-2 * Math.log(s) / s)
        nextNextGaussian = v2 * multiplier
        haveNextNextGaussian = true
        v1 * multiplier

      random = (if seed is undef then Math.random else (new Marsaglia(seed)).nextDouble)

    noiseProfile =
      generator: undef
      octaves: 4
      fallout: 0.5
      seed: undef

    p.noise = (x, y, z) ->
      noiseProfile.generator = new PerlinNoise(noiseProfile.seed)  if noiseProfile.generator is undef
      generator = noiseProfile.generator
      effect = 1
      k = 1
      sum = 0
      i = 0

      while i < noiseProfile.octaves
        effect *= noiseProfile.fallout
        switch arguments.length
          when 1
            sum += effect * (1 + generator.noise1d(k * x)) / 2
          when 2
            sum += effect * (1 + generator.noise2d(k * x, k * y)) / 2
          when 3
            sum += effect * (1 + generator.noise3d(k * x, k * y, k * z)) / 2
        k *= 2
        ++i
      sum

    p.noiseDetail = (octaves, fallout) ->
      noiseProfile.octaves = octaves
      noiseProfile.fallout = fallout  if fallout isnt undef

    p.noiseSeed = (seed) ->
      noiseProfile.seed = seed
      noiseProfile.generator = undef

    DrawingShared::size = (aWidth, aHeight, aMode) ->
      p.stroke 0  if doStroke
      p.fill 255  if doFill
      savedProperties =
        fillStyle: curContext.fillStyle
        strokeStyle: curContext.strokeStyle
        lineCap: curContext.lineCap
        lineJoin: curContext.lineJoin

      if curElement.style.length > 0
        curElement.style.removeProperty "width"
        curElement.style.removeProperty "height"
      curElement.width = p.width = aWidth or 100
      curElement.height = p.height = aHeight or 100
      for prop of savedProperties
        curContext[prop] = savedProperties[prop]  if savedProperties.hasOwnProperty(prop)
      p.textFont curTextFont
      p.background()
      maxPixelsCached = Math.max(1E3, aWidth * aHeight * 0.05)
      p.externals.context = curContext
      i = 0

      while i < 720
        sinLUT[i] = p.sin(i * (Math.PI / 180) * 0.5)
        cosLUT[i] = p.cos(i * (Math.PI / 180) * 0.5)
        i++

    Drawing2D::size = (aWidth, aHeight, aMode) ->
      if curContext is undef
        curContext = curElement.getContext("2d")
        userMatrixStack = new PMatrixStack
        userReverseMatrixStack = new PMatrixStack
        modelView = new PMatrix2D
        modelViewInv = new PMatrix2D
      DrawingShared::size.apply this, arguments

    Drawing3D::size = ->
      size3DCalled = false
      size = (aWidth, aHeight, aMode) ->
        getGLContext = (canvas) ->
          ctxNames = [ "experimental-webgl", "webgl", "webkit-3d" ]
          gl = undefined
          i = 0
          l = ctxNames.length

          while i < l
            gl = canvas.getContext(ctxNames[i],
              antialias: false
              preserveDrawingBuffer: true
            )
            break  if gl
            i++
          gl
        throw "Multiple calls to size() for 3D renders are not allowed."  if size3DCalled
        size3DCalled = true
        try
          curElement.width = p.width = aWidth or 100
          curElement.height = p.height = aHeight or 100
          curContext = getGLContext(curElement)
          canTex = curContext.createTexture()
          textTex = curContext.createTexture()
        catch e_size
          Processing.debug e_size
        throw "WebGL context is not supported on this browser."  unless curContext
        curContext.viewport 0, 0, curElement.width, curElement.height
        curContext.enable curContext.DEPTH_TEST
        curContext.enable curContext.BLEND
        curContext.blendFunc curContext.SRC_ALPHA, curContext.ONE_MINUS_SRC_ALPHA
        programObject2D = createProgramObject(curContext, vertexShaderSrc2D, fragmentShaderSrc2D)
        programObjectUnlitShape = createProgramObject(curContext, vertexShaderSrcUnlitShape, fragmentShaderSrcUnlitShape)
        p.strokeWeight 1
        programObject3D = createProgramObject(curContext, vertexShaderSrc3D, fragmentShaderSrc3D)
        curContext.useProgram programObject3D
        uniformi "usingTexture3d", programObject3D, "usingTexture", usingTexture
        p.lightFalloff 1, 0, 0
        p.shininess 1
        p.ambient 255, 255, 255
        p.specular 0, 0, 0
        p.emissive 0, 0, 0
        boxBuffer = curContext.createBuffer()
        curContext.bindBuffer curContext.ARRAY_BUFFER, boxBuffer
        curContext.bufferData curContext.ARRAY_BUFFER, boxVerts, curContext.STATIC_DRAW
        boxNormBuffer = curContext.createBuffer()
        curContext.bindBuffer curContext.ARRAY_BUFFER, boxNormBuffer
        curContext.bufferData curContext.ARRAY_BUFFER, boxNorms, curContext.STATIC_DRAW
        boxOutlineBuffer = curContext.createBuffer()
        curContext.bindBuffer curContext.ARRAY_BUFFER, boxOutlineBuffer
        curContext.bufferData curContext.ARRAY_BUFFER, boxOutlineVerts, curContext.STATIC_DRAW
        rectBuffer = curContext.createBuffer()
        curContext.bindBuffer curContext.ARRAY_BUFFER, rectBuffer
        curContext.bufferData curContext.ARRAY_BUFFER, rectVerts, curContext.STATIC_DRAW
        rectNormBuffer = curContext.createBuffer()
        curContext.bindBuffer curContext.ARRAY_BUFFER, rectNormBuffer
        curContext.bufferData curContext.ARRAY_BUFFER, rectNorms, curContext.STATIC_DRAW
        sphereBuffer = curContext.createBuffer()
        lineBuffer = curContext.createBuffer()
        fillBuffer = curContext.createBuffer()
        fillColorBuffer = curContext.createBuffer()
        strokeColorBuffer = curContext.createBuffer()
        shapeTexVBO = curContext.createBuffer()
        pointBuffer = curContext.createBuffer()
        curContext.bindBuffer curContext.ARRAY_BUFFER, pointBuffer
        curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array([ 0, 0, 0 ]), curContext.STATIC_DRAW
        textBuffer = curContext.createBuffer()
        curContext.bindBuffer curContext.ARRAY_BUFFER, textBuffer
        curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array([ 1, 1, 0, -1, 1, 0, -1, -1, 0, 1, -1, 0 ]), curContext.STATIC_DRAW
        textureBuffer = curContext.createBuffer()
        curContext.bindBuffer curContext.ARRAY_BUFFER, textureBuffer
        curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array([ 0, 0, 1, 0, 1, 1, 0, 1 ]), curContext.STATIC_DRAW
        indexBuffer = curContext.createBuffer()
        curContext.bindBuffer curContext.ELEMENT_ARRAY_BUFFER, indexBuffer
        curContext.bufferData curContext.ELEMENT_ARRAY_BUFFER, new Uint16Array([ 0, 1, 2, 2, 3, 0 ]), curContext.STATIC_DRAW
        cam = new PMatrix3D
        cameraInv = new PMatrix3D
        modelView = new PMatrix3D
        modelViewInv = new PMatrix3D
        projection = new PMatrix3D
        p.camera()
        p.perspective()
        userMatrixStack = new PMatrixStack
        userReverseMatrixStack = new PMatrixStack
        curveBasisMatrix = new PMatrix3D
        curveToBezierMatrix = new PMatrix3D
        curveDrawMatrix = new PMatrix3D
        bezierDrawMatrix = new PMatrix3D
        bezierBasisInverse = new PMatrix3D
        bezierBasisMatrix = new PMatrix3D
        bezierBasisMatrix.set -1, 3, -3, 1, 3, -6, 3, 0, -3, 3, 0, 0, 1, 0, 0, 0
        DrawingShared::size.apply this, arguments
    ()
    Drawing2D::ambientLight = DrawingShared::a3DOnlyFunction
    Drawing3D::ambientLight = (r, g, b, x, y, z) ->
      throw "can only create " + 8 + " lights"  if lightCount is 8
      pos = new PVector(x, y, z)
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.mult pos, pos
      col = color$4(r, g, b, 0)
      normalizedCol = [ ((col >> 16) & 255) / 255, ((col >> 8) & 255) / 255, (col & 255) / 255 ]
      curContext.useProgram programObject3D
      uniformf "uLights.color.3d." + lightCount, programObject3D, "uLights" + lightCount + ".color", normalizedCol
      uniformf "uLights.position.3d." + lightCount, programObject3D, "uLights" + lightCount + ".position", pos.array()
      uniformi "uLights.type.3d." + lightCount, programObject3D, "uLights" + lightCount + ".type", 0
      uniformi "uLightCount3d", programObject3D, "uLightCount", ++lightCount

    Drawing2D::directionalLight = DrawingShared::a3DOnlyFunction
    Drawing3D::directionalLight = (r, g, b, nx, ny, nz) ->
      throw "can only create " + 8 + " lights"  if lightCount is 8
      curContext.useProgram programObject3D
      mvm = new PMatrix3D
      mvm.scale 1, -1, 1
      mvm.apply modelView.array()
      mvm = mvm.array()
      dir = [ mvm[0] * nx + mvm[4] * ny + mvm[8] * nz, mvm[1] * nx + mvm[5] * ny + mvm[9] * nz, mvm[2] * nx + mvm[6] * ny + mvm[10] * nz ]
      col = color$4(r, g, b, 0)
      normalizedCol = [ ((col >> 16) & 255) / 255, ((col >> 8) & 255) / 255, (col & 255) / 255 ]
      uniformf "uLights.color.3d." + lightCount, programObject3D, "uLights" + lightCount + ".color", normalizedCol
      uniformf "uLights.position.3d." + lightCount, programObject3D, "uLights" + lightCount + ".position", dir
      uniformi "uLights.type.3d." + lightCount, programObject3D, "uLights" + lightCount + ".type", 1
      uniformi "uLightCount3d", programObject3D, "uLightCount", ++lightCount

    Drawing2D::lightFalloff = DrawingShared::a3DOnlyFunction
    Drawing3D::lightFalloff = (constant, linear, quadratic) ->
      curContext.useProgram programObject3D
      uniformf "uFalloff3d", programObject3D, "uFalloff", [ constant, linear, quadratic ]

    Drawing2D::lightSpecular = DrawingShared::a3DOnlyFunction
    Drawing3D::lightSpecular = (r, g, b) ->
      col = color$4(r, g, b, 0)
      normalizedCol = [ ((col >> 16) & 255) / 255, ((col >> 8) & 255) / 255, (col & 255) / 255 ]
      curContext.useProgram programObject3D
      uniformf "uSpecular3d", programObject3D, "uSpecular", normalizedCol

    p.lights = ->
      p.ambientLight 128, 128, 128
      p.directionalLight 128, 128, 128, 0, 0, -1
      p.lightFalloff 1, 0, 0
      p.lightSpecular 0, 0, 0

    Drawing2D::pointLight = DrawingShared::a3DOnlyFunction
    Drawing3D::pointLight = (r, g, b, x, y, z) ->
      throw "can only create " + 8 + " lights"  if lightCount is 8
      pos = new PVector(x, y, z)
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.mult pos, pos
      col = color$4(r, g, b, 0)
      normalizedCol = [ ((col >> 16) & 255) / 255, ((col >> 8) & 255) / 255, (col & 255) / 255 ]
      curContext.useProgram programObject3D
      uniformf "uLights.color.3d." + lightCount, programObject3D, "uLights" + lightCount + ".color", normalizedCol
      uniformf "uLights.position.3d." + lightCount, programObject3D, "uLights" + lightCount + ".position", pos.array()
      uniformi "uLights.type.3d." + lightCount, programObject3D, "uLights" + lightCount + ".type", 2
      uniformi "uLightCount3d", programObject3D, "uLightCount", ++lightCount

    Drawing2D::noLights = DrawingShared::a3DOnlyFunction
    Drawing3D::noLights = ->
      lightCount = 0
      curContext.useProgram programObject3D
      uniformi "uLightCount3d", programObject3D, "uLightCount", lightCount

    Drawing2D::spotLight = DrawingShared::a3DOnlyFunction
    Drawing3D::spotLight = (r, g, b, x, y, z, nx, ny, nz, angle, concentration) ->
      throw "can only create " + 8 + " lights"  if lightCount is 8
      curContext.useProgram programObject3D
      pos = new PVector(x, y, z)
      mvm = new PMatrix3D
      mvm.scale 1, -1, 1
      mvm.apply modelView.array()
      mvm.mult pos, pos
      mvm = mvm.array()
      dir = [ mvm[0] * nx + mvm[4] * ny + mvm[8] * nz, mvm[1] * nx + mvm[5] * ny + mvm[9] * nz, mvm[2] * nx + mvm[6] * ny + mvm[10] * nz ]
      col = color$4(r, g, b, 0)
      normalizedCol = [ ((col >> 16) & 255) / 255, ((col >> 8) & 255) / 255, (col & 255) / 255 ]
      uniformf "uLights.color.3d." + lightCount, programObject3D, "uLights" + lightCount + ".color", normalizedCol
      uniformf "uLights.position.3d." + lightCount, programObject3D, "uLights" + lightCount + ".position", pos.array()
      uniformf "uLights.direction.3d." + lightCount, programObject3D, "uLights" + lightCount + ".direction", dir
      uniformf "uLights.concentration.3d." + lightCount, programObject3D, "uLights" + lightCount + ".concentration", concentration
      uniformf "uLights.angle.3d." + lightCount, programObject3D, "uLights" + lightCount + ".angle", angle
      uniformi "uLights.type.3d." + lightCount, programObject3D, "uLights" + lightCount + ".type", 3
      uniformi "uLightCount3d", programObject3D, "uLightCount", ++lightCount

    Drawing2D::beginCamera = ->
      throw "beginCamera() is not available in 2D mode"

    Drawing3D::beginCamera = ->
      throw "You cannot call beginCamera() again before calling endCamera()"  if manipulatingCamera
      manipulatingCamera = true
      modelView = cameraInv
      modelViewInv = cam

    Drawing2D::endCamera = ->
      throw "endCamera() is not available in 2D mode"

    Drawing3D::endCamera = ->
      throw "You cannot call endCamera() before calling beginCamera()"  unless manipulatingCamera
      modelView.set cam
      modelViewInv.set cameraInv
      manipulatingCamera = false

    p.camera = (eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ) ->
      if eyeX is undef
        cameraX = p.width / 2
        cameraY = p.height / 2
        cameraZ = cameraY / Math.tan(cameraFOV / 2)
        eyeX = cameraX
        eyeY = cameraY
        eyeZ = cameraZ
        centerX = cameraX
        centerY = cameraY
        centerZ = 0
        upX = 0
        upY = 1
        upZ = 0
      z = new PVector(eyeX - centerX, eyeY - centerY, eyeZ - centerZ)
      y = new PVector(upX, upY, upZ)
      z.normalize()
      x = PVector.cross(y, z)
      y = PVector.cross(z, x)
      x.normalize()
      y.normalize()
      xX = x.x
      xY = x.y
      xZ = x.z
      yX = y.x
      yY = y.y
      yZ = y.z
      zX = z.x
      zY = z.y
      zZ = z.z
      cam.set xX, xY, xZ, 0, yX, yY, yZ, 0, zX, zY, zZ, 0, 0, 0, 0, 1
      cam.translate -eyeX, -eyeY, -eyeZ
      cameraInv.reset()
      cameraInv.invApply xX, xY, xZ, 0, yX, yY, yZ, 0, zX, zY, zZ, 0, 0, 0, 0, 1
      cameraInv.translate eyeX, eyeY, eyeZ
      modelView.set cam
      modelViewInv.set cameraInv

    p.perspective = (fov, aspect, near, far) ->
      if arguments.length is 0
        cameraY = curElement.height / 2
        cameraZ = cameraY / Math.tan(cameraFOV / 2)
        cameraNear = cameraZ / 10
        cameraFar = cameraZ * 10
        cameraAspect = p.width / p.height
        fov = cameraFOV
        aspect = cameraAspect
        near = cameraNear
        far = cameraFar
      yMax = undefined
      yMin = undefined
      xMax = undefined
      xMin = undefined
      yMax = near * Math.tan(fov / 2)
      yMin = -yMax
      xMax = yMax * aspect
      xMin = yMin * aspect
      p.frustum xMin, xMax, yMin, yMax, near, far

    Drawing2D::frustum = ->
      throw "Processing.js: frustum() is not supported in 2D mode"

    Drawing3D::frustum = (left, right, bottom, top, near, far) ->
      frustumMode = true
      projection = new PMatrix3D
      projection.set 2 * near / (right - left), 0, (right + left) / (right - left), 0, 0, 2 * near / (top - bottom), (top + bottom) / (top - bottom), 0, 0, 0, -(far + near) / (far - near), -(2 * far * near) / (far - near), 0, 0, -1, 0
      proj = new PMatrix3D
      proj.set projection
      proj.transpose()
      curContext.useProgram programObject2D
      uniformMatrix "projection2d", programObject2D, "uProjection", false, proj.array()
      curContext.useProgram programObject3D
      uniformMatrix "projection3d", programObject3D, "uProjection", false, proj.array()
      curContext.useProgram programObjectUnlitShape
      uniformMatrix "uProjectionUS", programObjectUnlitShape, "uProjection", false, proj.array()

    p.ortho = (left, right, bottom, top, near, far) ->
      if arguments.length is 0
        left = 0
        right = p.width
        bottom = 0
        top = p.height
        near = -10
        far = 10
      x = 2 / (right - left)
      y = 2 / (top - bottom)
      z = -2 / (far - near)
      tx = -(right + left) / (right - left)
      ty = -(top + bottom) / (top - bottom)
      tz = -(far + near) / (far - near)
      projection = new PMatrix3D
      projection.set x, 0, 0, tx, 0, y, 0, ty, 0, 0, z, tz, 0, 0, 0, 1
      proj = new PMatrix3D
      proj.set projection
      proj.transpose()
      curContext.useProgram programObject2D
      uniformMatrix "projection2d", programObject2D, "uProjection", false, proj.array()
      curContext.useProgram programObject3D
      uniformMatrix "projection3d", programObject3D, "uProjection", false, proj.array()
      curContext.useProgram programObjectUnlitShape
      uniformMatrix "uProjectionUS", programObjectUnlitShape, "uProjection", false, proj.array()
      frustumMode = false

    p.printProjection = ->
      projection.print()

    p.printCamera = ->
      cam.print()

    Drawing2D::box = DrawingShared::a3DOnlyFunction
    Drawing3D::box = (w, h, d) ->
      h = d = w  if not h or not d
      model = new PMatrix3D
      model.scale w, h, d
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.transpose()
      if doFill
        curContext.useProgram programObject3D
        uniformMatrix "model3d", programObject3D, "uModel", false, model.array()
        uniformMatrix "view3d", programObject3D, "uView", false, view.array()
        curContext.enable curContext.POLYGON_OFFSET_FILL
        curContext.polygonOffset 1, 1
        uniformf "color3d", programObject3D, "uColor", fillStyle
        if lightCount > 0
          v = new PMatrix3D
          v.set view
          m = new PMatrix3D
          m.set model
          v.mult m
          normalMatrix = new PMatrix3D
          normalMatrix.set v
          normalMatrix.invert()
          normalMatrix.transpose()
          uniformMatrix "uNormalTransform3d", programObject3D, "uNormalTransform", false, normalMatrix.array()
          vertexAttribPointer "aNormal3d", programObject3D, "aNormal", 3, boxNormBuffer
        else
          disableVertexAttribPointer "aNormal3d", programObject3D, "aNormal"
        vertexAttribPointer "aVertex3d", programObject3D, "aVertex", 3, boxBuffer
        disableVertexAttribPointer "aColor3d", programObject3D, "aColor"
        disableVertexAttribPointer "aTexture3d", programObject3D, "aTexture"
        curContext.drawArrays curContext.TRIANGLES, 0, boxVerts.length / 3
        curContext.disable curContext.POLYGON_OFFSET_FILL
      if lineWidth > 0 and doStroke
        curContext.useProgram programObject2D
        uniformMatrix "uModel2d", programObject2D, "uModel", false, model.array()
        uniformMatrix "uView2d", programObject2D, "uView", false, view.array()
        uniformf "uColor2d", programObject2D, "uColor", strokeStyle
        uniformi "uIsDrawingText2d", programObject2D, "uIsDrawingText", false
        vertexAttribPointer "vertex2d", programObject2D, "aVertex", 3, boxOutlineBuffer
        disableVertexAttribPointer "aTextureCoord2d", programObject2D, "aTextureCoord"
        curContext.drawArrays curContext.LINES, 0, boxOutlineVerts.length / 3

    initSphere = ->
      i = undefined
      sphereVerts = []
      i = 0
      while i < sphereDetailU
        sphereVerts.push 0
        sphereVerts.push -1
        sphereVerts.push 0
        sphereVerts.push sphereX[i]
        sphereVerts.push sphereY[i]
        sphereVerts.push sphereZ[i]
        i++
      sphereVerts.push 0
      sphereVerts.push -1
      sphereVerts.push 0
      sphereVerts.push sphereX[0]
      sphereVerts.push sphereY[0]
      sphereVerts.push sphereZ[0]
      v1 = undefined
      v11 = undefined
      v2 = undefined
      voff = 0
      i = 2
      while i < sphereDetailV
        v1 = v11 = voff
        voff += sphereDetailU
        v2 = voff
        j = 0

        while j < sphereDetailU
          sphereVerts.push sphereX[v1]
          sphereVerts.push sphereY[v1]
          sphereVerts.push sphereZ[v1++]
          sphereVerts.push sphereX[v2]
          sphereVerts.push sphereY[v2]
          sphereVerts.push sphereZ[v2++]
          j++
        v1 = v11
        v2 = voff
        sphereVerts.push sphereX[v1]
        sphereVerts.push sphereY[v1]
        sphereVerts.push sphereZ[v1]
        sphereVerts.push sphereX[v2]
        sphereVerts.push sphereY[v2]
        sphereVerts.push sphereZ[v2]
        i++
      i = 0
      while i < sphereDetailU
        v2 = voff + i
        sphereVerts.push sphereX[v2]
        sphereVerts.push sphereY[v2]
        sphereVerts.push sphereZ[v2]
        sphereVerts.push 0
        sphereVerts.push 1
        sphereVerts.push 0
        i++
      sphereVerts.push sphereX[voff]
      sphereVerts.push sphereY[voff]
      sphereVerts.push sphereZ[voff]
      sphereVerts.push 0
      sphereVerts.push 1
      sphereVerts.push 0
      curContext.bindBuffer curContext.ARRAY_BUFFER, sphereBuffer
      curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array(sphereVerts), curContext.STATIC_DRAW

    p.sphereDetail = (ures, vres) ->
      i = undefined
      ures = vres = arguments[0]  if arguments.length is 1
      ures = 3  if ures < 3
      vres = 2  if vres < 2
      return  if ures is sphereDetailU and vres is sphereDetailV
      delta = 720 / ures
      cx = new Float32Array(ures)
      cz = new Float32Array(ures)
      i = 0
      while i < ures
        cx[i] = cosLUT[i * delta % 720 | 0]
        cz[i] = sinLUT[i * delta % 720 | 0]
        i++
      vertCount = ures * (vres - 1) + 2
      currVert = 0
      sphereX = new Float32Array(vertCount)
      sphereY = new Float32Array(vertCount)
      sphereZ = new Float32Array(vertCount)
      angle_step = 720 * 0.5 / vres
      angle = angle_step
      i = 1
      while i < vres
        curradius = sinLUT[angle % 720 | 0]
        currY = -cosLUT[angle % 720 | 0]
        j = 0

        while j < ures
          sphereX[currVert] = cx[j] * curradius
          sphereY[currVert] = currY
          sphereZ[currVert++] = cz[j] * curradius
          j++
        angle += angle_step
        i++
      sphereDetailU = ures
      sphereDetailV = vres
      initSphere()

    Drawing2D::sphere = DrawingShared::a3DOnlyFunction
    Drawing3D::sphere = ->
      sRad = arguments[0]
      p.sphereDetail 30  if sphereDetailU < 3 or sphereDetailV < 2
      model = new PMatrix3D
      model.scale sRad, sRad, sRad
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.transpose()
      if doFill
        if lightCount > 0
          v = new PMatrix3D
          v.set view
          m = new PMatrix3D
          m.set model
          v.mult m
          normalMatrix = new PMatrix3D
          normalMatrix.set v
          normalMatrix.invert()
          normalMatrix.transpose()
          uniformMatrix "uNormalTransform3d", programObject3D, "uNormalTransform", false, normalMatrix.array()
          vertexAttribPointer "aNormal3d", programObject3D, "aNormal", 3, sphereBuffer
        else
          disableVertexAttribPointer "aNormal3d", programObject3D, "aNormal"
        curContext.useProgram programObject3D
        disableVertexAttribPointer "aTexture3d", programObject3D, "aTexture"
        uniformMatrix "uModel3d", programObject3D, "uModel", false, model.array()
        uniformMatrix "uView3d", programObject3D, "uView", false, view.array()
        vertexAttribPointer "aVertex3d", programObject3D, "aVertex", 3, sphereBuffer
        disableVertexAttribPointer "aColor3d", programObject3D, "aColor"
        curContext.enable curContext.POLYGON_OFFSET_FILL
        curContext.polygonOffset 1, 1
        uniformf "uColor3d", programObject3D, "uColor", fillStyle
        curContext.drawArrays curContext.TRIANGLE_STRIP, 0, sphereVerts.length / 3
        curContext.disable curContext.POLYGON_OFFSET_FILL
      if lineWidth > 0 and doStroke
        curContext.useProgram programObject2D
        uniformMatrix "uModel2d", programObject2D, "uModel", false, model.array()
        uniformMatrix "uView2d", programObject2D, "uView", false, view.array()
        vertexAttribPointer "aVertex2d", programObject2D, "aVertex", 3, sphereBuffer
        disableVertexAttribPointer "aTextureCoord2d", programObject2D, "aTextureCoord"
        uniformf "uColor2d", programObject2D, "uColor", strokeStyle
        uniformi "uIsDrawingText", programObject2D, "uIsDrawingText", false
        curContext.drawArrays curContext.LINE_STRIP, 0, sphereVerts.length / 3

    p.modelX = (x, y, z) ->
      mv = modelView.array()
      ci = cameraInv.array()
      ax = mv[0] * x + mv[1] * y + mv[2] * z + mv[3]
      ay = mv[4] * x + mv[5] * y + mv[6] * z + mv[7]
      az = mv[8] * x + mv[9] * y + mv[10] * z + mv[11]
      aw = mv[12] * x + mv[13] * y + mv[14] * z + mv[15]
      ox = ci[0] * ax + ci[1] * ay + ci[2] * az + ci[3] * aw
      ow = ci[12] * ax + ci[13] * ay + ci[14] * az + ci[15] * aw
      (if ow isnt 0 then ox / ow else ox)

    p.modelY = (x, y, z) ->
      mv = modelView.array()
      ci = cameraInv.array()
      ax = mv[0] * x + mv[1] * y + mv[2] * z + mv[3]
      ay = mv[4] * x + mv[5] * y + mv[6] * z + mv[7]
      az = mv[8] * x + mv[9] * y + mv[10] * z + mv[11]
      aw = mv[12] * x + mv[13] * y + mv[14] * z + mv[15]
      oy = ci[4] * ax + ci[5] * ay + ci[6] * az + ci[7] * aw
      ow = ci[12] * ax + ci[13] * ay + ci[14] * az + ci[15] * aw
      (if ow isnt 0 then oy / ow else oy)

    p.modelZ = (x, y, z) ->
      mv = modelView.array()
      ci = cameraInv.array()
      ax = mv[0] * x + mv[1] * y + mv[2] * z + mv[3]
      ay = mv[4] * x + mv[5] * y + mv[6] * z + mv[7]
      az = mv[8] * x + mv[9] * y + mv[10] * z + mv[11]
      aw = mv[12] * x + mv[13] * y + mv[14] * z + mv[15]
      oz = ci[8] * ax + ci[9] * ay + ci[10] * az + ci[11] * aw
      ow = ci[12] * ax + ci[13] * ay + ci[14] * az + ci[15] * aw
      (if ow isnt 0 then oz / ow else oz)

    Drawing2D::ambient = DrawingShared::a3DOnlyFunction
    Drawing3D::ambient = (v1, v2, v3) ->
      curContext.useProgram programObject3D
      uniformi "uUsingMat3d", programObject3D, "uUsingMat", true
      col = p.color(v1, v2, v3)
      uniformf "uMaterialAmbient3d", programObject3D, "uMaterialAmbient", p.color.toGLArray(col).slice(0, 3)

    Drawing2D::emissive = DrawingShared::a3DOnlyFunction
    Drawing3D::emissive = (v1, v2, v3) ->
      curContext.useProgram programObject3D
      uniformi "uUsingMat3d", programObject3D, "uUsingMat", true
      col = p.color(v1, v2, v3)
      uniformf "uMaterialEmissive3d", programObject3D, "uMaterialEmissive", p.color.toGLArray(col).slice(0, 3)

    Drawing2D::shininess = DrawingShared::a3DOnlyFunction
    Drawing3D::shininess = (shine) ->
      curContext.useProgram programObject3D
      uniformi "uUsingMat3d", programObject3D, "uUsingMat", true
      uniformf "uShininess3d", programObject3D, "uShininess", shine

    Drawing2D::specular = DrawingShared::a3DOnlyFunction
    Drawing3D::specular = (v1, v2, v3) ->
      curContext.useProgram programObject3D
      uniformi "uUsingMat3d", programObject3D, "uUsingMat", true
      col = p.color(v1, v2, v3)
      uniformf "uMaterialSpecular3d", programObject3D, "uMaterialSpecular", p.color.toGLArray(col).slice(0, 3)

    p.screenX = (x, y, z) ->
      mv = modelView.array()
      if mv.length is 16
        ax = mv[0] * x + mv[1] * y + mv[2] * z + mv[3]
        ay = mv[4] * x + mv[5] * y + mv[6] * z + mv[7]
        az = mv[8] * x + mv[9] * y + mv[10] * z + mv[11]
        aw = mv[12] * x + mv[13] * y + mv[14] * z + mv[15]
        pj = projection.array()
        ox = pj[0] * ax + pj[1] * ay + pj[2] * az + pj[3] * aw
        ow = pj[12] * ax + pj[13] * ay + pj[14] * az + pj[15] * aw
        ox /= ow  if ow isnt 0
        return p.width * (1 + ox) / 2
      modelView.multX x, y

    p.screenY = screenY = (x, y, z) ->
      mv = modelView.array()
      if mv.length is 16
        ax = mv[0] * x + mv[1] * y + mv[2] * z + mv[3]
        ay = mv[4] * x + mv[5] * y + mv[6] * z + mv[7]
        az = mv[8] * x + mv[9] * y + mv[10] * z + mv[11]
        aw = mv[12] * x + mv[13] * y + mv[14] * z + mv[15]
        pj = projection.array()
        oy = pj[4] * ax + pj[5] * ay + pj[6] * az + pj[7] * aw
        ow = pj[12] * ax + pj[13] * ay + pj[14] * az + pj[15] * aw
        oy /= ow  if ow isnt 0
        return p.height * (1 + oy) / 2
      modelView.multY x, y

    p.screenZ = screenZ = (x, y, z) ->
      mv = modelView.array()
      return 0  if mv.length isnt 16
      pj = projection.array()
      ax = mv[0] * x + mv[1] * y + mv[2] * z + mv[3]
      ay = mv[4] * x + mv[5] * y + mv[6] * z + mv[7]
      az = mv[8] * x + mv[9] * y + mv[10] * z + mv[11]
      aw = mv[12] * x + mv[13] * y + mv[14] * z + mv[15]
      oz = pj[8] * ax + pj[9] * ay + pj[10] * az + pj[11] * aw
      ow = pj[12] * ax + pj[13] * ay + pj[14] * az + pj[15] * aw
      oz /= ow  if ow isnt 0
      (oz + 1) / 2

    DrawingShared::fill = ->
      color = p.color(arguments[0], arguments[1], arguments[2], arguments[3])
      return  if color is currentFillColor and doFill
      doFill = true
      currentFillColor = color

    Drawing2D::fill = ->
      DrawingShared::fill.apply this, arguments
      isFillDirty = true

    Drawing3D::fill = ->
      DrawingShared::fill.apply this, arguments
      fillStyle = p.color.toGLArray(currentFillColor)

    p.noFill = ->
      doFill = false

    DrawingShared::stroke = ->
      color = p.color(arguments[0], arguments[1], arguments[2], arguments[3])
      return  if color is currentStrokeColor and doStroke
      doStroke = true
      currentStrokeColor = color

    Drawing2D::stroke = ->
      DrawingShared::stroke.apply this, arguments
      isStrokeDirty = true

    Drawing3D::stroke = ->
      DrawingShared::stroke.apply this, arguments
      strokeStyle = p.color.toGLArray(currentStrokeColor)

    p.noStroke = ->
      doStroke = false

    DrawingShared::strokeWeight = (w) ->
      lineWidth = w

    Drawing2D::strokeWeight = (w) ->
      DrawingShared::strokeWeight.apply this, arguments
      curContext.lineWidth = w

    Drawing3D::strokeWeight = (w) ->
      DrawingShared::strokeWeight.apply this, arguments
      curContext.useProgram programObject2D
      uniformf "pointSize2d", programObject2D, "uPointSize", w
      curContext.useProgram programObjectUnlitShape
      uniformf "pointSizeUnlitShape", programObjectUnlitShape, "uPointSize", w
      curContext.lineWidth w

    p.strokeCap = (value) ->
      drawing.$ensureContext().lineCap = value

    p.strokeJoin = (value) ->
      drawing.$ensureContext().lineJoin = value

    Drawing2D::smooth = ->
      renderSmooth = true
      style = curElement.style
      style.setProperty "image-rendering", "optimizeQuality", "important"
      style.setProperty "-ms-interpolation-mode", "bicubic", "important"
      curContext.mozImageSmoothingEnabled = true  if curContext.hasOwnProperty("mozImageSmoothingEnabled")

    Drawing3D::smooth = ->
      renderSmooth = true

    Drawing2D::noSmooth = ->
      renderSmooth = false
      style = curElement.style
      style.setProperty "image-rendering", "optimizeSpeed", "important"
      style.setProperty "image-rendering", "-moz-crisp-edges", "important"
      style.setProperty "image-rendering", "-webkit-optimize-contrast", "important"
      style.setProperty "image-rendering", "optimize-contrast", "important"
      style.setProperty "-ms-interpolation-mode", "nearest-neighbor", "important"
      curContext.mozImageSmoothingEnabled = false  if curContext.hasOwnProperty("mozImageSmoothingEnabled")

    Drawing3D::noSmooth = ->
      renderSmooth = false

    Drawing2D::point = (x, y) ->
      return  unless doStroke
      x = Math.round(x)
      y = Math.round(y)
      curContext.fillStyle = p.color.toString(currentStrokeColor)
      isFillDirty = true
      if lineWidth > 1
        curContext.beginPath()
        curContext.arc x, y, lineWidth / 2, 0, 6.283185307179586, false
        curContext.fill()
      else
        curContext.fillRect x, y, 1, 1

    Drawing3D::point = (x, y, z) ->
      model = new PMatrix3D
      model.translate x, y, z or 0
      model.transpose()
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.transpose()
      curContext.useProgram programObject2D
      uniformMatrix "uModel2d", programObject2D, "uModel", false, model.array()
      uniformMatrix "uView2d", programObject2D, "uView", false, view.array()
      if lineWidth > 0 and doStroke
        uniformf "uColor2d", programObject2D, "uColor", strokeStyle
        uniformi "uIsDrawingText2d", programObject2D, "uIsDrawingText", false
        uniformi "uSmooth2d", programObject2D, "uSmooth", renderSmooth
        vertexAttribPointer "aVertex2d", programObject2D, "aVertex", 3, pointBuffer
        disableVertexAttribPointer "aTextureCoord2d", programObject2D, "aTextureCoord"
        curContext.drawArrays curContext.POINTS, 0, 1

    p.beginShape = (type) ->
      curShape = type
      curvePoints = []
      vertArray = []

    Drawing2D::vertex = (x, y, moveTo) ->
      vert = []
      firstVert = false  if firstVert
      vert["isVert"] = true
      vert[0] = x
      vert[1] = y
      vert[2] = 0
      vert[3] = 0
      vert[4] = 0
      vert[5] = currentFillColor
      vert[6] = currentStrokeColor
      vertArray.push vert
      vertArray[vertArray.length - 1]["moveTo"] = moveTo  if moveTo

    Drawing3D::vertex = (x, y, z, u, v) ->
      vert = []
      firstVert = false  if firstVert
      vert["isVert"] = true
      if v is undef and usingTexture
        v = u
        u = z
        z = 0
      if u isnt undef and v isnt undef
        if curTextureMode is 2
          u /= curTexture.width
          v /= curTexture.height
        u = (if u > 1 then 1 else u)
        u = (if u < 0 then 0 else u)
        v = (if v > 1 then 1 else v)
        v = (if v < 0 then 0 else v)
      vert[0] = x
      vert[1] = y
      vert[2] = z or 0
      vert[3] = u or 0
      vert[4] = v or 0
      vert[5] = fillStyle[0]
      vert[6] = fillStyle[1]
      vert[7] = fillStyle[2]
      vert[8] = fillStyle[3]
      vert[9] = strokeStyle[0]
      vert[10] = strokeStyle[1]
      vert[11] = strokeStyle[2]
      vert[12] = strokeStyle[3]
      vert[13] = normalX
      vert[14] = normalY
      vert[15] = normalZ
      vertArray.push vert

    point3D = (vArray, cArray) ->
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.transpose()
      curContext.useProgram programObjectUnlitShape
      uniformMatrix "uViewUS", programObjectUnlitShape, "uView", false, view.array()
      uniformi "uSmoothUS", programObjectUnlitShape, "uSmooth", renderSmooth
      vertexAttribPointer "aVertexUS", programObjectUnlitShape, "aVertex", 3, pointBuffer
      curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array(vArray), curContext.STREAM_DRAW
      vertexAttribPointer "aColorUS", programObjectUnlitShape, "aColor", 4, fillColorBuffer
      curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array(cArray), curContext.STREAM_DRAW
      curContext.drawArrays curContext.POINTS, 0, vArray.length / 3

    line3D = (vArray, mode, cArray) ->
      ctxMode = undefined
      if mode is "LINES"
        ctxMode = curContext.LINES
      else if mode is "LINE_LOOP"
        ctxMode = curContext.LINE_LOOP
      else
        ctxMode = curContext.LINE_STRIP
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.transpose()
      curContext.useProgram programObjectUnlitShape
      uniformMatrix "uViewUS", programObjectUnlitShape, "uView", false, view.array()
      vertexAttribPointer "aVertexUS", programObjectUnlitShape, "aVertex", 3, lineBuffer
      curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array(vArray), curContext.STREAM_DRAW
      vertexAttribPointer "aColorUS", programObjectUnlitShape, "aColor", 4, strokeColorBuffer
      curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array(cArray), curContext.STREAM_DRAW
      curContext.drawArrays ctxMode, 0, vArray.length / 3

    fill3D = (vArray, mode, cArray, tArray) ->
      ctxMode = undefined
      if mode is "TRIANGLES"
        ctxMode = curContext.TRIANGLES
      else if mode is "TRIANGLE_FAN"
        ctxMode = curContext.TRIANGLE_FAN
      else
        ctxMode = curContext.TRIANGLE_STRIP
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.transpose()
      curContext.useProgram programObject3D
      uniformMatrix "model3d", programObject3D, "uModel", false, [ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ]
      uniformMatrix "view3d", programObject3D, "uView", false, view.array()
      curContext.enable curContext.POLYGON_OFFSET_FILL
      curContext.polygonOffset 1, 1
      uniformf "color3d", programObject3D, "uColor", [ -1, 0, 0, 0 ]
      vertexAttribPointer "vertex3d", programObject3D, "aVertex", 3, fillBuffer
      curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array(vArray), curContext.STREAM_DRAW
      curTint3d cArray  if usingTexture and curTint isnt null
      vertexAttribPointer "aColor3d", programObject3D, "aColor", 4, fillColorBuffer
      curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array(cArray), curContext.STREAM_DRAW
      disableVertexAttribPointer "aNormal3d", programObject3D, "aNormal"
      if usingTexture
        uniformi "uUsingTexture3d", programObject3D, "uUsingTexture", usingTexture
        vertexAttribPointer "aTexture3d", programObject3D, "aTexture", 2, shapeTexVBO
        curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array(tArray), curContext.STREAM_DRAW
      curContext.drawArrays ctxMode, 0, vArray.length / 3
      curContext.disable curContext.POLYGON_OFFSET_FILL

    Drawing2D::endShape = (mode) ->
      return  if vertArray.length is 0
      closeShape = mode is 2
      vertArray.push vertArray[0]  if closeShape
      lineVertArray = []
      fillVertArray = []
      colorVertArray = []
      strokeVertArray = []
      texVertArray = []
      cachedVertArray = undefined
      firstVert = true
      i = undefined
      j = undefined
      k = undefined
      vertArrayLength = vertArray.length
      i = 0
      while i < vertArrayLength
        cachedVertArray = vertArray[i]
        j = 0
        while j < 3
          fillVertArray.push cachedVertArray[j]
          j++
        i++
      i = 0
      while i < vertArrayLength
        cachedVertArray = vertArray[i]
        j = 5
        while j < 9
          colorVertArray.push cachedVertArray[j]
          j++
        i++
      i = 0
      while i < vertArrayLength
        cachedVertArray = vertArray[i]
        j = 9
        while j < 13
          strokeVertArray.push cachedVertArray[j]
          j++
        i++
      i = 0
      while i < vertArrayLength
        cachedVertArray = vertArray[i]
        texVertArray.push cachedVertArray[3]
        texVertArray.push cachedVertArray[4]
        i++
      if isCurve and (curShape is 20 or curShape is undef)
        if vertArrayLength > 3
          b = []
          s = 1 - curTightness
          curContext.beginPath()
          curContext.moveTo vertArray[1][0], vertArray[1][1]
          i = 1
          while i + 2 < vertArrayLength
            cachedVertArray = vertArray[i]
            b[0] = [ cachedVertArray[0], cachedVertArray[1] ]
            b[1] = [ cachedVertArray[0] + (s * vertArray[i + 1][0] - s * vertArray[i - 1][0]) / 6, cachedVertArray[1] + (s * vertArray[i + 1][1] - s * vertArray[i - 1][1]) / 6 ]
            b[2] = [ vertArray[i + 1][0] + (s * vertArray[i][0] - s * vertArray[i + 2][0]) / 6, vertArray[i + 1][1] + (s * vertArray[i][1] - s * vertArray[i + 2][1]) / 6 ]
            b[3] = [ vertArray[i + 1][0], vertArray[i + 1][1] ]
            curContext.bezierCurveTo b[1][0], b[1][1], b[2][0], b[2][1], b[3][0], b[3][1]
            i++
          fillStrokeClose()
      else if isBezier and (curShape is 20 or curShape is undef)
        curContext.beginPath()
        i = 0
        while i < vertArrayLength
          cachedVertArray = vertArray[i]
          if vertArray[i]["isVert"]
            if vertArray[i]["moveTo"]
              curContext.moveTo cachedVertArray[0], cachedVertArray[1]
            else
              curContext.lineTo cachedVertArray[0], cachedVertArray[1]
          else
            curContext.bezierCurveTo vertArray[i][0], vertArray[i][1], vertArray[i][2], vertArray[i][3], vertArray[i][4], vertArray[i][5]
          i++
        fillStrokeClose()
      else if curShape is 2
        i = 0
        while i < vertArrayLength
          cachedVertArray = vertArray[i]
          p.stroke cachedVertArray[6]  if doStroke
          p.point cachedVertArray[0], cachedVertArray[1]
          i++
      else if curShape is 4
        i = 0
        while i + 1 < vertArrayLength
          cachedVertArray = vertArray[i]
          p.stroke vertArray[i + 1][6]  if doStroke
          p.line cachedVertArray[0], cachedVertArray[1], vertArray[i + 1][0], vertArray[i + 1][1]
          i += 2
      else if curShape is 9
        i = 0
        while i + 2 < vertArrayLength
          cachedVertArray = vertArray[i]
          curContext.beginPath()
          curContext.moveTo cachedVertArray[0], cachedVertArray[1]
          curContext.lineTo vertArray[i + 1][0], vertArray[i + 1][1]
          curContext.lineTo vertArray[i + 2][0], vertArray[i + 2][1]
          curContext.lineTo cachedVertArray[0], cachedVertArray[1]
          if doFill
            p.fill vertArray[i + 2][5]
            executeContextFill()
          if doStroke
            p.stroke vertArray[i + 2][6]
            executeContextStroke()
          curContext.closePath()
          i += 3
      else if curShape is 10
        i = 0
        while i + 1 < vertArrayLength
          cachedVertArray = vertArray[i]
          curContext.beginPath()
          curContext.moveTo vertArray[i + 1][0], vertArray[i + 1][1]
          curContext.lineTo cachedVertArray[0], cachedVertArray[1]
          p.stroke vertArray[i + 1][6]  if doStroke
          p.fill vertArray[i + 1][5]  if doFill
          if i + 2 < vertArrayLength
            curContext.lineTo vertArray[i + 2][0], vertArray[i + 2][1]
            p.stroke vertArray[i + 2][6]  if doStroke
            p.fill vertArray[i + 2][5]  if doFill
          fillStrokeClose()
          i++
      else if curShape is 11
        if vertArrayLength > 2
          curContext.beginPath()
          curContext.moveTo vertArray[0][0], vertArray[0][1]
          curContext.lineTo vertArray[1][0], vertArray[1][1]
          curContext.lineTo vertArray[2][0], vertArray[2][1]
          if doFill
            p.fill vertArray[2][5]
            executeContextFill()
          if doStroke
            p.stroke vertArray[2][6]
            executeContextStroke()
          curContext.closePath()
          i = 3
          while i < vertArrayLength
            cachedVertArray = vertArray[i]
            curContext.beginPath()
            curContext.moveTo vertArray[0][0], vertArray[0][1]
            curContext.lineTo vertArray[i - 1][0], vertArray[i - 1][1]
            curContext.lineTo cachedVertArray[0], cachedVertArray[1]
            if doFill
              p.fill cachedVertArray[5]
              executeContextFill()
            if doStroke
              p.stroke cachedVertArray[6]
              executeContextStroke()
            curContext.closePath()
            i++
      else if curShape is 16
        i = 0
        while i + 3 < vertArrayLength
          cachedVertArray = vertArray[i]
          curContext.beginPath()
          curContext.moveTo cachedVertArray[0], cachedVertArray[1]
          j = 1
          while j < 4
            curContext.lineTo vertArray[i + j][0], vertArray[i + j][1]
            j++
          curContext.lineTo cachedVertArray[0], cachedVertArray[1]
          if doFill
            p.fill vertArray[i + 3][5]
            executeContextFill()
          if doStroke
            p.stroke vertArray[i + 3][6]
            executeContextStroke()
          curContext.closePath()
          i += 4
      else if curShape is 17
        if vertArrayLength > 3
          i = 0
          while i + 1 < vertArrayLength
            cachedVertArray = vertArray[i]
            curContext.beginPath()
            if i + 3 < vertArrayLength
              curContext.moveTo vertArray[i + 2][0], vertArray[i + 2][1]
              curContext.lineTo cachedVertArray[0], cachedVertArray[1]
              curContext.lineTo vertArray[i + 1][0], vertArray[i + 1][1]
              curContext.lineTo vertArray[i + 3][0], vertArray[i + 3][1]
              p.fill vertArray[i + 3][5]  if doFill
              p.stroke vertArray[i + 3][6]  if doStroke
            else
              curContext.moveTo cachedVertArray[0], cachedVertArray[1]
              curContext.lineTo vertArray[i + 1][0], vertArray[i + 1][1]
            fillStrokeClose()
            i += 2
      else
        curContext.beginPath()
        curContext.moveTo vertArray[0][0], vertArray[0][1]
        i = 1
        while i < vertArrayLength
          cachedVertArray = vertArray[i]
          if cachedVertArray["isVert"]
            if cachedVertArray["moveTo"]
              curContext.moveTo cachedVertArray[0], cachedVertArray[1]
            else
              curContext.lineTo cachedVertArray[0], cachedVertArray[1]
          i++
        fillStrokeClose()
      isCurve = false
      isBezier = false
      curveVertArray = []
      curveVertCount = 0
      vertArray.pop()  if closeShape

    Drawing3D::endShape = (mode) ->
      return  if vertArray.length is 0
      closeShape = mode is 2
      lineVertArray = []
      fillVertArray = []
      colorVertArray = []
      strokeVertArray = []
      texVertArray = []
      cachedVertArray = undefined
      firstVert = true
      i = undefined
      j = undefined
      k = undefined
      vertArrayLength = vertArray.length
      i = 0
      while i < vertArrayLength
        cachedVertArray = vertArray[i]
        j = 0
        while j < 3
          fillVertArray.push cachedVertArray[j]
          j++
        i++
      i = 0
      while i < vertArrayLength
        cachedVertArray = vertArray[i]
        j = 5
        while j < 9
          colorVertArray.push cachedVertArray[j]
          j++
        i++
      i = 0
      while i < vertArrayLength
        cachedVertArray = vertArray[i]
        j = 9
        while j < 13
          strokeVertArray.push cachedVertArray[j]
          j++
        i++
      i = 0
      while i < vertArrayLength
        cachedVertArray = vertArray[i]
        texVertArray.push cachedVertArray[3]
        texVertArray.push cachedVertArray[4]
        i++
      if closeShape
        fillVertArray.push vertArray[0][0]
        fillVertArray.push vertArray[0][1]
        fillVertArray.push vertArray[0][2]
        i = 5
        while i < 9
          colorVertArray.push vertArray[0][i]
          i++
        i = 9
        while i < 13
          strokeVertArray.push vertArray[0][i]
          i++
        texVertArray.push vertArray[0][3]
        texVertArray.push vertArray[0][4]
      if isCurve and (curShape is 20 or curShape is undef)
        lineVertArray = fillVertArray
        line3D lineVertArray, null, strokeVertArray  if doStroke
        fill3D fillVertArray, null, colorVertArray  if doFill
      else if isBezier and (curShape is 20 or curShape is undef)
        lineVertArray = fillVertArray
        lineVertArray.splice lineVertArray.length - 3
        strokeVertArray.splice strokeVertArray.length - 4
        line3D lineVertArray, null, strokeVertArray  if doStroke
        fill3D fillVertArray, "TRIANGLES", colorVertArray  if doFill
      else
        if curShape is 2
          i = 0
          while i < vertArrayLength
            cachedVertArray = vertArray[i]
            j = 0
            while j < 3
              lineVertArray.push cachedVertArray[j]
              j++
            i++
          point3D lineVertArray, strokeVertArray
        else if curShape is 4
          i = 0
          while i < vertArrayLength
            cachedVertArray = vertArray[i]
            j = 0
            while j < 3
              lineVertArray.push cachedVertArray[j]
              j++
            i++
          i = 0
          while i < vertArrayLength
            cachedVertArray = vertArray[i]
            j = 5
            while j < 9
              colorVertArray.push cachedVertArray[j]
              j++
            i++
          line3D lineVertArray, "LINES", strokeVertArray
        else if curShape is 9
          if vertArrayLength > 2
            i = 0
            while i + 2 < vertArrayLength
              fillVertArray = []
              texVertArray = []
              lineVertArray = []
              colorVertArray = []
              strokeVertArray = []
              j = 0
              while j < 3
                k = 0
                while k < 3
                  lineVertArray.push vertArray[i + j][k]
                  fillVertArray.push vertArray[i + j][k]
                  k++
                j++
              j = 0
              while j < 3
                k = 3
                while k < 5
                  texVertArray.push vertArray[i + j][k]
                  k++
                j++
              j = 0
              while j < 3
                k = 5
                while k < 9
                  colorVertArray.push vertArray[i + j][k]
                  strokeVertArray.push vertArray[i + j][k + 4]
                  k++
                j++
              line3D lineVertArray, "LINE_LOOP", strokeVertArray  if doStroke
              fill3D fillVertArray, "TRIANGLES", colorVertArray, texVertArray  if doFill or usingTexture
              i += 3
        else if curShape is 10
          if vertArrayLength > 2
            i = 0
            while i + 2 < vertArrayLength
              lineVertArray = []
              fillVertArray = []
              strokeVertArray = []
              colorVertArray = []
              texVertArray = []
              j = 0
              while j < 3
                k = 0
                while k < 3
                  lineVertArray.push vertArray[i + j][k]
                  fillVertArray.push vertArray[i + j][k]
                  k++
                j++
              j = 0
              while j < 3
                k = 3
                while k < 5
                  texVertArray.push vertArray[i + j][k]
                  k++
                j++
              j = 0
              while j < 3
                k = 5
                while k < 9
                  strokeVertArray.push vertArray[i + j][k + 4]
                  colorVertArray.push vertArray[i + j][k]
                  k++
                j++
              fill3D fillVertArray, "TRIANGLE_STRIP", colorVertArray, texVertArray  if doFill or usingTexture
              line3D lineVertArray, "LINE_LOOP", strokeVertArray  if doStroke
              i++
        else if curShape is 11
          if vertArrayLength > 2
            i = 0
            while i < 3
              cachedVertArray = vertArray[i]
              j = 0
              while j < 3
                lineVertArray.push cachedVertArray[j]
                j++
              i++
            i = 0
            while i < 3
              cachedVertArray = vertArray[i]
              j = 9
              while j < 13
                strokeVertArray.push cachedVertArray[j]
                j++
              i++
            line3D lineVertArray, "LINE_LOOP", strokeVertArray  if doStroke
            i = 2
            while i + 1 < vertArrayLength
              lineVertArray = []
              strokeVertArray = []
              lineVertArray.push vertArray[0][0]
              lineVertArray.push vertArray[0][1]
              lineVertArray.push vertArray[0][2]
              strokeVertArray.push vertArray[0][9]
              strokeVertArray.push vertArray[0][10]
              strokeVertArray.push vertArray[0][11]
              strokeVertArray.push vertArray[0][12]
              j = 0
              while j < 2
                k = 0
                while k < 3
                  lineVertArray.push vertArray[i + j][k]
                  k++
                j++
              j = 0
              while j < 2
                k = 9
                while k < 13
                  strokeVertArray.push vertArray[i + j][k]
                  k++
                j++
              line3D lineVertArray, "LINE_STRIP", strokeVertArray  if doStroke
              i++
            fill3D fillVertArray, "TRIANGLE_FAN", colorVertArray, texVertArray  if doFill or usingTexture
        else if curShape is 16
          i = 0
          while i + 3 < vertArrayLength
            lineVertArray = []
            j = 0
            while j < 4
              cachedVertArray = vertArray[i + j]
              k = 0
              while k < 3
                lineVertArray.push cachedVertArray[k]
                k++
              j++
            line3D lineVertArray, "LINE_LOOP", strokeVertArray  if doStroke
            if doFill
              fillVertArray = []
              colorVertArray = []
              texVertArray = []
              j = 0
              while j < 3
                fillVertArray.push vertArray[i][j]
                j++
              j = 5
              while j < 9
                colorVertArray.push vertArray[i][j]
                j++
              j = 0
              while j < 3
                fillVertArray.push vertArray[i + 1][j]
                j++
              j = 5
              while j < 9
                colorVertArray.push vertArray[i + 1][j]
                j++
              j = 0
              while j < 3
                fillVertArray.push vertArray[i + 3][j]
                j++
              j = 5
              while j < 9
                colorVertArray.push vertArray[i + 3][j]
                j++
              j = 0
              while j < 3
                fillVertArray.push vertArray[i + 2][j]
                j++
              j = 5
              while j < 9
                colorVertArray.push vertArray[i + 2][j]
                j++
              if usingTexture
                texVertArray.push vertArray[i + 0][3]
                texVertArray.push vertArray[i + 0][4]
                texVertArray.push vertArray[i + 1][3]
                texVertArray.push vertArray[i + 1][4]
                texVertArray.push vertArray[i + 3][3]
                texVertArray.push vertArray[i + 3][4]
                texVertArray.push vertArray[i + 2][3]
                texVertArray.push vertArray[i + 2][4]
              fill3D fillVertArray, "TRIANGLE_STRIP", colorVertArray, texVertArray
            i += 4
        else if curShape is 17
          tempArray = []
          if vertArrayLength > 3
            i = 0
            while i < 2
              cachedVertArray = vertArray[i]
              j = 0
              while j < 3
                lineVertArray.push cachedVertArray[j]
                j++
              i++
            i = 0
            while i < 2
              cachedVertArray = vertArray[i]
              j = 9
              while j < 13
                strokeVertArray.push cachedVertArray[j]
                j++
              i++
            line3D lineVertArray, "LINE_STRIP", strokeVertArray
            if vertArrayLength > 4 and vertArrayLength % 2 > 0
              tempArray = fillVertArray.splice(fillVertArray.length - 3)
              vertArray.pop()
            i = 0
            while i + 3 < vertArrayLength
              lineVertArray = []
              strokeVertArray = []
              j = 0
              while j < 3
                lineVertArray.push vertArray[i + 1][j]
                j++
              j = 0
              while j < 3
                lineVertArray.push vertArray[i + 3][j]
                j++
              j = 0
              while j < 3
                lineVertArray.push vertArray[i + 2][j]
                j++
              j = 0
              while j < 3
                lineVertArray.push vertArray[i + 0][j]
                j++
              j = 9
              while j < 13
                strokeVertArray.push vertArray[i + 1][j]
                j++
              j = 9
              while j < 13
                strokeVertArray.push vertArray[i + 3][j]
                j++
              j = 9
              while j < 13
                strokeVertArray.push vertArray[i + 2][j]
                j++
              j = 9
              while j < 13
                strokeVertArray.push vertArray[i + 0][j]
                j++
              line3D lineVertArray, "LINE_STRIP", strokeVertArray  if doStroke
              i += 2
            fill3D fillVertArray, "TRIANGLE_LIST", colorVertArray, texVertArray  if doFill or usingTexture
        else if vertArrayLength is 1
          j = 0
          while j < 3
            lineVertArray.push vertArray[0][j]
            j++
          j = 9
          while j < 13
            strokeVertArray.push vertArray[0][j]
            j++
          point3D lineVertArray, strokeVertArray
        else
          i = 0
          while i < vertArrayLength
            cachedVertArray = vertArray[i]
            j = 0
            while j < 3
              lineVertArray.push cachedVertArray[j]
              j++
            j = 5
            while j < 9
              strokeVertArray.push cachedVertArray[j]
              j++
            i++
          if doStroke and closeShape
            line3D lineVertArray, "LINE_LOOP", strokeVertArray
          else line3D lineVertArray, "LINE_STRIP", strokeVertArray  if doStroke and not closeShape
          fill3D fillVertArray, "TRIANGLE_FAN", colorVertArray, texVertArray  if doFill or usingTexture
        usingTexture = false
        curContext.useProgram programObject3D
        uniformi "usingTexture3d", programObject3D, "uUsingTexture", usingTexture
      isCurve = false
      isBezier = false
      curveVertArray = []
      curveVertCount = 0

    splineForward = (segments, matrix) ->
      f = 1 / segments
      ff = f * f
      fff = ff * f
      matrix.set 0, 0, 0, 1, fff, ff, f, 0, 6 * fff, 2 * ff, 0, 0, 6 * fff, 0, 0, 0

    curveInit = ->
      unless curveDrawMatrix
        curveBasisMatrix = new PMatrix3D
        curveDrawMatrix = new PMatrix3D
        curveInited = true
      s = curTightness
      curveBasisMatrix.set (s - 1) / 2, (s + 3) / 2, (-3 - s) / 2, (1 - s) / 2, 1 - s, (-5 - s) / 2, s + 2, (s - 1) / 2, (s - 1) / 2, 0, (1 - s) / 2, 0, 0, 1, 0, 0
      splineForward curveDet, curveDrawMatrix
      curveToBezierMatrix = new PMatrix3D  unless bezierBasisInverse
      curveToBezierMatrix.set curveBasisMatrix
      curveToBezierMatrix.preApply bezierBasisInverse
      curveDrawMatrix.apply curveBasisMatrix

    Drawing2D::bezierVertex = ->
      isBezier = true
      vert = []
      throw "vertex() must be used at least once before calling bezierVertex()"  if firstVert
      i = 0

      while i < arguments.length
        vert[i] = arguments[i]
        i++
      vertArray.push vert
      vertArray[vertArray.length - 1]["isVert"] = false

    Drawing3D::bezierVertex = ->
      isBezier = true
      vert = []
      throw "vertex() must be used at least once before calling bezierVertex()"  if firstVert
      if arguments.length is 9
        bezierDrawMatrix = new PMatrix3D  if bezierDrawMatrix is undef
        lastPoint = vertArray.length - 1
        splineForward bezDetail, bezierDrawMatrix
        bezierDrawMatrix.apply bezierBasisMatrix
        draw = bezierDrawMatrix.array()
        x1 = vertArray[lastPoint][0]
        y1 = vertArray[lastPoint][1]
        z1 = vertArray[lastPoint][2]
        xplot1 = draw[4] * x1 + draw[5] * arguments[0] + draw[6] * arguments[3] + draw[7] * arguments[6]
        xplot2 = draw[8] * x1 + draw[9] * arguments[0] + draw[10] * arguments[3] + draw[11] * arguments[6]
        xplot3 = draw[12] * x1 + draw[13] * arguments[0] + draw[14] * arguments[3] + draw[15] * arguments[6]
        yplot1 = draw[4] * y1 + draw[5] * arguments[1] + draw[6] * arguments[4] + draw[7] * arguments[7]
        yplot2 = draw[8] * y1 + draw[9] * arguments[1] + draw[10] * arguments[4] + draw[11] * arguments[7]
        yplot3 = draw[12] * y1 + draw[13] * arguments[1] + draw[14] * arguments[4] + draw[15] * arguments[7]
        zplot1 = draw[4] * z1 + draw[5] * arguments[2] + draw[6] * arguments[5] + draw[7] * arguments[8]
        zplot2 = draw[8] * z1 + draw[9] * arguments[2] + draw[10] * arguments[5] + draw[11] * arguments[8]
        zplot3 = draw[12] * z1 + draw[13] * arguments[2] + draw[14] * arguments[5] + draw[15] * arguments[8]
        j = 0

        while j < bezDetail
          x1 += xplot1
          xplot1 += xplot2
          xplot2 += xplot3
          y1 += yplot1
          yplot1 += yplot2
          yplot2 += yplot3
          z1 += zplot1
          zplot1 += zplot2
          zplot2 += zplot3
          p.vertex x1, y1, z1
          j++
        p.vertex arguments[6], arguments[7], arguments[8]

    p.texture = (pimage) ->
      curContext = drawing.$ensureContext()
      if pimage.__texture
        curContext.bindTexture curContext.TEXTURE_2D, pimage.__texture
      else if pimage.localName is "canvas"
        curContext.bindTexture curContext.TEXTURE_2D, canTex
        curContext.texImage2D curContext.TEXTURE_2D, 0, curContext.RGBA, curContext.RGBA, curContext.UNSIGNED_BYTE, pimage
        curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_MAG_FILTER, curContext.LINEAR
        curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_MIN_FILTER, curContext.LINEAR
        curContext.generateMipmap curContext.TEXTURE_2D
        curTexture.width = pimage.width
        curTexture.height = pimage.height
      else
        texture = curContext.createTexture()
        cvs = document.createElement("canvas")
        cvsTextureCtx = cvs.getContext("2d")
        pot = undefined
        unless pimage.width & pimage.width - 1 is 0
          pot = 1
          pot *= 2  while pot < pimage.width
          cvs.width = pot
        unless pimage.height & pimage.height - 1 is 0
          pot = 1
          pot *= 2  while pot < pimage.height
          cvs.height = pot
        cvsTextureCtx.drawImage pimage.sourceImg, 0, 0, pimage.width, pimage.height, 0, 0, cvs.width, cvs.height
        curContext.bindTexture curContext.TEXTURE_2D, texture
        curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_MIN_FILTER, curContext.LINEAR_MIPMAP_LINEAR
        curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_MAG_FILTER, curContext.LINEAR
        curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_WRAP_T, curContext.CLAMP_TO_EDGE
        curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_WRAP_S, curContext.CLAMP_TO_EDGE
        curContext.texImage2D curContext.TEXTURE_2D, 0, curContext.RGBA, curContext.RGBA, curContext.UNSIGNED_BYTE, cvs
        curContext.generateMipmap curContext.TEXTURE_2D
        pimage.__texture = texture
        curTexture.width = pimage.width
        curTexture.height = pimage.height
      usingTexture = true
      curContext.useProgram programObject3D
      uniformi "usingTexture3d", programObject3D, "uUsingTexture", usingTexture

    p.textureMode = (mode) ->
      curTextureMode = mode

    curveVertexSegment = (x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4) ->
      x0 = x2
      y0 = y2
      z0 = z2
      draw = curveDrawMatrix.array()
      xplot1 = draw[4] * x1 + draw[5] * x2 + draw[6] * x3 + draw[7] * x4
      xplot2 = draw[8] * x1 + draw[9] * x2 + draw[10] * x3 + draw[11] * x4
      xplot3 = draw[12] * x1 + draw[13] * x2 + draw[14] * x3 + draw[15] * x4
      yplot1 = draw[4] * y1 + draw[5] * y2 + draw[6] * y3 + draw[7] * y4
      yplot2 = draw[8] * y1 + draw[9] * y2 + draw[10] * y3 + draw[11] * y4
      yplot3 = draw[12] * y1 + draw[13] * y2 + draw[14] * y3 + draw[15] * y4
      zplot1 = draw[4] * z1 + draw[5] * z2 + draw[6] * z3 + draw[7] * z4
      zplot2 = draw[8] * z1 + draw[9] * z2 + draw[10] * z3 + draw[11] * z4
      zplot3 = draw[12] * z1 + draw[13] * z2 + draw[14] * z3 + draw[15] * z4
      p.vertex x0, y0, z0
      j = 0

      while j < curveDet
        x0 += xplot1
        xplot1 += xplot2
        xplot2 += xplot3
        y0 += yplot1
        yplot1 += yplot2
        yplot2 += yplot3
        z0 += zplot1
        zplot1 += zplot2
        zplot2 += zplot3
        p.vertex x0, y0, z0
        j++

    Drawing2D::curveVertex = (x, y) ->
      isCurve = true
      p.vertex x, y

    Drawing3D::curveVertex = (x, y, z) ->
      isCurve = true
      curveInit()  unless curveInited
      vert = []
      vert[0] = x
      vert[1] = y
      vert[2] = z
      curveVertArray.push vert
      curveVertCount++
      curveVertexSegment curveVertArray[curveVertCount - 4][0], curveVertArray[curveVertCount - 4][1], curveVertArray[curveVertCount - 4][2], curveVertArray[curveVertCount - 3][0], curveVertArray[curveVertCount - 3][1], curveVertArray[curveVertCount - 3][2], curveVertArray[curveVertCount - 2][0], curveVertArray[curveVertCount - 2][1], curveVertArray[curveVertCount - 2][2], curveVertArray[curveVertCount - 1][0], curveVertArray[curveVertCount - 1][1], curveVertArray[curveVertCount - 1][2]  if curveVertCount > 3

    Drawing2D::curve = (x1, y1, x2, y2, x3, y3, x4, y4) ->
      p.beginShape()
      p.curveVertex x1, y1
      p.curveVertex x2, y2
      p.curveVertex x3, y3
      p.curveVertex x4, y4
      p.endShape()

    Drawing3D::curve = (x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4) ->
      if z4 isnt undef
        p.beginShape()
        p.curveVertex x1, y1, z1
        p.curveVertex x2, y2, z2
        p.curveVertex x3, y3, z3
        p.curveVertex x4, y4, z4
        p.endShape()
        return
      p.beginShape()
      p.curveVertex x1, y1
      p.curveVertex z1, x2
      p.curveVertex y2, z2
      p.curveVertex x3, y3
      p.endShape()

    p.curveTightness = (tightness) ->
      curTightness = tightness

    p.curveDetail = (detail) ->
      curveDet = detail
      curveInit()

    p.rectMode = (aRectMode) ->
      curRectMode = aRectMode

    p.imageMode = (mode) ->
      switch mode
        when 0
          imageModeConvert = imageModeCorner
        when 1
          imageModeConvert = imageModeCorners
        when 3
          imageModeConvert = imageModeCenter
        else
          throw "Invalid imageMode"

    p.ellipseMode = (aEllipseMode) ->
      curEllipseMode = aEllipseMode

    p.arc = (x, y, width, height, start, stop) ->
      return  if width <= 0 or stop < start
      if curEllipseMode is 1
        width = width - x
        height = height - y
      else if curEllipseMode is 2
        x = x - width
        y = y - height
        width = width * 2
        height = height * 2
      else if curEllipseMode is 3
        x = x - width / 2
        y = y - height / 2
      while start < 0
        start += 6.283185307179586
        stop += 6.283185307179586
      if stop - start > 6.283185307179586
        start = 0
        stop = 6.283185307179586
      hr = width / 2
      vr = height / 2
      centerX = x + hr
      centerY = y + vr
      startLUT = 0 | 0.5 + start * p.RAD_TO_DEG * 2
      stopLUT = 0 | 0.5 + stop * p.RAD_TO_DEG * 2
      i = undefined
      j = undefined
      if doFill
        savedStroke = doStroke
        doStroke = false
        p.beginShape()
        p.vertex centerX, centerY
        i = startLUT
        while i <= stopLUT
          j = i % 720
          p.vertex centerX + cosLUT[j] * hr, centerY + sinLUT[j] * vr
          i++
        p.endShape 2
        doStroke = savedStroke
      if doStroke
        savedFill = doFill
        doFill = false
        p.beginShape()
        i = startLUT
        while i <= stopLUT
          j = i % 720
          p.vertex centerX + cosLUT[j] * hr, centerY + sinLUT[j] * vr
          i++
        p.endShape()
        doFill = savedFill

    Drawing2D::line = (x1, y1, x2, y2) ->
      return  unless doStroke
      x1 = Math.round(x1)
      x2 = Math.round(x2)
      y1 = Math.round(y1)
      y2 = Math.round(y2)
      if x1 is x2 and y1 is y2
        p.point x1, y1
        return
      swap = undef
      lineCap = undef
      drawCrisp = true
      currentModelView = modelView.array()
      identityMatrix = [ 1, 0, 0, 0, 1, 0 ]
      i = 0

      while i < 6 and drawCrisp
        drawCrisp = currentModelView[i] is identityMatrix[i]
        i++
      if drawCrisp
        if x1 is x2
          if y1 > y2
            swap = y1
            y1 = y2
            y2 = swap
          y2++
          curContext.translate 0.5, 0  if lineWidth % 2 is 1
        else if y1 is y2
          if x1 > x2
            swap = x1
            x1 = x2
            x2 = swap
          x2++
          curContext.translate 0, 0.5  if lineWidth % 2 is 1
        if lineWidth is 1
          lineCap = curContext.lineCap
          curContext.lineCap = "butt"
      curContext.beginPath()
      curContext.moveTo x1 or 0, y1 or 0
      curContext.lineTo x2 or 0, y2 or 0
      executeContextStroke()
      if drawCrisp
        if x1 is x2 and lineWidth % 2 is 1
          curContext.translate -0.5, 0
        else curContext.translate 0, -0.5  if y1 is y2 and lineWidth % 2 is 1
        curContext.lineCap = lineCap  if lineWidth is 1

    Drawing3D::line = (x1, y1, z1, x2, y2, z2) ->
      if y2 is undef or z2 is undef
        z2 = 0
        y2 = x2
        x2 = z1
        z1 = 0
      if x1 is x2 and y1 is y2 and z1 is z2
        p.point x1, y1, z1
        return
      lineVerts = [ x1, y1, z1, x2, y2, z2 ]
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.transpose()
      if lineWidth > 0 and doStroke
        curContext.useProgram programObject2D
        uniformMatrix "uModel2d", programObject2D, "uModel", false, [ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ]
        uniformMatrix "uView2d", programObject2D, "uView", false, view.array()
        uniformf "uColor2d", programObject2D, "uColor", strokeStyle
        uniformi "uIsDrawingText", programObject2D, "uIsDrawingText", false
        vertexAttribPointer "aVertex2d", programObject2D, "aVertex", 3, lineBuffer
        disableVertexAttribPointer "aTextureCoord2d", programObject2D, "aTextureCoord"
        curContext.bufferData curContext.ARRAY_BUFFER, new Float32Array(lineVerts), curContext.STREAM_DRAW
        curContext.drawArrays curContext.LINES, 0, 2

    Drawing2D::bezier = ->
      throw "You must use 8 parameters for bezier() in 2D mode"  if arguments.length isnt 8
      p.beginShape()
      p.vertex arguments[0], arguments[1]
      p.bezierVertex arguments[2], arguments[3], arguments[4], arguments[5], arguments[6], arguments[7]
      p.endShape()

    Drawing3D::bezier = ->
      throw "You must use 12 parameters for bezier() in 3D mode"  if arguments.length isnt 12
      p.beginShape()
      p.vertex arguments[0], arguments[1], arguments[2]
      p.bezierVertex arguments[3], arguments[4], arguments[5], arguments[6], arguments[7], arguments[8], arguments[9], arguments[10], arguments[11]
      p.endShape()

    p.bezierDetail = (detail) ->
      bezDetail = detail

    p.bezierPoint = (a, b, c, d, t) ->
      (1 - t) * (1 - t) * (1 - t) * a + 3 * (1 - t) * (1 - t) * t * b + 3 * (1 - t) * t * t * c + t * t * t * d

    p.bezierTangent = (a, b, c, d, t) ->
      3 * t * t * (-a + 3 * b - 3 * c + d) + 6 * t * (a - 2 * b + c) + 3 * (-a + b)

    p.curvePoint = (a, b, c, d, t) ->
      0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t * t * t)

    p.curveTangent = (a, b, c, d, t) ->
      0.5 * (-a + c + 2 * (2 * a - 5 * b + 4 * c - d) * t + 3 * (-a + 3 * b - 3 * c + d) * t * t)

    p.triangle = (x1, y1, x2, y2, x3, y3) ->
      p.beginShape 9
      p.vertex x1, y1, 0
      p.vertex x2, y2, 0
      p.vertex x3, y3, 0
      p.endShape()

    p.quad = (x1, y1, x2, y2, x3, y3, x4, y4) ->
      p.beginShape 16
      p.vertex x1, y1, 0
      p.vertex x2, y2, 0
      p.vertex x3, y3, 0
      p.vertex x4, y4, 0
      p.endShape()

    roundedRect$2d = (x, y, width, height, tl, tr, br, bl) ->
      if bl is undef
        tr = tl
        br = tl
        bl = tl
      halfWidth = width / 2
      halfHeight = height / 2
      tl = Math.min(halfWidth, halfHeight)  if tl > halfWidth or tl > halfHeight
      tr = Math.min(halfWidth, halfHeight)  if tr > halfWidth or tr > halfHeight
      br = Math.min(halfWidth, halfHeight)  if br > halfWidth or br > halfHeight
      bl = Math.min(halfWidth, halfHeight)  if bl > halfWidth or bl > halfHeight
      curContext.translate 0.5, 0.5  if not doFill or doStroke
      curContext.beginPath()
      curContext.moveTo x + tl, y
      curContext.lineTo x + width - tr, y
      curContext.quadraticCurveTo x + width, y, x + width, y + tr
      curContext.lineTo x + width, y + height - br
      curContext.quadraticCurveTo x + width, y + height, x + width - br, y + height
      curContext.lineTo x + bl, y + height
      curContext.quadraticCurveTo x, y + height, x, y + height - bl
      curContext.lineTo x, y + tl
      curContext.quadraticCurveTo x, y, x + tl, y
      curContext.translate -0.5, -0.5  if not doFill or doStroke
      executeContextFill()
      executeContextStroke()

    Drawing2D::rect = (x, y, width, height, tl, tr, br, bl) ->
      return  if not width and not height
      if curRectMode is 1
        width -= x
        height -= y
      else if curRectMode is 2
        width *= 2
        height *= 2
        x -= width / 2
        y -= height / 2
      else if curRectMode is 3
        x -= width / 2
        y -= height / 2
      x = Math.round(x)
      y = Math.round(y)
      width = Math.round(width)
      height = Math.round(height)
      if tl isnt undef
        roundedRect$2d x, y, width, height, tl, tr, br, bl
        return
      curContext.translate 0.5, 0.5  if doStroke and lineWidth % 2 is 1
      curContext.beginPath()
      curContext.rect x, y, width, height
      executeContextFill()
      executeContextStroke()
      curContext.translate -0.5, -0.5  if doStroke and lineWidth % 2 is 1

    Drawing3D::rect = (x, y, width, height, tl, tr, br, bl) ->
      throw "rect() with rounded corners is not supported in 3D mode"  if tl isnt undef
      if curRectMode is 1
        width -= x
        height -= y
      else if curRectMode is 2
        width *= 2
        height *= 2
        x -= width / 2
        y -= height / 2
      else if curRectMode is 3
        x -= width / 2
        y -= height / 2
      model = new PMatrix3D
      model.translate x, y, 0
      model.scale width, height, 1
      model.transpose()
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.transpose()
      if lineWidth > 0 and doStroke
        curContext.useProgram programObject2D
        uniformMatrix "uModel2d", programObject2D, "uModel", false, model.array()
        uniformMatrix "uView2d", programObject2D, "uView", false, view.array()
        uniformf "uColor2d", programObject2D, "uColor", strokeStyle
        uniformi "uIsDrawingText2d", programObject2D, "uIsDrawingText", false
        vertexAttribPointer "aVertex2d", programObject2D, "aVertex", 3, rectBuffer
        disableVertexAttribPointer "aTextureCoord2d", programObject2D, "aTextureCoord"
        curContext.drawArrays curContext.LINE_LOOP, 0, rectVerts.length / 3
      if doFill
        curContext.useProgram programObject3D
        uniformMatrix "uModel3d", programObject3D, "uModel", false, model.array()
        uniformMatrix "uView3d", programObject3D, "uView", false, view.array()
        curContext.enable curContext.POLYGON_OFFSET_FILL
        curContext.polygonOffset 1, 1
        uniformf "color3d", programObject3D, "uColor", fillStyle
        if lightCount > 0
          v = new PMatrix3D
          v.set view
          m = new PMatrix3D
          m.set model
          v.mult m
          normalMatrix = new PMatrix3D
          normalMatrix.set v
          normalMatrix.invert()
          normalMatrix.transpose()
          uniformMatrix "uNormalTransform3d", programObject3D, "uNormalTransform", false, normalMatrix.array()
          vertexAttribPointer "aNormal3d", programObject3D, "aNormal", 3, rectNormBuffer
        else
          disableVertexAttribPointer "normal3d", programObject3D, "aNormal"
        vertexAttribPointer "vertex3d", programObject3D, "aVertex", 3, rectBuffer
        curContext.drawArrays curContext.TRIANGLE_FAN, 0, rectVerts.length / 3
        curContext.disable curContext.POLYGON_OFFSET_FILL

    Drawing2D::ellipse = (x, y, width, height) ->
      x = x or 0
      y = y or 0
      return  if width <= 0 and height <= 0
      if curEllipseMode is 2
        width *= 2
        height *= 2
      else if curEllipseMode is 1
        width = width - x
        height = height - y
        x += width / 2
        y += height / 2
      else if curEllipseMode is 0
        x += width / 2
        y += height / 2
      if width is height
        curContext.beginPath()
        curContext.arc x, y, width / 2, 0, 6.283185307179586, false
        executeContextFill()
        executeContextStroke()
      else
        w = width / 2
        h = height / 2
        C = 0.5522847498307933
        c_x = C * w
        c_y = C * h
        p.beginShape()
        p.vertex x + w, y
        p.bezierVertex x + w, y - c_y, x + c_x, y - h, x, y - h
        p.bezierVertex x - c_x, y - h, x - w, y - c_y, x - w, y
        p.bezierVertex x - w, y + c_y, x - c_x, y + h, x, y + h
        p.bezierVertex x + c_x, y + h, x + w, y + c_y, x + w, y
        p.endShape()

    Drawing3D::ellipse = (x, y, width, height) ->
      x = x or 0
      y = y or 0
      return  if width <= 0 and height <= 0
      if curEllipseMode is 2
        width *= 2
        height *= 2
      else if curEllipseMode is 1
        width = width - x
        height = height - y
        x += width / 2
        y += height / 2
      else if curEllipseMode is 0
        x += width / 2
        y += height / 2
      w = width / 2
      h = height / 2
      C = 0.5522847498307933
      c_x = C * w
      c_y = C * h
      p.beginShape()
      p.vertex x + w, y
      p.bezierVertex x + w, y - c_y, 0, x + c_x, y - h, 0, x, y - h, 0
      p.bezierVertex x - c_x, y - h, 0, x - w, y - c_y, 0, x - w, y, 0
      p.bezierVertex x - w, y + c_y, 0, x - c_x, y + h, 0, x, y + h, 0
      p.bezierVertex x + c_x, y + h, 0, x + w, y + c_y, 0, x + w, y, 0
      p.endShape()
      if doFill
        xAv = 0
        yAv = 0
        i = undefined
        j = undefined
        i = 0
        while i < vertArray.length
          xAv += vertArray[i][0]
          yAv += vertArray[i][1]
          i++
        xAv /= vertArray.length
        yAv /= vertArray.length
        vert = []
        fillVertArray = []
        colorVertArray = []
        vert[0] = xAv
        vert[1] = yAv
        vert[2] = 0
        vert[3] = 0
        vert[4] = 0
        vert[5] = fillStyle[0]
        vert[6] = fillStyle[1]
        vert[7] = fillStyle[2]
        vert[8] = fillStyle[3]
        vert[9] = strokeStyle[0]
        vert[10] = strokeStyle[1]
        vert[11] = strokeStyle[2]
        vert[12] = strokeStyle[3]
        vert[13] = normalX
        vert[14] = normalY
        vert[15] = normalZ
        vertArray.unshift vert
        i = 0
        while i < vertArray.length
          j = 0
          while j < 3
            fillVertArray.push vertArray[i][j]
            j++
          j = 5
          while j < 9
            colorVertArray.push vertArray[i][j]
            j++
          i++
        fill3D fillVertArray, "TRIANGLE_FAN", colorVertArray

    p.normal = (nx, ny, nz) ->
      throw "normal() requires three numeric arguments."  if arguments.length isnt 3 or not (typeof nx is "number" and typeof ny is "number" and typeof nz is "number")
      normalX = nx
      normalY = ny
      normalZ = nz
      if curShape isnt 0
        if normalMode is 0
          normalMode = 1
        else normalMode = 2  if normalMode is 1

    p.save = (file, img) ->
      return window.open(img.toDataURL(), "_blank")  if img isnt undef
      window.open p.externals.canvas.toDataURL(), "_blank"

    saveNumber = 0
    p.saveFrame = (file) ->
      file = "screen-####.png"  if file is undef
      frameFilename = file.replace(/#+/, (all) ->
        s = "" + saveNumber++
        s = "0" + s  while s.length < all.length
        s
      )
      p.save frameFilename

    utilityContext2d = document.createElement("canvas").getContext("2d")
    canvasDataCache = [ undef, undef, undef ]
    PImage = (aWidth, aHeight, aFormat) ->
      @__isDirty = false
      if aWidth instanceof HTMLImageElement
        @fromHTMLImageData aWidth
      else if aHeight or aFormat
        @width = aWidth or 1
        @height = aHeight or 1
        canvas = @sourceImg = document.createElement("canvas")
        canvas.width = @width
        canvas.height = @height
        imageData = @imageData = canvas.getContext("2d").createImageData(@width, @height)
        @format = (if aFormat is 2 or aFormat is 4 then aFormat else 1)
        if @format is 1
          i = 3
          data = @imageData.data
          len = data.length

          while i < len
            data[i] = 255
            i += 4
        @__isDirty = true
        @updatePixels()
      else
        @width = 0
        @height = 0
        @imageData = utilityContext2d.createImageData(1, 1)
        @format = 2
      @pixels = buildPixelsObject(this)

    PImage:: =
      __isPImage: true
      updatePixels: ->
        canvas = @sourceImg
        canvas.getContext("2d").putImageData @imageData, 0, 0  if canvas and canvas instanceof HTMLCanvasElement and @__isDirty
        @__isDirty = false

      fromHTMLImageData: (htmlImg) ->
        canvasData = getCanvasData(htmlImg)
        try
          imageData = canvasData.context.getImageData(0, 0, htmlImg.width, htmlImg.height)
          @fromImageData imageData
        catch e
          if htmlImg.width and htmlImg.height
            @isRemote = true
            @width = htmlImg.width
            @height = htmlImg.height
        @sourceImg = htmlImg

      get: (x, y, w, h) ->
        return p.get(this)  unless arguments.length
        return p.get(x, y, this)  if arguments.length is 2
        p.get x, y, w, h, this  if arguments.length is 4

      set: (x, y, c) ->
        p.set x, y, c, this
        @__isDirty = true

      blend: (srcImg, x, y, width, height, dx, dy, dwidth, dheight, MODE) ->
        if arguments.length is 9
          p.blend this, srcImg, x, y, width, height, dx, dy, dwidth, dheight, this
        else p.blend srcImg, x, y, width, height, dx, dy, dwidth, dheight, MODE, this  if arguments.length is 10
        delete @sourceImg

      copy: (srcImg, sx, sy, swidth, sheight, dx, dy, dwidth, dheight) ->
        if arguments.length is 8
          p.blend this, srcImg, sx, sy, swidth, sheight, dx, dy, dwidth, 0, this
        else p.blend srcImg, sx, sy, swidth, sheight, dx, dy, dwidth, dheight, 0, this  if arguments.length is 9
        delete @sourceImg

      filter: (mode, param) ->
        if arguments.length is 2
          p.filter mode, param, this
        else p.filter mode, null, this  if arguments.length is 1
        delete @sourceImg

      save: (file) ->
        p.save file, this

      resize: (w, h) ->
        throw "Image is loaded remotely. Cannot resize."  if @isRemote
        if @width isnt 0 or @height isnt 0
          if w is 0 and h isnt 0
            w = Math.floor(@width / @height * h)
          else h = Math.floor(@height / @width * w)  if h is 0 and w isnt 0
          canvas = getCanvasData(@imageData).canvas
          imageData = getCanvasData(canvas, w, h).context.getImageData(0, 0, w, h)
          @fromImageData imageData

      mask: (mask) ->
        obj = @toImageData()
        i = undefined
        size = undefined
        if mask instanceof PImage or mask.__isPImage
          if mask.width is @width and mask.height is @height
            mask = mask.toImageData()
            i = 2
            size = @width * @height * 4

            while i < size
              obj.data[i + 1] = mask.data[i]
              i += 4
          else
            throw "mask must have the same dimensions as PImage."
        else if mask instanceof Array
          if @width * @height is mask.length
            i = 0
            size = mask.length

            while i < size
              obj.data[i * 4 + 3] = mask[i]
              ++i
          else
            throw "mask array must be the same length as PImage pixels array."
        @fromImageData obj

      loadPixels: nop
      toImageData: ->
        return @sourceImg  if @isRemote
        return @imageData  unless @__isDirty
        canvasData = getCanvasData(@sourceImg)
        canvasData.context.getImageData 0, 0, @width, @height

      toDataURL: ->
        throw "Image is loaded remotely. Cannot create dataURI."  if @isRemote
        canvasData = getCanvasData(@imageData)
        canvasData.canvas.toDataURL()

      fromImageData: (canvasImg) ->
        w = canvasImg.width
        h = canvasImg.height
        canvas = document.createElement("canvas")
        ctx = canvas.getContext("2d")
        @width = canvas.width = w
        @height = canvas.height = h
        ctx.putImageData canvasImg, 0, 0
        @format = 2
        @imageData = canvasImg
        @sourceImg = canvas

    p.PImage = PImage
    p.createImage = (w, h, mode) ->
      new PImage(w, h, mode)

    p.loadImage = (file, type, callback) ->
      file = file + "." + type  if type
      pimg = undefined
      if curSketch.imageCache.images[file]
        pimg = new PImage(curSketch.imageCache.images[file])
        pimg.loaded = true
        return pimg
      pimg = new PImage
      img = document.createElement("img")
      pimg.sourceImg = img
      img.onload = (aImage, aPImage, aCallback) ->
        image = aImage
        pimg = aPImage
        callback = aCallback
        ->
          pimg.fromHTMLImageData image
          pimg.loaded = true
          callback()  if callback
      (img, pimg, callback)
      img.src = file
      pimg

    p.requestImage = p.loadImage
    p.get = (x, y, w, h, img) ->
      return get$5(x, y, w, h, img)  if img isnt `undefined`
      return get$4(x, y, w, h)  if h isnt `undefined`
      return get$3(x, y, w)  if w isnt `undefined`
      return get$2(x, y)  if y isnt `undefined`
      return get$5(0, 0, x.width, x.height, x)  if x isnt `undefined`
      get$4 0, 0, p.width, p.height

    p.createGraphics = (w, h, render) ->
      pg = new Processing
      pg.size w, h, render
      pg.background 0, 0
      pg

    p.set = (x, y, obj, img) ->
      color = undefined
      oldFill = undefined
      if arguments.length is 3
        p.image obj, x, y  if obj instanceof PImage or obj.__isPImage  unless typeof obj is "number"
      else set$4 x, y, obj, img  if arguments.length is 4

    p.imageData = {}
    p.pixels =
      getLength: ->
        (if p.imageData.data.length then p.imageData.data.length / 4 else 0)

      getPixel: (i) ->
        offset = i * 4
        data = p.imageData.data
        data[offset + 3] << 24 & 4278190080 | data[offset + 0] << 16 & 16711680 | data[offset + 1] << 8 & 65280 | data[offset + 2] & 255

      setPixel: (i, c) ->
        offset = i * 4
        data = p.imageData.data
        data[offset + 0] = (c & 16711680) >>> 16
        data[offset + 1] = (c & 65280) >>> 8
        data[offset + 2] = c & 255
        data[offset + 3] = (c & 4278190080) >>> 24

      toArray: ->
        arr = []
        length = p.imageData.width * p.imageData.height
        data = p.imageData.data
        i = 0
        offset = 0

        while i < length
          arr.push data[offset + 3] << 24 & 4278190080 | data[offset + 0] << 16 & 16711680 | data[offset + 1] << 8 & 65280 | data[offset + 2] & 255
          i++
          offset += 4
        arr

      set: (arr) ->
        i = 0
        aL = arr.length

        while i < aL
          @setPixel i, arr[i]
          i++

    p.loadPixels = ->
      p.imageData = drawing.$ensureContext().getImageData(0, 0, p.width, p.height)

    p.updatePixels = ->
      drawing.$ensureContext().putImageData p.imageData, 0, 0  if p.imageData

    p.hint = (which) ->
      curContext = drawing.$ensureContext()
      if which is 4
        curContext.disable curContext.DEPTH_TEST
        curContext.depthMask false
        curContext.clear curContext.DEPTH_BUFFER_BIT
      else if which is -4
        curContext.enable curContext.DEPTH_TEST
        curContext.depthMask true
      else if which is -1 or which is 2
        renderSmooth = true
      else renderSmooth = false  if which is 1

    backgroundHelper = (arg1, arg2, arg3, arg4) ->
      obj = undefined
      if arg1 instanceof PImage or arg1.__isPImage
        obj = arg1
        throw "Error using image in background(): PImage not loaded."  unless obj.loaded
        throw "Background image must be the same dimensions as the canvas."  if obj.width isnt p.width or obj.height isnt p.height
      else
        obj = p.color(arg1, arg2, arg3, arg4)
      backgroundObj = obj

    Drawing2D::background = (arg1, arg2, arg3, arg4) ->
      backgroundHelper arg1, arg2, arg3, arg4  if arg1 isnt undef
      if backgroundObj instanceof PImage or backgroundObj.__isPImage
        saveContext()
        curContext.setTransform 1, 0, 0, 1, 0, 0
        p.image backgroundObj, 0, 0
        restoreContext()
      else
        saveContext()
        curContext.setTransform 1, 0, 0, 1, 0, 0
        curContext.clearRect 0, 0, p.width, p.height  if p.alpha(backgroundObj) isnt colorModeA
        curContext.fillStyle = p.color.toString(backgroundObj)
        curContext.fillRect 0, 0, p.width, p.height
        isFillDirty = true
        restoreContext()

    Drawing3D::background = (arg1, arg2, arg3, arg4) ->
      backgroundHelper arg1, arg2, arg3, arg4  if arguments.length > 0
      c = p.color.toGLArray(backgroundObj)
      curContext.clearColor c[0], c[1], c[2], c[3]
      curContext.clear curContext.COLOR_BUFFER_BIT | curContext.DEPTH_BUFFER_BIT

    Drawing2D::image = (img, x, y, w, h) ->
      x = Math.round(x)
      y = Math.round(y)
      if img.width > 0
        wid = w or img.width
        hgt = h or img.height
        bounds = imageModeConvert(x or 0, y or 0, w or img.width, h or img.height, arguments.length < 4)
        fastImage = !!img.sourceImg and curTint is null
        if fastImage
          htmlElement = img.sourceImg
          img.updatePixels()  if img.__isDirty
          curContext.drawImage htmlElement, 0, 0, htmlElement.width, htmlElement.height, bounds.x, bounds.y, bounds.w, bounds.h
        else
          obj = img.toImageData()
          if curTint isnt null
            curTint obj
            img.__isDirty = true
          curContext.drawImage getCanvasData(obj).canvas, 0, 0, img.width, img.height, bounds.x, bounds.y, bounds.w, bounds.h

    Drawing3D::image = (img, x, y, w, h) ->
      if img.width > 0
        x = Math.round(x)
        y = Math.round(y)
        w = w or img.width
        h = h or img.height
        p.beginShape p.QUADS
        p.texture img
        p.vertex x, y, 0, 0, 0
        p.vertex x, y + h, 0, 0, h
        p.vertex x + w, y + h, 0, w, h
        p.vertex x + w, y, 0, w, 0
        p.endShape()

    p.tint = (a1, a2, a3, a4) ->
      tintColor = p.color(a1, a2, a3, a4)
      r = p.red(tintColor) / colorModeX
      g = p.green(tintColor) / colorModeY
      b = p.blue(tintColor) / colorModeZ
      a = p.alpha(tintColor) / colorModeA
      curTint = (obj) ->
        data = obj.data
        length = 4 * obj.width * obj.height
        i = 0

        while i < length
          data[i++] *= r
          data[i++] *= g
          data[i++] *= b
          data[i++] *= a

      curTint3d = (data) ->
        i = 0

        while i < data.length
          data[i++] = r
          data[i++] = g
          data[i++] = b
          data[i++] = a

    p.noTint = ->
      curTint = null
      curTint3d = null

    p.copy = (src, sx, sy, sw, sh, dx, dy, dw, dh) ->
      if dh is undef
        dh = dw
        dw = dy
        dy = dx
        dx = sh
        sh = sw
        sw = sy
        sy = sx
        sx = src
        src = p
      p.blend src, sx, sy, sw, sh, dx, dy, dw, dh, 0

    p.blend = (src, sx, sy, sw, sh, dx, dy, dw, dh, mode, pimgdest) ->
      throw "Image is loaded remotely. Cannot blend image."  if src.isRemote
      if mode is undef
        mode = dh
        dh = dw
        dw = dy
        dy = dx
        dx = sh
        sh = sw
        sw = sy
        sy = sx
        sx = src
        src = p
      sx2 = sx + sw
      sy2 = sy + sh
      dx2 = dx + dw
      dy2 = dy + dh
      dest = pimgdest or p
      p.loadPixels()  if pimgdest is undef or mode is undef
      src.loadPixels()
      if src is p and p.intersect(sx, sy, sx2, sy2, dx, dy, dx2, dy2)
        p.blit_resize p.get(sx, sy, sx2 - sx, sy2 - sy), 0, 0, sx2 - sx - 1, sy2 - sy - 1, dest.imageData.data, dest.width, dest.height, dx, dy, dx2, dy2, mode
      else
        p.blit_resize src, sx, sy, sx2, sy2, dest.imageData.data, dest.width, dest.height, dx, dy, dx2, dy2, mode
      p.updatePixels()  if pimgdest is undef

    buildBlurKernel = (r) ->
      radius = p.floor(r * 3.5)
      i = undefined
      radiusi = undefined
      radius = (if radius < 1 then 1 else (if radius < 248 then radius else 248))
      if p.shared.blurRadius isnt radius
        p.shared.blurRadius = radius
        p.shared.blurKernelSize = 1 + (p.shared.blurRadius << 1)
        p.shared.blurKernel = new Float32Array(p.shared.blurKernelSize)
        sharedBlurKernal = p.shared.blurKernel
        sharedBlurKernelSize = p.shared.blurKernelSize
        sharedBlurRadius = p.shared.blurRadius
        i = 0
        while i < sharedBlurKernelSize
          sharedBlurKernal[i] = 0
          i++
        radiusiSquared = (radius - 1) * (radius - 1)
        i = 1
        while i < radius
          sharedBlurKernal[radius + i] = sharedBlurKernal[radiusi] = radiusiSquared
          i++
        sharedBlurKernal[radius] = radius * radius

    blurARGB = (r, aImg) ->
      sum = undefined
      cr = undefined
      cg = undefined
      cb = undefined
      ca = undefined
      c = undefined
      m = undefined
      read = undefined
      ri = undefined
      ym = undefined
      ymi = undefined
      bk0 = undefined
      wh = aImg.pixels.getLength()
      r2 = new Float32Array(wh)
      g2 = new Float32Array(wh)
      b2 = new Float32Array(wh)
      a2 = new Float32Array(wh)
      yi = 0
      x = undefined
      y = undefined
      i = undefined
      offset = undefined
      buildBlurKernel r
      aImgHeight = aImg.height
      aImgWidth = aImg.width
      sharedBlurKernelSize = p.shared.blurKernelSize
      sharedBlurRadius = p.shared.blurRadius
      sharedBlurKernal = p.shared.blurKernel
      pix = aImg.imageData.data
      y = 0
      while y < aImgHeight
        x = 0
        while x < aImgWidth
          cb = cg = cr = ca = sum = 0
          read = x - sharedBlurRadius
          if read < 0
            bk0 = -read
            read = 0
          else
            break  if read >= aImgWidth
            bk0 = 0
          i = bk0
          while i < sharedBlurKernelSize
            break  if read >= aImgWidth
            offset = (read + yi) * 4
            m = sharedBlurKernal[i]
            ca += m * pix[offset + 3]
            cr += m * pix[offset]
            cg += m * pix[offset + 1]
            cb += m * pix[offset + 2]
            sum += m
            read++
            i++
          ri = yi + x
          a2[ri] = ca / sum
          r2[ri] = cr / sum
          g2[ri] = cg / sum
          b2[ri] = cb / sum
          x++
        yi += aImgWidth
        y++
      yi = 0
      ym = -sharedBlurRadius
      ymi = ym * aImgWidth
      y = 0
      while y < aImgHeight
        x = 0
        while x < aImgWidth
          cb = cg = cr = ca = sum = 0
          if ym < 0
            bk0 = ri = -ym
            read = x
          else
            break  if ym >= aImgHeight
            bk0 = 0
            ri = ym
            read = x + ymi
          i = bk0
          while i < sharedBlurKernelSize
            break  if ri >= aImgHeight
            m = sharedBlurKernal[i]
            ca += m * a2[read]
            cr += m * r2[read]
            cg += m * g2[read]
            cb += m * b2[read]
            sum += m
            ri++
            read += aImgWidth
            i++
          offset = (x + yi) * 4
          pix[offset] = cr / sum
          pix[offset + 1] = cg / sum
          pix[offset + 2] = cb / sum
          pix[offset + 3] = ca / sum
          x++
        yi += aImgWidth
        ymi += aImgWidth
        ym++
        y++

    dilate = (isInverted, aImg) ->
      currIdx = 0
      maxIdx = aImg.pixels.getLength()
      out = new Int32Array(maxIdx)
      currRowIdx = undefined
      maxRowIdx = undefined
      colOrig = undefined
      colOut = undefined
      currLum = undefined
      idxRight = undefined
      idxLeft = undefined
      idxUp = undefined
      idxDown = undefined
      colRight = undefined
      colLeft = undefined
      colUp = undefined
      colDown = undefined
      lumRight = undefined
      lumLeft = undefined
      lumUp = undefined
      lumDown = undefined
      unless isInverted
        while currIdx < maxIdx
          currRowIdx = currIdx
          maxRowIdx = currIdx + aImg.width
          while currIdx < maxRowIdx
            colOrig = colOut = aImg.pixels.getPixel(currIdx)
            idxLeft = currIdx - 1
            idxRight = currIdx + 1
            idxUp = currIdx - aImg.width
            idxDown = currIdx + aImg.width
            idxLeft = currIdx  if idxLeft < currRowIdx
            idxRight = currIdx  if idxRight >= maxRowIdx
            idxUp = 0  if idxUp < 0
            idxDown = currIdx  if idxDown >= maxIdx
            colUp = aImg.pixels.getPixel(idxUp)
            colLeft = aImg.pixels.getPixel(idxLeft)
            colDown = aImg.pixels.getPixel(idxDown)
            colRight = aImg.pixels.getPixel(idxRight)
            currLum = 77 * (colOrig >> 16 & 255) + 151 * (colOrig >> 8 & 255) + 28 * (colOrig & 255)
            lumLeft = 77 * (colLeft >> 16 & 255) + 151 * (colLeft >> 8 & 255) + 28 * (colLeft & 255)
            lumRight = 77 * (colRight >> 16 & 255) + 151 * (colRight >> 8 & 255) + 28 * (colRight & 255)
            lumUp = 77 * (colUp >> 16 & 255) + 151 * (colUp >> 8 & 255) + 28 * (colUp & 255)
            lumDown = 77 * (colDown >> 16 & 255) + 151 * (colDown >> 8 & 255) + 28 * (colDown & 255)
            if lumLeft > currLum
              colOut = colLeft
              currLum = lumLeft
            if lumRight > currLum
              colOut = colRight
              currLum = lumRight
            if lumUp > currLum
              colOut = colUp
              currLum = lumUp
            if lumDown > currLum
              colOut = colDown
              currLum = lumDown
            out[currIdx++] = colOut
      else
        while currIdx < maxIdx
          currRowIdx = currIdx
          maxRowIdx = currIdx + aImg.width
          while currIdx < maxRowIdx
            colOrig = colOut = aImg.pixels.getPixel(currIdx)
            idxLeft = currIdx - 1
            idxRight = currIdx + 1
            idxUp = currIdx - aImg.width
            idxDown = currIdx + aImg.width
            idxLeft = currIdx  if idxLeft < currRowIdx
            idxRight = currIdx  if idxRight >= maxRowIdx
            idxUp = 0  if idxUp < 0
            idxDown = currIdx  if idxDown >= maxIdx
            colUp = aImg.pixels.getPixel(idxUp)
            colLeft = aImg.pixels.getPixel(idxLeft)
            colDown = aImg.pixels.getPixel(idxDown)
            colRight = aImg.pixels.getPixel(idxRight)
            currLum = 77 * (colOrig >> 16 & 255) + 151 * (colOrig >> 8 & 255) + 28 * (colOrig & 255)
            lumLeft = 77 * (colLeft >> 16 & 255) + 151 * (colLeft >> 8 & 255) + 28 * (colLeft & 255)
            lumRight = 77 * (colRight >> 16 & 255) + 151 * (colRight >> 8 & 255) + 28 * (colRight & 255)
            lumUp = 77 * (colUp >> 16 & 255) + 151 * (colUp >> 8 & 255) + 28 * (colUp & 255)
            lumDown = 77 * (colDown >> 16 & 255) + 151 * (colDown >> 8 & 255) + 28 * (colDown & 255)
            if lumLeft < currLum
              colOut = colLeft
              currLum = lumLeft
            if lumRight < currLum
              colOut = colRight
              currLum = lumRight
            if lumUp < currLum
              colOut = colUp
              currLum = lumUp
            if lumDown < currLum
              colOut = colDown
              currLum = lumDown
            out[currIdx++] = colOut
      aImg.pixels.set out

    p.filter = (kind, param, aImg) ->
      img = undefined
      col = undefined
      lum = undefined
      i = undefined
      if arguments.length is 3
        aImg.loadPixels()
        img = aImg
      else
        p.loadPixels()
        img = p
      param = null  if param is undef
      throw "Image is loaded remotely. Cannot filter image."  if img.isRemote
      imglen = img.pixels.getLength()
      switch kind
        when 11
          radius = param or 1
          blurARGB radius, img
        when 12
          if img.format is 4
            i = 0
            while i < imglen
              col = 255 - img.pixels.getPixel(i)
              img.pixels.setPixel i, 4278190080 | col << 16 | col << 8 | col
              i++
            img.format = 1
          else
            i = 0
            while i < imglen
              col = img.pixels.getPixel(i)
              lum = 77 * (col >> 16 & 255) + 151 * (col >> 8 & 255) + 28 * (col & 255) >> 8
              img.pixels.setPixel i, col & 4278190080 | lum << 16 | lum << 8 | lum
              i++
        when 13
          i = 0
          while i < imglen
            img.pixels.setPixel i, img.pixels.getPixel(i) ^ 16777215
            i++
        when 15
          throw "Use filter(POSTERIZE, int levels) instead of filter(POSTERIZE)"  if param is null
          levels = p.floor(param)
          throw "Levels must be between 2 and 255 for filter(POSTERIZE, levels)"  if levels < 2 or levels > 255
          levels1 = levels - 1
          i = 0
          while i < imglen
            rlevel = img.pixels.getPixel(i) >> 16 & 255
            glevel = img.pixels.getPixel(i) >> 8 & 255
            blevel = img.pixels.getPixel(i) & 255
            rlevel = (rlevel * levels >> 8) * 255 / levels1
            glevel = (glevel * levels >> 8) * 255 / levels1
            blevel = (blevel * levels >> 8) * 255 / levels1
            img.pixels.setPixel i, 4278190080 & img.pixels.getPixel(i) | rlevel << 16 | glevel << 8 | blevel
            i++
        when 14
          i = 0
          while i < imglen
            img.pixels.setPixel i, img.pixels.getPixel(i) | 4278190080
            i++
          img.format = 1
        when 16
          param = 0.5  if param is null
          throw "Level must be between 0 and 1 for filter(THRESHOLD, level)"  if param < 0 or param > 1
          thresh = p.floor(param * 255)
          i = 0
          while i < imglen
            max = p.max((img.pixels.getPixel(i) & 16711680) >> 16, p.max((img.pixels.getPixel(i) & 65280) >> 8, img.pixels.getPixel(i) & 255))
            img.pixels.setPixel i, img.pixels.getPixel(i) & 4278190080 | ((if max < thresh then 0 else 16777215))
            i++
        when 17
          dilate true, img
        when 18
          dilate false, img
      img.updatePixels()

    p.shared =
      fracU: 0
      ifU: 0
      fracV: 0
      ifV: 0
      u1: 0
      u2: 0
      v1: 0
      v2: 0
      sX: 0
      sY: 0
      iw: 0
      iw1: 0
      ih1: 0
      ul: 0
      ll: 0
      ur: 0
      lr: 0
      cUL: 0
      cLL: 0
      cUR: 0
      cLR: 0
      srcXOffset: 0
      srcYOffset: 0
      r: 0
      g: 0
      b: 0
      a: 0
      srcBuffer: null
      blurRadius: 0
      blurKernelSize: 0
      blurKernel: null

    p.intersect = (sx1, sy1, sx2, sy2, dx1, dy1, dx2, dy2) ->
      sw = sx2 - sx1 + 1
      sh = sy2 - sy1 + 1
      dw = dx2 - dx1 + 1
      dh = dy2 - dy1 + 1
      if dx1 < sx1
        dw += dx1 - sx1
        dw = sw  if dw > sw
      else
        w = sw + sx1 - dx1
        dw = w  if dw > w
      if dy1 < sy1
        dh += dy1 - sy1
        dh = sh  if dh > sh
      else
        h = sh + sy1 - dy1
        dh = h  if dh > h
      not (dw <= 0 or dh <= 0)

    blendFuncs = {}
    blendFuncs[1] = p.modes.blend
    blendFuncs[2] = p.modes.add
    blendFuncs[4] = p.modes.subtract
    blendFuncs[8] = p.modes.lightest
    blendFuncs[16] = p.modes.darkest
    blendFuncs[0] = p.modes.replace
    blendFuncs[32] = p.modes.difference
    blendFuncs[64] = p.modes.exclusion
    blendFuncs[128] = p.modes.multiply
    blendFuncs[256] = p.modes.screen
    blendFuncs[512] = p.modes.overlay
    blendFuncs[1024] = p.modes.hard_light
    blendFuncs[2048] = p.modes.soft_light
    blendFuncs[4096] = p.modes.dodge
    blendFuncs[8192] = p.modes.burn
    p.blit_resize = (img, srcX1, srcY1, srcX2, srcY2, destPixels, screenW, screenH, destX1, destY1, destX2, destY2, mode) ->
      x = undefined
      y = undefined
      srcX1 = 0  if srcX1 < 0
      srcY1 = 0  if srcY1 < 0
      srcX2 = img.width - 1  if srcX2 >= img.width
      srcY2 = img.height - 1  if srcY2 >= img.height
      srcW = srcX2 - srcX1
      srcH = srcY2 - srcY1
      destW = destX2 - destX1
      destH = destY2 - destY1
      return  if destW <= 0 or destH <= 0 or srcW <= 0 or srcH <= 0 or destX1 >= screenW or destY1 >= screenH or srcX1 >= img.width or srcY1 >= img.height
      dx = Math.floor(srcW / destW * 32768)
      dy = Math.floor(srcH / destH * 32768)
      pshared = p.shared
      pshared.srcXOffset = Math.floor((if destX1 < 0 then -destX1 * dx else srcX1 * 32768))
      pshared.srcYOffset = Math.floor((if destY1 < 0 then -destY1 * dy else srcY1 * 32768))
      if destX1 < 0
        destW += destX1
        destX1 = 0
      if destY1 < 0
        destH += destY1
        destY1 = 0
      destW = Math.min(destW, screenW - destX1)
      destH = Math.min(destH, screenH - destY1)
      destOffset = destY1 * screenW + destX1
      destColor = undefined
      pshared.srcBuffer = img.imageData.data
      pshared.iw = img.width
      pshared.iw1 = img.width - 1
      pshared.ih1 = img.height - 1
      filterBilinear = p.filter_bilinear
      filterNewScanline = p.filter_new_scanline
      blendFunc = blendFuncs[mode]
      blendedColor = undefined
      idx = undefined
      cULoffset = undefined
      cURoffset = undefined
      cLLoffset = undefined
      cLRoffset = undefined
      ALPHA_MASK = 4278190080
      RED_MASK = 16711680
      GREEN_MASK = 65280
      BLUE_MASK = 255
      PREC_MAXVAL = 32767
      PRECISIONB = 15
      PREC_RED_SHIFT = 1
      PREC_ALPHA_SHIFT = 9
      srcBuffer = pshared.srcBuffer
      min = Math.min
      y = 0
      while y < destH
        pshared.sX = pshared.srcXOffset
        pshared.fracV = pshared.srcYOffset & PREC_MAXVAL
        pshared.ifV = PREC_MAXVAL - pshared.fracV
        pshared.v1 = (pshared.srcYOffset >> PRECISIONB) * pshared.iw
        pshared.v2 = min((pshared.srcYOffset >> PRECISIONB) + 1, pshared.ih1) * pshared.iw
        x = 0
        while x < destW
          idx = (destOffset + x) * 4
          destColor = destPixels[idx + 3] << 24 & ALPHA_MASK | destPixels[idx] << 16 & RED_MASK | destPixels[idx + 1] << 8 & GREEN_MASK | destPixels[idx + 2] & BLUE_MASK
          pshared.fracU = pshared.sX & PREC_MAXVAL
          pshared.ifU = PREC_MAXVAL - pshared.fracU
          pshared.ul = pshared.ifU * pshared.ifV >> PRECISIONB
          pshared.ll = pshared.ifU * pshared.fracV >> PRECISIONB
          pshared.ur = pshared.fracU * pshared.ifV >> PRECISIONB
          pshared.lr = pshared.fracU * pshared.fracV >> PRECISIONB
          pshared.u1 = pshared.sX >> PRECISIONB
          pshared.u2 = min(pshared.u1 + 1, pshared.iw1)
          cULoffset = (pshared.v1 + pshared.u1) * 4
          cURoffset = (pshared.v1 + pshared.u2) * 4
          cLLoffset = (pshared.v2 + pshared.u1) * 4
          cLRoffset = (pshared.v2 + pshared.u2) * 4
          pshared.cUL = srcBuffer[cULoffset + 3] << 24 & ALPHA_MASK | srcBuffer[cULoffset] << 16 & RED_MASK | srcBuffer[cULoffset + 1] << 8 & GREEN_MASK | srcBuffer[cULoffset + 2] & BLUE_MASK
          pshared.cUR = srcBuffer[cURoffset + 3] << 24 & ALPHA_MASK | srcBuffer[cURoffset] << 16 & RED_MASK | srcBuffer[cURoffset + 1] << 8 & GREEN_MASK | srcBuffer[cURoffset + 2] & BLUE_MASK
          pshared.cLL = srcBuffer[cLLoffset + 3] << 24 & ALPHA_MASK | srcBuffer[cLLoffset] << 16 & RED_MASK | srcBuffer[cLLoffset + 1] << 8 & GREEN_MASK | srcBuffer[cLLoffset + 2] & BLUE_MASK
          pshared.cLR = srcBuffer[cLRoffset + 3] << 24 & ALPHA_MASK | srcBuffer[cLRoffset] << 16 & RED_MASK | srcBuffer[cLRoffset + 1] << 8 & GREEN_MASK | srcBuffer[cLRoffset + 2] & BLUE_MASK
          pshared.r = pshared.ul * ((pshared.cUL & RED_MASK) >> 16) + pshared.ll * ((pshared.cLL & RED_MASK) >> 16) + pshared.ur * ((pshared.cUR & RED_MASK) >> 16) + pshared.lr * ((pshared.cLR & RED_MASK) >> 16) << PREC_RED_SHIFT & RED_MASK
          pshared.g = pshared.ul * (pshared.cUL & GREEN_MASK) + pshared.ll * (pshared.cLL & GREEN_MASK) + pshared.ur * (pshared.cUR & GREEN_MASK) + pshared.lr * (pshared.cLR & GREEN_MASK) >>> PRECISIONB & GREEN_MASK
          pshared.b = pshared.ul * (pshared.cUL & BLUE_MASK) + pshared.ll * (pshared.cLL & BLUE_MASK) + pshared.ur * (pshared.cUR & BLUE_MASK) + pshared.lr * (pshared.cLR & BLUE_MASK) >>> PRECISIONB
          pshared.a = pshared.ul * ((pshared.cUL & ALPHA_MASK) >>> 24) + pshared.ll * ((pshared.cLL & ALPHA_MASK) >>> 24) + pshared.ur * ((pshared.cUR & ALPHA_MASK) >>> 24) + pshared.lr * ((pshared.cLR & ALPHA_MASK) >>> 24) << PREC_ALPHA_SHIFT & ALPHA_MASK
          blendedColor = blendFunc(destColor, pshared.a | pshared.r | pshared.g | pshared.b)
          destPixels[idx] = (blendedColor & RED_MASK) >>> 16
          destPixels[idx + 1] = (blendedColor & GREEN_MASK) >>> 8
          destPixels[idx + 2] = blendedColor & BLUE_MASK
          destPixels[idx + 3] = (blendedColor & ALPHA_MASK) >>> 24
          pshared.sX += dx
          x++
        destOffset += screenW
        pshared.srcYOffset += dy
        y++

    p.loadFont = (name, size) ->
      throw "font name required in loadFont."  if name is undef
      if name.indexOf(".svg") is -1
        size = curTextFont.size  if size is undef
        return PFont.get(name, size)
      font = p.loadGlyphs(name)
      name: name
      css: "12px sans-serif"
      glyph: true
      units_per_em: font.units_per_em
      horiz_adv_x: 1 / font.units_per_em * font.horiz_adv_x
      ascent: font.ascent
      descent: font.descent
      width: (str) ->
        width = 0
        len = str.length
        i = 0

        while i < len
          try
            width += parseFloat(p.glyphLook(p.glyphTable[name], str[i]).horiz_adv_x)
          catch e
            Processing.debug e
          i++
        width / p.glyphTable[name].units_per_em

    p.createFont = (name, size) ->
      p.loadFont name, size

    p.textFont = (pfont, size) ->
      if size isnt undef
        pfont = PFont.get(pfont.name, size)  unless pfont.glyph
        curTextSize = size
      curTextFont = pfont
      curFontName = curTextFont.name
      curTextAscent = curTextFont.ascent
      curTextDescent = curTextFont.descent
      curTextLeading = curTextFont.leading
      curContext = drawing.$ensureContext()
      curContext.font = curTextFont.css

    p.textSize = (size) ->
      curTextFont = PFont.get(curFontName, size)
      curTextSize = size
      curTextAscent = curTextFont.ascent
      curTextDescent = curTextFont.descent
      curTextLeading = curTextFont.leading
      curContext = drawing.$ensureContext()
      curContext.font = curTextFont.css

    p.textAscent = ->
      curTextAscent

    p.textDescent = ->
      curTextDescent

    p.textLeading = (leading) ->
      curTextLeading = leading

    p.textAlign = (xalign, yalign) ->
      horizontalTextAlignment = xalign
      verticalTextAlignment = yalign or 0

    Drawing2D::textWidth = (str) ->
      lines = toP5String(str).split(/\r?\n/g)
      width = 0
      i = undefined
      linesCount = lines.length
      curContext.font = curTextFont.css
      i = 0
      while i < linesCount
        width = Math.max(width, curTextFont.measureTextWidth(lines[i]))
        ++i
      width | 0

    Drawing3D::textWidth = (str) ->
      lines = toP5String(str).split(/\r?\n/g)
      width = 0
      i = undefined
      linesCount = lines.length
      textcanvas = document.createElement("canvas")  if textcanvas is undef
      textContext = textcanvas.getContext("2d")
      textContext.font = curTextFont.css
      i = 0
      while i < linesCount
        width = Math.max(width, textContext.measureText(lines[i]).width)
        ++i
      width | 0

    p.glyphLook = (font, chr) ->
      try
        switch chr
          when "1"
            return font.one
          when "2"
            return font.two
          when "3"
            return font.three
          when "4"
            return font.four
          when "5"
            return font.five
          when "6"
            return font.six
          when "7"
            return font.seven
          when "8"
            return font.eight
          when "9"
            return font.nine
          when "0"
            return font.zero
          when " "
            return font.space
          when "$"
            return font.dollar
          when "!"
            return font.exclam
          when "\""
            return font.quotedbl
          when "#"
            return font.numbersign
          when "%"
            return font.percent
          when "&"
            return font.ampersand
          when "'"
            return font.quotesingle
          when "("
            return font.parenleft
          when ")"
            return font.parenright
          when "*"
            return font.asterisk
          when "+"
            return font.plus
          when ","
            return font.comma
          when "-"
            return font.hyphen
          when "."
            return font.period
          when "/"
            return font.slash
          when "_"
            return font.underscore
          when ":"
            return font.colon
          when ";"
            return font.semicolon
          when "<"
            return font.less
          when "="
            return font.equal
          when ">"
            return font.greater
          when "?"
            return font.question
          when "@"
            return font.at
          when "["
            return font.bracketleft
          when "\\"
            return font.backslash
          when "]"
            return font.bracketright
          when "^"
            return font.asciicircum
          when "`"
            return font.grave
          when "{"
            return font.braceleft
          when "|"
            return font.bar
          when "}"
            return font.braceright
          when "~"
            return font.asciitilde
          else
            return font[chr]
      catch e
        Processing.debug e

    Drawing2D::text$line = (str, x, y, z, align) ->
      textWidth = 0
      xOffset = 0
      unless curTextFont.glyph
        if str and "fillText" of curContext
          if isFillDirty
            curContext.fillStyle = p.color.toString(currentFillColor)
            isFillDirty = false
          if align is 39 or align is 3
            textWidth = curTextFont.measureTextWidth(str)
            if align is 39
              xOffset = -textWidth
            else
              xOffset = -textWidth / 2
          curContext.fillText str, x + xOffset, y
      else
        font = p.glyphTable[curFontName]
        saveContext()
        curContext.translate x, y + curTextSize
        if align is 39 or align is 3
          textWidth = font.width(str)
          if align is 39
            xOffset = -textWidth
          else
            xOffset = -textWidth / 2
        upem = font.units_per_em
        newScale = 1 / upem * curTextSize
        curContext.scale newScale, newScale
        i = 0
        len = str.length

        while i < len
          try
            p.glyphLook(font, str[i]).draw()
          catch e
            Processing.debug e
          i++
        restoreContext()

    Drawing3D::text$line = (str, x, y, z, align) ->
      textcanvas = document.createElement("canvas")  if textcanvas is undef
      oldContext = curContext
      curContext = textcanvas.getContext("2d")
      curContext.font = curTextFont.css
      textWidth = curTextFont.measureTextWidth(str)
      textcanvas.width = textWidth
      textcanvas.height = curTextSize
      curContext = textcanvas.getContext("2d")
      curContext.font = curTextFont.css
      curContext.textBaseline = "top"
      Drawing2D::text$line str, 0, 0, 0, 37
      aspect = textcanvas.width / textcanvas.height
      curContext = oldContext
      curContext.bindTexture curContext.TEXTURE_2D, textTex
      curContext.texImage2D curContext.TEXTURE_2D, 0, curContext.RGBA, curContext.RGBA, curContext.UNSIGNED_BYTE, textcanvas
      curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_MAG_FILTER, curContext.LINEAR
      curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_MIN_FILTER, curContext.LINEAR
      curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_WRAP_T, curContext.CLAMP_TO_EDGE
      curContext.texParameteri curContext.TEXTURE_2D, curContext.TEXTURE_WRAP_S, curContext.CLAMP_TO_EDGE
      xOffset = 0
      if align is 39
        xOffset = -textWidth
      else xOffset = -textWidth / 2  if align is 3
      model = new PMatrix3D
      scalefactor = curTextSize * 0.5
      model.translate x + xOffset - scalefactor / 2, y - scalefactor, z
      model.scale -aspect * scalefactor, -scalefactor, scalefactor
      model.translate -1, -1, -1
      model.transpose()
      view = new PMatrix3D
      view.scale 1, -1, 1
      view.apply modelView.array()
      view.transpose()
      curContext.useProgram programObject2D
      vertexAttribPointer "aVertex2d", programObject2D, "aVertex", 3, textBuffer
      vertexAttribPointer "aTextureCoord2d", programObject2D, "aTextureCoord", 2, textureBuffer
      uniformi "uSampler2d", programObject2D, "uSampler", [ 0 ]
      uniformi "uIsDrawingText2d", programObject2D, "uIsDrawingText", true
      uniformMatrix "uModel2d", programObject2D, "uModel", false, model.array()
      uniformMatrix "uView2d", programObject2D, "uView", false, view.array()
      uniformf "uColor2d", programObject2D, "uColor", fillStyle
      curContext.bindBuffer curContext.ELEMENT_ARRAY_BUFFER, indexBuffer
      curContext.drawElements curContext.TRIANGLES, 6, curContext.UNSIGNED_SHORT, 0

    p.text = ->
      return  if textMode is 5
      if arguments.length is 3
        text$4 toP5String(arguments[0]), arguments[1], arguments[2], 0
      else if arguments.length is 4
        text$4 toP5String(arguments[0]), arguments[1], arguments[2], arguments[3]
      else if arguments.length is 5
        text$6 toP5String(arguments[0]), arguments[1], arguments[2], arguments[3], arguments[4], 0
      else text$6 toP5String(arguments[0]), arguments[1], arguments[2], arguments[3], arguments[4], arguments[5]  if arguments.length is 6

    p.textMode = (mode) ->
      textMode = mode

    p.loadGlyphs = (url) ->
      x = undefined
      y = undefined
      cx = undefined
      cy = undefined
      nx = undefined
      ny = undefined
      d = undefined
      a = undefined
      lastCom = undefined
      lenC = undefined
      horiz_adv_x = undefined
      getXY = "[0-9\\-]+"
      path = undefined
      regex = (needle, hay) ->
        i = 0
        results = []
        latest = undefined
        regexp = new RegExp(needle, "g")
        latest = results[i] = regexp.exec(hay)
        while latest
          i++
          latest = results[i] = regexp.exec(hay)
        results

      buildPath = (d) ->
        c = regex("[A-Za-z][0-9\\- ]+|Z", d)
        beforePathDraw = ->
          saveContext()
          drawing.$ensureContext()

        afterPathDraw = ->
          executeContextFill()
          executeContextStroke()
          restoreContext()

        path = "return {draw:function(){var curContext=beforePathDraw();curContext.beginPath();"
        x = 0
        y = 0
        cx = 0
        cy = 0
        nx = 0
        ny = 0
        d = 0
        a = 0
        lastCom = ""
        lenC = c.length - 1
        j = 0

        while j < lenC
          com = c[j][0]
          xy = regex(getXY, com)
          switch com[0]
            when "M"
              x = parseFloat(xy[0][0])
              y = parseFloat(xy[1][0])
              path += "curContext.moveTo(" + x + "," + -y + ");"
            when "L"
              x = parseFloat(xy[0][0])
              y = parseFloat(xy[1][0])
              path += "curContext.lineTo(" + x + "," + -y + ");"
            when "H"
              x = parseFloat(xy[0][0])
              path += "curContext.lineTo(" + x + "," + -y + ");"
            when "V"
              y = parseFloat(xy[0][0])
              path += "curContext.lineTo(" + x + "," + -y + ");"
            when "T"
              nx = parseFloat(xy[0][0])
              ny = parseFloat(xy[1][0])
              if lastCom is "Q" or lastCom is "T"
                d = Math.sqrt(Math.pow(x - cx, 2) + Math.pow(cy - y, 2))
                a = Math.PI + Math.atan2(cx - x, cy - y)
                cx = x + Math.sin(a) * d
                cy = y + Math.cos(a) * d
              else
                cx = x
                cy = y
              path += "curContext.quadraticCurveTo(" + cx + "," + -cy + "," + nx + "," + -ny + ");"
              x = nx
              y = ny
            when "Q"
              cx = parseFloat(xy[0][0])
              cy = parseFloat(xy[1][0])
              nx = parseFloat(xy[2][0])
              ny = parseFloat(xy[3][0])
              path += "curContext.quadraticCurveTo(" + cx + "," + -cy + "," + nx + "," + -ny + ");"
              x = nx
              y = ny
            when "Z"
              path += "curContext.closePath();"
          lastCom = com[0]
          j++
        path += "afterPathDraw();"
        path += "curContext.translate(" + horiz_adv_x + ",0);"
        path += "}}"
        (new Function("beforePathDraw", "afterPathDraw", path)) beforePathDraw, afterPathDraw

      parseSVGFont = (svg) ->
        font = svg.getElementsByTagName("font")
        p.glyphTable[url].horiz_adv_x = font[0].getAttribute("horiz-adv-x")
        font_face = svg.getElementsByTagName("font-face")[0]
        p.glyphTable[url].units_per_em = parseFloat(font_face.getAttribute("units-per-em"))
        p.glyphTable[url].ascent = parseFloat(font_face.getAttribute("ascent"))
        p.glyphTable[url].descent = parseFloat(font_face.getAttribute("descent"))
        glyph = svg.getElementsByTagName("glyph")
        len = glyph.length
        i = 0

        while i < len
          unicode = glyph[i].getAttribute("unicode")
          name = glyph[i].getAttribute("glyph-name")
          horiz_adv_x = glyph[i].getAttribute("horiz-adv-x")
          horiz_adv_x = p.glyphTable[url].horiz_adv_x  if horiz_adv_x is null
          d = glyph[i].getAttribute("d")
          if d isnt undef
            path = buildPath(d)
            p.glyphTable[url][name] =
              name: name
              unicode: unicode
              horiz_adv_x: horiz_adv_x
              draw: path.draw
          i++

      loadXML = ->
        xmlDoc = undefined
        try
          xmlDoc = document.implementation.createDocument("", "", null)
        catch e_fx_op
          Processing.debug e_fx_op.message
          return
        try
          xmlDoc.async = false
          xmlDoc.load url
          parseSVGFont xmlDoc.getElementsByTagName("svg")[0]
        catch e_sf_ch
          Processing.debug e_sf_ch
          try
            xmlhttp = new window.XMLHttpRequest
            xmlhttp.open "GET", url, false
            xmlhttp.send null
            parseSVGFont xmlhttp.responseXML.documentElement
          catch e
            Processing.debug e_sf_ch

      p.glyphTable[url] = {}
      loadXML url
      p.glyphTable[url]

    p.param = (name) ->
      attributeName = "data-processing-" + name
      return curElement.getAttribute(attributeName)  if curElement.hasAttribute(attributeName)
      i = 0
      len = curElement.childNodes.length

      while i < len
        item = curElement.childNodes.item(i)
        continue  if item.nodeType isnt 1 or item.tagName.toLowerCase() isnt "param"
        return item.getAttribute("value")  if item.getAttribute("name") is name
        ++i
      return curSketch.params[name]  if curSketch.params.hasOwnProperty(name)
      null

    DrawingPre::translate = createDrawingPreFunction("translate")
    DrawingPre::transform = createDrawingPreFunction("transform")
    DrawingPre::scale = createDrawingPreFunction("scale")
    DrawingPre::pushMatrix = createDrawingPreFunction("pushMatrix")
    DrawingPre::popMatrix = createDrawingPreFunction("popMatrix")
    DrawingPre::resetMatrix = createDrawingPreFunction("resetMatrix")
    DrawingPre::applyMatrix = createDrawingPreFunction("applyMatrix")
    DrawingPre::rotate = createDrawingPreFunction("rotate")
    DrawingPre::rotateZ = createDrawingPreFunction("rotateZ")
    DrawingPre::shearX = createDrawingPreFunction("shearX")
    DrawingPre::shearY = createDrawingPreFunction("shearY")
    DrawingPre::redraw = createDrawingPreFunction("redraw")
    DrawingPre::toImageData = createDrawingPreFunction("toImageData")
    DrawingPre::ambientLight = createDrawingPreFunction("ambientLight")
    DrawingPre::directionalLight = createDrawingPreFunction("directionalLight")
    DrawingPre::lightFalloff = createDrawingPreFunction("lightFalloff")
    DrawingPre::lightSpecular = createDrawingPreFunction("lightSpecular")
    DrawingPre::pointLight = createDrawingPreFunction("pointLight")
    DrawingPre::noLights = createDrawingPreFunction("noLights")
    DrawingPre::spotLight = createDrawingPreFunction("spotLight")
    DrawingPre::beginCamera = createDrawingPreFunction("beginCamera")
    DrawingPre::endCamera = createDrawingPreFunction("endCamera")
    DrawingPre::frustum = createDrawingPreFunction("frustum")
    DrawingPre::box = createDrawingPreFunction("box")
    DrawingPre::sphere = createDrawingPreFunction("sphere")
    DrawingPre::ambient = createDrawingPreFunction("ambient")
    DrawingPre::emissive = createDrawingPreFunction("emissive")
    DrawingPre::shininess = createDrawingPreFunction("shininess")
    DrawingPre::specular = createDrawingPreFunction("specular")
    DrawingPre::fill = createDrawingPreFunction("fill")
    DrawingPre::stroke = createDrawingPreFunction("stroke")
    DrawingPre::strokeWeight = createDrawingPreFunction("strokeWeight")
    DrawingPre::smooth = createDrawingPreFunction("smooth")
    DrawingPre::noSmooth = createDrawingPreFunction("noSmooth")
    DrawingPre::point = createDrawingPreFunction("point")
    DrawingPre::vertex = createDrawingPreFunction("vertex")
    DrawingPre::endShape = createDrawingPreFunction("endShape")
    DrawingPre::bezierVertex = createDrawingPreFunction("bezierVertex")
    DrawingPre::curveVertex = createDrawingPreFunction("curveVertex")
    DrawingPre::curve = createDrawingPreFunction("curve")
    DrawingPre::line = createDrawingPreFunction("line")
    DrawingPre::bezier = createDrawingPreFunction("bezier")
    DrawingPre::rect = createDrawingPreFunction("rect")
    DrawingPre::ellipse = createDrawingPreFunction("ellipse")
    DrawingPre::background = createDrawingPreFunction("background")
    DrawingPre::image = createDrawingPreFunction("image")
    DrawingPre::textWidth = createDrawingPreFunction("textWidth")
    DrawingPre::text$line = createDrawingPreFunction("text$line")
    DrawingPre::$ensureContext = createDrawingPreFunction("$ensureContext")
    DrawingPre::$newPMatrix = createDrawingPreFunction("$newPMatrix")
    DrawingPre::size = (aWidth, aHeight, aMode) ->
      wireDimensionalFunctions (if aMode is 2 then "3D" else "2D")
      p.size aWidth, aHeight, aMode

    DrawingPre::$init = nop
    Drawing2D::$init = ->
      p.size p.width, p.height
      curContext.lineCap = "round"
      p.noSmooth()
      p.disableContextMenu()

    Drawing3D::$init = ->
      p.use3DContext = true
      p.disableContextMenu()

    DrawingShared::$ensureContext = ->
      curContext

    attachEventHandler curElement, "touchstart", (t) ->
      curElement.setAttribute "style", "-webkit-user-select: none"
      curElement.setAttribute "onclick", "void(0)"
      curElement.setAttribute "style", "-webkit-tap-highlight-color:rgba(0,0,0,0)"
      i = 0
      ehl = eventHandlers.length

      while i < ehl
        type = eventHandlers[i].type
        detachEventHandler eventHandlers[i]  if type is "mouseout" or type is "mousemove" or type is "mousedown" or type is "mouseup" or type is "DOMMouseScroll" or type is "mousewheel" or type is "touchstart"
        i++
      if p.touchStart isnt undef or p.touchMove isnt undef or p.touchEnd isnt undef or p.touchCancel isnt undef
        attachEventHandler curElement, "touchstart", (t) ->
          if p.touchStart isnt undef
            t = addTouchEventOffset(t)
            p.touchStart t

        attachEventHandler curElement, "touchmove", (t) ->
          if p.touchMove isnt undef
            t.preventDefault()
            t = addTouchEventOffset(t)
            p.touchMove t

        attachEventHandler curElement, "touchend", (t) ->
          if p.touchEnd isnt undef
            t = addTouchEventOffset(t)
            p.touchEnd t

        attachEventHandler curElement, "touchcancel", (t) ->
          if p.touchCancel isnt undef
            t = addTouchEventOffset(t)
            p.touchCancel t

      else
        attachEventHandler curElement, "touchstart", (e) ->
          updateMousePosition curElement, e.touches[0]
          p.__mousePressed = true
          p.mouseDragging = false
          p.mouseButton = 37
          p.mousePressed()  if typeof p.mousePressed is "function"

        attachEventHandler curElement, "touchmove", (e) ->
          e.preventDefault()
          updateMousePosition curElement, e.touches[0]
          p.mouseMoved()  if typeof p.mouseMoved is "function" and not p.__mousePressed
          if typeof p.mouseDragged is "function" and p.__mousePressed
            p.mouseDragged()
            p.mouseDragging = true

        attachEventHandler curElement, "touchend", (e) ->
          p.__mousePressed = false
          p.mouseClicked()  if typeof p.mouseClicked is "function" and not p.mouseDragging
          p.mouseReleased()  if typeof p.mouseReleased is "function"

      curElement.dispatchEvent t

    (->
      enabled = true
      contextMenu = (e) ->
        e.preventDefault()
        e.stopPropagation()

      p.disableContextMenu = ->
        return  unless enabled
        attachEventHandler curElement, "contextmenu", contextMenu
        enabled = false

      p.enableContextMenu = ->
        return  if enabled
        detachEventHandler
          elem: curElement
          type: "contextmenu"
          fn: contextMenu

        enabled = true
    )()
    attachEventHandler curElement, "mousemove", (e) ->
      updateMousePosition curElement, e
      p.mouseMoved()  if typeof p.mouseMoved is "function" and not p.__mousePressed
      if typeof p.mouseDragged is "function" and p.__mousePressed
        p.mouseDragged()
        p.mouseDragging = true

    attachEventHandler curElement, "mouseout", (e) ->
      p.mouseOut()  if typeof p.mouseOut is "function"

    attachEventHandler curElement, "mouseover", (e) ->
      updateMousePosition curElement, e
      p.mouseOver()  if typeof p.mouseOver is "function"

    curElement.onmousedown = ->
      curElement.focus()
      false

    attachEventHandler curElement, "mousedown", (e) ->
      p.__mousePressed = true
      p.mouseDragging = false
      switch e.which
        when 1
          p.mouseButton = 37
        when 2
          p.mouseButton = 3
        when 3
          p.mouseButton = 39
      p.mousePressed()  if typeof p.mousePressed is "function"

    attachEventHandler curElement, "mouseup", (e) ->
      p.__mousePressed = false
      p.mouseClicked()  if typeof p.mouseClicked is "function" and not p.mouseDragging
      p.mouseReleased()  if typeof p.mouseReleased is "function"

    mouseWheelHandler = (e) ->
      delta = 0
      if e.wheelDelta
        delta = e.wheelDelta / 120
        delta = -delta  if window.opera
      else delta = -e.detail / 3  if e.detail
      p.mouseScroll = delta
      p.mouseScrolled()  if delta and typeof p.mouseScrolled is "function"

    attachEventHandler document, "DOMMouseScroll", mouseWheelHandler
    attachEventHandler document, "mousewheel", mouseWheelHandler
    curElement.setAttribute "tabindex", 0  unless curElement.getAttribute("tabindex")
    unless pgraphicsMode
      if aCode instanceof Processing.Sketch
        curSketch = aCode
      else if typeof aCode is "function"
        curSketch = new Processing.Sketch(aCode)
      else unless aCode
        curSketch = new Processing.Sketch(->
        )
      else
        curSketch = Processing.compile(aCode)
      p.externals.sketch = curSketch
      wireDimensionalFunctions()
      curElement.onfocus = ->
        p.focused = true

      curElement.onblur = ->
        p.focused = false
        resetKeyPressed()  unless curSketch.options.globalKeyEvents

      if curSketch.options.pauseOnBlur
        attachEventHandler window, "focus", ->
          p.loop()  if doLoop

        attachEventHandler window, "blur", ->
          if doLoop and loopStarted
            p.noLoop()
            doLoop = true
          resetKeyPressed()

      keyTrigger = (if curSketch.options.globalKeyEvents then window else curElement)
      attachEventHandler keyTrigger, "keydown", handleKeydown
      attachEventHandler keyTrigger, "keypress", handleKeypress
      attachEventHandler keyTrigger, "keyup", handleKeyup
      for i of Processing.lib
        if Processing.lib.hasOwnProperty(i)
          if Processing.lib[i].hasOwnProperty("attach")
            Processing.lib[i].attach p
          else Processing.lib[i].call this  if Processing.lib[i] instanceof Function
      retryInterval = 100
      executeSketch = (processing) ->
        unless curSketch.imageCache.pending or PFont.preloading.pending(retryInterval)
          if window.opera
            link = undefined
            element = undefined
            operaCache = curSketch.imageCache.operaCache
            for link of operaCache
              if operaCache.hasOwnProperty(link)
                element = operaCache[link]
                document.body.removeChild element  if element isnt null
                delete operaCache[link]
          curSketch.attach processing, defaultScope
          curSketch.onLoad processing
          if processing.setup
            processing.setup()
            processing.resetMatrix()
            curSketch.onSetup()
          resetContext()
          if processing.draw
            unless doLoop
              processing.redraw()
            else
              processing.loop()
        else
          window.setTimeout (->
            executeSketch processing
          ), retryInterval

      addInstance this
      executeSketch p
    else
      curSketch = new Processing.Sketch
      wireDimensionalFunctions()
      p.size = (w, h, render) ->
        if render and render is 2
          wireDimensionalFunctions "3D"
        else
          wireDimensionalFunctions "2D"
        p.size w, h, render

  Processing.debug = debug
  Processing:: = defaultScope
  Processing.compile = (pdeCode) ->
    sketch = new Processing.Sketch
    code = preprocessCode(pdeCode, sketch)
    compiledPde = parseProcessing(code)
    sketch.sourceCode = compiledPde
    sketch

  tinylogLite = ->
    tinylogLite = {}
    undef = "undefined"
    func = "function"
    False = not 1
    True = not 0
    logLimit = 512
    log = "log"
    if typeof tinylog isnt undef and typeof tinylog[log] is func
      tinylogLite[log] = tinylog[log]
    else if typeof document isnt undef and not document.fake
      (->
        doc = document
        $div = "div"
        $style = "style"
        $title = "title"
        containerStyles =
          zIndex: 1E4
          position: "fixed"
          bottom: "0px"
          width: "100%"
          height: "15%"
          fontFamily: "sans-serif"
          color: "#ccc"
          backgroundColor: "black"

        outputStyles =
          position: "relative"
          fontFamily: "monospace"
          overflow: "auto"
          height: "100%"
          paddingTop: "5px"

        resizerStyles =
          height: "5px"
          marginTop: "-5px"
          cursor: "n-resize"
          backgroundColor: "darkgrey"

        closeButtonStyles =
          position: "absolute"
          top: "5px"
          right: "20px"
          color: "#111"
          MozBorderRadius: "4px"
          webkitBorderRadius: "4px"
          borderRadius: "4px"
          cursor: "pointer"
          fontWeight: "normal"
          textAlign: "center"
          padding: "3px 5px"
          backgroundColor: "#333"
          fontSize: "12px"

        entryStyles = minHeight: "16px"
        entryTextStyles =
          fontSize: "12px"
          margin: "0 8px 0 8px"
          maxWidth: "100%"
          whiteSpace: "pre-wrap"
          overflow: "auto"

        view = doc.defaultView
        docElem = doc.documentElement
        docElemStyle = docElem[$style]
        setStyles = ->
          i = arguments.length
          elemStyle = undefined
          styles = undefined
          style = undefined
          while i--
            styles = arguments[i--]
            elemStyle = arguments[i][$style]
            for style of styles
              elemStyle[style] = styles[style]  if styles.hasOwnProperty(style)

        observer = (obj, event, handler) ->
          if obj.addEventListener
            obj.addEventListener event, handler, False
          else obj.attachEvent "on" + event, handler  if obj.attachEvent
          [ obj, event, handler ]

        unobserve = (obj, event, handler) ->
          if obj.removeEventListener
            obj.removeEventListener event, handler, False
          else obj.detachEvent "on" + event, handler  if obj.detachEvent

        clearChildren = (node) ->
          children = node.childNodes
          child = children.length
          node.removeChild children.item(0)  while child--

        append = (to, elem) ->
          to.appendChild elem

        createElement = (localName) ->
          doc.createElement localName

        createTextNode = (text) ->
          doc.createTextNode text

        createLog = tinylogLite[log] = (message) ->
          uninit = undefined
          originalPadding = docElemStyle.paddingBottom
          container = createElement($div)
          containerStyle = container[$style]
          resizer = append(container, createElement($div))
          output = append(container, createElement($div))
          closeButton = append(container, createElement($div))
          resizingLog = False
          previousHeight = False
          previousScrollTop = False
          messages = 0
          updateSafetyMargin = ->
            docElemStyle.paddingBottom = container.clientHeight + "px"

          setContainerHeight = (height) ->
            viewHeight = view.innerHeight
            resizerHeight = resizer.clientHeight
            if height < 0
              height = 0
            else height = viewHeight - resizerHeight  if height + resizerHeight > viewHeight
            containerStyle.height = height / viewHeight * 100 + "%"
            updateSafetyMargin()

          observers = [ observer(doc, "mousemove", (evt) ->
            if resizingLog
              setContainerHeight view.innerHeight - evt.clientY
              output.scrollTop = previousScrollTop
          ), observer(doc, "mouseup", ->
            resizingLog = previousScrollTop = False  if resizingLog
          ), observer(resizer, "dblclick", (evt) ->
            evt.preventDefault()
            if previousHeight
              setContainerHeight previousHeight
              previousHeight = False
            else
              previousHeight = container.clientHeight
              containerStyle.height = "0px"
          ), observer(resizer, "mousedown", (evt) ->
            evt.preventDefault()
            resizingLog = True
            previousScrollTop = output.scrollTop
          ), observer(resizer, "contextmenu", ->
            resizingLog = False
          ), observer(closeButton, "click", ->
            uninit()
          ) ]
          uninit = ->
            i = observers.length
            unobserve.apply tinylogLite, observers[i]  while i--
            docElem.removeChild container
            docElemStyle.paddingBottom = originalPadding
            clearChildren output
            clearChildren container
            tinylogLite[log] = createLog

          setStyles container, containerStyles, output, outputStyles, resizer, resizerStyles, closeButton, closeButtonStyles
          closeButton[$title] = "Close Log"
          append closeButton, createTextNode("?")
          resizer[$title] = "Double-click to toggle log minimization"
          docElem.insertBefore container, docElem.firstChild
          tinylogLite[log] = (message) ->
            if messages is logLimit
              output.removeChild output.firstChild
            else
              messages++
            entry = append(output, createElement($div))
            entryText = append(entry, createElement($div))
            entry[$title] = (new Date).toLocaleTimeString()
            setStyles entry, entryStyles, entryText, entryTextStyles
            append entryText, createTextNode(message)
            output.scrollTop = output.scrollHeight

          tinylogLite[log] message
          updateSafetyMargin()
      )()
    else tinylogLite[log] = print  if typeof print is func
    tinylogLite
  ()
  Processing.logger = tinylogLite
  Processing.version = "1.4.1"
  Processing.lib = {}
  Processing.registerLibrary = (name, desc) ->
    Processing.lib[name] = desc
    desc.init defaultScope  if desc.hasOwnProperty("init")

  Processing.instances = processingInstances
  Processing.getInstanceById = (name) ->
    processingInstances[processingInstanceIds[name]]

  Processing.Sketch = (attachFunction) ->
    @attachFunction = attachFunction
    @options =
      pauseOnBlur: false
      globalKeyEvents: false

    @onLoad = nop
    @onSetup = nop
    @onPause = nop
    @onLoop = nop
    @onFrameStart = nop
    @onFrameEnd = nop
    @onExit = nop
    @params = {}
    @imageCache =
      pending: 0
      images: {}
      operaCache: {}
      add: (href, img) ->
        return  if @images[href]
        @images[href] = null  unless isDOMPresent
        unless img
          img = new Image
          img.onload = (owner) ->
            ->
              owner.pending--
          (this)
          @pending++
          img.src = href
        @images[href] = img
        if window.opera
          div = document.createElement("div")
          div.appendChild img
          div.style.position = "absolute"
          div.style.opacity = 0
          div.style.width = "1px"
          div.style.height = "1px"
          unless @operaCache[href]
            document.body.appendChild div
            @operaCache[href] = div

    @sourceCode = `undefined`
    @attach = (processing) ->
      if typeof @attachFunction is "function"
        @attachFunction processing
      else if @sourceCode
        func = (new Function("return (" + @sourceCode + ");"))()
        func processing
        @attachFunction = func
      else
        throw "Unable to attach sketch to the processing instance"

    @toString = ->
      i = undefined
      code = "((function(Sketch) {\n"
      code += "var sketch = new Sketch(\n" + @sourceCode + ");\n"
      for i of @options
        if @options.hasOwnProperty(i)
          value = @options[i]
          code += "sketch.options." + i + " = " + ((if typeof value is "string" then "\"" + value + "\"" else "" + value)) + ";\n"
      for i of @imageCache
        code += "sketch.imageCache.add(\"" + i + "\");\n"  if @options.hasOwnProperty(i)
      code += "return sketch;\n})(Processing.Sketch))"
      code

  loadSketchFromSources = (canvas, sources) ->
    ajaxAsync = (url, callback) ->
      xhr = new XMLHttpRequest
      xhr.onreadystatechange = ->
        if xhr.readyState is 4
          error = undefined
          if xhr.status isnt 200 and xhr.status isnt 0
            error = "Invalid XHR status " + xhr.status
          else if xhr.responseText is ""
            if "withCredentials" of new XMLHttpRequest and (new XMLHttpRequest).withCredentials is false and window.location.protocol is "file:"
              error = "XMLHttpRequest failure, possibly due to a same-origin policy violation. You can try loading this page in another browser, or load it from http://localhost using a local webserver. See the Processing.js README for a more detailed explanation of this problem and solutions."
            else
              error = "File is empty."
          callback xhr.responseText, error

      xhr.open "GET", url, true
      xhr.overrideMimeType "application/json"  if xhr.overrideMimeType
      xhr.setRequestHeader "If-Modified-Since", "Fri, 01 Jan 1960 00:00:00 GMT"
      xhr.send null
    loadBlock = (index, filename) ->
      callback = (block, error) ->
        code[index] = block
        ++loaded
        errors.push filename + " ==> " + error  if error
        if loaded is sourcesCount
          if errors.length is 0
            try
              return new Processing(canvas, code.join("\n"))
            catch e
              throw "Processing.js: Unable to execute pjs sketch: " + e
          else
            throw "Processing.js: Unable to load pjs sketch files: " + errors.join("\n")
      if filename.charAt(0) is "#"
        scriptElement = document.getElementById(filename.substring(1))
        if scriptElement
          callback scriptElement.text or scriptElement.textContent
        else
          callback "", "Unable to load pjs sketch: element with id '" + filename.substring(1) + "' was not found"
        return
      ajaxAsync filename, callback
    code = []
    errors = []
    sourcesCount = sources.length
    loaded = 0
    i = 0

    while i < sourcesCount
      loadBlock i, sources[i]
      ++i

  init = ->
    document.removeEventListener "DOMContentLoaded", init, false
    processingInstances = []
    canvas = document.getElementsByTagName("canvas")
    filenames = undefined
    i = 0
    l = canvas.length

    while i < l
      processingSources = canvas[i].getAttribute("data-processing-sources")
      if processingSources is null
        processingSources = canvas[i].getAttribute("data-src")
        processingSources = canvas[i].getAttribute("datasrc")  if processingSources is null
      if processingSources
        filenames = processingSources.split(/\s+/g)
        j = 0

        while j < filenames.length
          if filenames[j]
            j++
          else
            filenames.splice j, 1
        loadSketchFromSources canvas[i], filenames
      i++
    s = undefined
    last = undefined
    source = undefined
    instance = undefined
    nodelist = document.getElementsByTagName("script")
    scripts = []
    s = nodelist.length - 1
    while s >= 0
      scripts.push nodelist[s]
      s--
    s = 0
    last = scripts.length

    while s < last
      script = scripts[s]
      continue  unless script.getAttribute
      type = script.getAttribute("type")
      if type and (type.toLowerCase() is "text/processing" or type.toLowerCase() is "application/processing")
        target = script.getAttribute("data-processing-target")
        canvas = undef
        unless target
          nextSibling = script.nextSibling
          nextSibling = nextSibling.nextSibling  while nextSibling and nextSibling.nodeType isnt 1
          canvas = nextSibling  if nextSibling and nextSibling.nodeName.toLowerCase() is "canvas"
        if canvas
          if script.getAttribute("src")
            filenames = script.getAttribute("src").split(/\s+/)
            loadSketchFromSources canvas, filenames
            continue
          source = script.textContent or script.text
          instance = new Processing(canvas, source)
      s++

  Processing.reload = ->
    if processingInstances.length > 0
      i = processingInstances.length - 1

      while i >= 0
        processingInstances[i].exit()  if processingInstances[i]
        i--
    init()

  Processing.loadSketchFromSources = loadSketchFromSources
  Processing.disableInit = ->
    document.removeEventListener "DOMContentLoaded", init, false  if isDOMPresent

  if isDOMPresent
    window["Processing"] = Processing
    document.addEventListener "DOMContentLoaded", init, false
  else
    @Processing = Processing
) window, window.document, Math