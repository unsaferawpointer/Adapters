//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 14.06.2022.
//

import AppKit

/// The ability to be a firstResponder
public protocol Focusable: NSView {
	func onFocus(_ value: Bool)
}
