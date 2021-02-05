// Copyright 2021 Guillaume Ducret. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:example/src/examples/animate_camera.dart';
import 'package:example/src/examples/move_camera.dart';
import 'package:flutter/material.dart';

import 'examples/track_controller.dart';

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
            title: Text('Track position'),
            onTap: () {
              Navigator.of(context)
                  .pushNamed(TrackMapControllerExample.routeName);
            },
          ),
          ListTile(
            title: Text('Move camera'),
            onTap: () {
              Navigator.of(context).pushNamed(MoveCameraExample.routeName);
            },
          ),
          ListTile(
            title: Text('Animate camera'),
            onTap: () {
              Navigator.of(context).pushNamed(AnimateCameraExample.routeName);
            },
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
      initialRoute: TrackMapControllerExample.routeName,
      routes: {
        TrackMapControllerExample.routeName: (context) => AppPage(
              title: 'Track position',
              child: TrackMapControllerExample(),
            ),
        MoveCameraExample.routeName: (context) => AppPage(
              title: 'Move camera',
              child: MoveCameraExample(),
            ),
        AnimateCameraExample.routeName: (context) => AppPage(
              title: 'Animate camera',
              child: AnimateCameraExample(),
            ),
      },
    );
  }
}
