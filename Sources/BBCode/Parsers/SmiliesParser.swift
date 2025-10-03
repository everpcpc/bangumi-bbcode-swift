import Foundation
import OSLog

func parseSmilies(_ g: inout USIterator, _ worker: Worker) -> Parser? {
  let newNode = Node(
    type: .unknown, parent: worker.currentNode, tagManager: worker.tagManager)
  worker.currentNode.children.append(newNode)

  var index: Int = 0
  let maxLength: Int = 50  // BMO codes can be longer than bgm
  let bgmRegex = try! Regex(#"bgm(?<id>\d+)"#, as: (Substring, id: Substring).self)
  while let c = g.next() {
    if c == UnicodeScalar(")") {
      if newNode.value.isEmpty {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
        return .content
      }

      // Check if this is a BMO code first
      if newNode.value.hasPrefix("bmo") {
        let bmoNode = Node(
          type: .bmo,
          parent: worker.currentNode, tagManager: worker.tagManager)
        worker.currentNode.children.append(bmoNode)
        bmoNode.value = "bmo"
        bmoNode.attr = newNode.value  // Store the full BMO code in attr
        bmoNode.setTag(tag: worker.tagManager.getInfo(type: .bmo)!)
        return .content
      }

      // Check if this is a bgm code
      if let match = newNode.value.wholeMatch(of: bgmRegex) {
        let bgmId = Int(match.id) ?? 0
        if bgmId < 24 || bgmId > 125 {
          restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
          return .content
        }
        let bgmNode = Node(
          type: .bgm,
          parent: worker.currentNode, tagManager: worker.tagManager)
        worker.currentNode.children.append(bgmNode)
        bgmNode.value = "bgm"
        bgmNode.attr = String(bgmId)
        bgmNode.setTag(tag: worker.tagManager.getInfo(type: .bgm)!)
        return .content
      } else {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
        return .content
      }
    } else {
      if index < maxLength {
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
