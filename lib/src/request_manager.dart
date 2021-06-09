import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'http_request.dart';
import 'error_interceptor.dart';

class RequestManager {
  final Dio _dio = Dio();

  factory RequestManager() => _sharedInstance();

  static RequestManager? _instance;

  RequestManager._() {
    // 具体初始化代码
    //忽略https证书验证
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
    };
    _dio.interceptors.add(ErrorInterceptor());
    _dio.interceptors.add(LogInterceptor(responseBody: false)); //开启请求日志
  }

  static RequestManager _sharedInstance() {
    if (_instance == null) {
      _instance = RequestManager._();
    }
    return _instance!;
  }

  void addRequest(BaseHttpRequest request) {
    String url = request.baseUrl + request.path;
    Options options = Options(
        sendTimeout: request.sendTimeout,
        receiveTimeout: request.receiveTimeout,
        headers: request.headers);
    try {
      switch (request.method) {
        case HttpRequestMethod.get:
          {
            _dio
                .get(url,
                    queryParameters: request.parameters,
                    cancelToken: request.token,
                    onReceiveProgress: request.progressCallback,
                    options: options)
                .then((value) => _responseHandler(request, value));
          }
          break;
        case HttpRequestMethod.post:
          {
            _dio
                .post(url,
                    data: request.parameters,
                    cancelToken: request.token,
                    onSendProgress: request.progressCallback,
                    options: options)
                .then((value) => _responseHandler(request, value));
          }
          break;
        default:
          debugPrint('request manager not this method ===: ${request.method}');
      }
    } on DioError catch (error) {
      _errorHandler(request, error);
    }
  }

  void _errorHandler(BaseHttpRequest request, DioError error) {
    if (CancelToken.isCancel(error)) {
      print('Request canceled! ' + error.message);
      request.status = HttpRequestStatus.canceled;
    } else {
      request.status = HttpRequestStatus.finished;
    }
    request.didFinishFailure(error.error);
  }

  void _responseHandler(BaseHttpRequest request, Response<dynamic> value) {
    request.status = HttpRequestStatus.finished;
    request.didFinishSuccess(value.data);
  }
}
