import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/api/weather_info.dart';
import 'package:flutter_app/secrets.dart';
import 'package:koin/koin.dart';
import 'package:koin_flutter/koin_flutter.dart';
import 'package:dio/dio.dart';

import 'api/weather_api.dart';

void main() {
  final module = Module()
    ..single((scope) {
      final dio = Dio();
      dio.options.queryParameters = <String, dynamic> {
        "appid": Secrets.apiKey,
        "units": "metric"
      };
      return WeatherApi(dio);
    });

  startKoin((app) {
    app.module(module);
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Weather'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WeatherApi api;
  WeatherInfo _weatherInfo = WeatherInfo.blank();
  String _city = "Zabrze";
  bool _accessibilityMode = false;

  AppBar _appBar;

  void _refreshWeather() {
    api.getCurrentWeather(_city)
      .then((value) {
        _setWeatherInfo(
          value
        );
      }
    );
  }

  void _setWeatherInfo(WeatherInfo value) {
    setState(() {
      _weatherInfo = value;
    });
  }

  void _setCity(String city) {
    setState(() {
      _city = city;
    });
  }

  void _triggerAccessibility() {
    setState(() {
      _accessibilityMode = !_accessibilityMode;
    });
  }

  @override
  void initState() {
    api = get();
    super.initState();
    _refreshWeather();
  }

  @override
  Widget build(BuildContext context) {
    void showCityDialog() {

      TextEditingController controller = TextEditingController();

      controller.text = _city;

      TextFormField input = TextFormField(
        style: Theme.of(context).textTheme.headline5,
        controller: controller,
      );

      showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Choose a city"),
            content: input,
            actions: [
              TextButton(
                  child: Text("Ok"), onPressed: () {
                    Navigator.pop(context, controller.text);
                  }
                ),
            ],
          )).then((value) {
            _setCity(value);
            _refreshWeather();
            controller.dispose();
          });
    }

    _appBar = AppBar(
      title: Text(
      "Weather App",
      textScaleFactor: 1.2,
      ),
      actions: [
        Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                _triggerAccessibility();
              },
              child: Icon(
                Icons.accessibility,
                size: 26.0,
              ),
            )
        ),
      ],
    );
    
    return Scaffold(
      appBar: _appBar,
      body:
      RefreshIndicator(
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        child:
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Container(
                  height: MediaQuery.of(context).size.height - _appBar.preferredSize.height - MediaQuery.of(context).padding.top,
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                          child: Text(
                            "$_city",
                            style: _accessibilityMode ? Theme.of(context).textTheme.headline3 : Theme.of(context).textTheme.headline4,
                          ),
                            onTap: showCityDialog,
                          ),
                          Text(
                            "${_weatherInfo.weather.first.description}",
                            style: _accessibilityMode ? Theme.of(context).textTheme.headline4 : Theme.of(context).textTheme.headline5,
                          ),
                          Row(
                            children: [
                              Text(
                                '${_weatherInfo.main.temp.toInt()}°C',
                                style: Theme.of(context).textTheme.headline1,
                              ),
                              Column(
                                children: [
                                  Text(
                                    "${_weatherInfo.main.tempMax.toInt()}°C",
                                    style: _accessibilityMode ? Theme.of(context).textTheme.headline3 : Theme.of(context).textTheme.headline4,
                                  ),
                                  HorizontalLine(_accessibilityMode ? 100 : 70),
                                  Text(
                                      "${_weatherInfo.main.tempMin.toInt()}°C",
                                      style: _accessibilityMode ? Theme.of(context).textTheme.headline3 : Theme.of(context).textTheme.headline4,
                                  )
                                ],
                              )
                            ],
                          )
                        ]
                      ),
                      WeatherDetailsBar()
                    ],
                  ),
                ),
              ]
            ),
          onRefresh: () {
            return api.getCurrentWeather(_city)
                .then((value) {
              _setWeatherInfo(
                  value
              );
            });
          },
      )
    );
  }
}

class WeatherDetailsBar extends StatelessWidget {
  WeatherDetailsBar();

  @override
  Widget build(BuildContext context) {
    _MyHomePageState homePageState = context.findAncestorStateOfType<_MyHomePageState>();

    bool accessibilityMode = homePageState._accessibilityMode;
    WeatherInfo weatherInfo = homePageState._weatherInfo;

    if (!accessibilityMode)
    return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IllustratedValue(
                image: 'assets/images/cloud.png',
                value: '${weatherInfo.clouds.all}%',
              ),
              VerticalLine(100),
              IllustratedValue(
                image: 'assets/images/rain.png',
                value: "${weatherInfo.rain?.lastHour ?? 0}mm",
              ),
              VerticalLine(100),
              IllustratedValue(
                image: 'assets/images/wind.png',
                value: "${weatherInfo.wind.speed.toInt()}km/h",
              ),
            ],
          ),
          HorizontalLine(350),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IllustratedValue(
                image: 'assets/images/fog.png',
                value: "${weatherInfo.visibility}m",
              ),
              VerticalLine(100),
              IllustratedValue(
                image: 'assets/images/humidity.png',
                value: "${weatherInfo.main.humidity}%",
              ),
              VerticalLine(100),
              IllustratedValue(
                image: 'assets/images/pressure.png',
                value: "${weatherInfo.main.pressure}hPa",
              ),
            ],
          )
        ]
    );
    else return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IllustratedValue(
                image: 'assets/images/cloud.png',
                value: '${weatherInfo.clouds.all}%',
                width: 140,
                height: 135,
                imageWidth: 70,
              ),
              VerticalLine(135),
              IllustratedValue(
                image: 'assets/images/rain.png',
                value: "${weatherInfo.rain?.lastHour ?? 0}mm",
                width: 140,
                height: 135,
                imageWidth: 70,
              ),
          ]
          ),
          HorizontalLine(350),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IllustratedValue(
                image: 'assets/images/wind.png',
                value: "${weatherInfo.wind.speed.toInt()}km/h",
                width: 140,
                height: 135,
                imageWidth: 70,
              ),
              VerticalLine(135),
              IllustratedValue(
                image: 'assets/images/fog.png',
                value: "${weatherInfo.visibility}m",
                width: 140,
                height: 135,
                imageWidth: 70,
              ),
            ],
          ),
          HorizontalLine(350),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IllustratedValue(
                image: 'assets/images/humidity.png',
                value: "${weatherInfo.main.humidity}%",
                width: 140,
                height: 135,
                imageWidth: 70,
              ),
              VerticalLine(135),
              IllustratedValue(
                image: 'assets/images/pressure.png',
                value: "${weatherInfo.main.pressure}hPa",
                width: 140,
                height: 135,
                imageWidth: 70,
              ),
            ],
          ),
        ]
    );
  }

}

class HorizontalLine extends Container {
  HorizontalLine(double length, {Color color}):
  super(
    width: length == null ? 10 : length,
    decoration: BoxDecoration(
        border: Border.all(
        color: color == null ? Colors.grey : color
      )
    )
  );
}

class VerticalLine extends Container {
  VerticalLine(double length, {Color color}):
    super(
      height: length == null ? 10 : length,
      decoration: BoxDecoration(
          border: Border.all(
          color: color == null ? Colors.grey : color
        )
      )
  );
}

class IllustratedValue extends StatelessWidget {
  final String image;
  final double imageWidth;
  final String value;
  final TextStyle textStyle;
  final double width;
  final double height;

  IllustratedValue(
    {
      this.image,
      this.imageWidth = 50,
      this.value,
      this.textStyle,
      this.width = 90,
      this.height = 90
    }
  );

  @override
  Widget build(BuildContext context) {

    _MyHomePageState homePageState = context.findAncestorStateOfType<_MyHomePageState>();

    bool accessibilityMode = homePageState._accessibilityMode;

    return Container(
      width: width,
      height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage(image),
              width: imageWidth,),
            Text(
                value,
                style: accessibilityMode ? Theme.of(context).textTheme.headline4 : Theme.of(context).textTheme.headline6
            )
          ],
        ),
    );
  }
}