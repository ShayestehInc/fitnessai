import 'dart:io';

import 'package:dio/dio.dart';

/// Determines whether a [DioException] represents a network connectivity
/// problem (timeout, connection error, or socket exception) as opposed to
/// a server-side or client-side logic error.
///
/// Used by offline repositories to decide whether to fall back to local
/// storage instead of treating the error as a hard failure.
bool isNetworkError(DioException e) {
  return e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError ||
      (e.type == DioExceptionType.unknown && e.error is SocketException);
}
