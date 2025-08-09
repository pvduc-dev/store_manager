import 'package:flutter/material.dart';
import 'package:store_manager/widgets/atom/text_field.dart';

class DesignSystemScreen extends StatelessWidget {
  const DesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Text Field',
              hint: 'Text Field',
              controller: TextEditingController(),
            ),
            AppTextField(
              label: 'Text Field',
              hint: 'Text Field',
              controller: TextEditingController(),
            ),
          ],
        ),
      ),
    );
  }
}
