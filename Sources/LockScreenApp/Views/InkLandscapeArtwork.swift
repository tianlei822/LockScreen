import AppKit
import SwiftUI

@MainActor
private enum InkLandscapeAsset {
  static let image: NSImage = {
    guard
      let url = Bundle.module.url(forResource: "InkLandscapeRefined", withExtension: "png"),
      let image = NSImage(contentsOf: url)
    else {
      return NSImage()
    }
    return image
  }()
}

enum InkLandscapeBoatInteraction {
  static let normalizedTarget = CGRect(x: 0.64, y: 0.77, width: 0.23, height: 0.167)
}

/// A full-bleed shan-shui scroll with no formation geometry layered over the painting.
struct InkLandscapeArtwork: View {
  let isActivated: Bool
  let onBoatActivate: () -> Void

  var body: some View {
    GeometryReader { proxy in
      let image = InkLandscapeAsset.image
      let viewport = InkLandscapeViewport(canvasSize: proxy.size, imageSize: image.size)
      let boatTarget = viewport.rect(for: InkLandscapeBoatInteraction.normalizedTarget)
      let boatHitSize = CGSize(
        width: max(boatTarget.width, 88),
        height: max(boatTarget.height, 64)
      )

      ZStack {
        Image(nsImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: proxy.size.width, height: proxy.size.height)
          .offset(viewport.imageOffset)
          .overlay {
            LinearGradient(
              colors: [
                Color.black.opacity(0.22),
                Color.clear,
                Color.black.opacity(0.12),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          }
          .allowsHitTesting(false)
          .accessibilityHidden(true)

        Button(action: onBoatActivate) {
          Ellipse()
            .fill(Color.clear)
            .contentShape(Ellipse())
            .frame(width: boatHitSize.width, height: boatHitSize.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: boatHitSize.width, height: boatHitSize.height)
        .position(x: boatTarget.midX, y: boatTarget.midY)
        .accessibilityLabel(
          L10n.text("Fishing boat — click to leave the ink landscape")
        )
        .help(L10n.text("Fishing boat — click to leave the ink landscape"))
        .opacity(isActivated ? 0 : 1)
        .allowsHitTesting(!isActivated)
        .accessibilityHidden(isActivated)
        .animation(.easeOut(duration: 0.18), value: isActivated)
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipped()
    }
  }
}

struct InkLandscapeViewport {
  let canvasSize: CGSize
  let imageSize: CGSize

  /// Wide screens would otherwise center-crop the bottom of the scroll and hide the fishing boat.
  var imageOffset: CGSize {
    CGSize(width: 0, height: -verticalOverflow * 0.27)
  }

  private var scale: CGFloat {
    max(canvasSize.width / max(imageSize.width, 1), canvasSize.height / max(imageSize.height, 1))
  }

  private var drawnSize: CGSize {
    CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
  }

  private var verticalOverflow: CGFloat {
    max(0, drawnSize.height - canvasSize.height)
  }

  private var origin: CGPoint {
    CGPoint(
      x: (canvasSize.width - drawnSize.width) * 0.5,
      y: (canvasSize.height - drawnSize.height) * 0.5 + imageOffset.height
    )
  }

  func rect(for normalizedRect: CGRect) -> CGRect {
    CGRect(
      x: origin.x + normalizedRect.minX * drawnSize.width,
      y: origin.y + normalizedRect.minY * drawnSize.height,
      width: normalizedRect.width * drawnSize.width,
      height: normalizedRect.height * drawnSize.height
    )
  }
}
