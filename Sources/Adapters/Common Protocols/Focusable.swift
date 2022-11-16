//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 14.06.2022.
//

import AppKit

/// The ability of the cell to be a firstResponder
public protocol Focusable: NSView {
	func onFocus(_ value: Bool)
}
