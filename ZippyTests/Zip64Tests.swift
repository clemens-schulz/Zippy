//
//  Zip64Tests.swift
//  Zippy
//
//  Created by Clemens on 23/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import XCTest
@testable import Zippy

class Zip64Tests: XCTestCase {

	override func setUp() {
		super.setUp()
		self.continueAfterFailure = false
	}

	override func tearDown() {
		super.tearDown()
	}

	func testFile(named name: String) {
		let zipFile: ZipFile! = TestData.openZipFile(named: name)
		do {
			let data = try zipFile.read(filename: "-")
			XCTAssert(data.count == zipFile.entries["-"]?.uncompressedSize)
		} catch {
			XCTFail("Reading data failed with error: \(error)")
		}
	}

	func testZip64File() {
		// Really small file containing >4GB of compressed data.
		self.testFile(named: "zip64.zip")
	}

	func testZip64FilePerformance() {
		self.measure {
			self.testZip64File()
		}
	}

	func testLargeFile() {
		// Large file (600MB) with bad compression ratio.
		self.testFile(named: "large.zip")
	}

	func testLargeFilePerformance() {
		self.measure {
			self.testLargeFile()
		}
	}

}
