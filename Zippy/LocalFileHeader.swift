//
//  LocalFileHeader.swift
//  Zippy
//
//  Created by Clemens on 14/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

struct LocalFileHeader: DataStruct {

	let version: Version
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
	let extraField: Data

	init(data: Data, offset: inout Data.Index) throws {
		if data.count - offset < 4 {
			throw ZipError.incomplete
		}

		let signature = data.readLittleUInt32(offset: &offset)
		if signature != 0x04034b50 {
			throw ZipError.unexpectedBytes
		}

		if data.count - offset < 26 {
			throw ZipError.incomplete
		}

		self.version = Version(rawValue: data.readLittleUInt16(offset: &offset))
		self.flags = GeneralPurposeBitFlag(rawValue: data.readLittleUInt16(offset: &offset))

		let compressionMethodRaw = data.readLittleUInt16(offset: &offset)
		if let compressionMethod = CompressionMethod(rawValue: compressionMethodRaw) {
			self.compressionMethod = compressionMethod
		} else {
			throw ZipError.unknownCompressionMethod(method: compressionMethodRaw)
		}

		self.modificationTime = MSDOSTime(rawValue: data.readLittleUInt16(offset: &offset))
		self.modificationDate = MSDOSDate(rawValue: data.readLittleUInt16(offset: &offset))
		self.crc32checksum = data.readLittleUInt32(offset: &offset)
		self.compressedSize = data.readLittleUInt32(offset: &offset)
		self.uncompressedSize = data.readLittleUInt32(offset: &offset)
		self.filenameLength = data.readLittleUInt16(offset: &offset)
		self.extraFieldLength = data.readLittleUInt16(offset: &offset)

		let filenameEndIndex = offset + Data.Index(self.filenameLength)
		if filenameEndIndex <= data.count {
			self.filename = data.subdata(in: offset..<filenameEndIndex)
			offset = filenameEndIndex
		} else {
			throw ZipError.incomplete
		}

		let extraFieldEndIndex = offset + Data.Index(self.extraFieldLength)
		if extraFieldEndIndex <= data.count {
			self.extraField = data.subdata(in: offset..<extraFieldEndIndex)
			offset = extraFieldEndIndex
		} else {
			throw ZipError.incomplete
		}
	}
	
}
