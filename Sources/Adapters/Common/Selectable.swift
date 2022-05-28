//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 15.06.2022.
//

import AppKit

public protocol Selectable: NSView {
	func didSelected(_ value: Bool)
}
