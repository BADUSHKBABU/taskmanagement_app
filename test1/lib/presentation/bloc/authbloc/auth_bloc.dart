import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/domain/usecase/auth_usecases.dart';
import 'package:test1/presentation/bloc/authbloc/auth_event.dart';
import 'package:test1/presentation/bloc/authbloc/auth_state.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthInitialState()) {
    on<CheckAuthEvent>(onCheckAuth);
    on<SignInEvent>(onSignIn);
    on<SignUpEvent>(onSignUp);
    on<SignOutEvent>(onSignOut);
    on<ClearAuthErrorEvent>(onClearAuthError);

    add(const CheckAuthEvent());
  }

  Future<void> onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {

    emit(const AuthLoadingState());
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
      
        emit(AuthenticatedState(user));
      } else {
        print("AuthBloc User is not authenticated");
        emit(const UnauthenticatedState());
      }
    } catch (e) {

      emit(const UnauthenticatedState());
    }
  }

  Future<void> onSignIn(SignInEvent event, Emitter<AuthState> emit) async {

    emit(const AuthLoadingState());
    try {
      final user = await signInUseCase(event.email, event.password);

      emit(AuthenticatedState(user));
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {

    emit(const AuthLoadingState());
    try {
      final user = await signUpUseCase(event.email, event.password, event.name);

      emit(AuthenticatedState(user));
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {

    emit(const AuthLoadingState());
    try {
      await signOutUseCase();

      emit(const UnauthenticatedState());
    } catch (e) {

      emit(const UnauthenticatedState());
    }
  }

  void onClearAuthError(ClearAuthErrorEvent event, Emitter<AuthState> emit) {
    if (state is AuthErrorState) {
      emit(const UnauthenticatedState());
    }
  }
}
