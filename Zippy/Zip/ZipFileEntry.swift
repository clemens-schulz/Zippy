//
//  ZipFileEntry.swift
//  Zippy
//
//  Created by Clemens on 02.02.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

struct ZipFileEntry: CompressedFileInfo {

	let compressedSize: Int
	let uncompressedSize: Int
	
	let crc32checksum: UInt32
	let localFileHeaderIndex: DataReader.Index
}
