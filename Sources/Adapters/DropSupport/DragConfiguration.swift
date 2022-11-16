//
//  DragConfiguration.swift
//  
//
//  Created by Anton Cherkasov on 12.09.2022.
//

import AppKit

public struct DragConfiguration {

	private var providers: [NSPasteboard.PasteboardType: () -> Data] = [:]

	/// The availability to be reordered
	public var isReordable: Bool = false

	/// The availability to be deleted by drop to trash
	public var isDeletable: Bool = false

	/// The availability of the forced copying (alt + draging)
	public var isCopyable: Bool = false

	/// Preview of the dragging item
	public var dragPreview: NSImage? = nil

	/// Initialization
	///
	/// - Parameters:
	///    - isReordable: The availability to be reordered
	///    - isDeletable: The availability to be deleted by draging to trash
	///    - isCopyable: The availability of the forced copying (alt + draging)
	public init(isReordable: Bool = false, isDeletable: Bool = false, isCopyable: Bool = false) {
		self.isReordable = isReordable
		self.isDeletable = isDeletable
		self.isCopyable = isCopyable
	}
}

// MARK: - Public interface
public extension DragConfiguration {

	@discardableResult
	func onDrag(of type: NSPasteboard.PasteboardType, action: @escaping () -> Data) -> Self {
		var copied = self
		copied.providers[type] = action
		return copied
	}

}

// MARK: Internal interface
extension DragConfiguration {

	func hasData() -> Bool {
		return providers.isEmpty == false
	}

	func enumerateData(action: @escaping (NSPasteboard.PasteboardType, Data) -> Void) {
		for (type, provider) in providers {
			action(type, provider())
		}
	}

	mutating func removeProvider(for type: NSPasteboard.PasteboardType) {
		providers[type] = nil
	}
}
