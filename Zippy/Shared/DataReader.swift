//
//  DataReader.swift
//  Zippy
//
//  Created by Clemens on 09.01.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

protocol DataReaderDataSource: class {

	func dataReader(_ dataReader: DataReader, dataForSegment segmentIndex: Int) -> Data?
}

enum DataReaderError: Error {

	/// Segment index or data offset is out of range
	case outOfRange

	/// Could not get data for segment
	case missingData

	/// Value does not match expected value
	case valueNotFound
}

extension DataReader.Index {

	static func <(lhs: DataReader.Index, rhs: DataReader.Index) -> Bool {
		return lhs.segment < rhs.segment || (lhs.segment == rhs.segment && lhs.offset < rhs.offset)
	}

	static func ==(lhs: DataReader.Index, rhs: DataReader.Index) -> Bool {
		return lhs.segment == rhs.segment && lhs.offset == rhs.offset
	}

	static func +(lhs: DataReader.Index, rhs: Int) -> DataReader.Index {
		var result = lhs
		result.offset += rhs
		return result
	}

	static func -(lhs: DataReader.Index, rhs: Int) -> DataReader.Index {
		var result = lhs
		result.offset -= rhs
		return result
	}

	static func +=(lhs: inout DataReader.Index, rhs: Int) {
		lhs.offset += rhs
	}

	static func -=(lhs: inout DataReader.Index, rhs: Int) {
		lhs.offset -= rhs
	}

}

class DataReader {

	struct Index: Comparable {

		var segment: Int
		var offset: Int

	}

	private var segmentData: [Int:Data]

	let numberOfSegments: Int
	weak var dataSource: DataReaderDataSource?

	init(data: Data, segment: Int = 0, numberOfSegments: Int = 1) {
		assert(segment < numberOfSegments)
		assert(numberOfSegments >= 1)

		self.numberOfSegments = numberOfSegments

		self.segmentData = [segment: data]
	}

	func data(forSegment segmentIndex: Int) throws -> Data {
		if let data = self.segmentData[segmentIndex] {
			return data
		}

		if segmentIndex < 0 || segmentIndex >= self.numberOfSegments {
			throw DataReaderError.outOfRange
		}

		if let data = self.dataSource?.dataReader(self, dataForSegment: segmentIndex) {
			self.segmentData[segmentIndex] = data
			return data
		} else {
			throw DataReaderError.missingData
		}
	}

	func size(ofSegment segmentIndex: Int) throws -> Int {
		let data = try self.data(forSegment: segmentIndex)
		return data.count
	}

	func remainingBytes(at index: Index) throws -> Int {
		var segmentIndex = index.segment
		var offset = index.offset
		var remainingBytes = 0

		while segmentIndex < self.numberOfSegments {
			let segmentSize = try self.size(ofSegment: segmentIndex)
			remainingBytes += segmentSize - offset

			segmentIndex += 1
			offset = 0
		}

		return remainingBytes
	}

	// MARK: - Working with indexes

	func offset(index: Index, by offset: Int) throws -> Index {
		var outIndex = index
		outIndex.offset += offset

		if outIndex.offset < 0 {
			repeat {
				outIndex.segment -= 1
				let segmentSize = try self.size(ofSegment: outIndex.segment)
				outIndex.offset = segmentSize + outIndex.offset
			} while outIndex.offset < 0
		} else {
			while true {
				let segmentSize = try self.size(ofSegment: outIndex.segment)
				if outIndex.offset >= segmentSize {
					outIndex.segment += 1
					outIndex.offset -= segmentSize

					if outIndex.segment == self.numberOfSegments && outIndex.offset == 0 {
						break
					}
				} else {
					break
				}
			}
		}

		return outIndex
	}

	var startIndex: Index {
		return Index(segment: 0, offset: 0)
	}

	var endIndex: Index {
		return Index(segment: self.numberOfSegments, offset: 0)
	}

	// MARK: - Reading

	func read(_ length: Int, at index: inout Index) throws -> Data {
		if length == 0 {
			return Data()
		}

		var currentSegmentIndex = index.segment
		var currentData = try self.data(forSegment: currentSegmentIndex)

		var endOffset = index.offset + length
		var remainingLength = 0

		if endOffset > currentData.count {
			remainingLength = endOffset - currentData.count
			endOffset = currentData.count
		}

		var subdata = currentData.subdata(in: index.offset..<endOffset)

		while remainingLength > 0 {
			currentSegmentIndex += 1
			currentData = try self.data(forSegment: currentSegmentIndex)

			endOffset = min(remainingLength, currentData.count)
			remainingLength -= endOffset

			subdata.append(currentData.subdata(in: 0..<endOffset))
		}

		if endOffset == currentData.count {
			index.segment = currentSegmentIndex + 1
			index.offset = 0
		} else {
			index.offset = endOffset
		}

		return subdata
	}

	func read<T: FixedWidthInteger>(at index: inout Index, littleEndian: Bool = true) throws -> T {
		let valueSize: Int = MemoryLayout<T>.size
		let subdata = try self.read(valueSize, at: &index)
		let value: T = subdata.withUnsafeBytes { (bytes: UnsafePointer<T>) -> T in
			return bytes.pointee
		}

		if littleEndian {
			return T(littleEndian: value)
		} else {
			return T(bigEndian: value)
		}
	}

	func peek<T: FixedWidthInteger>(at index: Index, littleEndian: Bool = true) throws -> T {
		var mutableIndex = index
		return try self.read(at: &mutableIndex, littleEndian: littleEndian)
	}

	// MARK: -

	func expect<T: FixedWidthInteger>(value expectedValue: T, littleEndian: Bool = true, at index: inout Index) throws {
		var outIndex = index
		let actualValue: T = try self.read(at: &outIndex, littleEndian: littleEndian)
		if actualValue != expectedValue {
			throw DataReaderError.valueNotFound
		} else {
			index = outIndex
		}
	}

	func find<T: FixedWidthInteger>(value expectedValue: T, in range: Range<Index>, reverse: Bool = false, littleEndian: Bool = true) throws -> Index {
		var success = false
		var index = reverse ? (try self.offset(index: range.upperBound, by: -1)) : range.lowerBound

		do {
			while index >= range.lowerBound && index < range.upperBound {
				var inoutIndex = index
				let oneValue: T = try self.read(at: &inoutIndex, littleEndian: littleEndian)
				if oneValue == expectedValue {
					success = true
					break
				}
				index = try self.offset(index: index, by: reverse ? -1 : 1)
			}
		} catch DataReaderError.outOfRange {
			throw DataReaderError.valueNotFound
		}

		if !success {
			throw DataReaderError.valueNotFound
		}

		return index
	}

}
