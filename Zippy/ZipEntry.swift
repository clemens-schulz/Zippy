//
//  ZipEntry.swift
//  Zippy
//
//  Created by Clemens on 14/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

class FileEntry {

	var filename: String
	var comment: String?
	var extraField: Data?

	var lastModification: Date

	var checksum: UInt32
	var compressedSize: Int
	var uncompressedSize: Int

	private var diskStartNumber: Int
	private var localHeaderOffset: Data.Index

	init(header: CentralDirectoryFileHeader) throws {
		// TODO: check version needed

		// TODO: use actual encoding
		let encoding: String.Encoding = .utf8

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

		self.diskStartNumber = Int(header.diskNumberStart)
		self.localHeaderOffset = Data.Index(header.offsetOfLocalHeader)
	}

	/**
	Returns uncompressed data.
	*/
	func getData() throws -> Data {
		fatalError()
	}

}
