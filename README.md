# Bangumi BBCode Swift

A BBCode parser and render for Bangumi writing in swift.

Tested on iOS and macOS.

inspired by: https://github.com/shiningdracon/BBCode-Swift

## Usage

### Parse BBCode to HTML mauanlly

```swift
import BBCode

let bbcode = "[b]Hello World[/b]"
let html = try! BBCode().html(code)
```

### Show BBCode with SwiftUI Native Components

```swift
import SwiftUI
import BBCode

struct ContentView: View {
  let example = "[b]Hello World[/b]"

  var body: some View {
    ScrollView {
      BBCodeText(example).padding()
    }
  }
}
```

### Show BBCode with WKWebView

```swift
import SwiftUI
import BBCode

struct ContentView: View {
  let example = "[b]Hello World[/b]"

  var body: some View {
    ScrollView {
      BBCodeWebView(example, textSize = 14)
    }
  }
}
```

### Show BBCode with UITextView

```swift
import SwiftUI
import BBCode

struct ContentView: View {
  let example = "[b]Hello World[/b]"

  var body: some View {
    ScrollView {
      BBCodeUITextView(example).padding()
    }
  }
}
```

# supported tags

- [x] b
- [x] i
- [x] u
- [x] s
- [x] img
- [x] mask
- [x] size
- [x] color
- [x] url
- [x] center
- [x] left
- [x] right
- [x] code
- [x] quote
- [x] photo
- [ ] subject
- [ ] email
- [ ] user
- [x] smilies
