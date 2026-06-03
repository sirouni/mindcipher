import XCTest

final class CodeBreakerUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-hasSeenTutorial", "YES"]
        app.launch()
    }

    // MARK: - Home Screen

    func testHomeScreenShowsAllMenuItems() {
        XCTAssertTrue(app.staticTexts["Code Breaker"].exists)
        XCTAssertTrue(app.staticTexts["Daily Challenge"].exists)
        XCTAssertTrue(app.staticTexts["Classic Missions"].exists)
        XCTAssertTrue(app.staticTexts["Lie Missions"].exists)
        XCTAssertTrue(app.staticTexts["Free Play"].exists)
        XCTAssertTrue(app.staticTexts["Duel Mode"].exists)
        XCTAssertTrue(app.staticTexts["Custom Level"].exists)
        XCTAssertTrue(app.staticTexts["Achievements"].exists)
    }

    func testHomeScreenShowsStats() {
        XCTAssertTrue(app.staticTexts["Games"].exists)
        XCTAssertTrue(app.staticTexts["Win%"].exists)
        XCTAssertTrue(app.staticTexts["Streak"].exists)
        XCTAssertTrue(app.staticTexts["Stars"].exists)
    }

    func testSettingsButtonExists() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gearshape'")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
    }

    func testHelpButtonExists() {
        let helpButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'questionmark'")).firstMatch
        XCTAssertTrue(helpButton.waitForExistence(timeout: 3))
    }

    // MARK: - Tutorial

    func testTutorialAutoShowsOnFirstLaunch() {
        let freshApp = XCUIApplication()
        freshApp.launchArguments += ["-hasSeenTutorial", "NO"]
        freshApp.launch()
        XCTAssertTrue(freshApp.staticTexts["Crack the Code"].waitForExistence(timeout: 5))
    }

    func testTutorialNavigation() {
        let helpButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'questionmark'")).firstMatch
        helpButton.tap()
        XCTAssertTrue(app.staticTexts["Crack the Code"].waitForExistence(timeout: 3))

        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3))
        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Pick Colors"].waitForExistence(timeout: 3))

        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Read the Clues"].waitForExistence(timeout: 3))

        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Lie Mode"].waitForExistence(timeout: 3))

        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Tips"].waitForExistence(timeout: 3))

        let startButton = app.buttons["Start!"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
    }

    // MARK: - Classic Missions

    func testClassicMissionsNavigation() {
        app.staticTexts["Classic Missions"].tap()
        XCTAssertTrue(app.navigationBars["Classic Missions"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["1"].waitForExistence(timeout: 3))
    }

    func testClassicMissionsLevelPreview() {
        app.staticTexts["Classic Missions"].tap()
        _ = app.staticTexts["1"].waitForExistence(timeout: 3)
        app.staticTexts["1"].tap()
        XCTAssertTrue(app.staticTexts["Level 1"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Code length"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 3))
    }

    func testClassicMissionsStartGame() {
        app.staticTexts["Classic Missions"].tap()
        _ = app.staticTexts["1"].waitForExistence(timeout: 3)
        app.staticTexts["1"].tap()
        _ = app.buttons["Start"].waitForExistence(timeout: 3)
        app.buttons["Start"].tap()
        XCTAssertTrue(app.staticTexts["Level 1"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["left"].waitForExistence(timeout: 3))
    }

    // MARK: - Free Play

    func testFreePlaySetup() {
        app.staticTexts["Free Play"].tap()
        _ = app.staticTexts["Free Play"].waitForExistence(timeout: 3)

        for diff in ["Beginner", "Easy", "Medium", "Hard", "Expert", "Master"] {
            XCTAssertTrue(app.staticTexts[diff].exists, "Difficulty \(diff) not found")
        }

        XCTAssertTrue(app.staticTexts["Code length"].exists)
        XCTAssertTrue(app.staticTexts["Colors"].exists)
        XCTAssertTrue(app.staticTexts["Max attempts"].exists)
    }

    func testFreePlayDifficultySelection() {
        app.staticTexts["Free Play"].tap()
        _ = app.staticTexts["Beginner"].waitForExistence(timeout: 3)

        app.staticTexts["Hard"].tap()
        XCTAssertTrue(app.staticTexts["5"].exists || app.staticTexts["6"].exists)
    }

    func testFreePlayStartGame() {
        app.staticTexts["Free Play"].tap()
        _ = app.staticTexts["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        XCTAssertTrue(app.staticTexts["left"].waitForExistence(timeout: 3))
    }

    // MARK: - Game Play

    func testGamePlayColorSelection() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 3)

        let slot1 = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Slot 1'")).firstMatch
        XCTAssertTrue(slot1.waitForExistence(timeout: 3))
    }

    func testGamePlaySubmitButton() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        XCTAssertTrue(app.buttons["Submit"].waitForExistence(timeout: 3))
    }

    func testGamePlayResetButton() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()

        let resetButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'counterclockwise'")).firstMatch
        XCTAssertTrue(resetButton.waitForExistence(timeout: 3))
    }

    func testGamePlayShareButton() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()

        let shareButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'arrow.up'")).firstMatch
        XCTAssertTrue(shareButton.waitForExistence(timeout: 3))
    }

    func testGamePlayBackButton() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()

        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'chevron'")).firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))
        backButton.tap()
        XCTAssertTrue(app.staticTexts["Code Breaker"].waitForExistence(timeout: 5))
    }

    func testGamePlayFeedbackLegend() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()

        XCTAssertTrue(app.staticTexts["= One right color in the right position"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["= One right color but in the wrong position"].exists)
        XCTAssertTrue(app.staticTexts["= One color is not in the secret code"].exists)
    }

    // MARK: - Duel Mode

    func testDuelModeSetup() {
        app.staticTexts["Duel Mode"].tap()
        XCTAssertTrue(app.staticTexts["Duel Mode"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["One sets code, one cracks it"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Rules"].waitForExistence(timeout: 3))
    }

    func testDuelModeDifficultySelection() {
        app.staticTexts["Duel Mode"].tap()
        _ = app.staticTexts["Beginner"].waitForExistence(timeout: 3)

        for diff in ["Beginner", "Easy", "Medium", "Hard", "Expert", "Master"] {
            XCTAssertTrue(app.staticTexts[diff].exists, "Duel difficulty \(diff) not found")
        }
    }

    // MARK: - Lie Missions

    func testLieMissionsNavigation() {
        app.staticTexts["Lie Missions"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
    }

    // MARK: - Daily Challenge

    func testDailyChallengeNavigation() {
        app.staticTexts["Daily Challenge"].tap()
        XCTAssertTrue(app.staticTexts["Daily Challenge"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Code length"].waitForExistence(timeout: 3))
    }

    // MARK: - Custom Level

    func testCustomLevelNavigation() {
        app.staticTexts["Custom Level"].tap()
        XCTAssertTrue(app.navigationBars["Custom Level"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Build your own challenge"].waitForExistence(timeout: 3))
    }

    func testCustomLevelParameters() {
        app.staticTexts["Custom Level"].tap()
        _ = app.navigationBars["Custom Level"].waitForExistence(timeout: 3)

        XCTAssertTrue(app.staticTexts["Allow repeat colors"].exists)
        XCTAssertTrue(app.staticTexts["Difficulty"].exists)
        XCTAssertTrue(app.staticTexts["Colors"].exists)
    }

    func testCustomLevelStartGame() {
        app.staticTexts["Custom Level"].tap()
        _ = app.buttons["Start Custom Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Custom Challenge"].tap()
        XCTAssertTrue(app.staticTexts["left"].waitForExistence(timeout: 3))
    }

    // MARK: - Achievements

    func testAchievementsNavigation() {
        app.staticTexts["Achievements"].tap()
        XCTAssertTrue(app.navigationBars["Achievements"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Unlocked"].waitForExistence(timeout: 3))
    }

    func testAchievementsCategories() {
        app.staticTexts["Achievements"].tap()
        _ = app.navigationBars["Achievements"].waitForExistence(timeout: 3)

        XCTAssertTrue(app.staticTexts["GETTING STARTED"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["First Crack"].exists)
    }

    func testAchievementsProgressBar() {
        app.staticTexts["Achievements"].tap()
        _ = app.navigationBars["Achievements"].waitForExistence(timeout: 3)
        XCTAssertTrue(app.staticTexts["Unlocked"].exists)
    }

    // MARK: - Settings

    func testSettingsNavigation() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gearshape'")).firstMatch
        settingsButton.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }

    func testSettingsToggles() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gearshape'")).firstMatch
        settingsButton.tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)

        XCTAssertTrue(app.staticTexts["Sound"].exists)
        XCTAssertTrue(app.staticTexts["Haptics"].exists)
        XCTAssertTrue(app.staticTexts["Colorblind"].exists)
    }

    func testSettingsStats() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gearshape'")).firstMatch
        settingsButton.tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)

        XCTAssertTrue(app.staticTexts["Games"].exists)
        XCTAssertTrue(app.staticTexts["Wins"].exists)
        XCTAssertTrue(app.staticTexts["Win%"].exists)
        XCTAssertTrue(app.staticTexts["Best streak"].exists)
    }

    func testSettingsManageSection() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gearshape'")).firstMatch
        settingsButton.tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Reset Stats"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Reset All Progress"].exists)
    }

    func testSettingsAbout() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gearshape'")).firstMatch
        settingsButton.tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Version"].waitForExistence(timeout: 3))
    }

    // MARK: - Lie Mode (Free Play)

    func testLieModeToggleInFreePlay() {
        app.staticTexts["Free Play"].tap()
        _ = app.staticTexts["Lie Mode"].waitForExistence(timeout: 3)
        XCTAssertTrue(app.staticTexts["1 fake feedback"].exists)
    }

    // MARK: - Level Grid Layout

    func testLevelGridShowsAllLevels() {
        app.staticTexts["Classic Missions"].tap()
        _ = app.staticTexts["1"].waitForExistence(timeout: 3)

        for i in 1...20 {
            XCTAssertTrue(app.staticTexts["\(i)"].exists, "Level \(i) not found in grid")
        }
    }

    func testLevelGridTierSwitcher() {
        app.staticTexts["Classic Missions"].tap()
        _ = app.staticTexts["1"].waitForExistence(timeout: 3)

        let rightChevron = app.buttons.matching(NSPredicate(format: "label CONTAINS 'chevron.right'")).firstMatch
        XCTAssertTrue(rightChevron.exists)
    }
}
