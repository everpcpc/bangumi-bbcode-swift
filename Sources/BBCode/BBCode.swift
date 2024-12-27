public class BBCode {

  let tagManager: TagManager

  var tags: [TagInfo] = [
    TagInfo(
      "", .plain,
      TagDescription(
        tagNeeded: false, isSelfClosing: true,
        allowedChildren: nil,
        allowAttr: false,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          return n.escapedValue
        }
      )
    ),
    TagInfo(
      "", .br,
      TagDescription(
        tagNeeded: false, isSelfClosing: true,
        allowedChildren: nil,
        allowAttr: false,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          return "<br>"
        }
      )
    ),
    TagInfo(
      "", .paragraphStart,
      TagDescription(
        tagNeeded: false, isSelfClosing: true,
        allowedChildren: nil,
        allowAttr: false,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          return "<p>"
        }
      )
    ),
    TagInfo(
      "", .paragraphEnd,
      TagDescription(
        tagNeeded: false, isSelfClosing: true,
        allowedChildren: nil,
        allowAttr: false,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          return "</p>"
        }
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
        isBlock: true,
        render: { (n: Node, args: [String: Any]?) in
          var html: String
          html = "<p style=\"text-align: center;\">"
          html.append(n.renderChildren(args))
          html.append("</p>")
          return html
        }
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
        isBlock: true,
        render: { (n: Node, args: [String: Any]?) in
          var html: String
          html = "<p style=\"text-align: left;\">"
          html.append(n.renderChildren(args))
          html.append("</p>")
          return html
        }
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
        isBlock: true,
        render: { (n: Node, args: [String: Any]?) in
          var html: String
          html = "<p style=\"text-align: right;\">"
          html.append(n.renderChildren(args))
          html.append("</p>")
          return html
        }
      )
    ),
    TagInfo(
      "code", .code,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: nil, allowAttr: false,
        isBlock: true,
        render: { (n: Node, args: [String: Any]?) in
          var html = "<div class=\"code\"><pre><code>"
          html.append(n.renderChildren(args))
          html.append("</code></pre></div>")
          return html
        }
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
        isBlock: true,
        render: { (n: Node, args: [String: Any]?) in
          var html: String
          html = "<div class=\"quote\"><blockquote>"
          html.append(n.renderChildren(args))
          html.append("</blockquote></div>")
          return html
        }
      )
    ),
    TagInfo(
      "url", .url,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.image],
        allowAttr: true, isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
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
    TagInfo(
      "img", .image,
      TagDescription(
        tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
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
    TagInfo(
      "b", .bold,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .italic, .delete, .underline, .url], allowAttr: false,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          var html: String = "<strong>"
          html.append(n.renderChildren(args))
          html.append("</strong>")
          return html
        }
      )
    ),
    TagInfo(
      "i", .italic,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .delete, .underline, .url], allowAttr: false,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          var html: String = "<em>"
          html.append(n.renderChildren(args))
          html.append("</em>")
          return html
        }
      )
    ),
    TagInfo(
      "u", .underline,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .italic, .delete, .url], allowAttr: false, isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          var html: String = "<u>"
          html.append(n.renderChildren(args))
          html.append("</u>")
          return html
        }
      )
    ),
    TagInfo(
      "s", .delete,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .italic, .underline, .url], allowAttr: false,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          var html: String = "<del>"
          html.append(n.renderChildren(args))
          html.append("</del>")
          return html
        }
      )
    ),
    TagInfo(
      "color", .color,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .italic, .underline], allowAttr: true, isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
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
    TagInfo(
      "size", .size,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.bold, .italic, .underline], allowAttr: true, isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
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
    TagInfo(
      "mask", .mask,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .delete, .underline], allowAttr: false,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          var html: String =
            "<span class=\"mask\">"
          html.append(n.renderChildren(args))
          html.append("</span>")
          return html
        }
      )
    ),
    TagInfo(
      "bgm", .smilies,
      TagDescription(
        tagNeeded: true, isSelfClosing: true,
        allowedChildren: nil, allowAttr: true,
        isBlock: false,
        render: { (n: Node, args: [String: Any]?) in
          let bgmId = Int(n.attr) ?? 24
          let iconId = String(format: "%02d", bgmId - 23)
          return
            "<img src=\"https://lain.bgm.tv/img/smiles/tv/\(iconId).gif\" alt=\"(bgm\(bgmId))\" />"
        }
      )
    ),
  ]

  public init() {
    // Create .root description
    let rootDescription = TagDescription(
      tagNeeded: false, isSelfClosing: false,
      allowedChildren: [],
      allowAttr: false, isBlock: true,
      render: { (n: Node, args: [String: Any]?) in
        return n.renderChildren(args)
      })
    for tag in tags {
      rootDescription.allowedChildren?.append(tag.type)
    }
    tags.append(TagInfo("", .root, rootDescription))
    self.tagManager = TagManager(tags: tags)
  }

  public func validate(bbcode: String) throws {
    let worker = Worker(tagManager: tagManager)

    guard worker.parse(bbcode) != nil else {
      throw worker.error!
    }
  }
}
