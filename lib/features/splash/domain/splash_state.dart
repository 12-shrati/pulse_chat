enum SplashStatus {
  loading,
  success,
  error,
}

class SplashState {
  final SplashStatus status;

  SplashState({required this.status});

  SplashState copyWith({SplashStatus? status}) {
    return SplashState(
      status: status ?? this.status,
    );
  }
}