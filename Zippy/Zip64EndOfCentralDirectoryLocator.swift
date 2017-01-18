//
//  Zip64EndOfCentralDirectoryLocator.swift
//  Zippy
//
//  Created by Clemens on 18/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

/*
Structure of the Zip64 end of central directory locator:

	| Description									| Size		| Value
----+-----------------------------------------------+-----------+------------
0	| Signature										| 4 bytes	| 0x07064b50
----+-----------------------------------------------+-----------+------------
4	| Number of disk with start of zip64 end of		| 4 bytes	|
	| central directory record						|			|
----+-----------------------------------------------+-----------+------------
8	| Relative offset of the zip64 end of			| 8 bytes	|
	| central directory record						|			|
----+-----------------------------------------------+-----------+------------
16	| Total number of disks							| 4 bytes	|

*/

struct Zip64EndOfCentralDirectoryLocator: DataStruct {

	static let signature: UInt32 = 0x07064b50
	static let length: Data.IndexDistance = 20

	/// Number of disk containing start of zip64 end of	central directory record
	let zip64EndRecordStartDiskNumber: UInt32

	/// Offset of zip64 end of	central directory record relative to locator start index
	let zip64EndRecordRelativeOffset: UInt64

	/// Total number of disks
	let totalNumberOfDisks: UInt32

	init(data: Data, offset: inout Data.Index) throws {
		if data.count - offset < 4 {
			throw ZipError.incomplete
		}

		let signature = data.readLittleUInt32(offset: &offset)
		if signature != Zip64EndOfCentralDirectoryLocator.signature {
			throw ZipError.unexpectedBytes
		}

		if data.count - offset < 16 {
			throw ZipError.incomplete
		}

		self.zip64EndRecordStartDiskNumber = data.readLittleUInt32(offset: &offset)
		self.zip64EndRecordRelativeOffset = data.readLittleUInt64(offset: &offset)
		self.totalNumberOfDisks = data.readLittleUInt32(offset: &offset)
	}
	
}
