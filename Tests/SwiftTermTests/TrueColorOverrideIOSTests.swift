#if os(iOS)
import Testing
import UIKit

@testable import SwiftTerm

@MainActor
private final class InvalidationRecordingTerminalView: TerminalView {
    private(set) var invalidatedRects: [CGRect] = []

    override func setNeedsDisplay(_ rect: CGRect) {
        invalidatedRects.append(rect)
        super.setNeedsDisplay(rect)
    }

    func resetInvalidatedRects() {
        invalidatedRects.removeAll()
    }
}

@Suite(.serialized)
@MainActor
struct TrueColorOverrideIOSTests {
    @Test func installInvalidatesLocalBoundsForNonzeroFrameOrigin() {
        let view = InvalidationRecordingTerminalView(
            frame: CGRect(x: 40, y: 60, width: 320, height: 200))
        view.resetInvalidatedRects()

        view.installTrueColorOverrides([0xB1B9F9: 0x0B7A55])

        #expect(view.invalidatedRects.last == view.bounds)
    }
}
#endif
