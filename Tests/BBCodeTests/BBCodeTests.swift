import XCTest

@testable import BBCode

class BBCodeTests: XCTestCase {
  func testBold() {
    XCTAssertEqual(try BBCode().parse(bbcode: "我是[b]粗体字[/b]"), "我是<strong>粗体字</strong>")
  }

  func testItalic() {
    XCTAssertEqual(try BBCode().parse(bbcode: "我是[i]斜体字[/i]"), "我是<em>斜体字</em>")
  }

  func testUnderline() {
    XCTAssertEqual(
      try BBCode().parse(bbcode: "我是[u]下划线文字[/u]"),
      "我是<span style=\"text-decoration: underline\">下划线文字</span>")
  }

  func testStrikeThrough() {
    XCTAssertEqual(
      try BBCode().parse(bbcode: "我是[s]删除线文字[/s]"),
      "我是<span style=\"text-decoration: line-through\">删除线文字</span>")
  }

  func testMask() {
    XCTAssertEqual(
      try BBCode().parse(bbcode: "我是[mask]马赛克文字[/mask]"),
      "我是<span style=\"background-color: #555; color: #555; border: 1px solid #555;\">马赛克文字</span>")
  }

  func testColor() {
    XCTAssertEqual(
      try BBCode().parse(
        bbcode:
          "我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]。"
      ),
      "我是<span style=\"color: red\">彩</span><span style=\"color: green\">色</span><span style=\"color: blue\">的</span><span style=\"color: orange\">哟</span>。"
    )
  }

  func testSize() {
    XCTAssertEqual(
      try BBCode().parse(bbcode: "[size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现。"),
      "<span style=\"font-size: 10px\">不同</span><span style=\"font-size: 14px\">大小的</span><span style=\"font-size: 18px\">文字</span>效果也可实现。"
    )
  }

  func testLink() {
    XCTAssertEqual(
      try BBCode().parse(bbcode: "Bangumi 番组计划: [url]https://chii.in/[/url]"),
      "Bangumi 番组计划: <a href=\"https://chii.in/\">https://chii.in/</a>"
    )
  }

  func testURL() {
    XCTAssertEqual(
      try BBCode().parse(bbcode: "带文字说明的网站链接：[url=https://chii.in]Bangumi 番组计划[/url]"),
      "带文字说明的网站链接：<a href=\"https://chii.in/\">Bangumi 番组计划</a>"
    )
  }

  func testImage() {
    XCTAssertEqual(
      try BBCode().parse(bbcode: "存放于其他网络服务器的图片：[img]https://chii.in/img/ico/bgm88-31.gif[/img]"),
      "存放于其他网络服务器的图片：<img src=\"https://chii.in/img/ico/bgm88-31.gif\"/>"
    )
  }

}
