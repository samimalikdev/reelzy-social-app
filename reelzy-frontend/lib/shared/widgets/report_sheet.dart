import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/service/authentication.dart';
import 'dart:ui';

class ReportSheet extends StatelessWidget {
  final String targetId;
  final String targetType;

  const ReportSheet({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  Widget build(BuildContext context) {
    final reasons = [
      {'icon': Icons.block, 'label': 'Spam', 'value': 'spam'},
      {'icon': Icons.warning_rounded, 'label': 'Abuse', 'value': 'abuse'},
      {'icon': Icons.person_off, 'label': 'Harassment', 'value': 'harassment'},
      {'icon': Icons.no_photography, 'label': 'Nudity', 'value': 'nudity'},
      {'icon': Icons.verified_user_outlined, 'label': 'Fake Account', 'value': 'fake'},
      {'icon': Icons.heart_broken, 'label': 'Hate Speech', 'value': 'hate'},
      {'icon': Icons.more_horiz, 'label': 'Other', 'value': 'other'},
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
          color:  Colors.white.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  'Report ${targetType == 'user' ? 'User' : 'Content'}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Help us understand what\'s happening',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Scrollable list
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: reasons.map((reason) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await ApiController().post('/report', {
                                  'reporterId': AuthenticationService().userId,
                                  'targetType': targetType,
                                  'targetId': targetId,
                                  'reason': reason['value'],
                                });

                                Get.back();
                                Get.snackbar(
                                  'Report Sent',
                                  'Thanks for keeping our community safe',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.black87,
                                  colorText: Colors.white,
                                  borderRadius: 12,
                                  margin: const EdgeInsets.all(16),
                                  icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                                  duration: const Duration(seconds: 3),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        reason['icon'] as IconData,
                                        color: Colors.red.shade400,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        reason['label'] as String,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}