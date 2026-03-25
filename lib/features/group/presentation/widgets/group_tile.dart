import 'package:flutter/material.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';
import 'package:pulse_chat/features/group/domain/entities/group_entity.dart';

class GroupTile extends StatelessWidget {
  final GroupEntity group;
  final VoidCallback onTap;

  const GroupTile({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final groupColor = group.color != null
        ? Color(group.color!)
        : AppColors.primary;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: groupColor,
        backgroundImage: group.avatarUrl != null
            ? NetworkImage(group.avatarUrl!)
            : null,
        child: group.avatarUrl == null
            ? Text(
                group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                style: const TextStyle(color: AppColors.white),
              )
            : null,
      ),
      title: Text(group.name),
      subtitle: Text(
        group.description ?? StringConstants.noDescription,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${group.members.length} members',
        style: TextStyle(color: AppColors.grey600, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}
