import Foundation
import OSLog

func parseSmilies(_ g: inout USIterator, _ worker: Worker) -> ParserType? {
  let newNode = Node(
    type: .unknown, parent: worker.currentNode, tagManager: worker.tagManager)
  worker.currentNode.children.append(newNode)

  var index: Int = 0
  let smiliesNameMaxLength: Int = 8
  let smiliesRegex = try! Regex(#"bgm(?<id>\d+)"#, as: (Substring, id: Substring).self)
  while let c = g.next() {
    if c == UnicodeScalar(")") {
      if newNode.value.isEmpty {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
        return .content
      }
      if let match = newNode.value.wholeMatch(of: smiliesRegex) {
        let bgmId = Int(match.id) ?? 0
        if bgmId < 24 || bgmId > 125 {
          restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
          return .content
        }
        let newNode = Node(
          type: .smilies,
          parent: worker.currentNode, tagManager: worker.tagManager)
        worker.currentNode.children.append(newNode)
        newNode.value = "bgm"
        newNode.attr = String(bgmId)
        newNode.setTag(tag: worker.tagManager.getInfo(type: .smilies)!)
        return .content
      } else {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
        return .content
      }
    } else {
      if index < smiliesNameMaxLength {
        newNode.value.append(Character(c))
      } else {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
        return .content
      }
    }
    index = index + 1
  }

  Logger.parser.error("unfinished closing tag: \(worker.currentNode.type.description)")
  worker.error = BBCodeError.unfinishedClosingTag(
    unclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

func restoreSmiliesToPlain(node: Node, c: UnicodeScalar, worker: Worker) {
  node.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
  node.value.insert(Character(UnicodeScalar(40)), at: node.value.startIndex)
  node.value.append(Character(c))
}
