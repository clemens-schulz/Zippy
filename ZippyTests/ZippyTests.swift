//
//  ZippyTests.swift
//  ZippyTests
//
//  Created by Clemens on 02/12/2016.
//  Copyright © 2016 Clemens Schulz. All rights reserved.
//

import XCTest
@testable import Zippy

class ZippyTests: XCTestCase {

	override func setUp() {
        super.setUp()
		self.continueAfterFailure = false
    }
    
    override func tearDown() {
        super.tearDown()
    }

	func openZipFile(named name: String) -> ZipFile {
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: name, withExtension: "zip", subdirectory: "testdata/zip/")
		XCTAssertNotNil(url, "Could not find zip-file.")

		let zipFile: ZipFile
		do {
			zipFile = try ZipFile(url: url!)
		} catch {
			XCTFail()
			fatalError()
		}

		return zipFile
	}
    
    func testFilenames() {
		let testFiles = ["deflate", "uncompressed"]
		for testFileName in testFiles {
			let zipFile = self.openZipFile(named: testFileName)
			let filenames = zipFile.filenames

			for i in 1...500 {
				let expectedFilename = "file_\(i).txt"
				XCTAssert(filenames.contains(expectedFilename), "'\(testFileName).zip' is missing file '\(expectedFilename)'")
			}
			XCTAssert(filenames.contains("filename_length_and_encoding_test äöüßÄÖÜ^°!§$%&()=?#+-;:,.あうえいおコンピュータ　日本語 한국어 普通话 العَرَبِيَّة ру́сский язы́к le français [lə fʁɑ̃sɛ].txt"), "'\(testFileName).zip' failed filename encoding test.")
			XCTAssert(filenames.count == 501, "'\(testFileName).zip' contains unexpected files.")
		}
    }

	func testRead() {
		let zipFile = self.openZipFile(named: "example")

		let expectedContents = [
			(file: "file1.txt", content: "Hello World!"),
			(file: "file2.txt", content: "File 2")
		]

		do {
			for (file, content) in expectedContents {
				let data = try zipFile.read(filename: file)
				let string = String(data: data, encoding: .utf8)
				XCTAssert(string == content)
			}
		} catch {
			XCTFail()
		}
	}

	func testIteratorAndSubscript() {
		let zipFile = self.openZipFile(named: "example")

		var filenames = zipFile.filenames

		for filename in zipFile {
			// Test if filename is in filenames array
			if let index = filenames.index(of: filename) {
				filenames.remove(at: index)
			} else {
				XCTFail("Filenames returned by iterator are different from filenames array!")
			}

			// Compare data returned by read(filename:) and subscript
			let dataReadMethod = try? zipFile.read(filename: filename)
			let dataSubscript = zipFile[filename]

			XCTAssert(dataReadMethod == dataSubscript)
		}

		XCTAssert(filenames.count == 0, "Iterator did not return all filenames!")
	}

	func testPerformanceBigZip() {
		self.measure {
			let zipFile = self.openZipFile(named: "big")

			for oneFilename in zipFile {
				let data = try? zipFile.read(filename: oneFilename)
				XCTAssert(data != nil)
			}
		}
	}

}
