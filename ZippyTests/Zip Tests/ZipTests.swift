//
//  ZipTests.swift
//  Zippy
//
//  Created by Clemens on 02.02.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import XCTest
@testable import Zippy

class ZipTests: XCTestCase {

	var archiveURL: URL!
	var uncompressedDataURL: URL!

	override func setUp() {
		super.setUp()

		self.continueAfterFailure = false

		let testBundle = Bundle(for: type(of: self))

		self.uncompressedDataURL = testBundle.url(forResource: "uncompressed", withExtension: nil, subdirectory: "Testdata")
		XCTAssertNotNil(self.uncompressedDataURL)

		self.archiveURL = testBundle.url(forResource: "Test", withExtension: "zip", subdirectory: "Testdata/zip/")
		XCTAssertNotNil(self.archiveURL)
	}

	override func tearDown() {
		self.continueAfterFailure = true
		super.tearDown()
	}

	// MARK: -

	func testNotExistingFile() {
		do {
			let url = URL(fileURLWithPath: "DOES NOT EXIST!")
			_ = try ZipArchive(url: url)
		} catch CompressedArchiveError.noSuchFile {
			// Expected error
		} catch {
			XCTFail("caught error: \(error)")
		}
	}

	func testRandomDataFile() {
		do {
			let url = self.uncompressedDataURL.appendingPathComponent("100-199/file_100.txt")
			_ = try ZipArchive(url: url)
		} catch is ZipError {
			// Expected error
		} catch {
			XCTFail("caught error: \(error)")
		}
	}

	func testEmptyFile() {
		// TODO: file without content
		XCTFail()
	}

	func testEmptyZipFile() {
		// TODO: only end of c.d. record
		XCTFail()
	}

	func testEnumerator() {
		do {
			let zipArchive = try ZipArchive(url: self.archiveURL)
			var filenames = zipArchive.filenames

			for filename in zipArchive {
				let expectedFilename = filenames.removeFirst()
				XCTAssertEqual(filename, expectedFilename)
			}
		} catch {
			XCTFail("caught error: \(error)")
		}
	}

	func testFilenames() {
		do {
			let fileManager = FileManager.default
			var filenames = try fileManager.subpathsOfDirectory(atPath: self.uncompressedDataURL.path)

			filenames = filenames.map({ (filename: String) -> String in
				var isDir: ObjCBool = false
				let path = self.uncompressedDataURL.appendingPathComponent(filename).path
				fileManager.fileExists(atPath: path, isDirectory: &isDir)
				if isDir.boolValue && !filename.hasSuffix("/") {
					return filename.appending("/")
				} else {
					return filename
				}
			})

			let expectedFilenames = Set<String>(filenames)

			let zipArchive = try ZipArchive(url: self.archiveURL)
			let actualFilenames = Set<String>(zipArchive.filenames)

			XCTAssertEqual(actualFilenames.count, zipArchive.filenames.count)
			XCTAssertEqual(actualFilenames.count, expectedFilenames.count)

			for filename in actualFilenames {
				XCTAssert(expectedFilenames.contains(filename), "Did not expect file '\(filename)'")
			}
		} catch {
			XCTFail("caught error: \(error)")
		}
	}

	func testExtract() {
		// TODO: test if output data matches uncompressed data
		XCTFail()
	}

	func testExtractToFile() {
		// TODO: test extract to file
		XCTFail()
	}

	func testVerify() {
		// TODO: test using corrupted data
		XCTFail()
	}

	func testFileSize() {
		// TODO: test filesize returned before extraction
		XCTFail()
	}

	func testExtractPerformance() {
		self.measure {
			do {
				let zipArchive = try ZipArchive(url: self.archiveURL)
				for filename in zipArchive {
					_ = try zipArchive.extract(file: filename, verify: false)
				}
			} catch {
				XCTFail("caught error: \(error)")
			}
		}
	}

	func testExtractAndVerifyPerformance() {
		self.measure {
			do {
				let zipArchive = try ZipArchive(url: self.archiveURL)
				for filename in zipArchive {
					_ = try zipArchive.extract(file: filename, verify: true)
				}
			} catch {
				XCTFail("caught error: \(error)")
			}
		}
	}

}
