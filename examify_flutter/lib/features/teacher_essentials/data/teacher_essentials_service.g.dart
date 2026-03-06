// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_essentials_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teacherEssentialsService)
final teacherEssentialsServiceProvider = TeacherEssentialsServiceProvider._();

final class TeacherEssentialsServiceProvider
    extends
        $FunctionalProvider<
          TeacherEssentialsService,
          TeacherEssentialsService,
          TeacherEssentialsService
        >
    with $Provider<TeacherEssentialsService> {
  TeacherEssentialsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teacherEssentialsServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teacherEssentialsServiceHash();

  @$internal
  @override
  $ProviderElement<TeacherEssentialsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TeacherEssentialsService create(Ref ref) {
    return teacherEssentialsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeacherEssentialsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeacherEssentialsService>(value),
    );
  }
}

String _$teacherEssentialsServiceHash() =>
    r'4d1759fe6cd0cdc934afd8b9aa6570ed7f656c93';
