import Foundation

class TagClosingParser: Parser {
  func parse(_ g: inout USIterator, _ worker: Worker) -> Parser? {
    var tagName: String = ""
    while let c = g.next() {
      if c == UnicodeScalar("]") {
        if !tagName.isEmpty && tagName == worker.currentNode.value {
          worker.currentNode.paired = true
          guard let p = worker.currentNode.parent else {
            // should not happen
            worker.error = BBCodeError.internalError("bug")
            return nil
          }
          worker.currentNode = p
          return ContentParser()
        } else {
          if let allowedChildren = worker.currentNode.description?.allowedChildren {
            if let tag = worker.tagManager.getInfo(str: tagName) {
              if allowedChildren.contains(tag.type) {
                // not paired tag
                // worker.error = BBCodeError.unpairedTag(
                //   unclosedTagDetail(unclosedNode: worker.currentNode))
                return ContentParser()
              }
            }
          }

          let newNode = Node(
            type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
          newNode.value = "[/" + tagName + "]"
          worker.currentNode.children.append(newNode)
          return ContentParser()
        }
      } else if c == UnicodeScalar("[") {
        // illegal syntax, treat it as plain text, and restart tag parsing from this new position
        let newNode = Node(
          type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
        newNode.value = "[/" + tagName
        worker.currentNode.children.append(newNode)
        return TagParser()
      } else if c == UnicodeScalar("=") {
        // illegal syntax, treat it as plain text
        let newNode = Node(
          type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
        newNode.value = "[/" + tagName + "="
        worker.currentNode.children.append(newNode)
        return ContentParser()
      } else {
        tagName.append(Character(c))
      }
    }

    worker.error = BBCodeError.unfinishedClosingTag(
      unclosedTagDetail(unclosedNode: worker.currentNode))
    return nil
  }
}
