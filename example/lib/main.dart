import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fitness/fitness.dart';

void main() {
  runApp(FitnessApplication());
}

class FitnessApplication extends StatefulWidget {
  @override
  _FitnessApplicationState createState() => _FitnessApplicationState();
}

class _FitnessApplicationState extends State<FitnessApplication> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Fitness Demo'),
        ),
      ),
    );
  }
}
