import CoreGraphics
import Foundation
import ImageIO
import simd

struct SolarSphereSample {
  let normal: SIMD3<Double>
  let u: Double
  let v: Double

  func illumination(light: SIMD3<Double>) -> Double {
    let diffuse = max(0, simd_dot(normal, light))
    // A small fill keeps the night side readable in the decorative atlas.
    return (0.12 + 0.88 * sqrt(diffuse)) * (0.78 + normal.z * 0.22)
  }
}

enum SolarSphereProjection {
  static func sample(x: Double, y: Double) -> SolarSphereSample? {
    let squaredRadius = x * x + y * y
    guard squaredRadius <= 1 else { return nil }
    let z = sqrt(max(0, 1 - squaredRadius))
    return SolarSphereSample(
      normal: SIMD3(x, y, z),
      u: 0.5 + atan2(x, z) / (2 * .pi),
      v: 0.5 + asin(y) / .pi
    )
  }
}

/// Small projected discs; only the latest frame for each planet is retained.
@MainActor
enum SolarPlanetTextureRenderer {
  private static let resolution = 160
  private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
  private static let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
    CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
  )
  private static let samples = (0..<resolution * resolution).map { index in
    SolarSphereProjection.sample(
      x: (Double(index % resolution) + 0.5) / Double(resolution) * 2 - 1,
      y: (Double(index / resolution) + 0.5) / Double(resolution) * 2 - 1
    )
  }
  private static var textures: [String: PlanetTexture] = [:]
  private static var frames: [String: (phase: Double, light: SIMD3<Double>, image: CGImage)] = [:]

  static func image(name: String, spin: Double, light: SIMD3<Double>) -> CGImage? {
    let resource: String
    switch name {
    case "Venus": resource = "venus_atmosphere"
    case "Earth": resource = "earth_daymap"
    default: resource = name.lowercased()
    }
    guard let surfaceTexture = texture(named: resource), spin.isFinite else { return nil }
    let turn = spin / (2 * .pi)
    let wrappedPhase = turn - floor(turn)
    // The large, slowly rotating Sun must advance every animation frame.
    // Quantizing it to 240 angles held each image for about 0.58 seconds.
    let phase = name == "Sun" ? wrappedPhase : floor(wrappedPhase * 240) / 240
    let quantizedLight = SIMD3<Double>(
      (light.x * 64).rounded() / 64,
      (light.y * 64).rounded() / 64,
      (light.z * 64).rounded() / 64
    )
    if let frame = frames[name], frame.phase == phase, frame.light == quantizedLight {
      return frame.image
    }
    let direction =
      simd_length(quantizedLight) > 0 ? simd_normalize(quantizedLight) : SIMD3(0, 0, 1)
    let clouds = name == "Earth" ? texture(named: "earth_clouds") : nil
    var pixels = [UInt8](repeating: 0, count: resolution * resolution * 4)
    for (index, sample) in samples.enumerated() {
      guard let sample else { continue }
      var color = surfaceTexture.color(u: sample.u + phase, v: sample.v)
      if let clouds {
        let cloud = clouds.color(u: sample.u + phase + 0.025, v: sample.v).x / 255
        let coverage = min(0.92, cloud * 0.88)
        color = color * (1 - coverage) + SIMD3<Double>(repeating: 248) * coverage
      }
      let brightness =
        name == "Sun" ? 0.72 + sample.normal.z * 0.28 : sample.illumination(light: direction)
      let coverage = min(1, sample.normal.z * sample.normal.z * Double(resolution) * 0.5)
      let offset = index * 4
      for channel in 0..<3 {
        pixels[offset + channel] = UInt8(min(255, max(0, color[channel] * brightness * coverage)))
      }
      pixels[offset + 3] = UInt8(255 * coverage)
    }
    guard let provider = CGDataProvider(data: Data(pixels) as CFData),
      let image = CGImage(
        width: resolution, height: resolution, bitsPerComponent: 8, bitsPerPixel: 32,
        bytesPerRow: resolution * 4, space: colorSpace, bitmapInfo: bitmapInfo,
        provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
      )
    else { return nil }
    frames[name] = (phase, quantizedLight, image)
    return image
  }

  private static func texture(named name: String) -> PlanetTexture? {
    if let texture = textures[name] { return texture }
    guard let url = Bundle.module.url(forResource: "2k_\(name)", withExtension: "jpg"),
      let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let context = CGContext(
        data: nil, width: 1_024, height: 512, bitsPerComponent: 8, bytesPerRow: 1_024 * 4,
        space: colorSpace, bitmapInfo: bitmapInfo.rawValue
      )
    else { return nil }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: 1_024, height: 512))
    guard let data = context.data else { return nil }
    let texture = PlanetTexture(
      pixels: Array(
        UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: 1_024 * 512 * 4)
      )
    )
    textures[name] = texture
    return texture
  }

  private struct PlanetTexture {
    let pixels: [UInt8]

    func color(u: Double, v: Double) -> SIMD3<Double> {
      let x = (u - floor(u)) * 1_024
      let y = min(511, max(0, v * 511))
      let x0 = Int(x) % 1_024
      let x1 = (x0 + 1) % 1_024
      let y0 = Int(y)
      let y1 = min(511, y0 + 1)
      let fx = x - floor(x)
      let fy = y - floor(y)
      func pixel(_ x: Int, _ y: Int) -> SIMD3<Double> {
        let offset = (y * 1_024 + x) * 4
        return SIMD3(Double(pixels[offset]), Double(pixels[offset + 1]), Double(pixels[offset + 2]))
      }
      let top = pixel(x0, y0) * (1 - fx) + pixel(x1, y0) * fx
      let bottom = pixel(x0, y1) * (1 - fx) + pixel(x1, y1) * fx
      return top * (1 - fy) + bottom * fy
    }
  }
}
