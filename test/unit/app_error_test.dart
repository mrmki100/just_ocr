// test/unit/app_error_test.dart
//
// Comprehensive unit tests for the AppError hierarchy and error boundaries.
// Tests cover all error types, factory constructors, recovery strategies,
// and edge cases with extreme precision.

import 'package:flutter_test/flutter_test.dart';
import 'package:just_ocr/core/error/app_error.dart';

void main() {
  group('AppError Base Class', () {
    test('should create AppError with required fields', () {
      const error = OcrException(
        message: 'Test error',
        failureType: OcrFailureType.unknown,
      );

      expect(error.message, 'Test error');
      expect(error.timestamp, isA<DateTime>());
      expect(error.technicalDetails, isNull);
    });

    test('should create AppError with optional technical details', () {
      const error = OcrException(
        message: 'Test error',
        technicalDetails: 'Stack trace here',
        failureType: OcrFailureType.unknown,
      );

      expect(error.technicalDetails, 'Stack trace here');
    });

    test('should support Equatable comparison', () {
      final error1 = const OcrException(
        message: 'Same error',
        failureType: OcrFailureType.unknown,
      );
      final error2 = const OcrException(
        message: 'Same error',
        failureType: OcrFailureType.unknown,
      );
      final error3 = const OcrException(
        message: 'Different error',
        failureType: OcrFailureType.unknown,
      );

      expect(error1, equals(error2));
      expect(error1, isNot(equals(error3)));
    });
  });

  group('OcrException', () {
    test('should create OcrException with all failure types', () {
      for (final type in OcrFailureType.values) {
        final error = OcrException(
          message: 'OCR failed',
          failureType: type,
        );
        expect(error.failureType, equals(type));
      }
    });

    test('should include failureType in props', () {
      final error1 = const OcrException(
        message: 'Error',
        failureType: OcrFailureType.noTextDetected,
      );
      final error2 = const OcrException(
        message: 'Error',
        failureType: OcrFailureType.invalidImageFormat,
      );

      expect(error1.props, isNot(equals(error2.props)));
    });
  });

  group('GeminiApiException', () {
    test('should parse timeout error correctly', () {
      final error = GeminiApiException.fromException(
        Exception('Connection timed out'),
      );

      expect(error.errorCode, equals(GeminiErrorCode.timeout));
      expect(error.message, contains('timed out'));
    });

    test('should parse quota exceeded error correctly', () {
      final error = GeminiApiException.fromException(
        Exception('Rate limit exceeded'),
      );

      expect(error.errorCode, equals(GeminiErrorCode.quotaExceeded));
      expect(error.message, contains('quota'));
    });

    test('should parse authentication error correctly', () {
      final error = GeminiApiException.fromException(
        Exception('Invalid API key'),
      );

      expect(error.errorCode, equals(GeminiErrorCode.authenticationFailed));
      expect(error.message, contains('Authentication failed'));
    });

    test('should parse permission denied error correctly', () {
      final error = GeminiApiException.fromException(
        Exception('Permission denied'),
      );

      expect(error.errorCode, equals(GeminiErrorCode.permissionDenied));
    });

    test('should parse 404 error correctly', () {
      final error = GeminiApiException.fromException(
        Exception('Resource not found 404'),
      );

      expect(error.errorCode, equals(GeminiErrorCode.resourceNotFound));
    });

    test('should parse server error correctly', () {
      final error = GeminiApiException.fromException(
        Exception('Internal server error 500'),
      );

      expect(error.errorCode, equals(GeminiErrorCode.serverError));
    });

    test('should default to unknown error for unrecognized messages', () {
      final error = GeminiApiException.fromException(
        Exception('Some random error'),
      );

      expect(error.errorCode, equals(GeminiErrorCode.unknown));
      expect(error.technicalDetails, contains('Some random error'));
    });

    test('should handle case-insensitive error parsing', () {
      final error = GeminiApiException.fromException(
        Exception('TIMEOUT occurred'),
      );

      expect(error.errorCode, equals(GeminiErrorCode.timeout));
    });
  });

  group('MLKitException', () {
    test('should parse no text detected error correctly', () {
      final error = MLKitException.fromException(
        Exception('No text detected in image'),
      );

      expect(error.failureType, equals(MLKitFailureType.noTextDetected));
    });

    test('should parse invalid image error correctly', () {
      final error = MLKitException.fromException(
        Exception('Invalid or corrupt image file'),
      );

      expect(error.failureType, equals(MLKitFailureType.invalidImage));
    });

    test('should parse model unavailable error correctly', () {
      final error = MLKitException.fromException(
        Exception('Model download failed'),
      );

      expect(error.failureType, equals(MLKitFailureType.modelUnavailable));
    });

    test('should default to unknown for unrecognized errors', () {
      final error = MLKitException.fromException(
        Exception('Random ML Kit error'),
      );

      expect(error.failureType, equals(MLKitFailureType.unknown));
      expect(error.technicalDetails, contains('Random ML Kit error'));
    });
  });

  group('FileOperationException', () {
    test('should parse permission denied error correctly', () {
      final error = FileOperationException.fromException(
        Exception('Permission denied'),
        'read_file',
      );

      expect(error.operationType, equals(FileOperationType.permissionDenied));
    });

    test('should parse file not found error correctly', () {
      final error = FileOperationException.fromException(
        Exception('File not found'),
        'read_file',
      );

      expect(error.operationType, equals(FileOperationType.fileNotFound));
    });

    test('should parse insufficient storage error correctly', () {
      final error = FileOperationException.fromException(
        Exception('No space left on device'),
        'write_file',
      );

      expect(error.operationType, equals(FileOperationType.insufficientStorage));
    });

    test('should parse corrupted file error correctly', () {
      final error = FileOperationException.fromException(
        Exception('File is corrupt'),
        'parse_pdf',
      );

      expect(error.operationType, equals(FileOperationType.corruptedFile));
    });

    test('should default to unknown for unrecognized errors', () {
      final error = FileOperationException.fromException(
        Exception('Unknown file error'),
        'custom_operation',
      );

      expect(error.operationType, equals(FileOperationType.unknown));
      expect(error.message, contains('custom_operation'));
    });
  });

  group('NetworkException', () {
    test('should parse connection refused error correctly', () {
      final error = NetworkException.fromException(
        Exception('Connection refused'),
      );

      expect(error.failureType, equals(NetworkFailureType.connectionRefused));
    });

    test('should parse timeout error correctly', () {
      final error = NetworkException.fromException(
        Exception('Socket timeout'),
      );

      expect(error.failureType, equals(NetworkFailureType.timeout));
    });

    test('should parse SSL error correctly', () {
      final error = NetworkException.fromException(
        Exception('SSL certificate verification failed'),
      );

      expect(error.failureType, equals(NetworkFailureType.sslError));
    });

    test('should parse no connection error correctly', () {
      final error = NetworkException.fromException(
        Exception('Network is unreachable'),
      );

      expect(error.failureType, equals(NetworkFailureType.noConnection));
    });

    test('should default to unknown for unrecognized errors', () {
      final error = NetworkException.fromException(
        Exception('Random network error'),
      );

      expect(error.failureType, equals(NetworkFailureType.unknown));
    });
  });

  group('AppErrorX Extension - isRetryable', () {
    test('should return true for retryable OcrException', () {
      const error = OcrException(
        message: 'Timeout',
        failureType: OcrFailureType.networkTimeout,
      );

      expect(error.isRetryable, isTrue);
    });

    test('should return false for non-retryable OcrException', () {
      const error = OcrException(
        message: 'No text',
        failureType: OcrFailureType.noTextDetected,
      );

      expect(error.isRetryable, isFalse);
    });

    test('should return true for retryable GeminiApiException', () {
      const error = GeminiApiException(
        message: 'Timeout',
        errorCode: GeminiErrorCode.timeout,
      );

      expect(error.isRetryable, isTrue);
    });

    test('should return true for retryable server error', () {
      const error = GeminiApiException(
        message: 'Server error',
        errorCode: GeminiErrorCode.serverError,
      );

      expect(error.isRetryable, isTrue);
    });

    test('should return false for authentication error', () {
      const error = GeminiApiException(
        message: 'Auth failed',
        errorCode: GeminiErrorCode.authenticationFailed,
      );

      expect(error.isRetryable, isFalse);
    });

    test('should return true for retryable NetworkException', () {
      const error = NetworkException(
        message: 'Timeout',
        failureType: NetworkFailureType.timeout,
      );

      expect(error.isRetryable, isTrue);
    });

    test('should return false for non-retryable errors', () {
      const error = NetworkException(
        message: 'SSL error',
        failureType: NetworkFailureType.sslError,
      );

      expect(error.isRetryable, isFalse);
    });
  });

  group('AppErrorX Extension - canFallback', () {
    test('should return true for fallbackable GeminiApiException', () {
      const error = GeminiApiException(
        message: 'Timeout',
        errorCode: GeminiErrorCode.timeout,
      );

      expect(error.canFallback, isTrue);
    });

    test('should return false for authentication error', () {
      const error = GeminiApiException(
        message: 'Auth failed',
        errorCode: GeminiErrorCode.authenticationFailed,
      );

      expect(error.canFallback, isFalse);
    });

    test('should return true for network timeout OcrException', () {
      const error = OcrException(
        message: 'Timeout',
        failureType: OcrFailureType.networkTimeout,
      );

      expect(error.canFallback, isTrue);
    });

    test('should return true for rate limit OcrException', () {
      const error = OcrException(
        message: 'Rate limited',
        failureType: OcrFailureType.rateLimitExceeded,
      );

      expect(error.canFallback, isTrue);
    });

    test('should return false for other error types', () {
      const error = FileOperationException(
        message: 'File error',
        operationType: FileOperationType.fileNotFound,
      );

      expect(error.canFallback, isFalse);
    });
  });

  group('AppErrorX Extension - recoverySuggestion', () {
    test('should provide suggestion for timeout error', () {
      const error = GeminiApiException(
        message: 'Timeout',
        errorCode: GeminiErrorCode.timeout,
      );

      expect(
        error.recoverySuggestion,
        contains('stable internet connection'),
      );
    });

    test('should provide suggestion for quota exceeded error', () {
      const error = GeminiApiException(
        message: 'Quota',
        errorCode: GeminiErrorCode.quotaExceeded,
      );

      expect(
        error.recoverySuggestion,
        contains('Wait a few minutes'),
      );
    });

    test('should provide suggestion for authentication error', () {
      const error = GeminiApiException(
        message: 'Auth failed',
        errorCode: GeminiErrorCode.authenticationFailed,
      );

      expect(
        error.recoverySuggestion,
        contains('verify your API key'),
      );
    });

    test('should provide suggestion for NetworkException', () {
      const error = NetworkException(
        message: 'Network error',
        failureType: NetworkFailureType.noConnection,
      );

      expect(
        error.recoverySuggestion,
        contains('Check your internet connection'),
      );
    });

    test('should provide suggestion for low resolution OCR error', () {
      const error = OcrException(
        message: 'Low resolution',
        failureType: OcrFailureType.lowResolution,
      );

      expect(
        error.recoverySuggestion,
        contains('higher resolution image'),
      );
    });

    test('should provide suggestion for no text detected OCR error', () {
      const error = OcrException(
        message: 'No text',
        failureType: OcrFailureType.noTextDetected,
      );

      expect(
        error.recoverySuggestion,
        contains('clear, visible text'),
      );
    });

    test('should provide generic suggestion for unknown errors', () {
      const error = FileOperationException(
        message: 'Unknown',
        operationType: FileOperationType.unknown,
      );

      expect(
        error.recoverySuggestion,
        contains('contact support'),
      );
    });
  });

  group('Edge Cases', () {
    test('should handle empty error messages', () {
      final error = GeminiApiException.fromException(Exception(''));
      expect(error, isA<GeminiApiException>());
    });

    test('should handle null-like strings', () {
      final error = FileOperationException.fromException(
        Exception('null'),
        'test',
      );
      expect(error, isA<FileOperationException>());
    });

    test('should handle very long error messages', () {
      final longMessage = 'Error: ' + 'x' * 10000;
      final error = NetworkException.fromException(Exception(longMessage));
      expect(error, isA<NetworkException>());
    });

    test('should handle special characters in error messages', () {
      final error = GeminiApiException.fromException(
        Exception('Error: @#\$%^&*()'),
      );
      expect(error, isA<GeminiApiException>());
    });

    test('should handle Unicode characters in error messages', () {
      final error = MLKitException.fromException(
        Exception('错误：无法处理图像'),
      );
      expect(error, isA<MLKitException>());
    });
  });

  group('Timestamp Consistency', () {
    test('should create timestamps close to current time', () {
      final before = DateTime.now();
      const error = OcrException(
        message: 'Test',
        failureType: OcrFailureType.unknown,
      );
      final after = DateTime.now();

      expect(error.timestamp.isAfter(before), isTrue);
      expect(error.timestamp.isBefore(after), isTrue);
    });

    test('should accept custom timestamp', () {
      final customTime = DateTime(2024, 1, 1, 12, 0, 0);
      final error = OcrException(
        message: 'Test',
        failureType: OcrFailureType.unknown,
        timestamp: customTime,
      );

      expect(error.timestamp, equals(customTime));
    });
  });
}
