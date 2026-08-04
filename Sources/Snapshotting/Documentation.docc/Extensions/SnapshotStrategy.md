# ``Snapshotting/SnapshotStrategy``

## Topics

### Defining a strategy

- ``init(identifier:pathExtension:serializer:comparator:snapshot:)``
- ``init(identifier:pathExtension:serializer:comparator:)``

### Transforming strategies

- ``transform(to:identifier:_:)-(_,_,(NewValue)->Value)``
- ``transform(to:identifier:_:)-(_,_,)``
- ``wait(for:on:)``

### Properties

- ``snapshot``
- ``serializer``
- ``comparator``
- ``identifier``
- ``pathExtension``

### Supporting types

- ``AnySnapshotStringConvertible``
- ``DirectSnapshotStrategy``
- ``SwiftUISnapshotLayout``
