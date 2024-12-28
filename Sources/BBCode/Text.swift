import SwiftUI

extension BBCode {
  public func text(_ bbcode: String, args: [String: Any]? = nil) -> AnyView {
    let worker: Worker = Worker(tagManager: tagManager)
    if let tree = worker.parse(bbcode) {
      handleNewlineAndParagraph(node: tree, tagManager: tagManager)
      if let text = tree.description?.text {
        let content = text(tree, args)
        switch content {
        case .string(let content):
          return AnyView(Text(content))
        case .text(let content):
          return AnyView(content)
        case .view(let content):
          return content
        }
      }
    }
    return AnyView(Text("BBCode Error!"))
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

#Preview {
  let example = """
    我是[b]粗体字[/b]
    我是[i]斜体字[/i]
    我是[u]下划线文字[/u]
    我是[s]删除线文字[/s]
    [center]居中文字[/center]
    [left]居左文字[/left]
    [right]居右文字[/right]
    我是[mask]马赛克文字[/mask]
    我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]
    [size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现
    Bangumi 番组计划: [url]https://chii.in/[/url]
    带文字说明的网站链接：[url=https://chii.in]Bangumi 番组计划[/url]
    存放于其他网络服务器的图片：[img]https://chii.in/img/ico/bgm88-31.gif[/img]
    代码片段：[code]print("Hello, World!")[/code]
    [quote]引用的片段[/quote]
    (bgm38) (bgm24)

    传说中性能超强的人型电脑，故事第一话时被人弃置在垃圾场，[i]后被我们的本须和秀树发现，[s]并抱[u]回家[/u][/s][/i]。[color=red]由于开始时唧只会[b]'唧，唧'[/b]的这样叫[/color]，所以秀树为其取名 '唧' [mask]TV版第二话「[s]ちぃでかける[/s]」[/mask]时发现小唧本身并没有安OS，不过因为拥有“学习程式”，所以可以通过对话和教导让她‘成长’起来 (bgm38)。
    """
  let text = try! BBCode().text(example)
  ScrollView {
    Divider()
    text.padding()
    Divider()
  }
}
