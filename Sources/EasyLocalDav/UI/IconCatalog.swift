import AppKit
import SwiftUI

enum IconCatalog {
    static func image(named name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "Icons"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.isTemplate = true
        return image
    }
}

struct TemplateIcon: View {
    let name: String
    let fallbackSystemName: String
    var size: CGFloat = 16

    var body: some View {
        if let image = IconCatalog.image(named: name) {
            Image(nsImage: image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: fallbackSystemName)
                .font(.system(size: size, weight: .regular))
        }
    }
}
