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

	var zipFilename: String {
		return "deflate.zip"
	}

	var zipFileForTesting: ZipFile?

	func openZipFile(named name: String) -> ZipFile? {
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: name, withExtension: nil, subdirectory: "testdata/zip/")
		XCTAssertNotNil(url, "Could not find file '\(name)'.")

		var zipFileForTesting: ZipFile? = nil
		do {
			zipFileForTesting = try ZipFile(url: url!)
		} catch {
			XCTFail("Opening '\(name)' failed with error: \(error)")
		}
		return zipFileForTesting
	}

	override func setUp() {
        super.setUp()
		self.continueAfterFailure = false
		self.zipFileForTesting = self.openZipFile(named: self.zipFilename)
    }
    
    override func tearDown() {
		self.zipFileForTesting = nil
        super.tearDown()
    }

	func readUncompressedFile(named name: String) -> Data? {
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: name, withExtension: nil, subdirectory: "testdata/uncompressed/")
		XCTAssertNotNil(url, "Could not find file '\(name)'.")

		var data: Data? = nil
		do {
			data = try Data(contentsOf: url!)
		} catch {
			XCTFail("Reading '\(name)' failed with error: \(error)")
		}
		return data
	}
    
	func testFilenames() {
		let zipFile = self.zipFileForTesting!
		XCTAssertNotNil(zipFile)

		let filenames = zipFile.filenames

		for i in 1...500 {
			let expectedFilename = "file_\(i).txt"
			XCTAssert(filenames.contains(expectedFilename), "'\(self.zipFilename)' is missing file '\(expectedFilename)'")
		}
		XCTAssert(filenames.contains("filename_length_and_encoding_test äöüßÄÖÜ^°!§$%&()=?#+-;:,.あうえいおコンピュータ　日本語 한국어 普通话 العَرَبِيَّة ру́сский язы́к le français [lə fʁɑ̃sɛ].txt"), "'\(self.zipFilename)' failed filename encoding test.")
		XCTAssert(filenames.count == 501, "'\(self.zipFilename)' contains unexpected files.")
    }

	func testRead() {
		let zipFile = self.zipFileForTesting!
		XCTAssertNotNil(zipFile)

		for oneFilename in zipFile {
			let expectedData = self.readUncompressedFile(named: oneFilename)
			XCTAssertNotNil(expectedData, "Failed to read uncompressed test data for file '\(oneFilename)'.")

			let data = zipFile[oneFilename]
			XCTAssert(data == expectedData, "Data for '\(oneFilename)' in '\(self.zipFilename)' does not match original data.")
		}
	}

	func testNotExistingFiles() {
		let zipFile = self.zipFileForTesting!
		XCTAssertNotNil(zipFile)

		let filename = "does not exist.txt"
		XCTAssert(zipFile[filename] == nil, "Data for not existing '\(filename)' in '\(self.zipFilename)' returned.")

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
				XCTFail("Filenames returned by iterator are different from filenames array for '\(self.zipFilename)'")
			}

			// Compare data returned by read(filename:) and subscript
			let dataReadMethod = try? zipFile.read(filename: filename)
			let dataSubscript = zipFile[filename]

			XCTAssert(dataReadMethod == dataSubscript, "Subscript returns different data than read(filename:) for '\(self.zipFilename)'")
		}

		XCTAssert(filenames.count == 0, "Iterator did not return all filenames for '\(self.zipFilename)'")
	}

	func testPerformance() {
		self.measure {
			self.testRead()
		}
	}

}
