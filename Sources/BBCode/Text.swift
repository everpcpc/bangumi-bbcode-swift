import SwiftUI

extension BBCode {
  func text(_ bbcode: String, args: [String: Any]? = nil) -> TextView {
    let worker: Worker = Worker(tagManager: tagManager)
    if let tree = worker.parse(bbcode) {
      handleNewlineAndParagraph(node: tree, tagManager: tagManager)
      if let text = tree.description?.text {
        let content = text(tree, args)
        return content
      }
    }
    return .string(AttributedString(bbcode))
  }
}

extension Node {
  func renderInnerText(_ args: [String: Any]?) -> TextView {
    var views: [AnyView] = []
    var texts: [Text] = []
    var strings: [AttributedString] = []
    for n in children {
      if let text = n.description?.text {
        let content = text(n, args)
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
