# Adapters

It is adapter to help to fast configure your NSTableView and NSOutlineView.

- create `Model`:

```swift

struct CellModel {

}

```

- create `ConfigurableCell`:

```swift

final class Cell: NSView, ConfigurableCell {

	typealias Model = CellModel

	static var userIdentifier: String = "cell"

	init(_ model: CellModel) {
		self.model = model
		super.init(frame: .zero)
	}

	@available(*, unavailable, message: "Use init(_ :)")
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var model: CellModel {
		didSet {
			updateInterface() {
		}
	}

	func updateInterface() {
		// Update your cell view
	}

}

```

- build tree structure

