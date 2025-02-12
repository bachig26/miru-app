import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/controllers/detail_controller.dart';
import 'package:miru_app/views/widgets/detail/detail_continue_play.dart';
import 'package:miru_app/views/widgets/detail/detail_extension_tile.dart';
import 'package:miru_app/views/widgets/detail/detail_favorite_button.dart';
import 'package:miru_app/views/widgets/cache_network_image.dart';

class DetailAppbarflexibleSpace extends StatefulWidget {
  const DetailAppbarflexibleSpace({
    super.key,
    this.tag,
  });

  final String? tag;

  @override
  State<DetailAppbarflexibleSpace> createState() =>
      _DetailAppbarflexibleSpaceState();
}

class _DetailAppbarflexibleSpaceState extends State<DetailAppbarflexibleSpace> {
  late DetailPageController c = Get.find(tag: widget.tag);

  double _offset = 1;
  // static const anlistExtensionMap = <ExtensionType, String>{
  //   ExtensionType.bangumi: "ANIME",
  //   ExtensionType.manga: "MANGA",
  // };

  @override
  void initState() {
    c.scrollController.addListener(() {
      setState(() {
        _offset = c.scrollController.offset;
      });
    });
    super.initState();
  }

  double _scrollListener() {
    if (_offset <= 0) {
      return 1;
    } else if (_offset >= 270) {
      return 0;
    } else {
      return (_offset - 270) / (0 - 270);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool needShowCover() {
      if (c.isLoading.value) {
        return true;
      }
      if (c.data.value?.cover != null) {
        return true;
      }
      return false;
    }

    return Obx(
      () => Opacity(
        opacity: _scrollListener(),
        child: Stack(
          children: [
            SizedBox(
                height: 400,
                width: double.infinity,
                child: const SizedBox.shrink()),
            Positioned(
              left: 20,
              bottom: 135,
              right: 20,
              child: Row(
                children: [
                  if (needShowCover())
                    Hero(
                      tag: c.heroTag ?? '',
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          height: 150,
                          width: 100,
                          child: c.isLoading.value
                              ? const Center(child: CircularProgressIndicator())
                              : CacheNetWorkImagePic(
                                  c.data.value?.cover ?? '',
                                  fit: BoxFit.cover,
                                  headers: c.detail?.headers,
                                  canFullScreen: true,
                                ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.isLoading.value ? "" : c.data.value!.title,
                            softWrap: true,
                            style: Get.theme.textTheme.titleLarge,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          DetailExtensionTile(
                            tag: widget.tag,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              top: null,
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DetailContinuePlay(
                          tag: widget.tag,
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      DetailFavoriteButton(
                        tag: widget.tag,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
