//
//  DataReaderTests.swift
//  Zippy
//
//  Created by Clemens on 12.01.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import XCTest
@testable import Zippy

class DataReaderTests: XCTestCase {

	var bytes: [UInt8]!
	var dataReader: DataReader!

	override func setUp() {
		super.setUp()

		self.bytes = [0x5a, 0x69, 0x70, 0x70, 0x79, 0x21]

		let data = Data(bytes: bytes)
		self.dataReader = DataReader(data: data)
	}

	override func tearDown() {
		super.tearDown()
	}

	func testIndexArithmetic() {
		do {
			// Test index arithmetic
			let startIndex = DataReader.Index(segment: 0, offset: 0)
			XCTAssert(startIndex == self.dataReader.startIndex)

			let midIndex = DataReader.Index(segment: 0, offset: 3)

			let endIndex = DataReader.Index(segment: 1, offset: 0)
			XCTAssert(endIndex == self.dataReader.endIndex)

			let offsetIndex = try self.dataReader.offset(index: startIndex, by: 3)
			XCTAssert(offsetIndex == midIndex)

			let nearEndIndex = try self.dataReader.offset(index: endIndex, by: -1)
			XCTAssert(nearEndIndex.segment == 0 && nearEndIndex.offset == 5)

			let shouldBeEndIndex = try self.dataReader.offset(index: startIndex, by: 6)
			XCTAssert(shouldBeEndIndex == self.dataReader.endIndex)

			XCTAssertThrowsError(try self.dataReader.offset(index: startIndex, by: 10))

			XCTAssert(startIndex < midIndex)
			XCTAssert(startIndex < endIndex)
			XCTAssert(midIndex < endIndex)

			XCTAssert(startIndex != midIndex)

			XCTAssert(startIndex + 3 == midIndex)
			XCTAssert(startIndex + 4 != midIndex)
			XCTAssert(startIndex + 5 == nearEndIndex)
			XCTAssert(midIndex - 3 == startIndex)
			XCTAssert(endIndex - 3 != startIndex)

			var mutableIndex = DataReader.Index(segment: 0, offset: 2)
			mutableIndex += 1
			XCTAssert(mutableIndex == midIndex)

			mutableIndex += 0
			XCTAssert(mutableIndex == midIndex)

			mutableIndex -= 0
			XCTAssert(mutableIndex == midIndex)

			mutableIndex -= 3
			XCTAssert(mutableIndex == startIndex)
		} catch let error {
			XCTFail("caught error: \(error)")
		}
	}

	func testReadData() throws {
		let dataRange = 1..<4
		var index = self.dataReader.startIndex + dataRange.lowerBound
		let readData = try self.dataReader.read(dataRange.count, at: &index)
		XCTAssertEqual(readData, Data(bytes: self.bytes[dataRange]))
	}

	func testReadUInt8() throws {
		var index = self.dataReader.startIndex
		for i in 0..<self.bytes.count {
			let value: UInt8 = try self.dataReader.read(at: &index)
			XCTAssertEqual(value, self.bytes[i])
		}
		XCTAssertEqual(index, self.dataReader.endIndex)
	}

	func testReadUInt16() throws {
		let expectedBytes: [UInt16] = [0x695a, 0x7070, 0x2179]
		var index = self.dataReader.startIndex
		for i in 0..<expectedBytes.count {
			let value: UInt16 = try self.dataReader.read(at: &index)
			XCTAssertEqual(value, expectedBytes[i])
		}
		XCTAssertEqual(index, self.dataReader.endIndex)
	}

	func testReadUInt16BigEndian() throws {
		let expectedBytes: [UInt16] = [0x5a69, 0x7070, 0x7921]
		var index = self.dataReader.startIndex
		for i in 0..<expectedBytes.count {
			let value: UInt16 = try self.dataReader.read(at: &index, littleEndian: false)
			XCTAssertEqual(value, expectedBytes[i])
		}
		XCTAssertEqual(index, self.dataReader.endIndex)
	}

	func testRemainingBytes() throws {
		let remainingBytes1 = try dataReader.remainingBytes(at: dataReader.startIndex)
		XCTAssertEqual(remainingBytes1, 6)

		let remainingBytes2 = try dataReader.remainingBytes(at: dataReader.startIndex + 3)
		XCTAssertEqual(remainingBytes2, 3)

		let remainingBytes3 = try dataReader.remainingBytes(at: dataReader.endIndex)
		XCTAssertEqual(remainingBytes3, 0)
	}

	func testExpect() throws {
		let expectedBytes: [UInt16] = [0x695a, 0x7070, 0x2179]
		let unexpectedByte: UInt16 = 0x0707

		var index = self.dataReader.startIndex
		for i in 0..<expectedBytes.count {
			XCTAssertNoThrow(try self.dataReader.expect(value: expectedBytes[i], at: &index))
			XCTAssertThrowsError(try self.dataReader.expect(value: unexpectedByte, at: &index))
		}
		XCTAssertEqual(index, self.dataReader.endIndex)
	}

	func testFind() {
		XCTFail("not implemented") // TODO
	}

	func testReadUInt16Performance() {
		let dataSize = 1024 * 1024

		var bytes = [UInt8]()
		for _ in 0..<dataSize {
			bytes.append(UInt8(arc4random() % 256))
		}

		let data = Data(bytes: bytes)
		let dataReader = DataReader(data: data)

		self.measure {
			var index = dataReader.startIndex
			while index < dataReader.endIndex {
				let _: UInt16 = try! dataReader.read(at: &index)
			}
		}
	}

	func testFindPerformance() {
		self.measure {
			XCTFail("not implemented") // TODO
		}
	}

}
