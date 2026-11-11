part of 'search_cubit.dart';

@immutable
sealed class SearchState {}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchSuccess extends SearchState {
  final List<UserModel> users;
  final bool hasMore;
  final bool isLoadingMore;

  SearchSuccess({required this.users,
    required this.hasMore, 
    this.isLoadingMore = false
    });
}

final class SearchEmpty extends SearchState {}

final class SearchFailure extends SearchState {
  final String message;

  SearchFailure({required this.message});
}