//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 04.06.2022.
//

import AppKit

/// Reference - type proxy for drag support
final class PasterboardWriter: NSObject {

	var model: DragSupportable

	init(model: DragSupportable) {
		self.model = model
		super.init()
	}

}
