//
//  EndOfCentralDirectoryRecord.swift
//  Zippy
//
//  Created by Clemens on 15/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

/*
Structure of the end of central directory (c.d.) record:

	| Description									| Size		| Value
----+-----------------------------------------------+-----------+------------
0	| Signature										| 4 bytes	| 0x06054b50
----+-----------------------------------------------+-----------+------------
4	| Disk number									| 2 bytes	|
----+-----------------------------------------------+-----------+------------
6	| Number of disk that contains start of c.d.	| 2 bytes	|
----+-----------------------------------------------+-----------+------------
8	| Entries in c.d. on this disk					| 2 bytes	|
----+-----------------------------------------------+-----------+------------
10	| Total entries in c.d.							| 2 bytes	|
----+-----------------------------------------------+-----------+------------
12	| c.d. size in bytes							| 4 bytes	|
----+-----------------------------------------------+-----------+------------
16	| offset of start of central directory with		| 4 bytes	|
	| respect to the starting disk number			|			|
----+-----------------------------------------------+-----------+------------
20	| file comment length							| 2 bytes	|
----+-----------------------------------------------+-----------+------------
22	| file comment									| variable	|

*/

struct EndOfCentralDirectoryRecord: DataStruct {

	static let signature: UInt32 = 0x06054b50
	static let minLength: Data.IndexDistance = 22
	static let maxLength: Data.IndexDistance = EndOfCentralDirectoryRecord.minLength + Data.IndexDistance(UInt16.max)

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

	init(data: Data, offset: inout Data.Index) throws {
		if data.count - offset < 4 {
			throw ZipError.incomplete
		}

		let signature = data.readLittleUInt32(offset: &offset)
		if signature != EndOfCentralDirectoryRecord.signature {
			throw ZipError.unexpectedBytes
		}

		if data.count - offset < 18 {
			throw ZipError.incomplete
		}

		self.diskNumber = data.readLittleUInt16(offset: &offset)
		self.centralDirectoryStartDiskNumber = data.readLittleUInt16(offset: &offset)
		self.entriesOnDisk = data.readLittleUInt16(offset: &offset)
		self.totalEntries = data.readLittleUInt16(offset: &offset)
		self.centralDirectorySize = data.readLittleUInt32(offset: &offset)
		self.centralDirectoryOffset = data.readLittleUInt32(offset: &offset)
		self.fileCommentLength = data.readLittleUInt16(offset: &offset)

		let commentEndIndex = offset + Data.Index(self.fileCommentLength)
		if commentEndIndex <= data.count {
			self.fileComment = data.subdata(in: offset..<commentEndIndex)
			offset = commentEndIndex
		} else {
			throw ZipError.incomplete
		}
	}

	/**
	Search for end of central directory record at end of `data`
	
	- Parameter data: Contents of zip-file
	
	- Throws: Error of type `ZipError`
	
	- Returns: Struct for end of central directory record
	*/
	static func find(in data: Data) throws -> EndOfCentralDirectoryRecord {
		// Search for end of central directory record from end of file in reverse
		var i = data.endIndex - EndOfCentralDirectoryRecord.minLength
		let minOffset = Swift.min(data.startIndex, data.endIndex - EndOfCentralDirectoryRecord.maxLength)

		var endRecordFound = false
		while i >= minOffset {
			let potentialSignature = data.readLittleUInt32(offset: i)
			if potentialSignature == EndOfCentralDirectoryRecord.signature {
				endRecordFound = true
				break
			}
			i -= 1
		}

		guard endRecordFound else {
			throw ZipError.endOfCentralDirectoryRecordMissing
		}

		let endOfCentralDirRec = try EndOfCentralDirectoryRecord(data: data, offset: &i)
		guard i == data.endIndex else {
			throw ZipError.unexpectedBytes
		}

		return endOfCentralDirRec
	}

}
