import 'dart:io';

import 'package:flutter_layered_architecture/application/state/overlay_loading_provider.dart';
import 'package:flutter_layered_architecture/domain/service/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/post/entity/post.dart';
import '../../../domain/post/post_repository.dart';
import '../../../domain/user/entity/user.dart';
import '../run_usecase_mixin.dart';

/// 投稿ユースケースプロバイダー
final postUsecaseProvider = Provider<PostUsecase>(
  (ref) => PostUsecase(
    postRepository: ref.watch(postRepositoryProvider),
    storageService: ref.watch(storageServiceProvider),
    loadingController: ref.watch(overlayLoadingProvider.notifier),
  ),
);

/// 投稿ユースケース
class PostUsecase with RunUsecaseMixin {
  PostUsecase({
    required this.postRepository,
    required this.storageService,
    required this.loadingController,
  });

  final PostRepository postRepository;
  final StorageService storageService;
  final StateController<bool> loadingController;

  /// 新規投稿をする
  Future<void> addPost({
    required File? image,
    required String comment,
    required User? user,
  }) async {
    if (image == null) {
      throw Exception('画像を選択してください');
    }
    if (user == null) {
      throw Exception('エラーが発生しました');
    }
    await execute(
        loadingController: loadingController,
        action: () async {
          final imageUrl = await storageService.uploadImage(image: image);
          await postRepository.add(
            post: Post(
              id: null,
              user: user,
              imageUrl: imageUrl,
              comment: comment,
              createdAt: DateTime.now(),
            ),
          );
        });
  }

  /// 投稿の全件取得処理
  ///
  /// 取得後に作成日時が新しい順に並び替える
  Future<List<Post>> fetchAll() async {
    final posts = await execute(action: () async {
      return await postRepository.fetchAll();
    });

    final sortedPosts = posts
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return sortedPosts;
  }
}
