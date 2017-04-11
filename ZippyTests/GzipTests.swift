//
//  GzipTests.swift
//  Zippy
//
//  Created by Clemens on 08.04.17.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import XCTest
import Zippy

class GzipTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGzipStream() {
        let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: "file_500.txt", withExtension: "gz", subdirectory: "testdata/gzip/")

		let inputStream = InputStream(url: url!)

		inputStream!.schedule(in: .current, forMode: .defaultRunLoopMode)
		inputStream!.open()

		var data = Data()

		do {
			let gzipStream = try GzipStream()

			while inputStream!.hasBytesAvailable {
				let bufferSize = 8 * 1024
				let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
				let count = inputStream!.read(buffer, maxLength: bufferSize)
				if count < 0 {
					XCTFail()
					break
				}
				let compressedData = Data(bytes: buffer, count: count)
				buffer.deallocate(capacity: bufferSize)
				
				let uncompressedData = try gzipStream.process(data: compressedData, endOfFile: !inputStream!.hasBytesAvailable)
				data.append(uncompressedData)

				XCTAssert(gzipStream.originalFileName == "file_500.txt")
			}
		} catch {
			XCTFail("Error \(error)")
		}

		inputStream!.close()

		let expectedData = TestData.readUncompressedFile(named: "file_500.txt")
		XCTAssert(data == expectedData)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
