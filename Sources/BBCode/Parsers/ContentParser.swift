import Foundation
import OSLog

class ContentParser: Parser {
  func parse(_ g: inout USIterator, _ worker: Worker) -> Parser? {
    var newNode = Node(
      type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
    worker.currentNode.children.append(newNode)
    var lastWasCR = false
    while let c = g.next() {
      if c == UnicodeScalar(10) || c == UnicodeScalar(13) {
        if let allowedChildren = worker.currentNode.description?.allowedChildren,
          allowedChildren.contains(.br)
        {
          if c == UnicodeScalar(13) || (c == UnicodeScalar(10) && !lastWasCR) {
            if newNode.value.isEmpty {
              worker.currentNode.children.removeLast()
            }
            newNode = Node(
              type: .br, parent: worker.currentNode, tagManager: worker.tagManager)
            worker.currentNode.children.append(newNode)
            newNode = Node(
              type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
            worker.currentNode.children.append(newNode)
          }

          if c == UnicodeScalar(13) {  // \r
            lastWasCR = true
          } else {  // \n
            lastWasCR = false
          }
        } else {
          if worker.currentNode.type == .code {
            newNode.value.append(Character(c))
          } else {
            Logger.parser.error("unclosed tag: \(worker.currentNode.type.description)")
            worker.error = BBCodeError.unclosedTag(
              unclosedTagDetail(unclosedNode: worker.currentNode))
            return nil
          }
        }
      } else {
        lastWasCR = false

        if c == UnicodeScalar("[") {  // <tag_start>
          Logger.parser.debug("tag_start: \(worker.currentNode.type.description)")
          if worker.currentNode.description?.allowedChildren != nil {
            if newNode.value.isEmpty {
              worker.currentNode.children.removeLast()
            }
            return TagParser()
          } else if !worker.currentNode.paired {
            return TagParser()
          } else {
            Logger.parser.debug(
              "tag_start appended to value: \(worker.currentNode.type.description)")
            newNode.value.append(Character(c))
          }
        } else if c == UnicodeScalar("(") {  // <smilies>
          Logger.parser.debug("smilies_start: \(worker.currentNode.type.description)")
          return SmiliesParser()
        } else {  // <content>
          newNode.value.append(Character(c))
        }
      }
    }
    if worker.currentNode.type != .root {
      if let p = worker.currentNode.parent {
        worker.currentNode = p
        return ContentParser()
      } else {
        // unfinished without parent
        // This should never happen
        Logger.parser.error("unfinished without parent: \(worker.currentNode.type.description)")
        worker.error = BBCodeError.internalError("bug")
        return nil
      }
    }
    return nil
  }
}
