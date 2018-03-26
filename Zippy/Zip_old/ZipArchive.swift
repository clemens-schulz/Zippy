//
//  ZipArchive.swift
//  Zippy
//
//  Created by Clemens on 09.01.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

open class ZipArchive: DataReaderDataSource {

	weak var delegate: ZipArchiveDelegate?

	private let dataReader: DataReader

	private let endOfCentralDirectoryRecordIndex: DataReader.Index
	private let endOfCentralDirectoryRecord: Zip.EndOfCentralDirectoryRecord
	private let zip64Locator: Zip.Zip64EndOfCentralDirectoryLocator?

	/// Number of segments. Is 1 unless archive is split into multiple files.
	open let numberOfSegments: Int

	/// Archive file comment
	open let comment: String?

	private lazy var entries: [String:CentralDirectoryFileHeader] = {


		// TODO: read central directory
		return [:]
	}()

	open private(set) lazy var filenames: [String] = {
		return [String](self.entries.keys) // TODO: Maintain order of central directory
	}()

	public required init(data: Data, delegate: ZipArchiveDelegate? = nil) throws {
		var reader = DataReader(data: data)

		// Find and read end of central directory record
		let endOfCentralDirRecIndex = try Zip.EndOfCentralDirectoryRecord.findStartIndex(reader: reader)
		let endOfCentralDirRec = try Zip.EndOfCentralDirectoryRecord(reader: reader, at: endOfCentralDirRecIndex)
		self.endOfCentralDirectoryRecord = endOfCentralDirRec

		// Check for Zip64 locator
		let zip64Locator: Zip.Zip64EndOfCentralDirectoryLocator?
		if endOfCentralDirRec.isProbablyZip64 {
			do {
				let zip64LocatorIndex = endOfCentralDirRecIndex - Zip.Zip64EndOfCentralDirectoryLocator.length
				zip64Locator = try Zip.Zip64EndOfCentralDirectoryLocator(reader: reader, at: zip64LocatorIndex)
			} catch ZipError.unexpectedSignature {
				zip64Locator = nil
			}
		} else {
			zip64Locator = nil
		}
		self.zip64Locator = zip64Locator

		// Get number of disk
		let numberOfDisks: Int
		if endOfCentralDirRec.diskNumber == UInt16.max && zip64Locator != nil {
			numberOfDisks = Int(zip64Locator!.totalNumberOfDisks)
		} else {
			numberOfDisks = Int(endOfCentralDirRec.diskNumber) + 1
		}
		self.numberOfSegments = numberOfDisks

		// Decode file comment
		let encoding: String.Encoding = .utf8 // TODO: pick right encoding
		self.comment = String(bytes: endOfCentralDirRec.fileComment, encoding: encoding)

		// Update data reader, if zip file has multiple segments
		if numberOfDisks > 1 {
			let lastDisk = numberOfDisks - 1
			reader = DataReader(data: data, disk: lastDisk, numberOfDisks: numberOfDisks)
		}

		self.endOfCentralDirectoryRecordIndex = DataReader.Index(disk: numberOfDisks - 1, offset: endOfCentralDirRecIndex.offset)

		self.dataReader = reader
		self.delegate = delegate

		self.dataReader.dataSource = self
	}

	public convenience init(fileWrapper: FileWrapper, delegate: ZipArchiveDelegate? = nil) throws {
		if !fileWrapper.isRegularFile {
			// TODO: support for symbolic links
			throw FileError.readFailed
		}

		if let data = fileWrapper.regularFileContents {
			try self.init(data: data, delegate: delegate)
		} else {
			throw FileError.readFailed
		}
	}

	public convenience init(url: URL, delegate: ZipArchiveDelegate? = nil) throws {
		let fileWrapper = try FileWrapper(url: url, options: [])
		try self.init(fileWrapper: fileWrapper, delegate: delegate)
	}

	private func readCentralDirectory() throws {
		// Get position and size of central directory from end record or zip64 end record
		var startIndex: DataReader.Index
		let length: Int
		let expectedNumberOfEntries: Int
		let expectedEndIndex: DataReader.Index

		if let zip64Locator = self.zip64Locator {
			// File is in Zip64 format.

			// Read zip64 end of central directory record
			let endRecordIndex = DataReader.Index(
				disk: Int(zip64Locator.zip64EndRecordStartDiskNumber),
				offset: Int(zip64Locator.zip64EndRecordRelativeOffset)
			)
			let zip64EndRecord = try Zip.Zip64EndOfCentralDirectoryRecord(reader: self.dataReader, at: endRecordIndex)

			// Get values from record
			startIndex = DataReader.Index(
				disk: Int(zip64EndRecord.centralDirectoryStartDiskNumber),
				offset: Int(zip64EndRecord.centralDirectoryOffset)
			)
			length = Int(zip64EndRecord.centralDirectorySize)
			expectedNumberOfEntries = Int(zip64EndRecord.totalEntries)
			expectedEndIndex = endRecordIndex

			// TODO: check zip64EndRecord.entriesOnDisk
			// TODO: check zip64EndRecord.versionNeeded

		} else {
			// File is not in Zip64 format

			// Get values from record
			let endOfCentralDirRec = self.endOfCentralDirectoryRecord
			startIndex = DataReader.Index(
				disk: Int(endOfCentralDirRec.centralDirectoryStartDiskNumber),
				offset: Int(endOfCentralDirRec.centralDirectoryOffset)
			)
			length = Int(endOfCentralDirRec.centralDirectorySize)
			expectedNumberOfEntries = Int(endOfCentralDirRec.totalEntries)
			expectedEndIndex = self.endOfCentralDirectoryRecordIndex

			// TODO: check endOfCentralDirRec.entriesOnDisk
		}

		// Check central directory start offset and size
		if startIndex > expectedEndIndex {
			throw ZipError.invalidCentralDirectoryOffset
		} else if (try dataReader.offset(index: startIndex, by: length)) != expectedEndIndex {
			throw ZipError.invalidCentralDirectoryLength
		}

		// Read entries from central directory
		var readingIndex = startIndex
		// TODO
	}

	/**
	Returns uncompressed data of file with specific filename.

	- Parameter filename: Name of file
	- Parameter verify: If `true`, verifies data integrity by calculating checksum.

	- Throws: An error of one of these types:
		- `FileError.doesNotExist`, if file does not exist.
		- `ZipError.invalidChecksum`, if `verify` is `true` and
	checksum check fails.

	- Returns: Uncompressed data
	*/
	open func read(filename: String, verify: Bool = false) throws -> Data {
		throw FileError.doesNotExist // TODO
	}

	// MARK: - DataReaderDataSource

	func dataReader(_ dataReader: DataReader, dataForDisk diskIndex: Int) -> Data? {
		return self.delegate?.zipArchive(self, dataForSegment: diskIndex + 1)
	}

}
