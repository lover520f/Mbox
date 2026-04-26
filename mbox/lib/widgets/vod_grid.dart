import 'package:flutter/material.dart';
import '../../models/vod.dart';
import '../../widgets/vod_card.dart';

/// 视频网格列表
class VodGrid extends StatelessWidget {
  final List<Vod>? items;

  const VodGrid({super.key, this.items});

  @override
  Widget build(BuildContext context) {
    // 如果没有传入 items，使用占位数据
    final displayItems = items ?? [];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayItems.isEmpty ? 6 : displayItems.length,
      itemBuilder: (context, index) {
        if (displayItems.isEmpty) {
          return _buildPlaceholderCard();
        } else {
          return VodCard(vod: displayItems[index]);
        }
      },
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 60,
                  color: Colors.grey[700],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
