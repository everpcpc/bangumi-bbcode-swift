import SwiftUI

@MainActor
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
        html: { (n: Node, args: [String: Any]?) in
          return n.escapedValue
        },
        text: { (n: Node, args: [String: Any]?) in
          return .string(AttributedString(n.value))
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
        html: { (n: Node, args: [String: Any]?) in
          return "<br>"
        },
        text: { (n: Node, args: [String: Any]?) in
          return .string(AttributedString("\n"))
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
        html: { (n: Node, args: [String: Any]?) in
          return "<p>"
        },
        text: { (n: Node, args: [String: Any]?) in
          return .string(AttributedString(""))
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
        html: { (n: Node, args: [String: Any]?) in
          return "</p>"
        },
        text: { (n: Node, args: [String: Any]?) in
          return .string(AttributedString(""))
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
        html: { (n: Node, args: [String: Any]?) in
          var html: String
          html = "<p style=\"text-align: center;\">"
          html.append(n.renderInnerHTML(args))
          html.append("</p>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          var inner: AnyView = AnyView(Text(""))
          switch n.renderInnerText(args) {
          case .string(let content):
            inner = AnyView(Text(content))
          case .text(let content):
            inner = AnyView(content)
          case .view(let content):
            inner = content
          }
          return .view(
            AnyView(
              HStack(spacing: 0) {
                Spacer()
                inner
                Spacer()
              }
            )
          )
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
        html: { (n: Node, args: [String: Any]?) in
          var html: String
          html = "<p style=\"text-align: left;\">"
          html.append(n.renderInnerHTML(args))
          html.append("</p>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          var inner: AnyView = AnyView(Text(""))
          switch n.renderInnerText(args) {
          case .string(let content):
            inner = AnyView(Text(content))
          case .text(let content):
            inner = AnyView(content)
          case .view(let content):
            inner = content
          }
          return .view(
            AnyView(
              HStack(spacing: 0) {
                inner
                Spacer()
              }
            )
          )
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
        html: { (n: Node, args: [String: Any]?) in
          var html: String
          html = "<p style=\"text-align: right;\">"
          html.append(n.renderInnerHTML(args))
          html.append("</p>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          var inner: AnyView = AnyView(Text(""))
          switch n.renderInnerText(args) {
          case .string(let content):
            inner = AnyView(Text(content))
          case .text(let content):
            inner = AnyView(content)
          case .view(let content):
            inner = content
          }
          return .view(
            AnyView(
              HStack(spacing: 0) {
                Spacer()
                inner
              }
            )
          )
        }
      )
    ),
    TagInfo(
      "code", .code,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: nil, allowAttr: false,
        isBlock: true,
        html: { (n: Node, args: [String: Any]?) in
          var html = "<div class=\"code\"><pre><code>"
          html.append(n.renderInnerHTML(args))
          html.append("</code></pre></div>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          var inner: AnyView = AnyView(Text(""))
          switch n.renderInnerText(args) {
          case .string(let content):
            inner = AnyView(Text(content))
          case .text(let content):
            inner = AnyView(content)
          case .view(let content):
            inner = content
          }
          return .view(
            AnyView(
              inner
                .font(.system(.footnote, design: .monospaced))
                .padding(12)
                .overlay {
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                }.padding(.vertical, 8)
            )
          )
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
        html: { (n: Node, args: [String: Any]?) in
          var html: String
          html = "<div class=\"quote\"><blockquote>"
          html.append(n.renderInnerHTML(args))
          html.append("</blockquote></div>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          var inner: AnyView = AnyView(Text(""))
          switch n.renderInnerText(args) {
          case .string(let content):
            inner = AnyView(Text(content))
          case .text(let content):
            inner = AnyView(content)
          case .view(let content):
            inner = content
          }
          return .view(
            AnyView(
              inner
                .foregroundStyle(.secondary)
                .padding(.leading, 12)
                .padding(.vertical, 8)
                .overlay(
                  HStack {
                    Rectangle()
                      .frame(width: 4)
                      .foregroundStyle(Color(hex: 0xCCCCCC))
                      .offset(x: 0, y: 0)
                    Spacer()
                  }
                )
                .padding(.vertical, 8)
            )
          )
        }
      )
    ),
    TagInfo(
      "url", .url,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.image],
        allowAttr: true, isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
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
              link = n.renderInnerHTML(args)
              if let safeLink = safeUrl(url: link, defaultScheme: scheme, defaultHost: host) {
                html =
                  "<a href=\"\(link)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(safeLink)</a>"
              } else {
                html = link
              }
            } else {
              html = n.renderInnerHTML(args)
            }
          } else {
            link = n.escapedAttr
            if let safeLink = safeUrl(url: link, defaultScheme: scheme, defaultHost: host) {
              html =
                "<a href=\"\(safeLink)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(n.renderInnerHTML(args))</a>"
            } else {
              html = n.renderInnerHTML(args)
            }
          }
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          let inner = n.renderInnerText(args)
          var url = n.attr
          if url.isEmpty {
            switch n.renderInnerText(args) {
            case .string(let content):
              url = String(content.characters)
            default:
              // UNREACHABLE: url tag should not have non-string inner content
              return .string(AttributedString(n.value))
            }
          }
          guard let link = URL(string: url) else {
            switch inner {
            case .string(let content):
              return .string(content)
            case .text(let content):
              return .text(content)
            case .view(let content):
              return .view(content)
            }
          }
          switch inner {
          case .string(var content):
            content.link = link
            return .string(content)
          case .text(var content):
            return .view(
              AnyView(
                Link(destination: link) {
                  content
                }
              )
            )
          case .view(let content):
            return .view(
              AnyView(
                Link(destination: link) {
                  content
                }
              )
            )
          }
        }
      )
    ),
    TagInfo(
      "img", .image,
      TagDescription(
        tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
        isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
          let scheme = args?["current_scheme"] as? String ?? "http"
          let host = args?["host"] as? String
          var html: String
          let link: String = n.renderInnerHTML(args)
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
        },
        text: { (n: Node, args: [String: Any]?) in
          var url = n.attr
          if url.isEmpty {
            switch n.renderInnerText(args) {
            case .string(let content):
              url = String(content.characters)
            default:
              // UNREACHABLE: image tag should not have non-string inner content
              return .string(AttributedString(n.value))
            }
          }
          guard let link = URL(string: url) else {
            return .string(AttributedString(n.value))
          }
          return .view(
            AnyView(
              AsyncImage(url: link) { image in
                image
              } placeholder: {
                Image(systemName: "photo")
              }
            )
          )
        }
      )
    ),
    TagInfo(
      "b", .bold,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .italic, .delete, .underline, .url], allowAttr: false,
        isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
          var html: String = "<strong>"
          html.append(n.renderInnerHTML(args))
          html.append("</strong>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          let inner = n.renderInnerText(args)
          switch inner {
          case .string(var content):
            if let font = content.font {
              content.font = font.bold()
            } else {
              content.font = .body.bold()
            }
            return .string(content)
          case .text(var content):
            return .text(content.bold())
          case .view(let content):
            return .view(
              AnyView(
                content.bold()
              )
            )
          }
        }
      )
    ),
    TagInfo(
      "i", .italic,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .delete, .underline, .url], allowAttr: false,
        isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
          var html: String = "<em>"
          html.append(n.renderInnerHTML(args))
          html.append("</em>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          let inner = n.renderInnerText(args)
          switch inner {
          case .string(var content):
            if let font = content.font {
              content.font = font.italic()
            } else {
              content.font = .body.italic()
            }
            return .string(content)
          case .text(var content):
            return .text(content.italic())
          case .view(let content):
            return .view(
              AnyView(
                content.italic()
              )
            )
          }
        }
      )
    ),
    TagInfo(
      "u", .underline,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .italic, .delete, .url], allowAttr: false, isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
          var html: String = "<u>"
          html.append(n.renderInnerHTML(args))
          html.append("</u>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          let inner = n.renderInnerText(args)
          switch inner {
          case .string(var content):
            content.underlineStyle = .single
            return .string(content)
          case .text(var content):
            return .text(content.underline())
          case .view(let content):
            return .view(
              AnyView(
                content.underline()
              )
            )
          }
        }
      )
    ),
    TagInfo(
      "s", .delete,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .italic, .underline, .url], allowAttr: false,
        isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
          var html: String = "<del>"
          html.append(n.renderInnerHTML(args))
          html.append("</del>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          let inner = n.renderInnerText(args)
          switch inner {
          case .string(var content):
            content.strikethroughStyle = .single
            return .string(content)
          case .text(var content):
            return .text(content.strikethrough())
          case .view(let content):
            return .view(
              AnyView(
                content.strikethrough()
              )
            )
          }
        }
      )
    ),
    TagInfo(
      "color", .color,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .italic, .underline], allowAttr: true, isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
          var html: String
          if n.attr.isEmpty {
            html = "<span style=\"color: black\">\(n.renderInnerHTML(args))</span>"
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
              html = "<span style=\"color: \(n.attr)\">\(n.renderInnerHTML(args))</span>"
            } else {
              html = "[color=\(n.escapedAttr)]\(n.renderInnerHTML(args))[/color]"
            }
          }
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          if n.attr.isEmpty {
            return n.renderInnerText(args)
          }
          guard let color = Color(n.attr) else {
            return n.renderInnerText(args)
          }
          switch n.renderInnerText(args) {
          case .string(var content):
            content.foregroundColor = color
            return .string(content)
          case .text(var content):
            return .text(content.foregroundColor(color))
          case .view(let content):
            return .view(
              AnyView(
                content.foregroundColor(color)
              )
            )
          }
        }
      )
    ),
    TagInfo(
      "size", .size,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.bold, .italic, .underline], allowAttr: true, isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
          var html: String
          if n.attr.isEmpty {
            html = "<span style=\"color: black\">\(n.renderInnerHTML(args))</span>"
          } else {
            var valid = false
            let size = Int(n.attr)
            if size != nil {
              valid = true
            }
            if valid {
              html = "<span style=\"font-size: \(n.attr)px\">\(n.renderInnerHTML(args))</span>"
            } else {
              html = "[size=\(n.escapedAttr)]\(n.renderInnerHTML(args))[/size]"
            }
          }
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          if n.attr.isEmpty {
            return n.renderInnerText(args)
          }
          guard let size = Int(n.attr) else {
            return n.renderInnerText(args)
          }
          switch n.renderInnerText(args) {
          case .string(var content):
            if let innerFont: AttributeScopes.SwiftUIAttributes.FontAttribute.Value = content.font {
              // FIXME: preserve inner font style
              content.font = .system(size: CGFloat(size))
            } else {
              content.font = .system(size: CGFloat(size))
            }
            return .string(content)
          case .text(let content):
            return .text(content.font(.system(size: CGFloat(size))))
          case .view(let content):
            return .view(
              AnyView(
                content.font(.system(size: CGFloat(size)))
              )
            )
          }
        }
      )
    ),
    TagInfo(
      "mask", .mask,
      TagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: [.br, .bold, .delete, .underline], allowAttr: false,
        isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
          var html: String =
            "<span class=\"mask\">"
          html.append(n.renderInnerHTML(args))
          html.append("</span>")
          return html
        },
        text: { (n: Node, args: [String: Any]?) in
          var inner: Text = Text("")
          switch n.renderInnerText(args) {
          case .string(let content):
            inner = Text(content)
          case .text(let content):
            inner = content
          case .view(let content):
            // UNREACHABLE: view should not be masked
            inner = Text("")
          }
          return
            .view(
              AnyView(
                inner
                  .padding(2)
                  .background(Color(hex: 0x555555))
                  .foregroundColor(Color(hex: 0x555555))
                  .cornerRadius(2)
                  .shadow(color: Color(hex: 0x555555), radius: 5)
                  .contextMenu {
                    Button(action: {}) {
                      Text("OK")
                    }
                  } preview: {
                    ScrollView {
                      VStack(alignment: .leading) {
                        inner
                      }
                      .padding()
                      .frame(idealWidth: 360)
                    }
                  }
              )
            )
        }
      )
    ),
    TagInfo(
      "bgm", .smilies,
      TagDescription(
        tagNeeded: true, isSelfClosing: true,
        allowedChildren: nil, allowAttr: true,
        isBlock: false,
        html: { (n: Node, args: [String: Any]?) in
          let bgmId = Int(n.attr) ?? 24
          let iconId = String(format: "%02d", bgmId - 23)
          return
            "<img src=\"https://lain.bgm.tv/img/smiles/tv/\(iconId).gif\" alt=\"(bgm\(bgmId))\" />"
        },
        text: { (n: Node, args: [String: Any]?) in
          let img = Image(packageResource: "bgm\(n.attr)", ofType: "gif")
          return .text(Text(img))
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
      html: { (n: Node, args: [String: Any]?) in
        return n.renderInnerHTML(args)
      },
      text: { (n: Node, args: [String: Any]?) in
        let inner = n.renderInnerText(args)
        switch inner {
        case .string(let content):
          return .string(content)
        case .text(let content):
          return .text(content)
        case .view(let content):
          return .view(content)
        }
      }
    )
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
