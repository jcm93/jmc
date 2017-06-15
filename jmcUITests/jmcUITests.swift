//
//  minimalTunesUITests.swift
//  minimalTunesUITests
//
//  Created by John Moody on 5/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import XCTest

class jmcUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let jmcWindow = XCUIApplication().windows["jmc"]
        let mainTableViewTable = jmcWindow.tables["Main Table View"]
        mainTableViewTable.children(matching: .tableRow).element(boundBy: 5).textFields["Track Name"].click()
        mainTableViewTable.children(matching: .tableRow).element(boundBy: 6).textFields["Track Name"].click()
        jmcWindow.click()
        
        let artistButton = jmcWindow.tables["Main Table View"].buttons["Artist"]
        artistButton.click()
        artistButton.click()
        artistButton.click()
        jmcWindow.click()
        
        let nsoutlineviewdisclosurebuttonkeyCell = jmcWindow.outlines["Source List Clip View"].cells.containing(.disclosureTriangle, identifier:"NSOutlineViewDisclosureButtonKey").element
        nsoutlineviewdisclosurebuttonkeyCell.click()
        nsoutlineviewdisclosurebuttonkeyCell.click()
        nsoutlineviewdisclosurebuttonkeyCell.click()
        nsoutlineviewdisclosurebuttonkeyCell.click()
        jmcWindow.click()
        
        
    }
    
}
