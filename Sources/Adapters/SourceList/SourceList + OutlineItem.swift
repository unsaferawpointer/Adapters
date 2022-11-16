//
//  OutlineItem.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import Foundation

extension SourceList {

	/// Reference - type wrapper of the identifier
	final class OutlineItem: NSObject {

		var id: AnyHashable

		init(id: AnyHashable) {
			self.id = id
			super.init()
		}
	}
}
