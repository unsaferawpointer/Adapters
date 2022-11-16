//
//  RowConfiguration.swift
//  
//
//  Created by Anton Cherkasov on 17.09.2022.
//

import CoreGraphics

/// Common configuration of the row
public struct RowConfiguration {

	public var isSelectable: Bool

	public var height: CGFloat?

	public var isGroup: Bool

	public init(isSelectable: Bool, height: CGFloat?, isGroup: Bool = false) {
		self.isSelectable = isSelectable
		self.height = height
		self.isGroup = isGroup
	}
}
