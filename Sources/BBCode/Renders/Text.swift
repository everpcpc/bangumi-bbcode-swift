import SwiftUI

extension BBCode {
  @MainActor
  func text(_ bbcode: String, args: [String: Any]? = nil) -> TextView {
    let worker: Worker = Worker(tagManager: tagManager)
    if let tree = worker.parse(bbcode) {
      handleNewlineAndParagraph(node: tree, tagManager: tagManager)
      if let render = textRenders[tree.type] {
        let content = render(tree, args)
        return content
      }
    }
    return .string(AttributedString(bbcode))
  }
}

extension Node {
  @MainActor
  func renderInnerText(_ args: [String: Any]?) -> TextView {
    var views: [AnyView] = []
    var texts: [Text] = []
    var strings: [AttributedString] = []
    for n in children {
      if let render = textRenders[n.type] {
        let content = render(n, args)
        switch content {
        case .string(let content):
          strings.append(content)
        case .text(let content):
          if !strings.isEmpty {
            texts.append(Text(strings.reduce(AttributedString(), +)))
            strings.removeAll()
          }
          texts.append(content)
        case .view(let content):
          if !strings.isEmpty {
            texts.append(Text(strings.reduce(AttributedString(), +)))
            strings.removeAll()
          }
          if !texts.isEmpty {
            views.append(AnyView(texts.reduce(Text(""), +)))
            texts.removeAll()
          }
          views.append(content)
        }
      }
    }
    if views.count > 0 {
      if !strings.isEmpty {
        texts.append(Text(strings.reduce(AttributedString(), +)))
        strings.removeAll()
      }
      if !texts.isEmpty {
        views.append(AnyView(texts.reduce(Text(""), +)))
        texts.removeAll()
      }
      return .view(
        AnyView(
          VStack(alignment: .leading) {
            ForEach(views.indices, id: \.self) { i in
              views[i]
            }
          }
        )
      )
    } else if texts.count > 0 {
      if !strings.isEmpty {
        texts.append(Text(strings.reduce(AttributedString(), +)))
        strings.removeAll()
      }
      return .text(texts.reduce(Text(""), +))
    } else if strings.count > 0 {
      return .string(strings.reduce(AttributedString(), +))
    } else {
      return .string(AttributedString())
    }
  }
}

@MainActor
var textRenders: [BBType: TextRender] {
  return [
    .plain: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString(n.value))
    },
    .br: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString("\n"))
    },
    .paragraphStart: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString(""))
    },
    .paragraphEnd: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString(""))
    },
    .root: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(let content):
        return .string(content)
      case .text(let content):
        return .text(content)
      case .view(let content):
        return .view(content)
      }
    },
    .center: { (n: Node, args: [String: Any]?) in
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
    },
    .left: { (n: Node, args: [String: Any]?) in
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
    },
    .right: { (n: Node, args: [String: Any]?) in
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
    },
    .code: { (n: Node, args: [String: Any]?) in
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
    },
    .quote: { (n: Node, args: [String: Any]?) in
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
    },
    .url: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      var url = n.attr
      if url.isEmpty {
        switch n.renderInnerText(args) {
        case .string(let content):
          url = String(content.characters)
        default:
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
      case .text(let content):
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
    },
    .image: { (n: Node, args: [String: Any]?) in
      var url = n.attr
      if url.isEmpty {
        switch n.renderInnerText(args) {
        case .string(let content):
          url = String(content.characters)
        default:
          return .string(AttributedString(n.value))
        }
      }
      guard let link = URL(string: url) else {
        return .string(AttributedString(n.value))
      }
      return .view(
        AnyView(
          AsyncImage(url: link) { image in
            let renderer = ImageRenderer(content: image)
            let width = renderer.cgImage?.width ?? 360
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: CGFloat(width))
          } placeholder: {
            Image(systemName: "photo")
          }
        )
      )
    },
    .photo: { (n: Node, args: [String: Any]?) in
      var url = "https://lain.bgm.tv/pic/photo/l/"
      switch n.renderInnerText(args) {
      case .string(let content):
        url += String(content.characters)
      default:
        return .string(AttributedString(n.value))
      }
      guard let link = URL(string: url) else {
        return .string(AttributedString(n.value))
      }
      return .view(
        AnyView(
          AsyncImage(url: link) { image in
            let renderer = ImageRenderer(content: image)
            let width = renderer.cgImage?.width ?? 360
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: CGFloat(width))
          } placeholder: {
            Image(systemName: "photo")
          }
        )
      )
    },
    .bold: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(var content):
        if let font = content.font {
          content.font = font.bold()
        } else {
          content.font = .body.bold()
        }
        return .string(content)
      case .text(let content):
        return .text(content.bold())
      case .view(let content):
        return .view(
          AnyView(
            content.bold()
          )
        )
      }
    },
    .italic: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(var content):
        if let font = content.font {
          content.font = font.italic()
        } else {
          content.font = .body.italic()
        }
        return .string(content)
      case .text(let content):
        return .text(content.italic())
      case .view(let content):
        return .view(
          AnyView(
            content.italic()
          )
        )
      }
    },
    .underline: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(var content):
        content.underlineStyle = .single
        return .string(content)
      case .text(let content):
        return .text(content.underline())
      case .view(let content):
        return .view(
          AnyView(
            content.underline()
          )
        )
      }
    },
    .delete: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(var content):
        content.strikethroughStyle = .single
        return .string(content)
      case .text(let content):
        return .text(content.strikethrough())
      case .view(let content):
        return .view(
          AnyView(
            content.strikethrough()
          )
        )
      }
    },
    .color: { (n: Node, args: [String: Any]?) in
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
      case .text(let content):
        return .text(content.foregroundColor(color))
      case .view(let content):
        return .view(
          AnyView(
            content.foregroundColor(color)
          )
        )
      }
    },
    .size: { (n: Node, args: [String: Any]?) in
      if n.attr.isEmpty {
        return n.renderInnerText(args)
      }
      guard let size = Int(n.attr) else {
        return n.renderInnerText(args)
      }
      switch n.renderInnerText(args) {
      case .string(var content):
        // FIXME: preserve inner font style
        content.font = .system(size: CGFloat(size))
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
    },
    .mask: { (n: Node, args: [String: Any]?) in
      var inner: Text = Text("")
      switch n.renderInnerText(args) {
      case .string(let content):
        inner = Text(content)
      case .text(let content):
        inner = content
      case .view(_):
        inner = Text("")
      }
      return .view(
        AnyView(
          MaskView {
            inner
          }
        )
      )
    },
    .smilies: { (n: Node, args: [String: Any]?) in
      let img = Image(packageResource: "bgm\(n.attr)", ofType: "gif")
      return .text(Text(img))
    },
  ]
}
