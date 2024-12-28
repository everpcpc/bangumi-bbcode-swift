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

struct TagDescription {
  let tagNeeded: Bool
  let isSelfClosing: Bool
  let allowedChildren: [BBType]?  // Allowed sub-elements of this element
  let allowAttr: Bool
  let isBlock: Bool

  init(
    tagNeeded: Bool, isSelfClosing: Bool, allowedChildren: [BBType]?, allowAttr: Bool, isBlock: Bool
  ) {
    self.tagNeeded = tagNeeded
    self.isSelfClosing = isSelfClosing
    self.allowedChildren = allowedChildren
    self.allowAttr = allowAttr
    self.isBlock = isBlock
  }
}

enum BBType: Int {
  case unknown = 0
  case root
  case plain
  case br
  case paragraphStart, paragraphEnd
  case quote, code, url, image, photo, center, left, right
  case bold, italic, underline, delete, color, size, mask
  case smilies
}

let tags: [TagInfo] = [
  TagInfo(
    "", .root,
    TagDescription(
      tagNeeded: false, isSelfClosing: false,
      allowedChildren: [
        .plain, .br, .paragraphStart, .paragraphEnd,
        .bold, .italic, .underline, .delete, .color,
        .mask, .size, .quote, .code, .url, .image,
        .center, .left, .right, .smilies, .photo,
      ],
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "", .plain,
    TagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "", .br,
    TagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "", .paragraphStart,
    TagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "", .paragraphEnd,
    TagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "center", .center,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .bold, .italic, .underline, .delete, .color,
        .mask, .size, .quote, .code, .url, .image,
      ],
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "left", .left,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .bold, .italic, .underline, .delete, .color,
        .mask, .size, .quote, .code, .url, .image,
      ],
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "right", .right,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .bold, .italic, .underline, .delete, .color,
        .mask, .size, .quote, .code, .url, .image,
      ],
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "code", .code,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil, allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "quote", .quote,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .bold, .italic, .underline, .delete,
        .color, .mask, .size, .quote, .code, .url,
        .image, .smilies,
      ],
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "url", .url,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.image],
      allowAttr: true, isBlock: false
    )
  ),
  TagInfo(
    "img", .image,
    TagDescription(
      tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "photo", .photo,
    TagDescription(
      tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "b", .bold,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .italic, .delete, .underline, .url], allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "i", .italic,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .bold, .delete, .underline, .url], allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "u", .underline,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .bold, .italic, .delete, .url], allowAttr: false, isBlock: false
    )
  ),
  TagInfo(
    "s", .delete,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .bold, .italic, .underline, .url], allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "color", .color,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .bold, .italic, .underline], allowAttr: true, isBlock: false
    )
  ),
  TagInfo(
    "size", .size,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.bold, .italic, .underline], allowAttr: true, isBlock: false
    )
  ),
  TagInfo(
    "mask", .mask,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .bold, .delete, .underline], allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "bgm", .smilies,
    TagDescription(
      tagNeeded: true, isSelfClosing: true,
      allowedChildren: nil, allowAttr: true,
      isBlock: false
    )
  ),
]
