import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_day_provider.g.dart';

@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  int build() => 1;

  void setDay(int day) => state = day;
}
