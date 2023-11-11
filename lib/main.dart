import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:weatherapp/controll/network/open_weather_map_client.dart';
import 'package:weatherapp/controll/state/state.dart';
import 'package:weatherapp/controll/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'dart:io' show Platform;

import 'package:weatherapp/model/constant/const.dart';
import 'package:weatherapp/model/forecast_result.dart';
import 'package:weatherapp/model/weather_result.dart';
import 'package:weatherapp/view/widget/fore_cast_tile_widget.dart';
import 'package:weatherapp/view/widget/info_widget.dart';
import 'package:weatherapp/view/widget/weather_title_widget.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MyProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Color(colorbg1)));
    if (Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Color(colorbg1)),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter weatherapp',
      theme: ThemeData(),
      home: const MyHomePage(title: 'Flutter weatherapp'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MyProvider myProvider;
  late Location location;
  late PermissionStatus permissionStatus;

  @override
  void initState() {
    super.initState();
    myProvider = Provider.of<MyProvider>(context, listen: false);
    location = Location();
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) async {
      await enableLocationListener();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ChangeNotifierProvider.value(
          value: myProvider,
          child: Consumer<MyProvider>(
            builder: (context, value, child) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    tileMode: TileMode.clamp,
                    begin: Alignment.topRight,
                    end: Alignment.bottomRight,
                    colors: [Color(colorbg1), Color(colorBg2)],
                  ),
                ),
                child: myProvider.locationData.latitude != null
                    ? FutureBuilder(
                        future: OpenWeatherMapClient()
                            .getWeather(myProvider.locationData),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                snapshot.error.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          } else if (!snapshot.hasData) {
                            return const Center(
                              child: Text(
                                'No Data..',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          } else {
                            var data = snapshot.data!;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.height /
                                        20),
                                WeatherTileWidget(
                                  context: context,
                                  title: (data.name != null &&
                                          !data.name!.isNotEmpty)
                                      ? data.name
                                      : ' ${data.coord!.lat}/${data.coord!.lon}',
                                  titleFontSize: 30.0,
                                  subTitle: DateFormat('dd-MMM-yyyy').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        (data.dt ?? 0) * 1000),
                                  ),
                                ),
                                Center(
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        BuildIcon(data.weather![0].icon ?? ' '),
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.fill,
                                    progressIndicatorBuilder: (context, url,
                                            downloadProgress) =>
                                        CircularProgressIndicator(
                                            value: downloadProgress.progress),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                      Icons.image,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                WeatherTileWidget(
                                  context: context,
                                  title: '${data.main!.temp}°C',
                                  titleFontSize: 60.0,
                                  subTitle: '${data.weather![0].description}',
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                8),
                                    InfoWidget(
                                      icon: FontAwesomeIcons.wind,
                                      text: '${data.wind!.speed}',
                                    ),
                                    InfoWidget(
                                      icon: FontAwesomeIcons.cloud,
                                      text: '${data.clouds!.all}',
                                    ),
                                    InfoWidget(
                                      icon: FontAwesomeIcons.snowflake,
                                      // ignore: unnecessary_null_comparison
                                      text: data.snow?.d1h?.toString() ?? '0',
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                8),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Expanded(
                                  child: FutureBuilder(
                                      future: OpenWeatherMapClient()
                                          .getForecast(myProvider.locationData),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          );
                                        } else if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              snapshot.error.toString(),
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          );
                                        } else if (!snapshot.hasData) {
                                          return const Center(
                                            child: Text(
                                              'No Data..',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          );
                                        } else {
                                          var data =
                                              snapshot.data as ForecastResult;
                                          return ListView.builder(
                                            itemCount: data.list!.length,
                                            itemBuilder: (context, index) {
                                              var item = data.list![index];
                                              return ForeCastTileWidget(
                                                temp:
                                                    '${item.main!.temp!.toDouble()}°C',
                                                time: DateFormat('HH:mm')
                                                    .format(DateTime
                                                        .fromMillisecondsSinceEpoch(
                                                            (item.dt ?? 0) *
                                                                1000)),
                                                imageUrl: BuildIcon(
                                                    item.weather![0].icon ?? '',
                                                    isBigSize: false),
                                              );
                                            },
                                            scrollDirection: Axis.horizontal,
                                          );
                                        }
                                      }),
                                ),
                              ],
                            );
                          }
                        })
                    : const Center(
                        child: Text(
                          "waiting..",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          myProvider.locationData = await location.getLocation();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Future<void> enableLocationListener() async {
    myProvider.isEnableLocation = await location.serviceEnabled();
    if (!myProvider.isEnableLocation) {
      myProvider.isEnableLocation = await location.requestService();
      if (!myProvider.isEnableLocation) {
        return;
      }
    }
    permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        return;
      }
    }
    myProvider.locationData = await location.getLocation();
    location.onLocationChanged.listen((event) {
      myProvider.locationData = event;
    });
  }
}
