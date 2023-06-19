import 'dart:async';
import 'dart:convert' show utf8;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'homeui.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({Key? key, required this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  // ignore: non_constant_identifier_names
  String service_uuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  // ignore: non_constant_identifier_names
  String charaCteristic_uuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  late bool isReady;
  late Stream<List<int>> stream;
  late List _temphumidata;
  double _temp = 0;
  double _humidity = 0;
  @override
  void initState() {
    super.initState();
    isReady = false;
    connectToDevice();
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  connectToDevice() async {
    // ignore: unnecessary_null_comparison
    if (widget.device == null) {
      _pop();
      return;
    }

    Timer(const Duration(seconds: 15), () {
      if (!isReady) {
        disconnectFromDevice();
        _pop();
      }
    });

    await widget.device.connect();
    discoverServices();
  }

  disconnectFromDevice() {
    // ignore: unnecessary_null_comparison
    if (widget.device == null) {
      _pop();
      return;
    }

    widget.device.disconnect();
  }

  discoverServices() async {
    // ignore: unnecessary_null_comparison
    if (widget.device == null) {
      _pop();
      return;
    }

    List<BluetoothService> services = await widget.device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == service_uuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == charaCteristic_uuid) {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            stream = characteristic.value;

            setState(() {
              isReady = true;
            });
          }
        }
      }
    }

    if (!isReady) {
      _pop();
    }
  }

  // Future _onWillPop() {
  //   return showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //             title: const Text('Are you sure?'),
  //             content:
  //                 const Text('Do you want to disconnect device and go back?'),
  //             actions: <Widget>[
  //               ElevatedButton(
  //                   onPressed: () => Navigator.of(context).pop(false),
  //                   child: const Text('No')),
  //               ElevatedButton(
  //                   onPressed: () {
  //                     disconnectFromDevice();
  //                     Navigator.of(context).pop(true);
  //                   },
  //                   child: const Text('Yes')),
  //             ],
  //           ));
  // }

  _pop() {
    Navigator.of(context).pop(true);
  }

  String _dataParser(List<int> dataFromDevice) {
    return utf8.decode(dataFromDevice);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('dht11 Sensor'),
        ),
        body: Container(
            child: !isReady
                ? const Center(
                    child: Text(
                      "Waiting...",
                      style: TextStyle(fontSize: 24, color: Colors.red),
                    ),
                  )
                : StreamBuilder<List<int>>(
                    stream: stream,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<int>> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.active) {
                        // geting data from bluetooth
                        var currentValue = _dataParser(snapshot.requireData);
                        _temphumidata = currentValue.split(",");
                        if (_temphumidata[0] != "nan") {
                          _temp = double.parse('${_temphumidata[0]}');
                        }
                        if (_temphumidata[1] != "nan") {
                          _humidity = double.parse('${_temphumidata[1]}');
                        }

                        return HomeUI(
                          humidity: _humidity,
                          temperature: _temp,
                        );
                      } else {
                        return const Text('Check the stream');
                      }
                    },
                  )),
      ),
    );
  }
}
