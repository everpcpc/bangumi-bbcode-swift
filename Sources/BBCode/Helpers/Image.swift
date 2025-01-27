import Foundation
import Kingfisher
import SwiftUI

extension Image {
  init(packageResource name: String, ofType type: String) {
    #if canImport(UIKit)
      guard let path = Bundle.module.path(forResource: name, ofType: type),
        let image = UIImage(contentsOfFile: path)
      else {
        self.init(name)
        return
      }
      self.init(uiImage: image)
    #elseif canImport(AppKit)
      guard let path = Bundle.module.path(forResource: name, ofType: type),
        let image = NSImage(contentsOfFile: path)
      else {
        self.init(name)
        return
      }
      self.init(nsImage: image)
    #else
      self.init(systemName: "photo")
    #endif
  }
}

struct ImageView: View {
  let url: URL

  @State private var width: CGFloat?

  #if canImport(UIKit)
    func saveImage() {
      Task {
        guard let data = try? await URLSession.shared.data(from: url).0 else { return }
        guard let img = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
      }
    }
  #elseif canImport(AppKit)
    func showSavePanel() -> URL? {
      let savePanel = NSSavePanel()
      savePanel.allowedContentTypes = [.png]
      savePanel.canCreateDirectories = true
      savePanel.isExtensionHidden = false
      savePanel.title = "Save your image"
      savePanel.message = "Choose a folder and a name to store the image."
      savePanel.nameFieldLabel = "Image file name:"

      let response = savePanel.runModal()
      return response == .OK ? savePanel.url : nil
    }

    func savePNG(imageName: String, path: URL) {
      guard let image = NSImage(named: imageName) else { return }
      guard let tiffData = image.tiffRepresentation else { return }
      guard let imageRepresentation = NSBitmapImageRep(data: tiffData) else {
        return
      }
      guard let pngData = imageRepresentation.representation(using: .png, properties: [:]) else {
        return
      }
      try? pngData.write(to: path)
    }
  #endif

  var body: some View {
    KFImage(url)
      .onSuccess { result in
        self.width = result.image.size.width
      }
      .placeholder { ProgressView() }
      .fade(duration: 0.25)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(maxWidth: width)
      .contextMenu {
        ShareLink(item: url)
        Button {
          #if canImport(UIKit)
            saveImage()
          #elseif canImport(AppKit)
            if let path = showSavePanel() {
              savePNG(imageName: url.lastPathComponent, path: path)
            }
          #endif
        } label: {
          Label("保存", systemImage: "square.and.arrow.down")
        }
      }
  }
}
