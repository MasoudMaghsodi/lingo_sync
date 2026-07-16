// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dailyTaskRepository)
final dailyTaskRepositoryProvider = DailyTaskRepositoryProvider._();

final class DailyTaskRepositoryProvider
    extends
        $FunctionalProvider<
          DailyTaskRepository,
          DailyTaskRepository,
          DailyTaskRepository
        >
    with $Provider<DailyTaskRepository> {
  DailyTaskRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyTaskRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyTaskRepositoryHash();

  @$internal
  @override
  $ProviderElement<DailyTaskRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyTaskRepository create(Ref ref) {
    return dailyTaskRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyTaskRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyTaskRepository>(value),
    );
  }
}

String _$dailyTaskRepositoryHash() =>
    r'9a7e0365a0f80d8e5cf822f30ec60c59e3ffc815';

/// Tasks for a single day of the 50-day plan, keyed by [dayNumber].
///
/// Riverpod generates a family provider automatically because [build] takes
/// an argument — this replaces the old hand-written
/// `StateNotifierProvider.family`, so this module now follows the same
/// `@riverpod` code-gen pattern used across the rest of the app (Auth,
/// Pomodoro, Settings, Dictionary, Mentor).
//
// keepAlive: true — the original StateNotifierProvider.family was a plain
// (non-autoDispose) provider, so each day's fetched task list stayed cached
// for the app's lifetime once loaded. Keeping that same behavior here.

@ProviderFor(DailyTasks)
final dailyTasksProvider = DailyTasksFamily._();

/// Tasks for a single day of the 50-day plan, keyed by [dayNumber].
///
/// Riverpod generates a family provider automatically because [build] takes
/// an argument — this replaces the old hand-written
/// `StateNotifierProvider.family`, so this module now follows the same
/// `@riverpod` code-gen pattern used across the rest of the app (Auth,
/// Pomodoro, Settings, Dictionary, Mentor).
//
// keepAlive: true — the original StateNotifierProvider.family was a plain
// (non-autoDispose) provider, so each day's fetched task list stayed cached
// for the app's lifetime once loaded. Keeping that same behavior here.
final class DailyTasksProvider
    extends $AsyncNotifierProvider<DailyTasks, List<DailyTaskModel>> {
  /// Tasks for a single day of the 50-day plan, keyed by [dayNumber].
  ///
  /// Riverpod generates a family provider automatically because [build] takes
  /// an argument — this replaces the old hand-written
  /// `StateNotifierProvider.family`, so this module now follows the same
  /// `@riverpod` code-gen pattern used across the rest of the app (Auth,
  /// Pomodoro, Settings, Dictionary, Mentor).
  //
  // keepAlive: true — the original StateNotifierProvider.family was a plain
  // (non-autoDispose) provider, so each day's fetched task list stayed cached
  // for the app's lifetime once loaded. Keeping that same behavior here.
  DailyTasksProvider._({
    required DailyTasksFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'dailyTasksProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyTasksHash();

  @override
  String toString() {
    return r'dailyTasksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DailyTasks create() => DailyTasks();

  @override
  bool operator ==(Object other) {
    return other is DailyTasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyTasksHash() => r'ca39c8f1e24fcf94f4c0a4e2367b490ff78f2803';

/// Tasks for a single day of the 50-day plan, keyed by [dayNumber].
///
/// Riverpod generates a family provider automatically because [build] takes
/// an argument — this replaces the old hand-written
/// `StateNotifierProvider.family`, so this module now follows the same
/// `@riverpod` code-gen pattern used across the rest of the app (Auth,
/// Pomodoro, Settings, Dictionary, Mentor).
//
// keepAlive: true — the original StateNotifierProvider.family was a plain
// (non-autoDispose) provider, so each day's fetched task list stayed cached
// for the app's lifetime once loaded. Keeping that same behavior here.

final class DailyTasksFamily extends $Family
    with
        $ClassFamilyOverride<
          DailyTasks,
          AsyncValue<List<DailyTaskModel>>,
          List<DailyTaskModel>,
          FutureOr<List<DailyTaskModel>>,
          int
        > {
  DailyTasksFamily._()
    : super(
        retry: null,
        name: r'dailyTasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Tasks for a single day of the 50-day plan, keyed by [dayNumber].
  ///
  /// Riverpod generates a family provider automatically because [build] takes
  /// an argument — this replaces the old hand-written
  /// `StateNotifierProvider.family`, so this module now follows the same
  /// `@riverpod` code-gen pattern used across the rest of the app (Auth,
  /// Pomodoro, Settings, Dictionary, Mentor).
  //
  // keepAlive: true — the original StateNotifierProvider.family was a plain
  // (non-autoDispose) provider, so each day's fetched task list stayed cached
  // for the app's lifetime once loaded. Keeping that same behavior here.

  DailyTasksProvider call(int dayNumber) =>
      DailyTasksProvider._(argument: dayNumber, from: this);

  @override
  String toString() => r'dailyTasksProvider';
}

/// Tasks for a single day of the 50-day plan, keyed by [dayNumber].
///
/// Riverpod generates a family provider automatically because [build] takes
/// an argument — this replaces the old hand-written
/// `StateNotifierProvider.family`, so this module now follows the same
/// `@riverpod` code-gen pattern used across the rest of the app (Auth,
/// Pomodoro, Settings, Dictionary, Mentor).
//
// keepAlive: true — the original StateNotifierProvider.family was a plain
// (non-autoDispose) provider, so each day's fetched task list stayed cached
// for the app's lifetime once loaded. Keeping that same behavior here.

abstract class _$DailyTasks extends $AsyncNotifier<List<DailyTaskModel>> {
  late final _$args = ref.$arg as int;
  int get dayNumber => _$args;

  FutureOr<List<DailyTaskModel>> build(int dayNumber);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<DailyTaskModel>>, List<DailyTaskModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<DailyTaskModel>>,
                List<DailyTaskModel>
              >,
              AsyncValue<List<DailyTaskModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
