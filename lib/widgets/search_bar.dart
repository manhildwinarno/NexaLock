import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppTheme.outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Search by name, method, or status...',
                hintStyle: TextStyle(
                  color: AppTheme.outline,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox(width: 16);
              return IconButton(
                onPressed: () => controller.clear(),
                icon: const Icon(Icons.close_rounded, color: AppTheme.outline, size: 20),
                splashRadius: 20,
              );
            },
          ),
        ],
      ),
    );
  }
}
