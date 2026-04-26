import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vod_config.dart';
import '../../provider/config_provider.dart';

/// 站点列表
class SourceList extends StatelessWidget {
  final List<Site> sites;
  final Function(Site)? onSourceSelected;

  const SourceList({
    super.key,
    required this.sites,
    this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sites.length,
      itemBuilder: (context, index) {
        final site = sites[index];
        return ListTile(
          title: Text(
            site.name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '类型：${site.type}',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          onTap: () {
            onSourceSelected?.call(site);
          },
        );
      },
    );
  }
}
