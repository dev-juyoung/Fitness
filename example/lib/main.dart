import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:fitness/fitness.dart';

import 'extensions/extensions.dart';

void main() {
  runApp(FitnessApplication());
}

enum PermissionStatus {
  granted,
  denied,
}

enum DateFilter {
  daily,
  weekly,
  monthly,
}

class FitnessApplication extends StatefulWidget {
  @override
  _FitnessApplicationState createState() => _FitnessApplicationState();
}

class _FitnessApplicationState extends State<FitnessApplication> {
  PermissionStatus _status = PermissionStatus.denied;
  DateFilter _filter = DateFilter.daily;
  List<DataPoint> _dataPoints = [];

  @override
  void initState() {
    super.initState();
    _hasPermission();
  }

  void _onFilterChanged(DateFilter filter) {
    if (!mounted) {
      return;
    }

    setState(() {
      _filter = filter;
    });

    final now = DateTime.now();
    switch (_filter) {
      case DateFilter.daily:
        _read(timeRange: now.daily(), timeUnit: TimeUnit.hours);
        break;
      case DateFilter.weekly:
        _read(timeRange: now.weekly());
        break;
      case DateFilter.monthly:
        _read(timeRange: now.monthly());
        break;
    }
  }

  /// Fitness Usage STARTED
  void _hasPermission() async {
    final result = await Fitness.hasPermission();
    print('[hasPermission]::$result');

    if (!mounted) {
      return;
    }

    setState(() {
      _status = result ? PermissionStatus.granted : PermissionStatus.denied;
    });

    if (_status != PermissionStatus.granted) {
      return;
    }

    _onFilterChanged(DateFilter.daily);
  }

  void _requestPermission() async {
    final result = await Fitness.requestPermission();
    print('[requestPermission]::$result');

    _hasPermission();
  }

  void _revokePermission() async {
    final result = await Fitness.revokePermission();
    print('[revokePermission]::$result');

    _hasPermission();
  }

  void _read({
    required TimeRange timeRange,
    int bucketByTime = 1,
    TimeUnit timeUnit = TimeUnit.days,
  }) async {
    final results = await Fitness.read(
      timeRange: timeRange,
      bucketByTime: bucketByTime,
      timeUnit: timeUnit,
    );
    print('[READ]::$results');

    if (!mounted) {
      return;
    }

    setState(() {
      _dataPoints = results;
    });
  }

  /// Fitness Usage ENDED

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Fitness Demo'),
        ),
        body: _buildBody(),
        floatingActionButton:
        _status == PermissionStatus.granted && Platform.isAndroid
            ? FloatingActionButton(
          child: Icon(Icons.link_off),
          backgroundColor: Colors.deepOrangeAccent,
          onPressed: _revokePermission,
        )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case PermissionStatus.granted:
        return _buildDataViewer();
      case PermissionStatus.denied:
      default:
        return _buildPermissionFlowView();
    }
  }

  Widget _buildPermissionFlowView() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            child: Image.asset(
              Platform.isAndroid
                  ? 'assets/ic_google_fit.png'
                  : 'assets/ic_health_kit.png',
              width: 56.0,
              height: 56.0,
            ),
            onTap: _requestPermission,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
            ),
            child: Text(
              '\u{1F446}\n\nHello! Touch it to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
          ),
        ],
        //U+1F446
      ),
    );
  }

  Widget _buildDataViewer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text('Today'),
                labelStyle: TextStyle(color: Colors.white),
                selected: _filter == DateFilter.daily,
                selectedColor: Colors.deepOrangeAccent,
                onSelected: (_) => _onFilterChanged(DateFilter.daily),
              ),
              SizedBox(width: 8.0),
              ChoiceChip(
                label: Text('This week'),
                labelStyle: TextStyle(color: Colors.white),
                selected: _filter == DateFilter.weekly,
                selectedColor: Colors.deepOrangeAccent,
                onSelected: (_) => _onFilterChanged(DateFilter.weekly),
              ),
              SizedBox(width: 8.0),
              ChoiceChip(
                label: Text('This month'),
                labelStyle: TextStyle(color: Colors.white),
                selected: _filter == DateFilter.monthly,
                selectedColor: Colors.deepOrangeAccent,
                onSelected: (_) => _onFilterChanged(DateFilter.monthly),
              ),
            ],
          ),
          Expanded(
            child: _dataPoints.isNotEmpty
                ? ListView.separated(
              shrinkWrap: true,
              itemCount: _dataPoints.length,
              itemBuilder: (context, index) {
                final dataPoint = _dataPoints[index];

                return ListTile(
                  leading: Image.asset(
                    'assets/ic_shoes.png',
                    width: 24.0,
                    height: 24.0,
                  ),
                  title: Text('${dataPoint.value} steps'),
                  subtitle: Text(
                    '${_format(dataPoint.dateFrom)} - ${_format(
                        dataPoint.dateTo)}',
                  ),
                );
              },
              separatorBuilder: (_, __) {
                return SizedBox(height: 16.0);
              },
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/walk.json',
                  width: 100.0,
                  fit: BoxFit.fill,
                ),
                Text('How about taking a walk for a while?'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(DateTime dateTime) {
    switch (_filter) {
      case DateFilter.daily:
        return DateFormat.jm().format(dateTime);
      case DateFilter.weekly:
      case DateFilter.monthly:
        return DateFormat.yMd().format(dateTime);
      default:
        throw Exception('Unsupported Type.');
    }
  }
}
