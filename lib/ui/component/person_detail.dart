import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:holo/entity/person.dart';
import 'package:holo/ui/component/cache_image.dart';

Future<void> showPersonDetailBottomSheet(Person person, BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      return SafeArea(
        right: false,
        left: false,
        top: false,
        bottom: true,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.only(top: 12, right: 12, left: 12),
          child: Row(
            spacing: 4,
            children: [
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CacheImage(
                    imageUrl: person.images?.large ?? '',
                    fit: BoxFit.fitHeight,
                    memCacheHeight: null,
                    memCacheWidth: null,
                  ),
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        person.name ?? "detail.unknown".tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (person.actors?.isNotEmpty ?? false)
                        Text(
                          'CV: ${person.actors?.map((e) => e.name).join('·') ?? ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      Text(
                        person.relation ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      Text(
                        person.summary ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
