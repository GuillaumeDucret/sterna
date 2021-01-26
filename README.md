# sterna

Moving map for Flutter.
Work in progress.

## Getting started

```dart
SternaMap(
  controller: MapController(initialCameraFocal: Latlng(45.6391, 5.8800)),
  children: <Widget>[
    TileLayer(
      delegate: SimpleTileLayerChildDelegate(),
    ),
    Layer(children: <Widget>[
      Marker(center: Latlng(45.6391, 5.8800)),
    ]),
    MarkerLayer(
      delegate: MarkerLayerChildResolverDelegate(
        resolver: (bounds) async => BuilderBundle<Latlng>(
          iterable: [Latlng(45.6391, 5.9769)].where(bounds.contains),
          builder: (_, latlng) => Marker(
            center: latlng,
          ),
        ),
      ),
    ),
  ],
);
```
