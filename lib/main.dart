import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
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
  runApp(const MyApp());
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
  final controller = Get.put(MyStateController());
  var location = Location();
  late StreamSubscription listener;
  late PermissionStatus permissionStatus;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) async {
      await enableLocationLsitener();
    });
  }

  @override
  void dispose() {
    listener.cancel();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                tileMode: TileMode.clamp,
                begin: Alignment.topRight,
                end: Alignment.bottomRight,
                colors: [Color(colorbg1), Color(colorBg2)],
              ),
            ),
            child: controller.locationData.value.latitude != null
                ? FutureBuilder(
                    future: OpenWeatherMapClient()
                        .getWeather(controller.locationData.value),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
                        var data = snapshot.data! as WeatherResult;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height / 20),
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
                                progressIndicatorBuilder:
                                    (context, url, downloadProgress) =>
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 8),
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
                                        MediaQuery.of(context).size.width / 8),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Expanded(
                              child: FutureBuilder(
                                  future: OpenWeatherMapClient().getForecast(
                                      controller.locationData.value),
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
                                          style: TextStyle(color: Colors.white),
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
                                            temp: '${item.main!.temp}°C',
                                            time: DateFormat('HH:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        (item.dt ?? 0) * 1000)),
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
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          controller.locationData.value = await location.getLocation();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Future<void> enableLocationLsitener() async {
    controller.isEnableLocation.value = await location.serviceEnabled();
    if (!controller.isEnableLocation.value) {
      controller.isEnableLocation.value = await location.requestService();
      if (!controller.isEnableLocation.value) {
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
    controller.locationData.value = await location.getLocation();
    listener = location.onLocationChanged.listen((event) {});
  }
}
