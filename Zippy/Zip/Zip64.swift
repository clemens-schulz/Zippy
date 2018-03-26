//
//  Zip64.swift
//  Zippy
//
//  Created by Clemens on 18/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

extension Zip {

	/**
	Struct for Zip64 end of central directory (c.d.) record. The record has the following memory layout:

		    | Description                               | Size      | Value
		----+-------------------------------------------+-----------+------------
		0   | Signature                                 | 4 bytes   | 0x06064b50
		----+-------------------------------------------+-----------+------------
		4   | Size of record without first 12 byte      | 8 bytes   |
		----+-------------------------------------------+-----------+------------
		12  | Version made by                           | 2 bytes   |
		----+-------------------------------------------+-----------+------------
		14  | Version needed to extract                 | 2 bytes   |
		----+-------------------------------------------+-----------+------------
		16  | Number of current disk                    | 4 bytes   |
		----+-------------------------------------------+-----------+------------
		20  | Number of disk containing start of c.d.   | 4 bytes   |
		----+-------------------------------------------+-----------+------------
		24  | Entries in c.d. on current disk           | 8 bytes   |
		----+-------------------------------------------+-----------+------------
		32  | Total entries in c.d.                     | 8 bytes   |
		----+-------------------------------------------+-----------+------------
		40  | c.d. size in bytes                        | 8 bytes   |
		----+-------------------------------------------+-----------+------------
		48  | Offset of start of c.d. on disk           | 8 bytes   |
		    | containing start                          |           |
		----+-------------------------------------------+-----------+------------
		56  | Zip64 extensible data sector              | variable  |

	*/
	struct Zip64EndOfCentralDirectoryRecord {

		static let signature: UInt32 = 0x06064b50
		static let minLength: Int = 56

		/// Length of Zip64 end of central directory record. Does not include the signature and length field itself.
		let length: UInt64

		/// Version that create ZIP archive
		let versionMadeBy: Version

		/// Min. version that is required to read ZIP file
		let versionNeeded: Version

		/// The number of this disk (containing the end of central directory record)
		let diskNumber: UInt32

		/// Number of disk containing start of central directory
		let centralDirectoryStartDiskNumber: UInt32

		/// Number of entries in central directory on current disk
		let entriesOnDisk: UInt64

		/// Total number of entries in central directory
		let totalEntries: UInt64

		/// Size of central directory in bytes
		let centralDirectorySize: UInt64

		/// Offset of start of central directory on disk that it starts on
		let centralDirectoryOffset: UInt64

		/// Data from extensible data sector
		let extensibleData: ExtensibleData

		init(reader: DataReader, at index: inout DataReader.Index) throws {
			do {
				try reader.expect(value: Zip64EndOfCentralDirectoryRecord.signature, at: &index)
			} catch DataReaderError.valueNotFound {
				throw ZipError.unexpectedSignature
			}

			self.length = try reader.read(at: &index)
			self.versionMadeBy = Version(rawValue: try reader.read(at: &index))
			self.versionNeeded = Version(rawValue: try reader.read(at: &index))
			self.diskNumber = try reader.read(at: &index)
			self.centralDirectoryStartDiskNumber = try reader.read(at: &index)
			self.entriesOnDisk = try reader.read(at: &index)
			self.totalEntries = try reader.read(at: &index)
			self.centralDirectorySize = try reader.read(at: &index)
			self.centralDirectoryOffset = try reader.read(at: &index)

			let extensibleDataLength = Int(self.length) - 44
			self.extensibleData = try ExtensibleData(reader: reader, at: &index, length: extensibleDataLength)
		}

		init(reader: DataReader, at index: DataReader.Index) throws {
			var mutableIndex = index
			try self.init(reader: reader, at: &mutableIndex)
		}
	}

	/**
	Struct for Zip64 end of central directory locator. The locator has the following memory layout:

		    | Description                                   | Size      | Value
		----+-----------------------------------------------+-----------+------------
		0   | Signature                                     | 4 bytes   | 0x07064b50
		----+-----------------------------------------------+-----------+------------
		4   | Index of disk containing start of zip64 end   | 4 bytes   |
		    | of central directory record                   |           |
		----+-----------------------------------------------+-----------+------------
		8   | Relative offset of the zip64 end of           | 8 bytes   |
		    | central directory record                      |           |
		----+-----------------------------------------------+-----------+------------
		16  | Total number of disks                         | 4 bytes   |

	Structure may only be located on the last disk.
	*/
	struct Zip64EndOfCentralDirectoryLocator {

		static let signature: UInt32 = 0x07064b50
		static let length: Int = 20

		/// Number of disk containing start of zip64 end of	central directory record
		let zip64EndRecordStartDiskNumber: UInt32

		/// Offset of zip64 end of	central directory record relative to locator start index
		let zip64EndRecordRelativeOffset: UInt64

		/// Total number of disks
		let totalNumberOfDisks: UInt32

		init(reader: DataReader, at index: inout DataReader.Index) throws {
			let startIndex = index

			do {
				try reader.expect(value: Zip64EndOfCentralDirectoryLocator.signature, at: &index)
			} catch DataReaderError.valueNotFound {
				throw ZipError.unexpectedSignature
			}

			self.zip64EndRecordStartDiskNumber = try reader.read(at: &index)
			self.zip64EndRecordRelativeOffset = try reader.read(at: &index)
			self.totalNumberOfDisks = try reader.read(at: &index)

			let lastDisk = self.totalNumberOfDisks - 1
			let disk = self.zip64EndRecordStartDiskNumber
			let offset = self.zip64EndRecordRelativeOffset
			let maxOffset = startIndex.offset - Zip64EndOfCentralDirectoryRecord.minLength

			if disk > lastDisk || (disk == lastDisk && offset > maxOffset) {
				index = startIndex
				throw ZipError.invalidZip64EndOfCentralDirectoryOffset
			}
		}

		init(reader: DataReader, at index: DataReader.Index) throws {
			var mutableIndex = index
			try self.init(reader: reader, at: &mutableIndex)
		}
	}

	/**
	Struct for Zip64 extended information extra field.
	*/
	struct Zip64ExtendedInformationExtraField {
		static let headerID: UInt16 = 0x0001

		struct Fields: OptionSet {
			var rawValue: Int

			static let none = Fields(rawValue: 0)
			static let originalSize = Fields(rawValue: 1 << 0)
			static let compressedSize = Fields(rawValue: 1 << 1)
			static let relativeHeaderOffset = Fields(rawValue: 1 << 2)
			static let startDiskNumber = Fields(rawValue: 1 << 3)
		}

		var originalSize: UInt64?
		var compressedSize: UInt64?
		var relativeHeaderOffset: UInt64?
		var startDiskNumber: UInt32?

		init(data: Data, fields: Fields) throws {
			let reader = DataReader(data: data)
			var index = reader.startIndex

			do {
				if fields.contains(.originalSize) {
					self.originalSize = try reader.read(at: &index)
				}

				if fields.contains(.compressedSize) {
					self.compressedSize = try reader.read(at: &index)
				}

				if fields.contains(.relativeHeaderOffset) {
					self.relativeHeaderOffset = try reader.read(at: &index)
				}

				if fields.contains(.startDiskNumber) {
					self.startDiskNumber = try reader.read(at: &index)
				}
			} catch DataReaderError.outOfRange {
				throw ZipError.invalidZip64ExtendedInformationExtraFieldLength
			}
		}
	}
}
