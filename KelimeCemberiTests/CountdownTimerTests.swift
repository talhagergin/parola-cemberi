import XCTest
@testable import KelimeCemberi

final class CountdownTimerTests: XCTestCase {
    func testPausePreventsCountdown() async {
        let timer = CountdownTimer(durationSeconds: 3)
        await timer.start()
        await timer.advanceOneSecond()
        await timer.pause()
        await timer.advanceOneSecond()
        let remaining = await timer.remainingSeconds
        XCTAssertEqual(remaining, 2)
    }

    func testTimerFinishesAtZero() async {
        let timer = CountdownTimer(durationSeconds: 1)
        await timer.start()
        await timer.advanceOneSecond()
        let remaining = await timer.remainingSeconds
        let state = await timer.state
        XCTAssertEqual(remaining, 0)
        guard case .finished = state else { return XCTFail("Timer bitmiş olmalı") }
    }
}
