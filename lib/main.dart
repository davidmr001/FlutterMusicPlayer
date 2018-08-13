import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttermusicplayer/BottomControls.dart';
import 'package:fluttermusicplayer/songs.dart';
import 'package:fluttermusicplayer/theme.dart';
import 'package:fluttery/gestures.dart';
import 'package:fluttery_audio/fluttery_audio.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final String appTitle = 'Flutter Music Player';
    return new MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void setState(VoidCallback fn) {}

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    PlaybackState currentPlaybackState = PlaybackState.paused;

    return AudioPlaylist(
      playlist: demoPlaylist.songs.map((DemoSong song) {
        return song.audioUrl;
      }).toList(growable: false),
      playbackState: currentPlaybackState,
      child: new Scaffold(
        appBar: new AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          leading: new IconButton(
            icon: new Icon(
              Icons.arrow_back_ios,
            ),
            color: const Color(0xFFDDDDDD),
            onPressed: () {},
          ),
          title: new Text(widget.title),
          actions: <Widget>[
            new IconButton(
              icon: new Icon(
                Icons.menu,
              ),
              color: const Color(0xFFDDDDDD),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            // SEEK BAR SECTION
            new Expanded(
              child: AudioPlaylistComponent(
                playlistBuilder: (BuildContext context, Playlist playlist, Widget child) {
                  String _albumArtUri = demoPlaylist.songs[playlist.activeIndex].albumArtUrl;
                  return AudioRadialSeekBar(
                    albumArtUri: _albumArtUri,
                  );
                },
              ),
            ),

            // VISUALIZER SECTION
            Container(
              width: double.infinity,
              height: 125.0,
            ),

            // Song Title, Artist name, Controls SECTION
            AudioPlaylistComponent(
              playlistBuilder: (BuildContext context, Playlist playlist, Widget child) {
                String songName = demoPlaylist.songs[playlist.activeIndex].songTitle;
                String artistName = demoPlaylist.songs[playlist.activeIndex].artist;
                int listSize = demoPlaylist.songs.length;
                return BottomControls(
                  songName: songName,
                  artistName: artistName,
                  listSize: listSize,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AudioRadialSeekBar extends StatefulWidget {
  final String albumArtUri;

  AudioRadialSeekBar({this.albumArtUri});

  @override
  AudioRadialSeekBarState createState() {
    return new AudioRadialSeekBarState();
  }
}

class AudioRadialSeekBarState extends State<AudioRadialSeekBar> {
  double _seekPercent;

  @override
  Widget build(BuildContext context) {
    return new AudioComponent(
      updateMe: [
        WatchableAudioProperties.audioSeeking,
        WatchableAudioProperties.audioPlayhead,
      ],
      playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
        double playbackProgress = 0.0;
        if (player.audioLength != null && player.position != null) {
          playbackProgress = player.position.inMilliseconds / player.audioLength.inMilliseconds;
        }
        _seekPercent = player.isSeeking ? _seekPercent : null;

        return new RadialSeekBar(
          progress: playbackProgress,
          seekPercent: _seekPercent,
          onSeekRequested: (double seekPercent) {
            setState(() => _seekPercent = seekPercent);

            final seekMillis = (player.audioLength.inMilliseconds * seekPercent).round();
            player.seek(Duration(milliseconds: seekMillis));
          },
          child: Container(
            color: accentColor,
            child: Image.network(
              widget.albumArtUri,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

class RadialSeekBar extends StatefulWidget {
  final double progress;
  final double seekPercent;
  final Function(double) onSeekRequested;
  final Widget child;

  RadialSeekBar({
    this.progress = 0.0,
    this.seekPercent = 0.0,
    this.onSeekRequested,
    this.child,
  });

  @override
  RadialSeekBarState createState() {
    return new RadialSeekBarState();
  }
}

class RadialSeekBarState extends State<RadialSeekBar> {
  double _progress = 0.0;
  PolarCoord _startDragCoord;
  double _startDragPercent;
  double _currentDragPercent;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
  }

  @override
  void didUpdateWidget(RadialSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _progress = oldWidget.progress;
  }

  void _onDragStart(PolarCoord startCoord) {
    _startDragCoord = startCoord;
    _startDragPercent = _progress;
  }

  void _onDragUpdate(PolarCoord dragCoord) {
    final dragAngle = dragCoord.angle - _startDragCoord.angle;
    final dragPercent = dragAngle / (2 * pi);
    setState(() => _currentDragPercent = (_startDragPercent + dragPercent) % 1.0);
  }

  void _onDragEnd() {
    if (widget.onSeekRequested != null) {
      widget.onSeekRequested(_currentDragPercent);
    }

    setState(() {
      _currentDragPercent = null;
      _startDragCoord = null;
      _startDragPercent = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double thumbPosition = _progress;
    if (_currentDragPercent != null) {
      thumbPosition = _currentDragPercent;
    } else if (widget.seekPercent != null) {
      thumbPosition = widget.seekPercent;
    }

    return new RadialDragGestureDetector(
        onRadialDragStart: _onDragStart,
        onRadialDragUpdate: _onDragUpdate,
        onRadialDragEnd: _onDragEnd,
        child: new Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent, // needed
          child: Center(
              child: Container(
            width: 150.0,
            height: 150.0,
            color: Colors.transparent,
            child: RadialProgressBar(
              trackColor: Colors.grey[400],
              progressColor: accentColor,
              thumbColor: darkAccentColor,
              progressPercent: _progress,
              thumbPositionPercent: thumbPosition,
              innerPadding: EdgeInsets.all(0.0),
              outerPadding: EdgeInsets.all(0.0),
              thumbSize: 8.0,
              child: ClipOval(
                clipper: CircleClipper(),
                child: widget.child,
              ),
            ),
          )),
        ));
  }
}

class RadialProgressBar extends StatefulWidget {
  final double trackWidth;
  final Color trackColor;
  final double progressWidth;
  final Color progressColor;
  final double progressPercent;
  final double thumbSize;
  final Color thumbColor;
  final double thumbPositionPercent;
  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;

  final Widget child;

  RadialProgressBar(
      {this.trackWidth = 3.0,
      this.trackColor = Colors.grey,
      this.progressWidth = 5.0,
      this.progressColor = Colors.blue,
      this.progressPercent = 0.0,
      this.thumbSize = 8.0,
      this.thumbColor = Colors.black,
      this.thumbPositionPercent = 0.0,
      this.outerPadding = const EdgeInsets.all(0.0),
      this.innerPadding = const EdgeInsets.all(0.0),
      this.child});

  @override
  RadialProgressBarState createState() {
    return new RadialProgressBarState();
  }
}

class RadialProgressBarState extends State<RadialProgressBar> {
  EdgeInsets _insetsForPadding() {
    final outerThickness = max(widget.trackWidth, max(widget.progressWidth, widget.thumbSize)) / 2;
    return EdgeInsets.all(outerThickness);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.outerPadding,
      child: CustomPaint(
          foregroundPainter: RadialSeekBarPainter(
              trackWidth: widget.trackWidth,
              trackColor: widget.trackColor,
              progressWidth: widget.progressWidth,
              progressColor: widget.progressColor,
              progressPercent: widget.progressPercent,
              thumbColor: widget.thumbColor,
              thumbSize: widget.thumbSize,
              thumbPositionPercent: widget.thumbPositionPercent),
          child: Padding(padding: _insetsForPadding() + widget.innerPadding, child: widget.child)),
    );
  }
}

class RadialSeekBarPainter extends CustomPainter {
  final double trackWidth;
  final Paint trackPaint;
  final double progressWidth;
  final double progressPercent;
  final Paint progressPaint;
  final double thumbSize;
  final double thumbPositionPercent;
  final Paint thumbPaint;

  RadialSeekBarPainter(
      {@required this.trackWidth,
      @required trackColor,
      @required this.progressWidth,
      @required progressColor,
      @required this.progressPercent,
      @required this.thumbSize,
      @required thumbColor,
      @required this.thumbPositionPercent})
      : trackPaint = new Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackWidth,
        progressPaint = new Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = progressWidth
          ..strokeCap = StrokeCap.round,
        thumbPaint = new Paint()
          ..color = thumbColor
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final outerThickness = max(trackWidth, max(progressWidth, thumbSize));
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 + outerThickness / 2;

    //painting the track
    canvas.drawCircle(center, radius, trackPaint);

    //painting the  progress
    final progressAngle = 2 * pi * progressPercent;
    final Rect rect = new Rect.fromCircle(center: center, radius: radius);
    final double startAngle = -pi / 2;
    canvas.drawArc(rect, startAngle, progressAngle, false, progressPaint);

    // paint the thumb circle
    final double thumbAngle = 2 * pi * thumbPositionPercent + startAngle;
    final Offset thumbCenter = center + Offset(cos(thumbAngle) * radius, sin(thumbAngle) * radius);
    final thumbRadius = thumbSize / 2;
    canvas.drawCircle(thumbCenter, thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class CircleClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: min(size.width, size.height) / 2,
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    // TODO: implement shouldReclip
    return true;
  }
}
