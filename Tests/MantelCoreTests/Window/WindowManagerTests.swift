import AppKit
import Testing

@testable import MantelCore

@MainActor
@Suite("WindowManager")
struct WindowManagerTests {
    let fake = FakeEnvironment()
    let manager: WindowManager

    init() {
        fake.addTerminal(pid: 100, bounds: CGRect(x: 0, y: 0, width: 800, height: 480), windowNumber: 42)
        manager = WindowManager(environment: fake.environment)
    }

    func add(_ command: AddCommand = .fixture()) {
        manager.execute(.add(command))
    }

    // MARK: add

    @Test func addCreatesWindowAboveTerminalWithCellFrame() throws {
        add(.fixture(x: 8, y: 2, width: 40, height: 10, cols: 80, rows: 24))

        let window = try #require(fake.window("preview"))
        #expect(window.frame == CGRect(x: 80, y: 1000 - 40 - 200, width: 400, height: 200))
        #expect(window.calls == [.orderAbove(42)])
        #expect(window.isVisible)
        #expect(fake.loadedPaths == ["/img.png"])
    }

    @Test func addSameIdentifierReusesWindow() throws {
        add()
        let window = try #require(fake.window("preview"))
        window.resetCalls()

        add(.fixture(path: "/other.png", x: 1))

        #expect(fake.windows["preview"]?.count == 1)
        #expect(
            window.calls == [
                .updateImage, .updateFrame(CGRect(x: 10, y: 1000 - 100, width: 100, height: 100)), .orderAbove(42),
            ])
    }

    @Test func addDifferentIdentifiersCreatesSeparateWindows() {
        add(.fixture(identifier: "a"))
        add(.fixture(identifier: "b"))

        #expect(fake.window("a") != nil)
        #expect(fake.window("b") != nil)
    }

    @Test func addWithMissingImageDoesNothing() {
        fake.missingImages = ["/img.png"]

        add()

        #expect(fake.windows.isEmpty)
        #expect(fake.observedTerminalPids.isEmpty)
    }

    @Test func addWithUnknownTerminalDoesNothing() {
        add(.fixture(terminalPid: 999))

        #expect(fake.windows.isEmpty)
        #expect(fake.observedTerminalPids.isEmpty)
    }

    @Test func addWithInvalidGridDoesNothing() {
        add(.fixture(cols: 0))

        #expect(fake.windows.isEmpty)
    }

    @Test func failedReAddKeepsPreviousWindowUntouched() throws {
        add()
        let window = try #require(fake.window("preview"))
        window.resetCalls()
        fake.missingImages = ["/broken.png"]

        add(.fixture(path: "/broken.png"))

        #expect(window.calls.isEmpty)
        #expect(window.isVisible)
    }

    // MARK: observers

    @Test func observersStartOncePerTerminalAndFocusOnce() {
        fake.addTerminal(pid: 200, windowNumber: 43)

        add(.fixture(identifier: "a", terminalPid: 100))
        add(.fixture(identifier: "b", terminalPid: 100))
        add(.fixture(identifier: "c", terminalPid: 200))

        #expect(fake.observedTerminalPids == [100, 200])
        #expect(fake.focusObserverStarts == 1)
    }

    @Test func failedTerminalObserverIsRetriedOnNextAdd() {
        fake.observerStartSucceeds = false
        add()
        fake.observerStartSucceeds = true
        add()

        #expect(fake.observedTerminalPids == [100, 100])
    }

    // MARK: hide / show / toggle

    @Test func hideHidesWindow() throws {
        add()

        manager.execute(.hide(BaseCommand(identifier: "preview")))

        let window = try #require(fake.window("preview"))
        #expect(!window.isVisible)
        #expect(window.calls.last == .hide)
    }

    @Test func showOrdersAboveTerminalNotFront() throws {
        add()
        manager.execute(.hide(BaseCommand(identifier: "preview")))
        let window = try #require(fake.window("preview"))
        window.resetCalls()

        manager.execute(.show(BaseCommand(identifier: "preview")))

        #expect(window.calls == [.orderAbove(42)])
        #expect(window.isVisible)
    }

    @Test func toggleFlipsVisibility() throws {
        add()
        let window = try #require(fake.window("preview"))

        manager.execute(.toggle(BaseCommand(identifier: "preview")))
        #expect(!window.isVisible)

        manager.execute(.toggle(BaseCommand(identifier: "preview")))
        #expect(window.isVisible)
        #expect(window.calls.last == .orderAbove(42))
    }

    @Test func showAfterRemoveKeepsWindowHidden() throws {
        add()
        manager.execute(.remove(BaseCommand(identifier: "preview")))
        let window = try #require(fake.window("preview"))
        window.resetCalls()

        manager.execute(.show(BaseCommand(identifier: "preview")))
        manager.execute(.toggle(BaseCommand(identifier: "preview")))

        #expect(window.calls.isEmpty)
        #expect(!window.isVisible)
    }

    @Test func commandsForUnknownIdentifierAreIgnored() {
        for command: Command in [
            .hide(BaseCommand(identifier: "nope")),
            .show(BaseCommand(identifier: "nope")),
            .toggle(BaseCommand(identifier: "nope")),
            .remove(BaseCommand(identifier: "nope")),
        ] {
            manager.execute(command)
        }

        #expect(fake.windows.isEmpty)
    }

    // MARK: remove / clear

    @Test func removeClosesButKeepsWindowForReuse() throws {
        add()
        manager.execute(.remove(BaseCommand(identifier: "preview")))
        let window = try #require(fake.window("preview"))
        #expect(window.calls.last == .close)
        #expect(!window.isVisible)

        add()

        #expect(fake.windows["preview"]?.count == 1)
        #expect(window.isVisible)
    }

    @Test func clearDestroysAllAndNextAddCreatesFreshWindow() throws {
        add(.fixture(identifier: "a"))
        add(.fixture(identifier: "b"))
        let a = try #require(fake.window("a"))
        let b = try #require(fake.window("b"))

        manager.execute(.clear(ClearAll()))

        #expect(a.calls.last == .destroy)
        #expect(b.calls.last == .destroy)

        add(.fixture(identifier: "a"))
        #expect(fake.windows["a"]?.count == 2)
    }

    // MARK: terminal move / resize

    @Test func terminalMoveRepositionsItsImages() throws {
        add(.fixture(x: 1, y: 1, width: 1, height: 1))
        let window = try #require(fake.window("preview"))
        window.resetCalls()
        fake.addTerminal(pid: 100, bounds: CGRect(x: 200, y: 100, width: 1600, height: 960), windowNumber: 42)

        manager.handleTerminalWindowChange(pid: 100)

        #expect(
            window.calls == [.updateFrame(CGRect(x: 220, y: 1000 - 140 - 40, width: 20, height: 40)), .orderAbove(42)])
    }

    @Test func terminalChangeViaObserverCallbackRepositions() async throws {
        add()
        let window = try #require(fake.window("preview"))
        window.resetCalls()
        let handler = try #require(fake.terminalChangeHandlers[100])

        handler()
        for _ in 0..<5 where window.calls.isEmpty {
            await Task.yield()
        }

        #expect(window.calls.first == .updateFrame(window.frame))
    }

    @Test func terminalMoveKeepsHiddenImagesHidden() throws {
        add()
        manager.execute(.hide(BaseCommand(identifier: "preview")))
        let window = try #require(fake.window("preview"))
        window.resetCalls()
        fake.addTerminal(pid: 100, bounds: CGRect(x: 50, y: 0, width: 800, height: 480), windowNumber: 42)

        manager.handleTerminalWindowChange(pid: 100)

        #expect(window.calls == [.updateFrame(window.frame)])
        #expect(window.frame.origin.x == 50)
        #expect(!window.isVisible)
    }

    @Test func terminalMoveIgnoresOtherTerminalsAndRemovedImages() throws {
        fake.addTerminal(pid: 200, windowNumber: 43)
        add(.fixture(identifier: "other", terminalPid: 200))
        add(.fixture(identifier: "removed", terminalPid: 100))
        manager.execute(.remove(BaseCommand(identifier: "removed")))
        let other = try #require(fake.window("other"))
        let removed = try #require(fake.window("removed"))
        other.resetCalls()
        removed.resetCalls()

        manager.handleTerminalWindowChange(pid: 100)

        #expect(other.calls.isEmpty)
        #expect(removed.calls.isEmpty)
    }

    @Test func terminalGoneSkipsReposition() throws {
        add()
        let window = try #require(fake.window("preview"))
        window.resetCalls()
        fake.terminals.removeValue(forKey: 100)

        manager.handleTerminalWindowChange(pid: 100)

        #expect(window.calls.isEmpty)
    }

    // MARK: focus

    @Test func focusChangeReordersOnlyVisibleImages() throws {
        fake.addTerminal(pid: 200, windowNumber: 43)
        add(.fixture(identifier: "visible", terminalPid: 100))
        add(.fixture(identifier: "hidden", terminalPid: 200))
        manager.execute(.hide(BaseCommand(identifier: "hidden")))
        let visible = try #require(fake.window("visible"))
        let hidden = try #require(fake.window("hidden"))
        visible.resetCalls()
        hidden.resetCalls()

        let handler = try #require(fake.focusHandler)
        handler(12345)

        #expect(visible.calls == [.orderAbove(42)])
        #expect(hidden.calls.isEmpty)
    }

    // MARK: queue

    @Test func handleCommandRunsQueuedCommandsInOrder() async throws {
        manager.handleCommand(.add(.fixture()))
        manager.handleCommand(.hide(BaseCommand(identifier: "preview")))
        manager.handleCommand(.show(BaseCommand(identifier: "preview")))

        for _ in 0..<50 where (fake.window("preview")?.calls.count ?? 0) < 3 {
            try await Task.sleep(for: .milliseconds(5))
        }

        let window = try #require(fake.window("preview"))
        #expect(window.calls == [.orderAbove(42), .hide, .orderAbove(42)])
    }
}
