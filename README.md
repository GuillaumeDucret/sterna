# sterna

Moving map for Flutter.
This project is not stable yet. API may change.

## Features

- Moving map tailored for navigation apps
- Camera animation
- Camera focal alignment
- Asynchronous marker resolution when map bounds change
- Auto zoom to fit markers
- Implemented with RenderObject to optimise performance.
- Plain dart code with no dependencies. Supports Android, IOS and Web.

## Usage

```dart
SternaMap(
  controller: MapController(initialCameraFocal: Latlng(45.6391, 5.8800)),
  children: <Widget>[
    TileLayer(
      delegate: RasterTileLayerChildDelegate.osm(),
    ),
    Layer(children: <Widget>[
      Marker(center: Latlng(45.6391, 5.8800)),
    ]),
    MarkerLayer(
      delegate: MarkerLayerChildResolverDelegate(
        resolver: (bounds) async => BuilderBundle<Latlng>(
          iterable: [Latlng(45.6391, 5.9769)].where(bounds.contains),
          builder: (_, latlng) => Marker(
            key: ValueKey(latlng),
            center: latlng,
          ),
        ),
      ),
    ),
  ],
);
```
