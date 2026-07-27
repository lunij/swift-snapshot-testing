# ``Snapshotting/SnapshotStrategy``

## Topics

### Defining a strategy

- ``init(pathExtension:serializer:comparator:snapshot:)``
- ``init(pathExtension:serializer:comparator:)``

### Transforming strategies

- ``pullback(_:)``
- ``asyncPullback(_:)``
- ``wait(for:on:)``

### Properties

- ``snapshot``
- ``serializer``
- ``comparator``
- ``pathExtension``

### Supporting types

- ``AnySnapshotStringConvertible``
- ``DirectSnapshotStrategy``
- ``SwiftUISnapshotLayout``
