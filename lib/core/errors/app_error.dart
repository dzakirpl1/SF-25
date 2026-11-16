class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppError(this.message, {this.code, this.originalError});

  @override
  String toString() => message;

  factory AppError.fromPostgres(dynamic error) {
    return AppError(mapMessage(error), originalError: error);
  }

  static String mapMessage(dynamic error) {
    final str = error.toString().toLowerCase();
    if (str.contains('invalid login credentials') ||
        str.contains('invalid_grant')) {
      return 'Email atau kata sandi tidak valid.';
    }
    if (str.contains('network') ||
        str.contains('socketexception') ||
        str.contains('failed to connect')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    if (str.contains('jwt expired') || str.contains('pgrst301')) {
      return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    }
    if (str.contains('p0001') || str.contains('kategori sedang digunakan')) {
      return 'Kategori sedang digunakan oleh catatan aktif dan tidak dapat dihapus.';
    }
    return 'Terjadi kesalahan sistem. Silakan coba kembali.';
  }
}
