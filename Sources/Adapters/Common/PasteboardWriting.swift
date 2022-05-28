//
//  PasteboardWriting.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 12.05.2022.
//

import AppKit

public protocol PasteboardWriting {
	var pasterboardMap: [NSPasteboard.PasteboardType: Data]? { get }
}
