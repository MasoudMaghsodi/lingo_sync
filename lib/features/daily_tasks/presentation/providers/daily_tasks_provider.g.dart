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

@ProviderFor(DailyTasks)
final dailyTasksProvider = DailyTasksFamily._();

final class DailyTasksProvider
    extends $AsyncNotifierProvider<DailyTasks, List<DailyTaskModel>> {
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

String _$dailyTasksHash() => r'73164b86fbd08379973c97ce44bb4d77a910a09b';

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

  DailyTasksProvider call(int dayNumber) =>
      DailyTasksProvider._(argument: dayNumber, from: this);

  @override
  String toString() => r'dailyTasksProvider';
}

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
