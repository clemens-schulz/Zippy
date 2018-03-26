//
//  CompressionStreamTests.swift
//  Zippy
//
//  Created by Clemens on 02.02.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import XCTest
@testable import Zippy

class CompressionStreamTests: XCTestCase {

	var inputData: Data!

	override func setUp() {
		super.setUp()

		self.continueAfterFailure = false

		let testBundle = Bundle(for: type(of: self))

		let url: URL! = testBundle.url(forResource: "file_250", withExtension: "txt", subdirectory: "Testdata/uncompressed/200-250/")
		XCTAssertNotNil(url)

		do {
			let inputData = try Data(contentsOf: url)
			XCTAssert(inputData.count > 0)
			self.inputData = inputData
		} catch {
			XCTFail("caught error: \(error)")
		}
	}

	override func tearDown() {
		self.inputData = nil
		self.continueAfterFailure = true
		super.tearDown()
	}

	func testCompression() {
		do {
			let algorithms: [CompressionStream.Algorithm] = [.lz4, .lzfse, .lzma, .zlib]
			for algorithm in algorithms {
				// Compress data
				let encodeStream = try CompressionStream(mode: .encode, algorithm: algorithm)
				XCTAssertFalse(encodeStream.isComplete)

				var compressedData = try encodeStream.process(data: self.inputData)
				XCTAssertFalse(encodeStream.isComplete)

				compressedData.append(try encodeStream.finalize())
				XCTAssertTrue(encodeStream.isComplete)

				XCTAssert(compressedData.count > 0)
				XCTAssert(compressedData.count < self.inputData.count)

				// Decompress data
				let decodeStream = try CompressionStream(mode: .decode, algorithm: algorithm)
				XCTAssertFalse(decodeStream.isComplete)

				let uncompressedData = try decodeStream.process(data: compressedData)
				XCTAssertTrue(decodeStream.isComplete)

				XCTAssertEqual(self.inputData, uncompressedData)
			}
		} catch {
			XCTFail("caught error: \(error)")
		}
	}

	func testDecodingUncompressedData() {
		do {
			let algorithms: [CompressionStream.Algorithm] = [.lz4, .lzfse, .lzma, .zlib]
			for algorithm in algorithms {
				let stream = try CompressionStream(mode: .decode, algorithm: algorithm)

				do {
					_ = try stream.process(data: self.inputData)
					XCTAssertFalse(stream.isComplete)
				} catch CompressionStreamError.processingError {
					// Acceptable condition
				}
			}
		} catch {
			XCTFail("caught error: \(error)")
		}
	}

	func testDataAfterEndMarker() {
		do {
			let algorithms: [CompressionStream.Algorithm] = [.lz4, .lzfse, .lzma, .zlib]
			for algorithm in algorithms {
				// Compress data
				let encodeStream = try CompressionStream(mode: .encode, algorithm: algorithm)
				var compressedData = try encodeStream.process(data: self.inputData)
				compressedData.append(try encodeStream.finalize())
				compressedData.append(self.inputData)

				// Decompress data
				let decodeStream = try CompressionStream(mode: .decode, algorithm: algorithm)
				let uncompressedData = try decodeStream.process(data: compressedData)

				XCTAssertEqual(self.inputData, uncompressedData)
			}
		} catch {
			XCTFail("caught error: \(error)")
		}
	}

	func testSmallChunkCompression() {
		let chunkSize = 50

		do {
			let algorithms: [CompressionStream.Algorithm] = [.lz4, .lzfse, .lzma, .zlib]
			for algorithm in algorithms {
				// Compress data
				let encodeStream = try CompressionStream(mode: .encode, algorithm: algorithm)
				XCTAssertFalse(encodeStream.isComplete)

				var compressedData = Data()

				var i = self.inputData.startIndex
				while i < inputData.endIndex {
					let range = i..<min(i + chunkSize, self.inputData.endIndex)
					compressedData.append(try encodeStream.process(data: self.inputData[range]))
					XCTAssertFalse(encodeStream.isComplete)
					i += chunkSize
				}

				compressedData.append(try encodeStream.finalize())
				XCTAssertTrue(encodeStream.isComplete)

				do {
					_ = try encodeStream.process(data: self.inputData)
					XCTFail("expected error")
				} catch CompressionStreamError.isComplete {
					// Expected error
				}

				// Decompress data
				let decodeStream = try CompressionStream(mode: .decode, algorithm: algorithm)

				var uncompressedData = Data()

				i = compressedData.startIndex
				while i < compressedData.endIndex {
					XCTAssertFalse(decodeStream.isComplete)

					let range = i..<min(i + chunkSize, compressedData.endIndex)
					uncompressedData.append(try decodeStream.process(data: compressedData[range]))
					i += chunkSize
				}

				XCTAssertTrue(decodeStream.isComplete)
				XCTAssertEqual(self.inputData, uncompressedData)
			}
		} catch {
			XCTFail("caught error: \(error)")
		}
	}

}
