//
//  CompressedFileInfo.swift
//  Zippy-iOS
//
//  Created by Clemens on 09.11.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

public protocol CompressedFileInfo {
	var compressedSize: Int { get }
	var uncompressedSize: Int { get }
	var hasPassword: Bool { get }
}
