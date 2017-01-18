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

	func readUncompressedFile(named name: String) -> Data? {
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: name, withExtension: nil, subdirectory: "testdata/uncompressed/")
		XCTAssertNotNil(url, "Could not find file '\(name)'.")

		return try? Data(contentsOf: url!)
	}

	func openZipFile(named name: String) throws -> ZipFile {
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: name, withExtension: nil, subdirectory: "testdata/zip/")
		XCTAssertNotNil(url, "Could not find file '\(name)'.")

		return try ZipFile(url: url!)
	}
    
    func testFilenames() {
		let testFiles = ["deflate.zip", "uncompressed.zip"]
		for testFileName in testFiles {
			let zipFile: ZipFile
			do {
				zipFile = try self.openZipFile(named: testFileName)
			} catch {
				XCTFail("Could not open zip file: \(error)")
				continue
			}

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
		let testFiles = ["deflate.zip", "uncompressed.zip"]
		for testFileName in testFiles {
			let zipFile: ZipFile
			do {
				zipFile = try self.openZipFile(named: testFileName)
			} catch {
				XCTFail("Could not open zip file: \(error)")
				continue
			}

			for oneFilename in zipFile {
				let expectedData = self.readUncompressedFile(named: oneFilename)
				XCTAssert(expectedData != nil, "Failed to read uncompressed test data.")

				let data = zipFile[oneFilename]
				XCTAssert(data == expectedData, "Data in ZIP file does not match original data.")
			}
		}
	}

	func testReadingOfNotExistingFiles() {
		let zipFile: ZipFile
		do {
			zipFile = try self.openZipFile(named: "deflate.zip")
		} catch {
			XCTFail("Could not open zip file: \(error)")
			return
		}

		let filename = "does not exist.txt"
		XCTAssert(zipFile[filename] == nil, "Data for not existing file returned.")

		do {
			_ = try zipFile.read(filename: filename)
			XCTFail("Expected error not thrown")
		} catch {
			XCTAssert(error as? FileError == FileError.doesNotExist, "Unexpected error thrown")
		}
	}

	func testIteratorAndSubscript() {
		let testFiles = ["deflate.zip", "uncompressed.zip"]
		for testFileName in testFiles {
			let zipFile: ZipFile
			do {
				zipFile = try self.openZipFile(named: testFileName)
			} catch {
				XCTFail("Could not open zip file: \(error)")
				continue
			}

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

				XCTAssert(dataReadMethod == dataSubscript, "Subscript returns different data than read(filename:)")
			}

			XCTAssert(filenames.count == 0, "Iterator did not return all filenames!")
		}
	}

	func testZip64() {
		let zipFile: ZipFile
		do {
			zipFile = try self.openZipFile(named: "zip64_stream.zip")
		} catch {
			XCTFail("Could not open zip file: \(error)")
			return
		}

		do {
			let data = try zipFile.read(filename: "-")
			XCTAssert(data.count > 0)
		} catch {
			XCTFail("File extraction failed: \(error)")
			return
		}
	}

	func testPerformanceBigZip() {
		self.measure {
			self.testZip64()
		}
	}

}
