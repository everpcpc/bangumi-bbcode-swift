import Foundation

class AttrParser: Parser {
  func parse(_ g: inout USIterator, _ worker: Worker) -> Parser? {
    while let c = g.next() {
      if c == UnicodeScalar("]") {
        return ContentParser()
      } else if c == UnicodeScalar(10) || c == UnicodeScalar(13) {
        worker.error = BBCodeError.unfinishedAttr(
          unclosedTagDetail(unclosedNode: worker.currentNode))
        return nil
      } else {
        worker.currentNode.attr.append(Character(c))
      }
    }

    //unfinished attr
    worker.error = BBCodeError.unfinishedAttr(unclosedTagDetail(unclosedNode: worker.currentNode))
    return nil
  }
}
