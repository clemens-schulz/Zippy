//
//  CentralDirectoryFileHeader.swift
//  Zippy
//
//  Created by Clemens on 16/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation
import os

struct InternalFileAttribute: OptionSet {

	let rawValue: UInt16

	static let apparentlyASCIIOrTextFile = InternalFileAttribute(rawValue: 1 << 0)
	static let controlFieldRecordsPrecedeLogicalRecords = InternalFileAttribute(rawValue: 1 << 2)

}

struct CentralDirectoryFileHeader: DataStruct {

	static let signature: UInt32 = 0x02014b50
	static let minLength: Data.IndexDistance = 46
	static let maxLength: Data.IndexDistance = CentralDirectoryFileHeader.minLength + 3 * Data.IndexDistance(UInt16.max)

	let version: Version
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
	let fileCommentLength: UInt16
	let diskNumberStart: UInt16
	let internalAttributes: InternalFileAttribute
	let externalAttributes: UInt32
	let offsetOfLocalHeader: UInt32
	let filename: Data
	let extraField: Data
	let fileComment: Data

	init(data: Data, offset: inout Data.Index) throws {
		if data.count - offset < 4 {
			throw ZipError.incomplete
		}

		let signature = data.readLittleUInt32(offset: &offset)
		if signature != CentralDirectoryFileHeader.signature {
			throw ZipError.unexpectedBytes
		}

		if data.count - offset < 42 {
			throw ZipError.incomplete
		}

		self.version = Version(rawValue: data.readLittleUInt16(offset: &offset))
		self.versionNeeded = Version(rawValue: data.readLittleUInt16(offset: &offset))
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
		self.fileCommentLength = data.readLittleUInt16(offset: &offset)
		self.diskNumberStart = data.readLittleUInt16(offset: &offset)
		self.internalAttributes = InternalFileAttribute(rawValue: data.readLittleUInt16(offset: &offset))
		self.externalAttributes = data.readLittleUInt32(offset: &offset)
		self.offsetOfLocalHeader = data.readLittleUInt32(offset: &offset)

		let headerLength = Int(self.filenameLength) + Int(self.extraFieldLength) + Int(self.fileCommentLength) + 46
		let maxRecommendedLength = 65535
		if headerLength > maxRecommendedLength {
			let log = OSLog(subsystem: "Zippy", category: "ReadZip")
			os_log("File header in central directory is %d bytes long and exceeds recommended max. size of %d bytes.", log: log, type: .info, headerLength, maxRecommendedLength)
		}

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

		let fileCommentEndIndex = offset + Data.Index(self.fileCommentLength)
		if fileCommentEndIndex <= data.count {
			self.fileComment = data.subdata(in: offset..<fileCommentEndIndex)
			offset = fileCommentEndIndex
		} else {
			throw ZipError.incomplete
		}
	}
	
}
