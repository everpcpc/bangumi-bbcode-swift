import Foundation
import SwiftUI

typealias HTMLRender = (Node, [String: Any]?) -> String
typealias TextRender = (Node, [String: Any]?) -> TextView

enum TextView {
  case view(AnyView)
  case text(Text)
  case string(AttributedString)
}

class TagManager {
  let tags: [TagInfo]

  init(tags: [TagInfo]) {
    var tmptags = tags

    tmptags.sort(by: { a, b in
      if a.label.count > b.label.count {
        return true
      } else {
        return false
      }
    })
    self.tags = tmptags
  }

  func getType(str: String) -> BBType? {
    for tag in tags {
      if tag.label == str {
        return tag.type
      }
    }
    return nil
  }

  func getInfo(str: String) -> TagInfo? {
    for tag in tags {
      if tag.label == str {
        return tag
      }
    }
    return nil
  }

  func getInfo(type: BBType) -> TagInfo? {
    for tag in tags {
      if tag.type == type {
        return tag
      }
    }
    return nil
  }
}

struct TagInfo {
  let label: String
  let type: BBType
  let desc: TagDescription

  init(_ label: String, _ type: BBType, _ desc: TagDescription) {
    self.label = label
    self.type = type
    self.desc = desc
  }
}

class TagDescription {
  var tagNeeded: Bool
  var isSelfClosing: Bool
  var allowedChildren: [BBType]?  // Allowed sub-elements of this element
  var allowAttr: Bool
  var isBlock: Bool
  var html: HTMLRender?
  var text: TextRender?

  init(
    tagNeeded: Bool, isSelfClosing: Bool, allowedChildren: [BBType]?, allowAttr: Bool,
    isBlock: Bool, html: HTMLRender?, text: TextRender?
  ) {
    self.tagNeeded = tagNeeded
    self.isSelfClosing = isSelfClosing
    self.allowedChildren = allowedChildren
    self.allowAttr = allowAttr
    self.isBlock = isBlock
    self.html = html
    self.text = text
  }
}

enum BBType: Int {
  case unknown = 0
  case root
  case plain
  case br
  case paragraphStart, paragraphEnd
  case quote, code, url, image, center, left, right
  case bold, italic, underline, delete, color, size, mask
  case smilies
}
