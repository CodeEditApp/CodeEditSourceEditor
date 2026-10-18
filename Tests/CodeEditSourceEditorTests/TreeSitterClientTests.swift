import XCTest
import CodeEditTextView
import SwiftTreeSitter
@testable import CodeEditSourceEditor

// swiftlint:disable all

/// Holds a ``TreeSitterExecutor``'s async operations at their start until opened (see
/// ``TreeSitterExecutor/asyncStartGate``), so operations a test cancels are still pending when it does.
private final class ExecutorGate: @unchecked Sendable {
    private let lock = NSLock()
    private var isOpen = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func hold(_ client: TreeSitterClient) {
        client.executor.asyncStartGate = { [self] in await wait() }
    }

    func wait() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            if isOpen {
                lock.unlock()
                continuation.resume()
            } else {
                waiting.append(continuation)
                lock.unlock()
            }
        }
    }

    func open() {
        lock.lock()
        isOpen = true
        let continuations = waiting
        waiting = []
        lock.unlock()
        continuations.forEach { $0.resume() }
    }
}

final class TreeSitterClientTests: XCTestCase {

    private var maxSyncContentLength: Int = 0

    override func setUp() {
        maxSyncContentLength = TreeSitterClient.Constants.maxSyncContentLength
        TreeSitterClient.Constants.maxSyncContentLength = 0
    }

    override func tearDown() {
        TreeSitterClient.Constants.maxSyncContentLength = maxSyncContentLength
    }

    @MainActor
    func performEdit(
        textView: TextView,
        client: TreeSitterClient,
        string: String,
        range: NSRange,
        completion: @escaping (Result<IndexSet, Error>) -> Void
    ) {
        let delta = string.isEmpty ? -range.length : range.length
        textView.replaceString(in: range, with: string)
        client.applyEdit(textView: textView, range: range, delta: delta, completion: completion)
    }

    @MainActor 
    func test_clientSetup() async {
        let client = Mock.treeSitterClient()
        let textView = Mock.textView()
        client.setUp(textView: textView, codeLanguage: .swift)

        let expectation = XCTestExpectation(description: "Setup occurs")

        Task.detached {
            while client.state == nil {
                try await Task.sleep(for: .seconds(0.5))
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)

        let primaryLanguage = client.state?.primaryLayer.id
        let layerCount = client.state?.layers.count
        XCTAssertEqual(primaryLanguage, .swift, "Client set up incorrect language")
        XCTAssertEqual(layerCount, 1, "Client set up too many layers")
    }

    /// Edits to documents over `maxSyncContentLength` run on the executor's thread (`setUp` makes every document
    /// count as long); their completion must still be delivered on the main thread.
    @MainActor
    func test_asyncEditCompletionRunsOnMainThread() async {
        let client = Mock.treeSitterClient()
        let textView = Mock.textView()
        client.setUp(textView: textView, codeLanguage: .swift)

        let setUp = XCTestExpectation(description: "Setup occurs")
        Task.detached {
            while client.state == nil {
                try await Task.sleep(for: .seconds(0.1))
            }
            setUp.fulfill()
        }
        await fulfillment(of: [setUp], timeout: 5.0)

        let completed = XCTestExpectation(description: "Edit completes on the main thread")
        performEdit(textView: textView, client: client, string: "1", range: NSRange(location: 0, length: 0)) { result in
            XCTAssertTrue(Thread.isMainThread, "applyEdit's completion ran off the main thread")
            if case .failure(let error) = result {
                XCTFail("Edit failed: \(error)")
            }
            completed.fulfill()
        }
        await fulfillment(of: [completed], timeout: 5.0)
    }

    /// Asynchronous edits parse from a text snapshot, so they finish while the main thread is blocked.
    @MainActor
    func test_asyncEditFinishesWhileTheMainThreadIsBlocked() throws {
        let client = Mock.treeSitterClient()
        let textView = Mock.textView()
        client.setUp(textView: textView, codeLanguage: .swift)
        let stateBefore = try XCTUnwrap(client.state, "small documents are parsed during setUp")

        let insertion = "let value = 1\n"
        let length = (insertion as NSString).length
        client.willApplyEdit(textView: textView, range: NSRange(location: 0, length: 0))
        textView.replaceString(in: NSRange(location: 0, length: 0), with: insertion)
        client.applyEdit(textView: textView, range: NSRange(location: 0, length: length), delta: length) { _ in }

        // Block the main thread (no run loop, no main queue) until the edit commits its new state.
        let deadline = Date().addingTimeInterval(10)
        while client.state === stateBefore && Date() < deadline {
            usleep(1_000)
        }
        XCTAssertFalse(client.state === stateBefore, "the edit did not finish without the main thread")

        let fresh = Mock.treeSitterClient()
        fresh.setUp(textView: TextView(string: textView.string), codeLanguage: .swift)
        XCTAssertNotNil(primaryTree(client))
        XCTAssertEqual(primaryTree(client), primaryTree(fresh))
    }

    /// The primary language layer's syntax tree as an S-expression.
    func primaryTree(_ client: TreeSitterClient) -> String? {
        guard let state = client.state else { return nil }
        return state.layers.first { $0.id == state.primaryLayer.id }?.tree?.rootNode?.sExpressionString
    }

    func resultIsCancel<T>(_ result: Result<T, Error>) -> Bool {
        if case let .failure(error) = result {
            if case HighlightProvidingError.operationCancelled = error {
                return true
            }
        }
        return false
    }

    @MainActor
    func test_editsDuringSetup() {
        let client = Mock.treeSitterClient()
        let textView = Mock.textView()
        let gate = ExecutorGate()
        gate.hold(client)

        client.setUp(textView: textView, codeLanguage: .swift)

        // Perform a highlight query
        let cancelledQuery = XCTestExpectation(description: "Highlight query should be cancelled by edits.")
        client.queryHighlightsFor(textView: textView, range: NSRange(location: 0, length: 10)) { result in
            if self.resultIsCancel(result) {
                cancelledQuery.fulfill()
            } else {
                XCTFail("Highlight query was not cancelled.")
            }
        }

        // Perform an edit
        let cancelledEdit = XCTestExpectation(description: "First edit should be cancelled by second one.")
        performEdit(textView: textView, client: client, string: "func ", range: .zero) { result in
            if self.resultIsCancel(result) {
                cancelledEdit.fulfill()
            } else {
                XCTFail("Edit was not cancelled.")
            }
        }

        // Perform a second edit
        let successEdit = XCTestExpectation(description: "Second edit should succeed.")
        performEdit(textView: textView, client: client, string: "", range: NSRange(location: 0, length: 5)) { result in
            if case let .success(ranges) = result {
                XCTAssertEqual(ranges.count, 0, "Edits, when combined, should produce the original syntax tree.")
                successEdit.fulfill()
            } else {
                XCTFail("Second edit was not successful.")
            }
        }

        // Every cancellation has been issued; let the queued operations run.
        gate.open()
        wait(for: [cancelledQuery, cancelledEdit, successEdit], timeout: 5.0)
    }

    @MainActor
    func test_multipleSetupsCancelAllOperations() async {
        let client = Mock.treeSitterClient()
        let textView = Mock.textView()
        let gate = ExecutorGate()
        gate.hold(client)

        // First setup, wrong language
        client.setUp(textView: textView, codeLanguage: .c)

        // Perform a highlight query
        let cancelledQuery = XCTestExpectation(description: "Highlight query should be cancelled by second setup.")
        client.queryHighlightsFor(textView: textView, range: NSRange(location: 0, length: 10)) { result in
            if self.resultIsCancel(result) {
                cancelledQuery.fulfill()
            } else {
                XCTFail("Highlight query was not cancelled by the second setup.")
            }
        }

        // Perform an edit
        let cancelledEdit = XCTestExpectation(description: "First edit should be cancelled by second setup.")
        performEdit(textView: textView, client: client, string: "func ", range: .zero) { result in
            if self.resultIsCancel(result) {
                cancelledEdit.fulfill()
            } else {
                XCTFail("Edit was not cancelled by the second setup.")
            }
        }

        // Second setup, which should cancel all previous operations
        client.setUp(textView: textView, codeLanguage: .swift)
        gate.open()

        let finalSetupExpectation = XCTestExpectation(description: "Final setup should complete successfully.")

        Task.detached {
            while client.state?.primaryLayer.id != .swift {
                try await Task.sleep(for: .seconds(0.5))
            }
            finalSetupExpectation.fulfill()
        }

        await fulfillment(of: [cancelledQuery, cancelledEdit, finalSetupExpectation], timeout: 5.0)

        // Ensure only the final setup's language is active
        let primaryLanguage = client.state?.primaryLayer.id
        let layerCount = client.state?.layers.count
        XCTAssertEqual(primaryLanguage, .swift, "Client set up incorrect language after re-setup.")
        XCTAssertEqual(layerCount, 1, "Client set up too many layers after re-setup.")
    }

    @MainActor
    func test_cancelAllEditsUntilFinalOne() {
        let client = Mock.treeSitterClient()
        let textView = Mock.textView()
        textView.setText("asadajkfijio;amfjamc;aoijaoajkvarpfjo;sdjlkj")
        let gate = ExecutorGate()
        gate.hold(client)

        client.setUp(textView: textView, codeLanguage: .swift)

        // Set up random edits
        let editExpectations = (0..<10).map { index -> XCTestExpectation in
            let expectation = XCTestExpectation(description: "Edit \(index) should be cancelled.")
            let isDeletion = Int.random(in: 0..<10) < 4
            let editText = isDeletion ? "" : "\(index)"
            let editLocation = Int.random(in: 0..<textView.string.count)
            let editRange = if isDeletion {
                NSRange(location: editLocation, length: 1)
            } else {
                NSRange(location: editLocation, length: 0)
            }
            performEdit(textView: textView, client: client, string: editText, range: editRange) { result in
                if self.resultIsCancel(result) {
                    expectation.fulfill()
                } else {
                    XCTFail("Edit \(index) was not cancelled.")
                }
            }
            return expectation
        }

        // Final edit that should succeed
        let finalEditExpectation = XCTestExpectation(description: "Final edit should succeed.")
        performEdit(textView: textView, client: client, string: "", range: textView.documentRange) { result in
            if case .success(_) = result {
                finalEditExpectation.fulfill()
            } else {
                XCTFail("Final edit did not succeed.")
            }
        }

        gate.open()
        wait(for: editExpectations + [finalEditExpectation], timeout: 5.0)
    }
}
// swiftlint:enable all
