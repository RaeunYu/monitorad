import MonitoradCore
import XCTest

/// 최대 3개·최소 1개·순서 변경·미지원 지표 처리 규칙.
final class MetricSelectionPolicyTests: XCTestCase {
    private let threeIDs = ["a", "b", "c"]
    private let fourIDs = ["a", "b", "c", "d"]

    func testFourthMetricCannotBeSelected() {
        XCTAssertFalse(
            MetricSelectionPolicy.canSelect("d", selectedIDs: threeIDs, knownMetricIDs: fourIDs)
        )
        let unchanged = MetricSelectionPolicy.toggling(
            "d",
            selectedIDs: threeIDs,
            knownMetricIDs: fourIDs
        )
        XCTAssertEqual(unchanged, threeIDs)
    }

    func testSelectionCanGrowUpToThreeMetrics() {
        var selection: [String] = []
        for id in fourIDs {
            selection = MetricSelectionPolicy.toggling(id, selectedIDs: selection, knownMetricIDs: fourIDs)
        }
        XCTAssertEqual(selection, threeIDs)
    }

    func testLastSelectedMetricCannotBeDeselected() {
        XCTAssertFalse(MetricSelectionPolicy.canDeselect("a", selectedIDs: ["a"]))
        let unchanged = MetricSelectionPolicy.toggling("a", selectedIDs: ["a"], knownMetricIDs: fourIDs)
        XCTAssertEqual(unchanged, ["a"])
    }

    func testTogglingSelectsAndDeselects() {
        let added = MetricSelectionPolicy.toggling("b", selectedIDs: ["a"], knownMetricIDs: fourIDs)
        XCTAssertEqual(added, ["a", "b"])

        let removed = MetricSelectionPolicy.toggling("a", selectedIDs: ["a", "b"], knownMetricIDs: fourIDs)
        XCTAssertEqual(removed, ["b"])
    }

    func testUnknownMetricCannotBeSelected() {
        XCTAssertFalse(
            MetricSelectionPolicy.canSelect("unknown", selectedIDs: ["a"], knownMetricIDs: fourIDs)
        )
        let unchanged = MetricSelectionPolicy.toggling(
            "unknown",
            selectedIDs: ["a"],
            knownMetricIDs: fourIDs
        )
        XCTAssertEqual(unchanged, ["a"])
    }

    func testSelectionDisabledReasonExplainsRules() {
        XCTAssertEqual(
            MetricSelectionPolicy.selectionDisabledReason(
                "d",
                selectedIDs: threeIDs,
                knownMetricIDs: fourIDs
            ),
            "최대 3개까지 표시할 수 있습니다"
        )
        XCTAssertEqual(
            MetricSelectionPolicy.selectionDisabledReason(
                "a",
                selectedIDs: ["a"],
                knownMetricIDs: fourIDs
            ),
            "최소 1개는 표시해야 합니다"
        )
        XCTAssertEqual(
            MetricSelectionPolicy.selectionDisabledReason(
                "unknown",
                selectedIDs: ["a"],
                knownMetricIDs: fourIDs
            ),
            "지원하지 않는 지표입니다"
        )
        XCTAssertNil(
            MetricSelectionPolicy.selectionDisabledReason(
                "b",
                selectedIDs: ["a"],
                knownMetricIDs: fourIDs
            )
        )
    }

    func testMovingReordersSelection() {
        let moved = MetricSelectionPolicy.moving("c", before: "a", selectedIDs: threeIDs)
        XCTAssertEqual(moved, ["c", "a", "b"])

        let middle = MetricSelectionPolicy.moving("a", before: "c", selectedIDs: threeIDs)
        XCTAssertEqual(middle, ["b", "a", "c"])
    }

    func testMovingBeforeNilMovesToEnd() {
        let moved = MetricSelectionPolicy.moving("a", before: nil, selectedIDs: threeIDs)
        XCTAssertEqual(moved, ["b", "c", "a"])
    }

    func testMovingUnknownMetricChangesNothing() {
        let moved = MetricSelectionPolicy.moving("unknown", before: "a", selectedIDs: threeIDs)
        XCTAssertEqual(moved, threeIDs)
    }

    func testMovingBeforeItselfIsNoOp() {
        XCTAssertEqual(
            MetricSelectionPolicy.moving("a", before: "a", selectedIDs: threeIDs),
            threeIDs
        )
        XCTAssertEqual(
            MetricSelectionPolicy.moving("b", before: "b", selectedIDs: threeIDs),
            threeIDs
        )
    }
}
