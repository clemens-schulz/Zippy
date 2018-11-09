//
//  EndOfCentralDirectoryRecord.swift
//  Zippy
//
//  Created by Clemens on 15/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

extension Zip {

	/**
	Struct for the end of central directory (c.d.) record. The record has the following memory layout:

		    | Description                                   | Size      | Value
		----+-----------------------------------------------+-----------+------------
		0   | Signature                                     | 4 bytes   | 0x06054b50
		----+-----------------------------------------------+-----------+------------
		4   | Number of current disk                        | 2 bytes   |
		----+-----------------------------------------------+-----------+------------
		6   | Number of disk that contains start of c.d.    | 2 bytes   |
		----+-----------------------------------------------+-----------+------------
		8   | Entries in c.d. on current disk               | 2 bytes   |
		----+-----------------------------------------------+-----------+------------
		10  | Total entries in c.d.                         | 2 bytes   |
		----+-----------------------------------------------+-----------+------------
		12  | c.d. size in bytes                            | 4 bytes   |
		----+-----------------------------------------------+-----------+------------
		16  | Offset of start of central directory with     | 4 bytes   |
		    | respect to the starting disk number           |           |
		----+-----------------------------------------------+-----------+------------
		20  | File comment length                           | 2 bytes   |
		----+-----------------------------------------------+-----------+------------
		22  | File comment                                  | variable  |

	Structure may only be located on the last disk.
	*/
	struct EndOfCentralDirectoryRecord {

		static let signature: UInt32 = 0x06054b50
		static let minLength: Int = 22
		static let maxLength: Int = EndOfCentralDirectoryRecord.minLength + Int(UInt16.max)

		/// The number of this disk (containing the end of central directory record)
		let diskNumber: UInt16

		/// Number of disk containing start of central directory
		let centralDirectoryStartDiskNumber: UInt16

		/// Number of entries in central directory on current disk
		let entriesOnDisk: UInt16

		/// Total number of entries in central directory
		let totalEntries: UInt16

		/// Size of central directory in bytes
		let centralDirectorySize: UInt32

		/// Offset of start of central directory on disk that it starts on
		let centralDirectoryOffset: UInt32

		/// Length of file comment
		let fileCommentLength: UInt16

		/// File comment
		let fileComment: Data

		/**
		Reads end of central directory record.

		- Parameter reader: Data reader for ZIP file

		- Throws: `ZipError.endOfCentralDirectoryRecordMissing`
		*/
		init(reader: DataReader, at index: inout DataReader.Index) throws {
			do {
				try reader.expect(value: EndOfCentralDirectoryRecord.signature, at: &index)
			} catch DataReaderError.valueNotFound {
				throw ZipError.endOfCentralDirectoryRecordNotFound
			}

			self.diskNumber = try reader.read(at: &index)
			self.centralDirectoryStartDiskNumber = try reader.read(at: &index)

			self.entriesOnDisk = try reader.read(at: &index)
			self.totalEntries = try reader.read(at: &index)

			self.centralDirectorySize = try reader.read(at: &index)
			self.centralDirectoryOffset = try reader.read(at: &index)

			self.fileCommentLength = try reader.read(at: &index)
			self.fileComment = try reader.read(Int(self.fileCommentLength), at: &index)
		}

		init(reader: DataReader, at index: DataReader.Index) throws {
			var mutableIndex = index
			try self.init(reader: reader, at: &mutableIndex)
		}

		/**
		Finds and returns index of end of central directory record.

		- Parameter reader: Data reader

		- Throws: Error of type `ZipError.endOfCentralDirectoryRecordNotFound`, if record not found.

		- Returns: Index of beginning of end of central directory record
		*/
		static func findStartIndex(reader: DataReader) throws -> DataReader.Index {
			let lastDisk = reader.numberOfSegments - 1
			let lastDiskSize = try reader.size(ofSegment: lastDisk)

			if lastDiskSize < EndOfCentralDirectoryRecord.minLength {
				throw ZipError.endOfCentralDirectoryRecordNotFound
			}

			// Record is always completely on last disk
			let sizeOfLargestPossibleRecord = min(EndOfCentralDirectoryRecord.maxLength, lastDiskSize)
			let indexOfLargestPossibleRecord = try reader.offset(index: reader.endIndex, by: -sizeOfLargestPossibleRecord)
			assert(indexOfLargestPossibleRecord.segment == lastDisk)

			// We start looking for the signature at the index of the smallest possible record and work our way up
			// to the largest possible index until we find it.
			let sizeOfSmallestPossibleRecord = EndOfCentralDirectoryRecord.minLength
			var indexOfRecord = try reader.offset(index: reader.endIndex, by: -sizeOfSmallestPossibleRecord)
			assert(indexOfRecord.segment == lastDisk)

			var success = false

			do {
				repeat {
					let searchRange = indexOfLargestPossibleRecord..<(indexOfRecord + 1)
					indexOfRecord = try reader.find(value: EndOfCentralDirectoryRecord.signature, in: searchRange, reverse: true)

					var readingIndex = indexOfRecord + 20
					let fileCommentLength: UInt16 = try reader.read(at: &readingIndex)
					let remainingBytes = try reader.remainingBytes(at: readingIndex)

					if fileCommentLength != remainingBytes {
						indexOfRecord -= 1
						continue
					} else {
						success = true
						break
					}
				} while indexOfRecord > indexOfLargestPossibleRecord
			} catch {
				success = false
			}

			if !success {
				throw ZipError.endOfCentralDirectoryRecordNotFound
			}

			return indexOfRecord
		}

	}
}
