import Foundation
import SwiftUI

typealias USIterator = String.UnicodeScalarView.Iterator

protocol Parser {
  func parse(_ g: inout USIterator, _ worker: Worker) -> Parser?
}

class Node {
  var children: [Node] = []
  weak var parent: Node? = nil
  private var tagType: BBType
  private var tagDescription: TagDescription? = nil

  var value: String = ""
  var attr: String = ""
  var paired: Bool = true

  var type: BBType {
    return tagType
  }

  var description: TagDescription? {
    return tagDescription
  }

  init(tag: TagInfo, parent: Node?) {
    self.tagType = tag.type
    self.tagDescription = tag.desc
    self.parent = parent
  }

  convenience init(type: BBType, parent: Node?, tagManager: TagManager) {
    if let tag = tagManager.getInfo(type: type) {
      self.init(tag: tag, parent: parent)
    } else {
      let desc = TagDescription(
        tagNeeded: false, isSelfClosing: false, allowedChildren: nil,
        allowAttr: false, isBlock: false)
      let tag = TagInfo("", .unknown, desc)
      self.init(tag: tag, parent: parent)
    }
  }

  func setTag(tag: TagInfo) {
    self.tagType = tag.type
    self.tagDescription = tag.desc
  }
}

class Worker {
  let tagManager: TagManager
  var currentNode: Node
  var error: BBCodeError?
  private let rootNode: Node

  init(tagManager: TagManager) {
    self.tagManager = tagManager
    self.rootNode = Node(type: .root, parent: nil, tagManager: tagManager)

    self.currentNode = self.rootNode
    self.error = nil
  }

  func parse(_ bbcode: String) -> Node? {
    var g: USIterator = bbcode.unicodeScalars.makeIterator()
    var parser: Parser? = ContentParser()

    repeat {
      parser = parser?.parse(&g, self)
    } while parser != nil

    if error == nil {
      if currentNode.type == .root {
        return currentNode
      }
    }

    return nil
  }
}

// For unclosed tag error handling
func unclosedTagDetail(unclosedNode: Node) -> String {
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
func nodeContext(node: Node) -> String {
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
