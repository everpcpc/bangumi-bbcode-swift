import Foundation

extension BBCode {
  public func html(_ bbcode: String, args: [String: Any]? = nil) throws -> String {
    let worker: Worker = Worker(tagManager: tagManager)

    if let domTree = worker.parse(bbcode) {
      handleNewlineAndParagraph(node: domTree, tagManager: tagManager)
      return (domTree.description!.html!(domTree, args))
    } else {
      throw worker.error!
    }
  }
}

extension Node {
  var escapedValue: String {
    // Only plain node value is directly usable in render, other tags needs to render subnode.
    return value.stringByEncodingHTML
  }

  var escapedAttr: String {
    return attr.stringByEncodingHTML
  }

  func renderInnerHTML(_ args: [String: Any]?) -> String {
    var html = ""
    for n in children {
      if let render = n.description?.html {
        html.append(render(n, args))
      }
    }
    return html
  }
}

@MainActor
func BBCodeToHTML(code: String, textSize: Int) -> String {
  guard let body = try? BBCode().html(code) else {
    return code
  }
  let html = """
    <!doctype html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name='viewport' content='width=device-width, shrink-to-fit=YES' initial-scale='1.0' maximum-scale='1.0' minimum-scale='1.0' user-scalable='no'>
        <style type="text/css">
          :root {
            color-scheme: light dark;
          }
          body {
            font-size: \(textSize)px;
            font-family: sans-serif;
          }
          li:last-child {
            margin-bottom: 1em;
          }
          a {
            color: #0084B4;
            text-decoration: none;
          }
          span.mask {
            background-color: #555;
            color: #555;
            border-radius: 2px;
            box-shadow: #555 0 0 5px;
            -webkit-transition: all .5s linear;
          }
          span.mask:hover {
            color: #FFF;
          }
          pre code {
            border: 1px solid #EEE;
            border-radius: 0.5em;
            padding: 1em;
            display: block;
            overflow: auto;
          }
          blockquote {
            display: inline-block;
            color: #666;
          }
          blockquote:before {
            content: open-quote;
            display: inline;
            line-height: 0;
            position: relative;
            left: -0.5em;
            color: #CCC;
            font-size: 1em;
          }
          blockquote:after {
            content: close-quote;
            display: inline;
            line-height: 0;
            position: relative;
            left: 0.5em;
            color: #CCC;
            font-size: 1em;
          }
        </style>
      </head>
      <body>
        \(body)
      </body>
      </html>
    """
  return html
}

func handleNewlineAndParagraph(node: Node, tagManager: TagManager) {
  // The end tag may be omitted if the <p> element is immediately followed by an <address>, <article>, <aside>, <blockquote>, <div>, <dl>, <fieldset>, <footer>, <form>, <h1>, <h2>, <h3>, <h4>, <h5>, <h6>, <header>, <hr>, <menu>, <nav>, <ol>, <pre>, <section>, <table>, <ul> or another <p> element, or if there is no more content in the parent element and the parent element is not an <a> element.

  // Trim head "br"s
  while node.children.first?.type == .br {
    node.children.removeFirst()
  }
  // Trim tail "br"s
  while node.children.last?.type == .br {
    node.children.removeLast()
  }

  let currentIsBlock = node.description?.isBlock ?? false
  // if currentIsBlock && !(node.children.first?.description?.isBlock ?? false) && node.type != .code {
  //   node.children.insert(
  //     Node(type: .paragraphStart, parent: node, tagManager: tagManager), at: 0)
  // }

  var brCount = 0
  var previous: Node? = nil
  var previousOfPrevious: Node? = nil
  var previousIsBlock: Bool = false
  for n in node.children {
    let isBlock = n.description?.isBlock ?? false
    if n.type == .br {
      if previousIsBlock {
        n.setTag(tag: tagManager.getInfo(type: .plain)!)
        previousIsBlock = false
      } else {
        previousOfPrevious = previous
        previous = n
        brCount = brCount + 1
      }
    } else {
      if brCount >= 2 && currentIsBlock {  // only block element can contain paragraphs
        previousOfPrevious!.setTag(tag: tagManager.getInfo(type: .paragraphEnd)!)
        previous!.setTag(tag: tagManager.getInfo(type: .paragraphStart)!)
      }
      brCount = 0
      previous = nil
      previousOfPrevious = nil

      handleNewlineAndParagraph(node: n, tagManager: tagManager)
    }

    previousIsBlock = isBlock
  }
}

func safeUrl(url: String, defaultScheme: String?, defaultHost: String?) -> String? {
  if var components = URLComponents(string: url) {
    if components.scheme == nil {
      if defaultScheme != nil {
        components.scheme = defaultScheme!
      } else {
        return nil
      }
    }
    if components.host == nil {
      if defaultHost != nil {
        components.host = defaultHost!
      } else {
        return nil
      }
    }
    return components.url?.absoluteString
  }
  return nil
}

extension String {
  /// Returns the String with all special HTML characters encoded.
  var stringByEncodingHTML: String {
    var ret = ""
    var g = self.unicodeScalars.makeIterator()
    while let c = g.next() {
      if c < UnicodeScalar(0x0009) {
        if let scale = UnicodeScalar(0x0030 + UInt32(c)) {
          ret.append("&#x")
          ret.append(String(Character(scale)))
          ret.append(";")
        }
      } else if c == UnicodeScalar(0x0022) {
        ret.append("&quot;")
      } else if c == UnicodeScalar(0x0026) {
        ret.append("&amp;")
      } else if c == UnicodeScalar(0x0027) {
        ret.append("&#39;")
      } else if c == UnicodeScalar(0x003C) {
        ret.append("&lt;")
      } else if c == UnicodeScalar(0x003E) {
        ret.append("&gt;")
      } else if c >= UnicodeScalar(0x3000 as UInt16)! && c <= UnicodeScalar(0x303F as UInt16)! {
        // CJK 标点符号 (3000-303F)
        ret.append(Character(c))
      } else if c >= UnicodeScalar(0x3400 as UInt16)! && c <= UnicodeScalar(0x4DBF as UInt16)! {
        // CJK Unified Ideographs Extension A (3400–4DBF) Rare
        ret.append(Character(c))
      } else if c >= UnicodeScalar(0x4E00 as UInt16)! && c <= UnicodeScalar(0x9FFF as UInt16)! {
        // CJK Unified Ideographs (4E00-9FFF) Common
        ret.append(Character(c))
      } else if c >= UnicodeScalar(0xFF00 as UInt16)! && c <= UnicodeScalar(0xFFEF as UInt16)! {
        // 全角ASCII、全角中英文标点、半宽片假名、半宽平假名、半宽韩文字母 (FF00-FFEF)
        ret.append(Character(c))
      } else if c >= UnicodeScalar(0x20000 as UInt32)! && c <= UnicodeScalar(0x2A6DF as UInt32)! {
        // CJK Unified Ideographs Extension B (20000-2A6DF) Rare, historic
        ret.append(Character(c))
      } else if c >= UnicodeScalar(0x2A700 as UInt32)! && c <= UnicodeScalar(0x2B73F as UInt32)! {
        // CJK Unified Ideographs Extension C (2A700–2B73F) Rare, historic
        ret.append(Character(c))
      } else if c >= UnicodeScalar(0x2B740 as UInt32)! && c <= UnicodeScalar(0x2B81F as UInt32)! {
        // CJK Unified Ideographs Extension D (2B740–2B81F) Uncommon, some in current use
        ret.append(Character(c))
      } else if c >= UnicodeScalar(0x2B820 as UInt32)! && c <= UnicodeScalar(0x2CEAF as UInt32)! {
        // CJK Unified Ideographs Extension E (2B820–2CEAF) Rare, historic
        ret.append(Character(c))
      } else if c > UnicodeScalar(0x7E) {
        ret.append("&#\(UInt32(c));")
      } else {
        ret.append(String(Character(c)))
      }
    }
    return ret
  }
}
