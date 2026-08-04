# ``Snapshotting/SnapshotStrategy``

## Topics

### Defining a strategy

- ``init(pathExtension:serializer:comparator:snapshot:)``
- ``init(pathExtension:serializer:comparator:)``

### Transforming strategies

- ``transform(to:_:)-(_,(NewValue)->Value)``
- ``transform(to:_:)-(_,)``
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
