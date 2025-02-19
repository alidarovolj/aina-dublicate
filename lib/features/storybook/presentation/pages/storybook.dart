import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:aina_flutter/core/widgets/custom_button.dart';

class StorybookScreen extends StatelessWidget {
  const StorybookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storybook'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Storybook(
        stories: [
          Story(
            name: 'Custom Button',
            description: 'A simple customizable button.',
            builder: (context) {
              final label =
                  context.knobs.text(label: 'Label', initial: 'Click Me');
              final enabled =
                  context.knobs.boolean(label: 'Enabled', initial: true);
              final color = context.knobs.options<Color>(
                label: 'Color',
                initial: Colors.blue,
                options: [
                  const Option(label: 'Blue', value: Colors.blue),
                  const Option(label: 'Green', value: Colors.green),
                  const Option(label: 'Red', value: Colors.red),
                  const Option(label: 'Grey', value: Colors.grey),
                ],
              );
              final iconEnabled = context.knobs.boolean(
                label: 'Show Icon',
                initial: true,
              );

              return Center(
                child: CustomButton(
                  label: label,
                  // onPressed: enabled
                  //     ? () => // print('Button pressed')
                  //         // type
                  //         : ButtonType.normal,
                  isFullWidth: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
