//
//  ZipArchive.swift
//  Zippy
//
//  Created by Clemens on 12.06.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation
import os.log

public class ZipArchive: CompressedArchive {

	static let log = OSLog(subsystem: "de.wetfish.Zippy", category: "ZipArchive")

	public weak var delegate: CompressedArchiveDelegate?

	public private(set) var filenames = [String]()
	private var fileEntries = [String:FileEntry]()

	private let reader: DataReader

	private let endOfCentralDirectoryRecord: Zip.EndOfCentralDirectoryRecord
	private let zip64EndOfCentralDirectoryLocator: Zip.Zip64EndOfCentralDirectoryLocator?

	public required init(data: Data, delegate: CompressedArchiveDelegate?) throws {
		var reader = DataReader(data: data)

		// Find and read end of central directory record
		var endOfCentralDirRecIndex = try Zip.EndOfCentralDirectoryRecord.findStartIndex(reader: reader)
		let endOfCentralDirRec = try Zip.EndOfCentralDirectoryRecord(reader: reader, at: endOfCentralDirRecIndex)
		self.endOfCentralDirectoryRecord = endOfCentralDirRec

		// Check for Zip64 end of central directory locator
		let zip64EndLocator: Zip.Zip64EndOfCentralDirectoryLocator?
		do {
			let zip64EndLocatorIndex = endOfCentralDirRecIndex - Zip.Zip64EndOfCentralDirectoryLocator.length
			zip64EndLocator = try Zip.Zip64EndOfCentralDirectoryLocator(reader: reader, at: zip64EndLocatorIndex)
		} catch ZipError.unexpectedSignature {
			zip64EndLocator = nil
		} catch DataReaderError.outOfRange {
			zip64EndLocator = nil
		}
		self.zip64EndOfCentralDirectoryLocator = zip64EndLocator

		// Get number of segments
		let numberOfDisks: Int
		if endOfCentralDirRec.diskNumber == UInt16.max && zip64EndLocator != nil {
			numberOfDisks = Int(zip64EndLocator!.totalNumberOfDisks)
		} else {
			numberOfDisks = Int(endOfCentralDirRec.diskNumber) + 1
		}

		// Update data reader, if zip file has multiple segments
		if numberOfDisks > 1 {
			let lastDisk = numberOfDisks - 1
			reader = DataReader(data: data, segment: lastDisk, numberOfSegments: numberOfDisks)
			endOfCentralDirRecIndex.segment = numberOfDisks - 1
		}

		self.reader = reader
		self.delegate = delegate

		reader.dataSource = self

		// Read central directory
		let centralDirectory = try self.readCentralDirectory() // TODO: catch reader errors
		let fileEntries = try self.fileEntries(for: centralDirectory)

		var filenames = [String]()
		var fileEntriesDict = [String:FileEntry]()

		for oneFileEntry in fileEntries {
			let filename = oneFileEntry.filename
			guard fileEntriesDict[filename] == nil else {
				os_log("Archive contains multiple files named '%@'.", log: ZipArchive.log, type: .debug, filename)
				continue
			}

			filenames.append(filename)
			fileEntriesDict[filename] = oneFileEntry
		}

		self.fileEntries = fileEntriesDict
		self.filenames = filenames
	}

	private func readCentralDirectory() throws -> Zip.CentralDirectory {
		// Read Zip64 end of central directory record, if it exists
		let zip64EndOfCentralDirRec: Zip.Zip64EndOfCentralDirectoryRecord?
		if let zip64EndLocator = self.zip64EndOfCentralDirectoryLocator {
			let segment = Int(zip64EndLocator.zip64EndRecordStartDiskNumber)
			let offset = Int(zip64EndLocator.zip64EndRecordRelativeOffset)
			let recordIndex = DataReader.Index(segment: segment, offset: offset)
			zip64EndOfCentralDirRec = try Zip.Zip64EndOfCentralDirectoryRecord(reader: self.reader, at: recordIndex)
		} else {
			zip64EndOfCentralDirRec = nil
		}

		// Read central directory
		let centralDirStartDisk: Int
		let centralDirOffset: Int
		let centralDirSize: Int

		if let zip64EndOfCentralDirRec = zip64EndOfCentralDirRec {
			centralDirStartDisk = Int(zip64EndOfCentralDirRec.centralDirectoryStartDiskNumber)
			centralDirOffset = Int(zip64EndOfCentralDirRec.centralDirectoryOffset)
			centralDirSize = Int(zip64EndOfCentralDirRec.centralDirectorySize)
		} else {
			let endOfCentralDirRec = self.endOfCentralDirectoryRecord
			centralDirStartDisk = Int(endOfCentralDirRec.centralDirectoryStartDiskNumber)
			centralDirOffset = Int(endOfCentralDirRec.centralDirectoryOffset)
			centralDirSize = Int(endOfCentralDirRec.centralDirectorySize)
		}

		var centralDirIndex = DataReader.Index(segment: centralDirStartDisk, offset: centralDirOffset)
		let centralDirectory = try Zip.CentralDirectory(reader: self.reader, at: &centralDirIndex, length: centralDirSize)

		// TODO: verify digital signature of central directory

		return centralDirectory
	}

	private func fileEntries(for centralDirectory: Zip.CentralDirectory) throws -> [FileEntry] {
		let encoding: String.Encoding = .utf8 // TODO: check if always utf-8

		var entries = [FileEntry]()

		for oneHeader in centralDirectory.headers {
			let entry = try FileEntry(header: oneHeader, encoding: encoding)
			entries.append(entry)
		}

		return entries
	}

	public func extract(file filename: String, verify: Bool) throws -> Data {
		guard let fileEntry = self.fileEntries[filename] else {
			throw CompressedArchiveError.noSuchFile
		}

		let outputStream = OutputStream.toMemory()

		try fileEntry.extract(from: self.reader, to: outputStream, verify: verify)

		guard let data = outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
			throw CompressedArchiveError.writeFailed
		}

		return data
	}

	public func extract(file filename: String, to url: URL, verify: Bool) throws {
		guard let fileEntry = self.fileEntries[filename] else {
			throw CompressedArchiveError.noSuchFile
		}

		// TODO: check if output file is a already existing folder, append filename if yes
		// TODO: check if file already exists, throw error if it does

		guard let outputStream = OutputStream(url: url, append: false) else {
			throw CompressedArchiveError.writeFailed
		}
		
		try fileEntry.extract(from: self.reader, to: outputStream, verify: verify)
	}

	public func info(for filename: String) throws -> CompressedFileInfo {
		guard let fileEntry = self.fileEntries[filename] else {
			throw CompressedArchiveError.noSuchFile
		}

		return fileEntry
	}
}

extension ZipArchive: Sequence {}

extension ZipArchive: DataReaderDataSource {

	func dataReader(_ dataReader: DataReader, dataForSegment segmentIndex: Int) -> Data? {
		return self.delegate?.compressedArchive(self, dataForSegment: segmentIndex, segmentCount: dataReader.numberOfSegments)
	}

}
