//
//  ZipTests.swift
//  ZippyTests
//
//  Created by Clemens on 02/12/2016.
//  Copyright © 2016 Clemens Schulz. All rights reserved.
//

import XCTest
@testable import Zippy

class ZipTests: XCTestCase {

	var zipFileForTesting: ZipFile?

	override func setUp() {
        super.setUp()
		self.continueAfterFailure = false
		self.loadTestData()
    }
    
    override func tearDown() {
		self.zipFileForTesting = nil
        super.tearDown()
    }

	func loadTestData() {
		self.zipFileForTesting = TestData.openZipFile(named: "deflate.zip")
	}
    
	func testFilenames() {
		let zipFile = self.zipFileForTesting!
		XCTAssertNotNil(zipFile)

		let filenames = zipFile.filenames

		for i in 1...500 {
			let expectedFilename = "file_\(i).txt"
			XCTAssert(filenames.contains(expectedFilename), "Archive is missing file '\(expectedFilename)'")
		}
		XCTAssert(filenames.contains("filename_length_and_encoding_test äöüßÄÖÜ^°!§$%&()=?#+-;:,.あうえいおコンピュータ　日本語 한국어 普通话 العَرَبِيَّة ру́сский язы́к le français [lə fʁɑ̃sɛ].txt"), "'Archive failed filename encoding test")
		XCTAssert(filenames.count == 501, "Archive contains unexpected files.")
    }

	func testRead() {
		let zipFile = self.zipFileForTesting!
		XCTAssertNotNil(zipFile)

		for oneFilename in zipFile {
			let expectedData = TestData.readUncompressedFile(named: oneFilename)
			XCTAssertNotNil(expectedData, "Failed to read uncompressed test data for file '\(oneFilename)'.")

			let data = zipFile[oneFilename]
			XCTAssert(data == expectedData, "Data for '\(oneFilename)' does not match original data.")
		}
	}

	func testNotExistingFiles() {
		let zipFile = self.zipFileForTesting!
		XCTAssertNotNil(zipFile)

		let filename = "does not exist.txt"
		XCTAssertNil(zipFile[filename], "Data for not existing '\(filename)' returned.")

		do {
			_ = try zipFile.read(filename: filename)
			XCTFail("Expected error not thrown")
		} catch {
			XCTAssert((error as? FileError) == FileError.doesNotExist, "Unexpected error thrown")
		}
	}

	func testIteratorAndSubscript() {
		let zipFile = self.zipFileForTesting!
		XCTAssertNotNil(zipFile)

		var filenames = zipFile.filenames

		for filename in zipFile {
			// Test if filename is in filenames array
			if let index = filenames.index(of: filename) {
				filenames.remove(at: index)
			} else {
				XCTFail("Filenames returned by iterator are different from filenames array")
			}

			// Compare data returned by read(filename:) and subscript
			let dataReadMethod = try? zipFile.read(filename: filename)
			let dataSubscript = zipFile[filename]

			XCTAssert(dataReadMethod == dataSubscript, "Subscript returns different data than read(filename:)")
		}

		XCTAssert(filenames.count == 0, "Iterator did not return all filenames")
	}

	func testPerformance() {
		self.measure {
			self.testRead()
		}
	}

}
