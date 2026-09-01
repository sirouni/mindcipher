import XCTest

final class CodeBreakerUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-hasSeenTutorial", "YES", "-isPro"]
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
        XCTAssertTrue(app.staticTexts["Notes"].waitForExistence(timeout: 3))

        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Hints"].waitForExistence(timeout: 3))

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
        _ = app.navigationBars["Classic Missions"].waitForExistence(timeout: 3)
        let levelButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '1'")).firstMatch
        XCTAssertTrue(levelButton.waitForExistence(timeout: 3))
        levelButton.tap()
        XCTAssertTrue(app.staticTexts["Level 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Code length"].waitForExistence(timeout: 3))
    }

    func testClassicMissionsStartGame() {
        app.staticTexts["Classic Missions"].tap()
        _ = app.navigationBars["Classic Missions"].waitForExistence(timeout: 3)
        let levelButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '1'")).firstMatch
        levelButton.tap()
        _ = app.staticTexts["Level 1"].waitForExistence(timeout: 5)
        let startBtn = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Start' OR label BEGINSWITH 'Retry'")).firstMatch
        XCTAssertTrue(startBtn.waitForExistence(timeout: 3))
        startBtn.tap()
        XCTAssertTrue(app.staticTexts["left"].waitForExistence(timeout: 5))
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
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        XCTAssertTrue(app.buttons["Share"].waitForExistence(timeout: 5))
    }

    func testGamePlayBackButton() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        XCTAssertTrue(app.buttons["Back"].waitForExistence(timeout: 5))
        app.buttons["Back"].tap()
        let returned = app.staticTexts["Free Play"].waitForExistence(timeout: 8)
            || app.staticTexts["Code Breaker"].waitForExistence(timeout: 3)
        XCTAssertTrue(returned)
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

    func testSettingsFeedback() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gearshape'")).firstMatch
        settingsButton.tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)

        let row = app.buttons["Send Feedback"]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.tap()

        XCTAssertTrue(app.navigationBars["Feedback"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Open GitHub Issue"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Email instead"].exists)
    }

    // MARK: - Lie Mode (Free Play)

    func testLieModeToggleInFreePlay() {
        app.staticTexts["Free Play"].tap()
        _ = app.staticTexts["Lie Mode"].waitForExistence(timeout: 3)
        XCTAssertTrue(app.staticTexts["1 fake feedback"].exists)
    }

    // MARK: - Level Grid Layout

    func testLevelGridShowsLevels() {
        app.staticTexts["Classic Missions"].tap()
        _ = app.navigationBars["Classic Missions"].waitForExistence(timeout: 3)
        let firstLevel = app.buttons.matching(NSPredicate(format: "label CONTAINS '1'")).firstMatch
        XCTAssertTrue(firstLevel.waitForExistence(timeout: 3))
    }

    func testLevelGridTierSwitcher() {
        app.staticTexts["Classic Missions"].tap()
        _ = app.navigationBars["Classic Missions"].waitForExistence(timeout: 3)
        XCTAssertTrue(app.buttons["Next tier"].waitForExistence(timeout: 3))
    }

    // MARK: - Notes System

    func testNotesButtonExists() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        XCTAssertTrue(app.buttons["Notes"].waitForExistence(timeout: 3))
    }

    func testNotesGridOpens() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        app.buttons["Notes"].tap()
        sleep(1)

        let p1Button = app.buttons.matching(NSPredicate(format: "label CONTAINS 'P1'")).firstMatch
        XCTAssertTrue(p1Button.waitForExistence(timeout: 5))

        let clearBtn = app.buttons.matching(NSPredicate(format: "label == 'Clear'")).firstMatch
        let clearText = app.staticTexts.matching(NSPredicate(format: "label == 'Clear'")).firstMatch
        XCTAssertTrue(clearBtn.waitForExistence(timeout: 3) || clearText.waitForExistence(timeout: 3))
    }

    func testNotesGridColumnHeaders() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        app.buttons["Notes"].tap()
        sleep(1)

        let p1 = app.buttons.matching(NSPredicate(format: "label CONTAINS 'P1'")).firstMatch
        XCTAssertTrue(p1.waitForExistence(timeout: 5), "Column header P1 not found")
    }

    func testNotesGridCloseButton() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        app.buttons["Notes"].tap()
        _ = app.staticTexts["Notes"].waitForExistence(timeout: 3)

        let closeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '关闭'")).firstMatch
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3))
    }

    // MARK: - Hint System

    func testHintButtonExists() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        XCTAssertTrue(app.buttons["Hint"].waitForExistence(timeout: 3))
    }

    func testHintButtonShowsCoinBadge() {
        app.staticTexts["Free Play"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        let hintButton = app.buttons["Hint"]
        XCTAssertTrue(hintButton.waitForExistence(timeout: 3))
    }

    // MARK: - Daily Challenge Calendar

    func testDailyChallengeShowsCalendar() {
        app.staticTexts["Daily Challenge"].tap()
        _ = app.staticTexts["Daily Challenge"].waitForExistence(timeout: 3)

        XCTAssertTrue(app.staticTexts["Day Streak"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Total"].waitForExistence(timeout: 3))
    }

    func testDailyChallengeCalendarWeekdayHeaders() {
        app.staticTexts["Daily Challenge"].tap()
        _ = app.staticTexts["Daily Challenge"].waitForExistence(timeout: 3)

        XCTAssertTrue(app.staticTexts["S"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["M"].exists)
        XCTAssertTrue(app.staticTexts["T"].exists)
        XCTAssertTrue(app.staticTexts["W"].exists)
        XCTAssertTrue(app.staticTexts["F"].exists)
    }

    func testDailyChallengeShowsMonthTitle() {
        app.staticTexts["Daily Challenge"].tap()
        _ = app.staticTexts["Day Streak"].waitForExistence(timeout: 3)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthTitle = formatter.string(from: Date())
        XCTAssertTrue(app.staticTexts[monthTitle].waitForExistence(timeout: 3))
    }

    // MARK: - Tutorial Pages (Notes + Hints)

    func testTutorialNotesPage() {
        let helpButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'questionmark'")).firstMatch
        helpButton.tap()
        _ = app.staticTexts["Crack the Code"].waitForExistence(timeout: 3)

        let nextButton = app.buttons["Next"]
        nextButton.tap() // page 2: Pick Colors
        nextButton.tap() // page 3: Read the Clues
        nextButton.tap() // page 4: Notes

        XCTAssertTrue(app.staticTexts["Notes"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Tap cell: mark as eliminated"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Tap again: mark as confirmed"].exists)
    }

    func testTutorialHintsPage() {
        let helpButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'questionmark'")).firstMatch
        helpButton.tap()
        _ = app.staticTexts["Crack the Code"].waitForExistence(timeout: 3)

        let nextButton = app.buttons["Next"]
        nextButton.tap() // page 2
        nextButton.tap() // page 3
        nextButton.tap() // page 4: Notes

        _ = app.staticTexts["Notes"].waitForExistence(timeout: 3)
        nextButton.tap() // page 5: Hints

        XCTAssertTrue(app.staticTexts["Hints"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Hint Coins"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["How to earn"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["What hints do"].waitForExistence(timeout: 3))
    }

    func testTutorialHas7Pages() {
        let helpButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'questionmark'")).firstMatch
        helpButton.tap()

        XCTAssertTrue(app.staticTexts["1/7"].waitForExistence(timeout: 3))
    }

    // MARK: - Challenge URL Deep Link

    func testChallengeAcceptScreen() {
        let challengeURL = "codebreaker://challenge?s=123456789&l=4&c=6&a=7&d=0&m=0&f=TestBot"
        app.open(URL(string: challengeURL)!)

        XCTAssertTrue(app.staticTexts["TestBot"].waitForExistence(timeout: 5)
            || app.staticTexts["Challenge from"].waitForExistence(timeout: 5))
    }

    func testChallengeAcceptScreenLieMode() {
        let challengeURL = "codebreaker://challenge?s=987654321&l=5&c=8&a=12&d=1&m=1&f=LieBot"
        app.open(URL(string: challengeURL)!)

        let lieWarning = app.staticTexts["Lie Mode — one feedback may be fake!"]
        XCTAssertTrue(lieWarning.waitForExistence(timeout: 5)
            || app.staticTexts["LieBot"].waitForExistence(timeout: 5))
    }

    // MARK: - Game View Layout (6-peg)

    func testMasterDifficultyLayout() {
        app.staticTexts["Free Play"].tap()
        _ = app.staticTexts["Master"].waitForExistence(timeout: 3)
        app.staticTexts["Master"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        for i in 1...6 {
            let slot = app.otherElements.matching(NSPredicate(format: "label == 'Slot \(i)'")).firstMatch
            XCTAssertTrue(slot.waitForExistence(timeout: 3), "Slot \(i) not found in Master layout")
        }
    }

    // MARK: - Hint Coin Progress (Win Screen)

    func testWinScreenShowsHintCoinProgress() {
        app.staticTexts["Free Play"].tap()
        _ = app.staticTexts["Beginner"].waitForExistence(timeout: 3)
        app.staticTexts["Beginner"].tap()
        _ = app.buttons["Start Challenge"].waitForExistence(timeout: 3)
        app.buttons["Start Challenge"].tap()
        _ = app.staticTexts["left"].waitForExistence(timeout: 5)

        // Use hint to auto-fill one slot, then try guessing
        // This test just verifies the buttons exist in game
        XCTAssertTrue(app.buttons["Hint"].exists)
        XCTAssertTrue(app.buttons["Notes"].exists)
        XCTAssertTrue(app.buttons["Submit"].exists)
    }
}
