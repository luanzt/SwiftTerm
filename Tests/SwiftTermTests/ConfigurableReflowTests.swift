#if os(macOS)
import Testing

@testable import SwiftTerm

final class ConfigurableReflowTests {
    @Test func normalBufferReflowCanBeEnabledAndSurvivesReset() {
        let terminal = HeadlessTerminal(
            queue: SwiftTermTests.queue,
            options: TerminalOptions(cols: 80, rows: 24, scrollback: 100),
            onEnd: { _ in }).terminal!

        #expect(terminal.reflowOnResize == false)
        terminal.reflowOnResize = true
        #expect(terminal.reflowOnResize == true)

        terminal.resetNormalBuffer()
        #expect(terminal.reflowOnResize == true)
    }

    @Test func alternateScreenBufferNeverReflows() {
        let buffer = Buffer(
            cols: 80,
            rows: 24,
            tabStopWidth: 8,
            scrollback: nil)

        buffer.reflowOnResize = true

        #expect(buffer.isReflowEnabled == false)
    }
}
#endif
