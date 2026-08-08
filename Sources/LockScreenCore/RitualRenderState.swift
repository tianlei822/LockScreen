public struct RitualRenderState: Equatable, Sendable {
  public private(set) var isPresented = false

  public var pausesAnimations: Bool { !isPresented }

  public init() {}

  public mutating func present() {
    isPresented = true
  }

  public mutating func retreat() {
    isPresented = false
  }
}
