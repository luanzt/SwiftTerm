#if os(macOS)
import AppKit
import Testing

@testable import SwiftTerm

@Suite(.serialized)
@MainActor
struct TrueColorOverrideTests {
    private let suggestion = Attribute.Color.trueColor(red: 0xB1, green: 0xB9, blue: 0xF9)
    private let messageBackground = Attribute.Color.trueColor(red: 0x37, green: 0x37, blue: 0x37)

    private func rgb24(_ color: NSColor) -> UInt32 {
        let rgb = color.usingColorSpace(.sRGB) ?? color
        let red = UInt32((rgb.redComponent * 255).rounded())
        let green = UInt32((rgb.greenComponent * 255).rounded())
        let blue = UInt32((rgb.blueComponent * 255).rounded())
        return (red << 16) | (green << 8) | blue
    }

    private func hostedTerminalView() -> (view: TerminalView, window: NSWindow) {
        let view = TerminalView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let window = NSWindow(
            contentRect: view.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        return (view, window)
    }

    @Test func exactTrueColorMappingLeavesNonmatchesLiteral() {
        let view = TerminalView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))

        #expect(rgb24(view.mapColor(color: suggestion, isFg: true, isBold: false)) == 0xB1B9F9)
        view.installTrueColorOverrides([0xB1B9F9: 0x0B7A55])
        #expect(rgb24(view.mapColor(color: suggestion, isFg: true, isBold: false)) == 0x0B7A55)
        #expect(rgb24(view.mapColor(
            color: .trueColor(red: 0x12, green: 0x34, blue: 0x56),
            isFg: true,
            isBold: false)) == 0x123456)
    }

    @Test func foregroundAndBackgroundCachesRefreshAndClear() throws {
        let (view, window) = hostedTerminalView()
        defer { window.close() }
        let attribute = Attribute(fg: suggestion, bg: messageBackground, style: .none)

        let original = try #require(view.getAttributes(attribute))
        #expect(rgb24(try #require(original[.foregroundColor] as? NSColor)) == 0xB1B9F9)
        #expect(rgb24(try #require(original[.backgroundColor] as? NSColor)) == 0x373737)

        view.needsDisplay = false
        view.installTrueColorOverrides([0xB1B9F9: 0x0B7A55, 0x373737: 0xE2ECE6])
        #expect(view.needsDisplay)
        let mapped = try #require(view.getAttributes(attribute))
        #expect(rgb24(try #require(mapped[.foregroundColor] as? NSColor)) == 0x0B7A55)
        #expect(rgb24(try #require(mapped[.backgroundColor] as? NSColor)) == 0xE2ECE6)
        #expect(attribute.fg == suggestion)
        #expect(attribute.bg == messageBackground)

        view.installTrueColorOverrides([:])
        let restored = try #require(view.getAttributes(attribute))
        #expect(rgb24(try #require(restored[.foregroundColor] as? NSColor)) == 0xB1B9F9)
        #expect(rgb24(try #require(restored[.backgroundColor] as? NSColor)) == 0x373737)
    }

    @Test func mappingMasksPackedValuesAndEqualInstallIsNoOp() {
        let (view, window) = hostedTerminalView()
        defer { window.close() }
        let maskedInput: [UInt32: UInt32] = [0xFFB1B9F9: 0xAA0B7A55]

        view.installTrueColorOverrides(maskedInput)
        #expect(rgb24(view.mapColor(color: suggestion, isFg: true, isBold: false)) == 0x0B7A55)
        #expect(view.trueColors.count == 1)

        view.display()
        view.needsDisplay = false
        view.installTrueColorOverrides(maskedInput)
        #expect(view.trueColors.count == 1)
        #expect(!view.needsDisplay)
    }

    @Test func ANSIAndDefaultColorsDoNotUseTrueColorOverrides() {
        let view = TerminalView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let ansiBefore = rgb24(view.mapColor(
            color: .ansi256(code: 1), isFg: true, isBold: false))
        let defaultBefore = rgb24(view.mapColor(
            color: .defaultColor, isFg: true, isBold: false))

        view.installTrueColorOverrides([
            0xB1B9F9: 0x0B7A55,
            0x000000: 0x123456,
            0xFFFFFF: 0x654321,
        ])

        #expect(rgb24(view.mapColor(
            color: .ansi256(code: 1), isFg: true, isBold: false)) == ansiBefore)
        #expect(rgb24(view.mapColor(
            color: .defaultColor, isFg: true, isBold: false)) == defaultBefore)
    }
}
#endif
