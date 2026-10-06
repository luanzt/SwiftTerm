//
//  HistoryTests.swift
//  SwiftTerm
//
//  Created for testing the dynamic history size change API
//

import Testing
@testable import SwiftTerm

final class HistoryTests {
    
    class TestDelegate: TerminalDelegate {
        func showCursor(source: Terminal) {}
        func hideCursor(source: Terminal) {}
        func setTerminalTitle(source: Terminal, title: String) {}
        func setTerminalIconTitle(source: Terminal, title: String) {}
        func windowCommand(source: Terminal, command: Terminal.WindowManipulationCommand) -> [UInt8]? { return nil }
        func sizeChanged(source: Terminal) {}
        func send(source: Terminal, data: ArraySlice<UInt8>) {}
        func scrolled(source: Terminal, yDisp: Int) {}
        func linefeed(source: Terminal) {}
        func bufferActivated(source: Terminal) {}
        func bell(source: Terminal) {}
    }
    
    @Test func testChangeHistorySize() {
        let delegate = TestDelegate()
        let options = TerminalOptions(scrollback: 100)
        let terminal = Terminal(delegate: delegate, options: options)
        
        // Test initial scrollback
        #expect(terminal.buffer.scrollback == 100)
        #expect(terminal.buffer.hasScrollback)
        
        // Test increasing history size
        terminal.changeHistorySize(500)
        #expect(terminal.buffer.scrollback == 500)
        #expect(terminal.buffer.hasScrollback)
        #expect(terminal.options.scrollback == 500)
        
        // Test decreasing history size
        terminal.changeHistorySize(50)
        #expect(terminal.buffer.scrollback == 50)
        #expect(terminal.buffer.hasScrollback)
        #expect(terminal.options.scrollback == 50)
        
        // Test disabling scrollback
        terminal.changeHistorySize(nil)
        #expect(terminal.buffer.scrollback == nil)
        #expect(!terminal.buffer.hasScrollback)
        #expect(terminal.options.scrollback == 0)
        
        // Test re-enabling scrollback
        terminal.changeHistorySize(1000)
        #expect(terminal.buffer.scrollback == 1000)
        #expect(terminal.buffer.hasScrollback)
        #expect(terminal.options.scrollback == 1000)
    }

    @Test func testChangeScrollbackApi() {
        let delegate = TestDelegate()
        let options = TerminalOptions(scrollback: 20)
        let terminal = Terminal(delegate: delegate, options: options)

        terminal.changeScrollback(80)
        #expect(terminal.buffer.scrollback == 80)
        #expect(terminal.options.scrollback == 80)

        terminal.changeScrollback(nil)
        #expect(terminal.buffer.scrollback == nil)
        #expect(!terminal.buffer.hasScrollback)
        #expect(terminal.options.scrollback == 0)
    }
    
    @Test func testHistorySizeBufferLength() {
        let delegate = TestDelegate()
        let options = TerminalOptions(cols: 80, rows: 25, scrollback: 100)
        let terminal = Terminal(delegate: delegate, options: options)
        
        let initialMaxLength = terminal.buffer.lines.maxLength
        #expect(initialMaxLength == 125) // 25 rows + 100 scrollback
        
        // Increase history size
        terminal.changeHistorySize(200)
        #expect(terminal.buffer.lines.maxLength == 225) // 25 rows + 200 scrollback
        
        // Decrease history size
        terminal.changeHistorySize(50)
        #expect(terminal.buffer.lines.maxLength == 75) // 25 rows + 50 scrollback
        
        // Disable scrollback
        terminal.changeHistorySize(nil)
        #expect(terminal.buffer.lines.maxLength == 25) // 25 rows only
    }

    /// The saved cursor is screen-relative, so trimming history above the
    /// screen must not move it: leaving an alternate-screen program after the
    /// limit was lowered has to restore the prompt row, not row 0.
    @Test func testShrinkingHistoryKeepsSavedCursorRow() {
        let delegate = TestDelegate()
        let options = TerminalOptions(cols: 80, rows: 25, scrollback: 100)
        let terminal = Terminal(delegate: delegate, options: options)
        for i in 0..<200 {
            terminal.feed(text: "line \(i)\r\n")
        }
        terminal.feed(text: "\u{1b}[20;5H")
        let row = terminal.buffer.y
        let col = terminal.buffer.x

        terminal.feed(text: "\u{1b}[?1049h")
        terminal.changeScrollback(10)
        terminal.feed(text: "\u{1b}[?1049l")

        #expect(terminal.buffer.y == row)
        #expect(terminal.buffer.x == col)
        #expect(terminal.buffer.lines.count == 35)
    }
}
