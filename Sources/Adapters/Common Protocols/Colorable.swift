//
//  Colorable.swift
//  
//
//  Created by Anton Cherkasov on 19.06.2022.
//

import AppKit

/// Cell painting for cell icons
public protocol Colorable {
	var tintColor: NSColor? { get }
}
