//
//  DataReaderMultiSegmentTests.swift
//  Zippy
//
//  Created by Clemens on 14.01.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import XCTest
@testable import Zippy

class DataReaderMultiSegmentTests: XCTestCase {

	override func setUp() {
		super.setUp()

//		let segmentBytes: [[UInt8]] = [
//			[0x5a, 0x69, 0x70],
//			[0x70, 0x79, 0x21],
//			[0x20, 0x69, 0x73, 0x20, 0x67, 0x72, 0x65, 0x61, 0x74]
//		]
//		let lastSegmentBytes: [UInt8] = [0x21]
//
//		let dataReader = DataReader(segment: Data(bytes: lastSegmentBytes))
	}

	override func tearDown() {
		super.tearDown()
	}

	func testIndexArithmetic() throws {
		XCTFail("not implemented") // TODO
	}

	func testReadData() throws {
		XCTFail("not implemented") // TODO
	}

	func testReadUInt8() throws {
		XCTFail("not implemented") // TODO
	}

	func testReadUInt16() throws {
		XCTFail("not implemented") // TODO
	}

	func testReadUInt16BigEndian() throws {
		XCTFail("not implemented") // TODO
	}

	func testRemainingBytes() throws {
		XCTFail("not implemented") // TODO
	}

	func testExpect() throws {
		XCTFail("not implemented") // TODO
	}

	func testFind() {
		XCTFail("not implemented") // TODO
	}

	func testReadUInt16Performance() {
		XCTFail("not implemented") // TODO
	}

	func testFindPerformance() {
		self.measure {
			XCTFail("not implemented") // TODO
		}
	}

}
