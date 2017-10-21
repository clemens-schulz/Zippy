//
//  TestData.swift
//  Zippy
//
//  Created by Clemens on 25/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import XCTest
@testable import Zippy

class TestData {

	static func urlForFile(name: String, subdirectory: String?) -> URL? {
		let testBundle = Bundle(for: self)
		// let url = testBundle.url(forResource: name, withExtension: nil, subdirectory: subdirectory)  // For some reason this doesn't find the file with the special characters filename
		let url = testBundle.urls(forResourcesWithExtension: nil, subdirectory: subdirectory)?.first(where: {oneURL in return oneURL.lastPathComponent == name})
		XCTAssertNotNil(url, "Could not find file '\(name)' in '\(subdirectory ?? ".")'.")
		return url
	}

	static func openZipFile(named name: String) -> ZipFile! {
		guard let url = self.urlForFile(name: name, subdirectory: "testdata/zip/") else {
			return nil
		}

		var zipFileForTesting: ZipFile? = nil
		do {
			zipFileForTesting = try ZipFile(url: url)
		} catch {
			XCTFail("Opening '\(name)' failed with error: \(error)")
		}
		return zipFileForTesting
	}

	static func readUncompressedFile(named name: String) -> Data! {
		guard let url = self.urlForFile(name: name, subdirectory: "testdata/uncompressed/") else {
			return nil
		}

		var data: Data? = nil
		do {
			data = try Data(contentsOf: url)
		} catch {
			XCTFail("Reading '\(name)' failed with error: \(error)")
		}
		return data
	}

}
