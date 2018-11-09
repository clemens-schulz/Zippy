//
//  LocalFileHeader.swift
//  Zippy
//
//  Created by Clemens on 08.11.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

extension Zip {

	/**
	Struct for local file header. The header has the following memory layout:

	| Description                      | Size      | Value
	----+----------------------------------+-----------+------------
	0   | Signature                        | 4 bytes   | 0x04034b50
	----+----------------------------------+-----------+------------
	4   | Version needed to extract        | 2 bytes   |
	----+----------------------------------+-----------+------------
	6   | General purpose bit flag         | 2 bytes   |
	----+----------------------------------+-----------+------------
	8   | Compression method               | 2 bytes   |
	----+----------------------------------+-----------+------------
	10  | Last mod file time               | 2 bytes   |
	----+----------------------------------+-----------+------------
	12  | Last mod file date               | 2 bytes   |
	----+----------------------------------+-----------+------------
	14  | CRC-32                           | 4 bytes   |
	----+----------------------------------+-----------+------------
	18  | Compressed size                  | 4 bytes   |
	----+----------------------------------+-----------+------------
	22  | Uncompressed size                | 4 bytes   |
	----+----------------------------------+-----------+------------
	26  | File name length                 | 2 bytes   |
	----+----------------------------------+-----------+------------
	28  | Extra field length               | 2 bytes   |
	----+----------------------------------+-----------+------------
	30  | File name                        | variable  |
	----+----------------------------------+-----------+------------
	*   | Extra field                      | variable  |

	*/
	struct LocalFileHeader {

		static let signature: UInt32 = 0x04034b50
		static let minLength: Int = 30

		let versionNeeded: Version
		let flags: GeneralPurposeBitFlag
		let compressionMethod: CompressionMethod
		let modificationTime: MSDOSTime
		let modificationDate: MSDOSDate
		let crc32checksum: UInt32
		let compressedSize: UInt32
		let uncompressedSize: UInt32
		let filenameLength: UInt16
		let extraFieldLength: UInt16
		let filename: Data
		let extraFields: ExtensibleData

		init(reader: DataReader, at index: inout DataReader.Index) throws {
			do {
				try reader.expect(value: LocalFileHeader.signature, at: &index)
			} catch DataReaderError.valueNotFound {
				throw ZipError.unexpectedSignature
			}
			
			self.versionNeeded = Version(rawValue: try reader.read(at: &index))
			self.flags = GeneralPurposeBitFlag(rawValue: try reader.read(at: &index))

			let compressionMethodRaw: UInt16 = try reader.read(at: &index)
			if let compressionMethod = CompressionMethod(rawValue: compressionMethodRaw) {
				self.compressionMethod = compressionMethod
			} else {
				throw ZipError.unknownCompressionMethod(method: compressionMethodRaw)
			}

			self.modificationTime = MSDOSTime(rawValue: try reader.read(at: &index))
			self.modificationDate = MSDOSDate(rawValue: try reader.read(at: &index))

			self.crc32checksum = try reader.read(at: &index)
			self.compressedSize = try reader.read(at: &index)
			self.uncompressedSize = try reader.read(at: &index)

			self.filenameLength = try reader.read(at: &index)
			self.extraFieldLength = try reader.read(at: &index)

			self.filename = try reader.read(Int(self.filenameLength), at: &index)
			self.extraFields = try ExtensibleData(reader: reader, at: &index, length: Int(self.extraFieldLength))
		}

	}
}
