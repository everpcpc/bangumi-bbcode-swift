import Foundation

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
            worker.error = BBCodeError.unclosedTag(
              unclosedTagDetail(unclosedNode: worker.currentNode))
            return nil
          }
        }
      } else {
        lastWasCR = false

        if c == UnicodeScalar("[") {  // <tag_start>
          if worker.currentNode.description?.allowedChildren != nil {
            if newNode.value.isEmpty {
              worker.currentNode.children.removeLast()
            }
            return TagParser()
          } else if !worker.currentNode.paired {
            return TagParser()
          } else {
            newNode.value.append(Character(c))
          }
        } else if c == UnicodeScalar("(") {  // <smilies>
          return SmiliesParser()
        } else {  // <content>
          newNode.value.append(Character(c))
        }
      }
    }
    return nil
  }
}
