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
  case center, left, right, align
  case quote, code, url, image, photo
  case bold, italic, underline, delete, color, size, mask
  case list, listitem
  case smilies
  case background, avatar

  static let unsupported: [BBType] = [.background, .avatar]
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
        .center, .left, .right, .align, .smilies, .photo,
        .list,
      ] + BBType.unsupported,
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
    "bg", .background,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil,
      allowAttr: true,
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
      ] + BBType.unsupported,
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
      ] + BBType.unsupported,
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
      ] + BBType.unsupported,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "align", .align,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .bold, .italic, .underline, .delete, .color,
        .mask, .size, .quote, .code, .url, .image,
      ] + BBType.unsupported,
      allowAttr: true,
      isBlock: true
    )
  ),
  TagInfo(
    "list", .list,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .list, .listitem, .br, .bold, .italic, .underline, .delete, .color, .url,
      ] + BBType.unsupported,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "*", .listitem,
    TagDescription(
      tagNeeded: true, isSelfClosing: true,
      allowedChildren: [
        .br, .bold, .italic, .underline, .delete, .color, .url,
      ] + BBType.unsupported,
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
      ] + BBType.unsupported,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "url", .url,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .image, .color, .size,
        .bold, .italic, .underline, .delete, .br,
      ] + BBType.unsupported,
      allowAttr: true, isBlock: false
    )
  ),
  TagInfo(
    "img", .image,
    TagDescription(
      tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
      isBlock: true
    )
  ),
  TagInfo(
    "photo", .photo,
    TagDescription(
      tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
      isBlock: true
    )
  ),
  TagInfo(
    "b", .bold,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .italic, .delete, .underline, .url, .color] + BBType.unsupported,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "i", .italic,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .bold, .delete, .underline, .url, .color] + BBType.unsupported,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "u", .underline,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .bold, .italic, .delete, .url, .color] + BBType.unsupported,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "s", .delete,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .bold, .italic, .underline, .url, .color] + BBType.unsupported,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "color", .color,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .bold, .delete, .italic, .underline,
        .size, .left, .right, .center, .align, .url,
      ] + BBType.unsupported,
      allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "size", .size,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .bold, .italic, .delete, .underline, .color,
        .url, .left, .right, .center, .align, .mask,
        .smilies, .br,
      ]
        + BBType.unsupported, allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "mask", .mask,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [.br, .bold, .delete, .underline, .italic, .size] + BBType.unsupported, allowAttr: false,
      isBlock: true
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
