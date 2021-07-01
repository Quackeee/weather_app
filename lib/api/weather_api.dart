import 'package:flutter_app/api/weather_info.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'weather_api.g.dart';

@RestApi(baseUrl: "https://api.openweathermap.org/data/2.5")
abstract class WeatherApi {
  factory WeatherApi(Dio dio, {String baseUrl}) = _WeatherApi;

  @GET("/weather")
  Future<WeatherInfo> getCurrentWeather(
        @Query("q") String cityName
      );
}
