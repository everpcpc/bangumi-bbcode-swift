import Foundation

public enum BBCodeError: Error {
  case internalError(String)
  case unfinishedOpeningTag(String)
  case unfinishedClosingTag(String)
  case unfinishedAttr(String)
  case unpairedTag(String)
  case unclosedTag(String)

  public var description: String {
    switch self {
    case .internalError(let msg):
      return msg
    case .unfinishedOpeningTag(let msg):
      return msg
    case .unfinishedClosingTag(let msg):
      return msg
    case .unfinishedAttr(let msg):
      return msg
    case .unpairedTag(let msg):
      return msg
    case .unclosedTag(let msg):
      return msg
    }
  }
}

typealias USIterator = String.UnicodeScalarView.Iterator
typealias Render = (DOMNode, [String: Any]?) -> String
typealias TagInfo = (String, BBType, TagDescription)

struct Parser {
  let parse: (inout USIterator, Worker) -> (Parser)?
}

class Worker {
  let tagManager: TagManager
  var currentNode: DOMNode
  var error: BBCodeError?
  private let rootNode: DOMNode

  init(tagManager: TagManager) {
    self.tagManager = tagManager
    self.rootNode = newDOMNode(type: .root, parent: nil, tagManager: tagManager)

    self.currentNode = self.rootNode
    self.error = nil
  }

  func parse(_ bbcode: String) -> DOMNode? {
    var g: USIterator = bbcode.unicodeScalars.makeIterator()
    var currentParser: Parser? = content_parser

    repeat {
      currentParser = currentParser?.parse(&g, self)
    } while currentParser != nil

    if error == nil {
      if currentNode.type == .root {
        return currentNode
      }
    }

    return nil
  }
}

class DOMNode {
  var children: [DOMNode] = []
  weak var parent: DOMNode? = nil
  private var tagType: BBType
  private var tagDescription: TagDescription? = nil
  var type: BBType {
    return tagType
  }
  var description: TagDescription? {
    return tagDescription
  }
  var value: String = ""
  var attr: String = ""
  var paired: Bool = true

  var escapedValue: String {
    // Only plain node value is directly usable in render, other tags needs to render subnode.
    return value.stringByEncodingHTML
  }

  var escapedAttr: String {
    return attr.stringByEncodingHTML
  }

  init(tag: TagInfo, parent: DOMNode?) {
    self.tagType = tag.1
    self.tagDescription = tag.2
    self.parent = parent
  }

  func setTag(tag: TagInfo) {
    self.tagType = tag.1
    self.tagDescription = tag.2
  }

  func renderChildren(_ args: [String: Any]?) -> String {
    var html = ""
    for n in children {
      if let render = n.description?.render {
        html.append(render(n, args))
      }
    }
    return html
  }
}

class TagDescription {
  var tagNeeded: Bool
  var isSelfClosing: Bool
  var allowedChildren: [BBType]?  // Allowed sub-elements of this element
  var allowAttr: Bool
  var isBlock: Bool
  var render: Render?

  init(
    tagNeeded: Bool, isSelfClosing: Bool, allowedChildren: [BBType]?, allowAttr: Bool,
    isBlock: Bool, render: Render?
  ) {
    self.tagNeeded = tagNeeded
    self.isSelfClosing = isSelfClosing
    self.allowedChildren = allowedChildren
    self.allowAttr = allowAttr
    self.isBlock = isBlock
    self.render = render
  }
}

enum BBType: Int {
  case unknow = 0
  case root
  case plain
  case br
  case paragraphStart, paragraphEnd
  case quote, code, url, image, center, left, right
  case bold, italic, underline, delete, color, size, mask
  case smilies
}

class TagManager {
  let tags: [TagInfo]

  init(tags: [TagInfo]) {
    var tmptags = tags

    tmptags.sort(by: { a, b in
      if a.0.count > b.0.count {
        return true
      } else {
        return false
      }
    })
    self.tags = tmptags
  }

  func getType(str: String) -> BBType? {
    for tag in tags {
      if tag.0 == str {
        return tag.1
      }
    }
    return nil
  }

  func getInfo(str: String) -> TagInfo? {
    for tag in tags {
      if tag.0 == str {
        return tag
      }
    }
    return nil
  }

  func getInfo(type: BBType) -> TagInfo? {
    for tag in tags {
      if tag.1 == type {
        return tag
      }
    }
    return nil
  }
}

func newDOMNode(type: BBType, parent: DOMNode?, tagManager: TagManager) -> DOMNode {
  if let tag = tagManager.getInfo(type: type) {
    return DOMNode(tag: tag, parent: parent)
  } else {
    return DOMNode(
      tag: (
        "", .unknow,
        TagDescription(
          tagNeeded: false, isSelfClosing: false, allowedChildren: nil, allowAttr: false,
          isBlock: false, render: nil)
      ), parent: parent)
  }
}

func contentParser(g: inout USIterator, worker: Worker) -> Parser? {
  var newNode: DOMNode = newDOMNode(
    type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
  worker.currentNode.children.append(newNode)
  var lastWasCR = false
  while let c = g.next() {
    if c == UnicodeScalar(10) || c == UnicodeScalar(13) {
      if let allowedChildren = worker.currentNode.description?.allowedChildren,
        allowedChildren.contains(.br)
      {
        if c == UnicodeScalar(13) || (c == UnicodeScalar(10) && !lastWasCR) {
          if newNode.value.isEmpty {
            worker.currentNode.children.removeLast()
          }
          newNode = newDOMNode(type: .br, parent: worker.currentNode, tagManager: worker.tagManager)
          worker.currentNode.children.append(newNode)
          newNode = newDOMNode(
            type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
          worker.currentNode.children.append(newNode)
        }

        if c == UnicodeScalar(13) {  // \r
          lastWasCR = true
        } else {  // \n
          lastWasCR = false
        }
      } else {
        if worker.currentNode.type == .code {
          newNode.value.append(Character(c))
        } else {
          worker.error = BBCodeError.unclosedTag(
            unclosedTagDetail(unclosedNode: worker.currentNode))
          return nil
        }
      }
    } else {
      lastWasCR = false

      if c == "[" {  // <tag_start>
        if worker.currentNode.description?.allowedChildren != nil {
          if newNode.value.isEmpty {
            worker.currentNode.children.removeLast()
          }
          return tag_parser
        } else if !worker.currentNode.paired {
          return tag_parser
        } else {
          newNode.value.append(Character(c))
        }
      } else if c == "(" {  // <smilies>
        return smilies_parser
      } else {  // <content>
        newNode.value.append(Character(c))
      }
    }
  }

  return nil
}

func tagParser(g: inout USIterator, worker: Worker) -> Parser? {
  //<opening_tag> ::= <opening_tag_1> | <opening_tag_2>
  let newNode: DOMNode = newDOMNode(
    type: .unknow, parent: worker.currentNode, tagManager: worker.tagManager)
  worker.currentNode.children.append(newNode)

  var index: Int = 0
  let tagNameMaxLength: Int = 8
  var isFirst: Bool = true

  while let c = g.next() {
    if isFirst && c == "/" {
      if !worker.currentNode.paired {
        //<closing_tag> ::= <tag_start> '/' <tag_name> <tag_end>
        worker.currentNode.children.removeLast()
        return tag_close_parser
      } else {
        // illegal syntax, may be an unpaired closing tag, treat it as plain text
        restoreNodeToPlain(node: newNode, c: c, worker: worker)
        return content_parser
      }
    } else if c == "=" {
      //<opening_tag_2> ::= <tag_prefix> '=' <attr> <tag_end>
      if let tag = worker.tagManager.getInfo(str: newNode.value) {
        newNode.setTag(tag: tag)
        if let allowedChildren = worker.currentNode.description?.allowedChildren,
          allowedChildren.contains(newNode.type)
        {
          if (newNode.description?.allowAttr)! {
            newNode.paired = false  //isSelfClosing tag has no attr, so its must be not paired
            worker.currentNode = newNode
            return attr_parser
          }
        }
      }
      restoreNodeToPlain(node: newNode, c: c, worker: worker)
      return content_parser
    } else if c == "]" {
      //<tag> ::= <opening_tag_1> | <opening_tag> <content> <closing_tag>
      if let tag = worker.tagManager.getInfo(str: newNode.value) {
        newNode.setTag(tag: tag)
        if let allowedChildren = worker.currentNode.description?.allowedChildren,
          allowedChildren.contains(newNode.type)
        {
          if (newNode.description?.isSelfClosing)! {
            //<opening_tag_1> ::= <tag_prefix> <tag_end>
            return content_parser
          } else {
            //<opening_tag> <content> <closing_tag>
            newNode.paired = false
            worker.currentNode = newNode
            return content_parser
          }
        }
      }
      restoreNodeToPlain(node: newNode, c: c, worker: worker)
      return content_parser
    } else if c == "[" {
      // illegal syntax, treat it as plain text, and restart tag parsing from this new position
      newNode.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
      newNode.value.insert(Character(UnicodeScalar(91)), at: newNode.value.startIndex)
      return tag_parser
    } else {
      if index < tagNameMaxLength {
        newNode.value.append(Character(c))
      } else {
        // no such tag
        restoreNodeToPlain(node: newNode, c: c, worker: worker)
        return content_parser
      }
    }
    index = index + 1
    isFirst = false
  }

  worker.error = BBCodeError.unfinishedOpeningTag(
    unclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

func restoreNodeToPlain(node: DOMNode, c: UnicodeScalar, worker: Worker) {
  node.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
  node.value.insert(Character(UnicodeScalar(91)), at: node.value.startIndex)
  node.value.append(Character(c))
}

func attrParser(g: inout USIterator, worker: Worker) -> Parser? {
  while let c = g.next() {
    if c == "]" {
      return content_parser
    } else if c == UnicodeScalar(10) || c == UnicodeScalar(13) {
      worker.error = BBCodeError.unfinishedAttr(unclosedTagDetail(unclosedNode: worker.currentNode))
      return nil
    } else {
      worker.currentNode.attr.append(Character(c))
    }
  }

  //unfinished attr
  worker.error = BBCodeError.unfinishedAttr(unclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

func tagClosingParser(g: inout USIterator, worker: Worker) -> Parser? {
  // <tag_name> <tag_end>
  var tagName: String = ""
  while let c = g.next() {
    if c == "]" {
      if !tagName.isEmpty && tagName == worker.currentNode.value {
        worker.currentNode.paired = true
        guard let p = worker.currentNode.parent else {
          // should not happen
          worker.error = BBCodeError.internalError("bug")
          return nil
        }
        worker.currentNode = p
        return content_parser
      } else {
        if let allowedChildren = worker.currentNode.description?.allowedChildren {
          if let tag = worker.tagManager.getInfo(str: tagName) {
            if allowedChildren.contains(tag.1) {
              // not paired tag
              worker.error = BBCodeError.unpairedTag(
                unclosedTagDetail(unclosedNode: worker.currentNode))
              return nil
            }
          }
        }

        let newNode: DOMNode = newDOMNode(
          type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
        newNode.value = "[/" + tagName + "]"
        worker.currentNode.children.append(newNode)
        return content_parser
      }
    } else if c == "[" {
      // illegal syntax, treat it as plain text, and restart tag parsing from this new position
      let newNode: DOMNode = newDOMNode(
        type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
      newNode.value = "[/" + tagName
      worker.currentNode.children.append(newNode)
      return tag_parser
    } else if c == "=" {
      // illegal syntax, treat it as plain text
      let newNode: DOMNode = newDOMNode(
        type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
      newNode.value = "[/" + tagName + "="
      worker.currentNode.children.append(newNode)
      return content_parser
    } else {
      tagName.append(Character(c))
    }
  }

  worker.error = BBCodeError.unfinishedClosingTag(
    unclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

func smiliesParser(g: inout USIterator, worker: Worker) -> Parser? {
  let newNode: DOMNode = newDOMNode(
    type: .unknow, parent: worker.currentNode, tagManager: worker.tagManager)
  worker.currentNode.children.append(newNode)

  var index: Int = 0
  let smiliesNameMaxLength: Int = 8
  let smiliesRegex = try! Regex(#"bgm(?<id>\d+)"#, as: (Substring, id: Substring).self)
  while let c = g.next() {
    if c == ")" {
      if newNode.value.isEmpty {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
        return content_parser
      }
      if let match = newNode.value.wholeMatch(of: smiliesRegex) {
        let bgmId = Int(match.id) ?? 0
        if bgmId < 24 || bgmId > 125 {
          restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
          return content_parser
        }
        let newNode: DOMNode = newDOMNode(
          type: .smilies,
          parent: worker.currentNode, tagManager: worker.tagManager)
        worker.currentNode.children.append(newNode)
        newNode.value = "bgm"
        newNode.attr = String(bgmId)
        newNode.setTag(tag: worker.tagManager.getInfo(type: .smilies)!)
        return content_parser
      } else {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
        return content_parser
      }
    } else {
      if index < smiliesNameMaxLength {
        newNode.value.append(Character(c))
      } else {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
        return content_parser
      }
    }
    index = index + 1
  }

  worker.error = BBCodeError.unfinishedClosingTag(
    unclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

func restoreSmiliesToPlain(node: DOMNode, c: UnicodeScalar, worker: Worker) {
  node.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
  node.value.insert(Character(UnicodeScalar(40)), at: node.value.startIndex)
  node.value.append(Character(c))
}

func handleNewlineAndParagraph(node: DOMNode, tagManager: TagManager) {
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
  //     newDOMNode(type: .paragraphStart, parent: node, tagManager: tagManager), at: 0)
  // }

  var brCount = 0
  var previous: DOMNode? = nil
  var previousOfPrevious: DOMNode? = nil
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

// For unclosed tag error handling
func unclosedTagDetail(unclosedNode: DOMNode) -> String {
  if unclosedNode.type == .root {
    // should not be here
    return ""
  }
  var text: String =
    "[" + unclosedNode.value + (unclosedNode.attr.isEmpty ? "]" : "=" + unclosedNode.attr + "]")
  for child in unclosedNode.children {
    text = text + nodeContext(node: child)
  }
  return text
}

// Called by unclosedTagDetail
func nodeContext(node: DOMNode) -> String {
  if node.type == .root {
    // should not be here
    return ""
  } else if node.type == .plain {
    return node.value
  } else {
    if let desc = node.description, desc.isSelfClosing {
      return "[" + node.value + "]"
    } else {
      var text: String = "[" + node.value + (node.attr.isEmpty ? "]" : "=" + node.attr + "]")
      for child in node.children {
        text = text + nodeContext(node: child)
      }
      text = text + "[/" + node.value + "]"

      return text
    }
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

let content_parser: Parser = Parser(parse: contentParser)
let tag_parser: Parser = Parser(parse: tagParser)
let tag_close_parser: Parser = Parser(parse: tagClosingParser)
let attr_parser: Parser = Parser(parse: attrParser)
let smilies_parser: Parser = Parser(parse: smiliesParser)

public class BBCode {

  let tagManager: TagManager

  public init() {
    var tags: [TagInfo] = [
      (
        "", .plain,
        TagDescription(
          tagNeeded: false, isSelfClosing: true,
          allowedChildren: nil,
          allowAttr: false,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            return n.escapedValue
          }
        )
      ),
      (
        "", .br,
        TagDescription(
          tagNeeded: false, isSelfClosing: true,
          allowedChildren: nil,
          allowAttr: false,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            return "<br>"
          }
        )
      ),
      (
        "", .paragraphStart,
        TagDescription(
          tagNeeded: false, isSelfClosing: true,
          allowedChildren: nil,
          allowAttr: false,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            return "<p>"
          }
        )
      ),
      (
        "", .paragraphEnd,
        TagDescription(
          tagNeeded: false, isSelfClosing: true,
          allowedChildren: nil,
          allowAttr: false,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            return "</p>"
          }
        )
      ),
      (
        "center", .center,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [
            .br, .bold, .italic, .underline, .delete, .color,
            .mask, .size, .quote, .code, .url, .image,
          ],
          allowAttr: false,
          isBlock: true,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String
            html = "<p style=\"text-align: center;\">"
            html.append(n.renderChildren(args))
            html.append("</p>")
            return html
          }
        )
      ),
      (
        "left", .left,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [
            .br, .bold, .italic, .underline, .delete, .color,
            .mask, .size, .quote, .code, .url, .image,
          ],
          allowAttr: false,
          isBlock: true,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String
            html = "<p style=\"text-align: left;\">"
            html.append(n.renderChildren(args))
            html.append("</p>")
            return html
          }
        )
      ),
      (
        "right", .right,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [
            .br, .bold, .italic, .underline, .delete, .color,
            .mask, .size, .quote, .code, .url, .image,
          ],
          allowAttr: false,
          isBlock: true,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String
            html = "<p style=\"text-align: right;\">"
            html.append(n.renderChildren(args))
            html.append("</p>")
            return html
          }
        )
      ),
      (
        "code", .code,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: nil, allowAttr: false,
          isBlock: true,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html = "<div class=\"code\"><pre><code>"
            html.append(n.renderChildren(args))
            html.append("</code></pre></div>")
            return html
          }
        )
      ),
      (
        "quote", .quote,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [
            .br, .bold, .italic, .underline, .delete,
            .color, .mask, .size, .quote, .code, .url,
            .image, .smilies,
          ],
          allowAttr: false,
          isBlock: true,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String
            html = "<div class=\"quote\"><blockquote>"
            html.append(n.renderChildren(args))
            html.append("</blockquote></div>")
            return html
          }
        )
      ),
      (
        "url", .url,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [.image],
          allowAttr: true, isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            let scheme = args?["current_scheme"] as? String ?? "http"
            let host = args?["host"] as? String
            var html: String
            var link: String
            if n.attr.isEmpty {
              var isPlain = true
              for child in n.children {
                if child.type != BBType.plain {
                  isPlain = false
                }
              }
              if isPlain {
                link = n.renderChildren(args)
                if let safeLink = safeUrl(url: link, defaultScheme: scheme, defaultHost: host) {
                  html =
                    "<a href=\"\(link)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(safeLink)</a>"
                } else {
                  html = link
                }
              } else {
                html = n.renderChildren(args)
              }
            } else {
              link = n.escapedAttr
              if let safeLink = safeUrl(url: link, defaultScheme: scheme, defaultHost: host) {
                html =
                  "<a href=\"\(safeLink)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(n.renderChildren(args))</a>"
              } else {
                html = n.renderChildren(args)
              }
            }
            return html
          }
        )
      ),
      (
        "img", .image,
        TagDescription(
          tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            let scheme = args?["current_scheme"] as? String ?? "http"
            let host = args?["host"] as? String
            var html: String
            let link: String = n.renderChildren(args)
            if let safeLink = safeUrl(url: link, defaultScheme: scheme, defaultHost: host) {
              if n.attr.isEmpty {
                html =
                  "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
              } else {
                let values = n.attr.components(separatedBy: ",").compactMap { Int($0) }
                if values.count == 2 && values[0] > 0 && values[0] <= 4096 && values[1] > 0
                  && values[1] <= 4096
                {
                  html =
                    "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" width=\"\(values[0])\" height=\"\(values[1])\" />"
                } else {
                  html =
                    "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\(n.escapedAttr)\" />"
                }
              }
              return html
            } else {
              return link
            }
          }
        )
      ),
      (
        "b", .bold,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [.br, .italic, .delete, .underline, .url], allowAttr: false,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String = "<strong>"
            html.append(n.renderChildren(args))
            html.append("</strong>")
            return html
          }
        )
      ),
      (
        "i", .italic,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [.br, .bold, .delete, .underline, .url], allowAttr: false,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String = "<em>"
            html.append(n.renderChildren(args))
            html.append("</em>")
            return html
          }
        )
      ),
      (
        "u", .underline,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [.br, .bold, .italic, .delete, .url], allowAttr: false, isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String = "<u>"
            html.append(n.renderChildren(args))
            html.append("</u>")
            return html
          }
        )
      ),
      (
        "s", .delete,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [.br, .bold, .italic, .underline, .url], allowAttr: false,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String = "<del>"
            html.append(n.renderChildren(args))
            html.append("</del>")
            return html
          }
        )
      ),
      (
        "color", .color,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [.br, .bold, .italic, .underline], allowAttr: true, isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String
            if n.attr.isEmpty {
              html = "<span style=\"color: black\">\(n.renderChildren(args))</span>"
            } else {
              var valid = false
              if [
                "black", "green", "silver", "gray", "olive", "white", "yellow", "orange", "maroon",
                "navy", "red", "blue", "purple", "teal", "fuchsia", "aqua", "violet", "pink",
                "lime", "magenta", "brown",
              ].contains(n.attr) {
                valid = true
              } else {
                if n.attr.unicodeScalars.count == 4 || n.attr.unicodeScalars.count == 7 {
                  var g = n.attr.unicodeScalars.makeIterator()
                  if g.next() == "#" {
                    while let c = g.next() {
                      if (c >= UnicodeScalar("0") && c <= UnicodeScalar("9"))
                        || (c >= UnicodeScalar("a") && c <= UnicodeScalar("f"))
                        || (c >= UnicodeScalar("A") && c <= UnicodeScalar("F"))
                      {
                        valid = true
                      } else {
                        valid = false
                        break
                      }
                    }
                  }
                }
              }
              if valid {
                html = "<span style=\"color: \(n.attr)\">\(n.renderChildren(args))</span>"
              } else {
                html = "[color=\(n.escapedAttr)]\(n.renderChildren(args))[/color]"
              }
            }
            return html
          }
        )
      ),
      (
        "size", .size,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [.bold, .italic, .underline], allowAttr: true, isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String
            if n.attr.isEmpty {
              html = "<span style=\"color: black\">\(n.renderChildren(args))</span>"
            } else {
              var valid = false
              let size = Int(n.attr)
              if size != nil {
                valid = true
              }
              if valid {
                html = "<span style=\"font-size: \(n.attr)px\">\(n.renderChildren(args))</span>"
              } else {
                html = "[size=\(n.escapedAttr)]\(n.renderChildren(args))[/size]"
              }
            }
            return html
          }
        )
      ),
      (
        "mask", .mask,
        TagDescription(
          tagNeeded: true, isSelfClosing: false,
          allowedChildren: [.br, .bold, .delete, .underline], allowAttr: false,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            var html: String =
              "<span class=\"mask\">"
            html.append(n.renderChildren(args))
            html.append("</span>")
            return html
          }
        )
      ),
      (
        "bgm", .smilies,
        TagDescription(
          tagNeeded: true, isSelfClosing: true,
          allowedChildren: nil, allowAttr: true,
          isBlock: false,
          render: { (n: DOMNode, args: [String: Any]?) in
            let bgmId = Int(n.attr) ?? 24
            let iconId = String(format: "%02d", bgmId - 23)
            return
              "<img src=\"https://lain.bgm.tv/img/smiles/tv/\(iconId).gif\" alt=\"(bgm\(bgmId))\" />"
          }
        )
      ),
    ]

    // Create .root description
    let rootDescription = TagDescription(
      tagNeeded: false, isSelfClosing: false,
      allowedChildren: [],
      allowAttr: false, isBlock: true,
      render: { (n: DOMNode, args: [String: Any]?) in
        return n.renderChildren(args)
      })
    for tag in tags {
      rootDescription.allowedChildren?.append(tag.1)
    }
    tags.append(("", .root, rootDescription))

    self.tagManager = TagManager(tags: tags)
  }

  public func parse(bbcode: String, args: [String: Any]? = nil) throws -> String {
    let worker: Worker = Worker(tagManager: tagManager)

    if let domTree = worker.parse(bbcode) {
      handleNewlineAndParagraph(node: domTree, tagManager: tagManager)
      return (domTree.description!.render!(domTree, args))
    } else {
      throw worker.error!
    }
  }

  public func validate(bbcode: String) throws {
    let worker = Worker(tagManager: tagManager)

    guard worker.parse(bbcode) != nil else {
      throw worker.error!
    }
  }
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
