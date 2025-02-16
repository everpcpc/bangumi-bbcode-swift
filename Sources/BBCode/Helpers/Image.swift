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
  @State private var showPreview = false

  @State private var currentZoom = 0.0
  @State private var totalZoom = 1.0

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
        Button {
          showPreview = true
        } label: {
          Label("预览", systemImage: "eye")
        }
        ShareLink(item: url)
      }
      #if os(iOS)
        .fullScreenCover(isPresented: $showPreview) {
          ZStack {
            Color.black
            .ignoresSafeArea()

            KFImage(url)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(currentZoom + totalZoom)
            .gesture(
              MagnifyGesture()
                .onChanged { value in
                  currentZoom = value.magnification - 1
                }
                .onEnded { value in
                  totalZoom += currentZoom
                  currentZoom = 0
                }
            )
            .accessibilityZoomAction { action in
              if action.direction == .zoomIn {
                totalZoom += 1
              } else {
                totalZoom -= 1
              }
            }

            VStack {
              HStack {
                Spacer()
                Button {
                  showPreview = false
                } label: {
                  Image(systemName: "xmark.circle.fill")
                  .font(.title)
                  .foregroundColor(.white)
                  .padding()
                }
              }
              Spacer()
            }
          }
        }
      #else
        .sheet(isPresented: $showPreview) {
          ZStack {
            Color.black

            KFImage(url)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(currentZoom + totalZoom)
            .gesture(
              MagnifyGesture()
                .onChanged { value in
                  currentZoom = value.magnification - 1
                }
                .onEnded { value in
                  totalZoom += currentZoom
                  currentZoom = 0
                }
            )
            .accessibilityZoomAction { action in
              if action.direction == .zoomIn {
                totalZoom += 1
              } else {
                totalZoom -= 1
              }
            }

            VStack {
              HStack {
                Spacer()
                Button {
                  showPreview = false
                } label: {
                  Image(systemName: "xmark.circle.fill")
                  .font(.title)
                  .foregroundColor(.white)
                  .padding()
                }
              }
              Spacer()
            }
          }
        }
      #endif
  }
}
