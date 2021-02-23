// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:example/src/examples/align_camera.dart';
import 'package:example/src/examples/animate_camera.dart';
import 'package:example/src/examples/camera.dart';
import 'package:example/src/examples/fit_bounds.dart';
import 'package:example/src/examples/marker.dart';
import 'package:example/src/examples/resolve_marker.dart';
import 'package:example/src/examples/track_camera.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Flight display',
                style: TextStyle(color: Colors.black, fontSize: 40.0)),
            decoration: BoxDecoration(
              color: Colors.white,
            ),
          ),
          ListTile(
            title: Text('Marker'),
            onTap: () =>
                Navigator.of(context).pushNamed(MarkerExample.routeName),
          ),
          ListTile(
            title: Text('Resolve Marker'),
            onTap: () =>
                Navigator.of(context).pushNamed(ResolveMarkerExample.routeName),
          ),
          Divider(),
          ListTile(
            title: Text('Camera'),
            onTap: () =>
                Navigator.of(context).pushNamed(CameraExample.routeName),
          ),
          ListTile(
            title: Text('Animate camera'),
            onTap: () =>
                Navigator.of(context).pushNamed(AnimateCameraExample.routeName),
          ),
          ListTile(
            title: Text('Track camera'),
            onTap: () =>
                Navigator.of(context).pushNamed(TrackCameraExample.routeName),
          ),
          ListTile(
            title: Text('Align camera'),
            onTap: () =>
                Navigator.of(context).pushNamed(AlignCameraExample.routeName),
          ),
          Divider(),
          ListTile(
            title: Text('Fit bounds'),
            onTap: () =>
                Navigator.of(context).pushNamed(FitBoundsExample.routeName),
          ),
        ],
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  AppPage({this.title, this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Flight display demo'),
      ),
      drawer: AppDrawer(),
      body: Container(
        child: child,
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints.expand(),
      ),
    );
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flight display demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        fontFamily: 'Roboto',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: MarkerExample.routeName,
      routes: {
        MarkerExample.routeName: (_) => AppPage(
              title: 'Marker',
              child: MarkerExample(),
            ),
        ResolveMarkerExample.routeName: (_) => AppPage(
              title: 'Resolve marker',
              child: ResolveMarkerExample(),
            ),
        CameraExample.routeName: (_) => AppPage(
              title: 'Camera',
              child: CameraExample(),
            ),
        AnimateCameraExample.routeName: (_) => AppPage(
              title: 'Animate camera',
              child: AnimateCameraExample(),
            ),
        TrackCameraExample.routeName: (_) => AppPage(
              title: 'Track camera',
              child: TrackCameraExample(),
            ),
        AlignCameraExample.routeName: (_) => AppPage(
              title: 'Align camera',
              child: AlignCameraExample(),
            ),
        FitBoundsExample.routeName: (_) => AppPage(
              title: 'Fit bounds',
              child: FitBoundsExample(),
            ),
      },
    );
  }
}
