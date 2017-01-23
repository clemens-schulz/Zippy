//
//  ZipEntry.swift
//  Zippy
//
//  Created by Clemens on 14/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation
import Compression

class FileEntry {

	var filename: String
	var comment: String?
	var extraField: Data?

	var lastModification: Date

	var checksum: UInt32
	var compressedSize: Int
	var uncompressedSize: Int

	var compressionMethod: CompressionMethod
	var compressionOption1: Bool
	var compressionOption2: Bool

	private var diskStartNumber: Int
	private var localHeaderOffset: Int

	init(header: CentralDirectoryFileHeader, encoding: String.Encoding) throws {
		// TODO: check version needed

		self.filename = String(data: header.filename, encoding: encoding) ?? ""
		self.comment = header.fileComment.count > 0 ? String(data: header.fileComment, encoding: encoding) : nil
		self.extraField = header.extraField.count > 0 ? header.extraField : nil

		var dateComponents = DateComponents()
		dateComponents.calendar = Calendar(identifier: .gregorian)
		dateComponents.timeZone = TimeZone(abbreviation: "UTC")
		dateComponents.second = header.modificationTime.second
		dateComponents.minute = header.modificationTime.minute
		dateComponents.hour = header.modificationTime.hour
		dateComponents.day = header.modificationDate.day
		dateComponents.month = header.modificationDate.month
		dateComponents.year = header.modificationDate.year
		self.lastModification = dateComponents.date ?? Date(timeIntervalSince1970: 0.0)

		self.checksum = header.crc32checksum
		self.compressedSize = Int(header.compressedSize)
		self.uncompressedSize = Int(header.uncompressedSize)

		self.compressionMethod = header.compressionMethod
		self.compressionOption1 = header.flags.contains(.compressionOption1)
		self.compressionOption2 = header.flags.contains(.compressionOption2)

		self.diskStartNumber = Int(header.diskNumberStart)
		self.localHeaderOffset = Int(header.offsetOfLocalHeader)

		// TODO: check compression method
	}

	/**
	Returns uncompressed data.
	
	- Parameter data: Data of zip file
	
	- Throws: Instance of `ZipError`, `FileError` or `ZippyError`
	
	- Returns: Uncompressed data for file described by entry
	*/
	func extract(from data: SplitData) throws -> Data {
		var disk = self.diskStartNumber
		var offset = self.localHeaderOffset

		let localHeader = try LocalFileHeader(data: data, disk: &disk, offset: &offset)
		print(localHeader)

		//let dataDescriptor = localHeader.flags.contains(.dataDescriptor)
		// TODO: check size before or after reading, depending on existance of data descriptor
		// TODO: check other header values

		let compressedData = try data.subdata(disk: &disk, offset: &offset, length: self.compressedSize)

		switch compressionMethod {
		case .noCompression:
			return compressedData
		case .deflated:
			let data = compressedData.withUnsafeBytes { (body: UnsafePointer<UInt8>) -> Data in
				let algo = COMPRESSION_ZLIB
				let dst_buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: self.uncompressedSize)
				let dst_size = compression_decode_buffer(dst_buffer, uncompressedSize, body, self.compressedSize, nil, algo)
				let uncompressedData = Data(bytes: dst_buffer, count: dst_size)
				free(dst_buffer)
				return uncompressedData
			}
			// TODO: check for errors
			return data
		default:
			throw ZippyError.unsupportedCompression
		}
	}

}
