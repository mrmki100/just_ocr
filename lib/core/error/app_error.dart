// lib/core/error/app_error.dart
//
// Centralized error hierarchy for all API failures and OCR operations.
// Using sealed classes ensures exhaustive switching at compile time,
// preventing unhandled error scenarios from reaching the UI.

import 'package:equatable/equatable.dart';

/// Base class for all application errors.
/// All errors are equatable to enable proper state comparison in Riverpod.
sealed class AppError extends Equatable {
  final String message;
  final String? technicalDetails;
  final DateTime timestamp;

  const AppError({
    required this.message,
    this.technicalDetails,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [message, technicalDetails, timestamp];
}

// ---------------------------------------------------------------------------
// OCR-specific errors
// ---------------------------------------------------------------------------

/// Error during OCR processing (applies to both Gemini and ML Kit)
final class OcrException extends AppError {
  final OcrFailureType failureType;

  const OcrException({
    required super.message,
    super.technicalDetails,
    required this.failureType,
  });

  @override
  List<Object?> get props => [...super.props, failureType];
}

/// Categorizes OCR failure modes for precise error handling and recovery
enum OcrFailureType {
  /// No text detected in the image
  noTextDetected,
  
  /// Image file is corrupted or unreadable
  invalidImageFormat,
  
  /// Image resolution too low for accurate OCR
  lowResolution,
  
  /// Network timeout during cloud OCR
  networkTimeout,
  
  /// API rate limit exceeded
  rateLimitExceeded,
  
  /// Authentication/authorization failure
  authenticationFailed,
  
  /// API returned malformed response
  invalidApiResponse,
  
  /// Unknown/unexpected error
  unknown,
}

// ---------------------------------------------------------------------------
// API-specific errors
// ---------------------------------------------------------------------------

/// Gemini API specific errors
final class GeminiApiException extends AppError {
  final GeminiErrorCode errorCode;

  const GeminiApiException({
    required super.message,
    super.technicalDetails,
    required this.errorCode,
  });

  factory GeminiApiException.fromException(Object error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return const GeminiApiException(
        message: 'Connection timed out. Please check your internet connection.',
        errorCode: GeminiErrorCode.timeout,
      );
    }
    
    if (errorStr.contains('quota') || errorStr.contains('rate limit')) {
      return const GeminiApiException(
        message: 'API quota exceeded. Please try again later.',
        errorCode: GeminiErrorCode.quotaExceeded,
      );
    }
    
    if (errorStr.contains('unauthorized') || errorStr.contains('invalid api key') || 
        errorStr.contains('authentication')) {
      return const GeminiApiException(
        message: 'Authentication failed. Please verify your API key.',
        errorCode: GeminiErrorCode.authenticationFailed,
      );
    }
    
    if (errorStr.contains('permission')) {
      return const GeminiApiException(
        message: 'Permission denied. API access may be restricted.',
        errorCode: GeminiErrorCode.permissionDenied,
      );
    }
    
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return const GeminiApiException(
        message: 'Requested resource not found.',
        errorCode: GeminiErrorCode.resourceNotFound,
      );
    }
    
    if (errorStr.contains('server error') || errorStr.contains('500')) {
      return const GeminiApiException(
        message: 'Gemini server error. Please try again later.',
        errorCode: GeminiErrorCode.serverError,
      );
    }
    
    // Default: generic API error
    return GeminiApiException(
      message: 'Gemini API error occurred.',
      technicalDetails: error.toString(),
      errorCode: GeminiErrorCode.unknown,
    );
  }

  @override
  List<Object?> get props => [...super.props, errorCode];
}

/// Gemini API error codes for precise error handling
enum GeminiErrorCode {
  timeout,
  quotaExceeded,
  authenticationFailed,
  permissionDenied,
  resourceNotFound,
  serverError,
  invalidRequest,
  unknown,
}

/// ML Kit specific errors
final class MLKitException extends AppError {
  final MLKitFailureType failureType;

  const MLKitException({
    required super.message,
    super.technicalDetails,
    required this.failureType,
  });

  factory MLKitException.fromException(Object error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('no text')) {
      return const MLKitException(
        message: 'No text detected in the image.',
        failureType: MLKitFailureType.noTextDetected,
      );
    }
    
    if (errorStr.contains('invalid') || errorStr.contains('corrupt')) {
      return const MLKitException(
        message: 'Invalid or corrupted image file.',
        failureType: MLKitFailureType.invalidImage,
      );
    }
    
    if (errorStr.contains('model') || errorStr.contains('download')) {
      return const MLKitException(
        message: 'ML Kit model unavailable. Please check your connection.',
        failureType: MLKitFailureType.modelUnavailable,
      );
    }
    
    // Default: generic ML Kit error
    return MLKitException(
      message: 'ML Kit processing failed.',
      technicalDetails: error.toString(),
      failureType: MLKitFailureType.unknown,
    );
  }

  @override
  List<Object?> get props => [...super.props, failureType];
}

/// ML Kit failure modes
enum MLKitFailureType {
  noTextDetected,
  invalidImage,
  modelUnavailable,
  processingFailed,
  unknown,
}

// ---------------------------------------------------------------------------
// File operation errors
// ---------------------------------------------------------------------------

/// File-related errors (PDF parsing, image loading, etc.)
final class FileOperationException extends AppError {
  final FileOperationType operationType;

  const FileOperationException({
    required super.message,
    super.technicalDetails,
    required this.operationType,
  });

  factory FileOperationException.fromException(Object error, String operation) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('permission')) {
      return FileOperationException(
        message: 'Permission denied. Cannot access the file.',
        technicalDetails: error.toString(),
        operationType: FileOperationType.permissionDenied,
      );
    }
    
    if (errorStr.contains('not found') || errorStr.contains('no such file')) {
      return FileOperationException(
        message: 'File not found.',
        technicalDetails: error.toString(),
        operationType: FileOperationType.fileNotFound,
      );
    }
    
    if (errorStr.contains('space') || errorStr.contains('storage')) {
      return FileOperationException(
        message: 'Insufficient storage space.',
        technicalDetails: error.toString(),
        operationType: FileOperationType.insufficientStorage,
      );
    }
    
    if (errorStr.contains('corrupt') || errorStr.contains('invalid format')) {
      return FileOperationException(
        message: 'File is corrupted or in an unsupported format.',
        technicalDetails: error.toString(),
        operationType: FileOperationType.corruptedFile,
      );
    }
    
    // Default based on operation
    return FileOperationException(
      message: 'File operation failed: $operation',
      technicalDetails: error.toString(),
      operationType: FileOperationType.unknown,
    );
  }

  @override
  List<Object?> get props => [...super.props, operationType];
}

enum FileOperationType {
  permissionDenied,
  fileNotFound,
  insufficientStorage,
  corruptedFile,
  readFailed,
  writeFailed,
  unknown,
}

// ---------------------------------------------------------------------------
// Network errors
// ---------------------------------------------------------------------------

/// Network connectivity errors
final class NetworkException extends AppError {
  final NetworkFailureType failureType;

  const NetworkException({
    required super.message,
    super.technicalDetails,
    required this.failureType,
  });

  factory NetworkException.fromException(Object error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socket') || errorStr.contains('connection refused')) {
      return const NetworkException(
        message: 'Cannot connect to server. Please check your internet connection.',
        failureType: NetworkFailureType.connectionRefused,
      );
    }
    
    if (errorStr.contains('timeout')) {
      return const NetworkException(
        message: 'Connection timed out. Please try again.',
        failureType: NetworkFailureType.timeout,
      );
    }
    
    if (errorStr.contains('ssl') || errorStr.contains('certificate')) {
      return const NetworkException(
        message: 'Secure connection failed. Please check your date/time settings.',
        failureType: NetworkFailureType.sslError,
      );
    }
    
    if (errorStr.contains('no internet') || errorStr.contains('network is unreachable')) {
      return const NetworkException(
        message: 'No internet connection available.',
        failureType: NetworkFailureType.noConnection,
      );
    }
    
    // Default: generic network error
    return NetworkException(
      message: 'Network error occurred.',
      technicalDetails: error.toString(),
      failureType: NetworkFailureType.unknown,
    );
  }

  @override
  List<Object?> get props => [...super.props, failureType];
}

enum NetworkFailureType {
  noConnection,
  connectionRefused,
  timeout,
  sslError,
  dnsFailure,
  unknown,
}

// ---------------------------------------------------------------------------
// Error recovery strategies
// ---------------------------------------------------------------------------

/// Suggests recovery actions for each error type
extension AppErrorX on AppError {
  /// Whether the error is recoverable with retry
  bool get isRetryable {
    if (this is OcrException) {
      final ocrError = this as OcrException;
      return ocrError.failureType == OcrFailureType.networkTimeout ||
             ocrError.failureType == OcrFailureType.unknown;
    }
    
    if (this is GeminiApiException) {
      final geminiError = this as GeminiApiException;
      return geminiError.errorCode == GeminiErrorCode.timeout ||
             geminiError.errorCode == GeminiErrorCode.serverError;
    }
    
    if (this is NetworkException) {
      final networkError = this as NetworkException;
      return networkError.failureType == NetworkFailureType.timeout ||
             networkError.failureType == NetworkFailureType.connectionRefused;
    }
    
    return false;
  }

  /// Whether fallback to alternative method is possible
  bool get canFallback {
    if (this is GeminiApiException) {
      final geminiError = this as GeminiApiException;
      // Can fallback to ML Kit for most Gemini errors except auth issues
      return geminiError.errorCode != GeminiErrorCode.authenticationFailed;
    }
    
    if (this is OcrException) {
      final ocrError = this as OcrException;
      return ocrError.failureType == OcrFailureType.networkTimeout ||
             ocrError.failureType == OcrFailureType.rateLimitExceeded;
    }
    
    return false;
  }

  /// User-friendly action suggestion
  String get recoverySuggestion {
    if (this is GeminiApiException) {
      final geminiError = this as GeminiApiException;
      switch (geminiError.errorCode) {
        case GeminiErrorCode.timeout:
          return 'Try again with a stable internet connection.';
        case GeminiErrorCode.quotaExceeded:
          return 'Wait a few minutes before retrying.';
        case GeminiErrorCode.authenticationFailed:
          return 'Please verify your API key in settings.';
        default:
          return 'Please try again later.';
      }
    }
    
    if (this is NetworkException) {
      return 'Check your internet connection and try again.';
    }
    
    if (this is OcrException) {
      final ocrError = this as OcrException;
      if (ocrError.failureType == OcrFailureType.lowResolution) {
        return 'Try capturing a higher resolution image.';
      }
      if (ocrError.failureType == OcrFailureType.noTextDetected) {
        return 'Ensure the image contains clear, visible text.';
      }
    }
    
    return 'Please try again or contact support if the issue persists.';
  }
}