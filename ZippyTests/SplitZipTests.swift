//
//  SplitZipTests.swift
//  Zippy
//
//  Created by Clemens on 23/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import XCTest
@testable import Zippy

class SplitZipTests: ZipTests {

	override func loadTestData() {
		let name = "split"
		let numberOfSegments = 8

		let testBundle = Bundle(for: type(of: self))
		var urls = [URL]()

		for i in 1...numberOfSegments {
			let ext: String
			if i == numberOfSegments {
				ext = "zip"
			} else {
				ext = String(format: "z%02d", i)
			}

			let url = testBundle.url(forResource: name, withExtension: ext, subdirectory: "testdata/zip/")
			XCTAssertNotNil(url, "Could not find file '\(name)'.")

			if url != nil {
				urls.append(url!)
			}
		}

		var zipFileForTesting: ZipFile? = nil
		do {
			zipFileForTesting = try ZipFile(segmentURLs: urls)
		} catch {
			XCTFail("Opening '\(name)' failed with error: \(error)")
		}
		self.zipFileForTesting = zipFileForTesting
	}

	override func testFilenames() {
		super.testFilenames()
	}

	override func testRead() {
		super.testRead()
	}

	override func testNotExistingFiles() {
		super.testNotExistingFiles()
	}

	override func testIteratorAndSubscript() {
		super.testIteratorAndSubscript()
	}

	override func testPerformance() {
		super.testPerformance()
	}
    
}
