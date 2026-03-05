import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A platform-adaptive search bar.
///
/// iOS: [CupertinoSearchTextField] — rounded gray pill, inset icon, cancel button.
/// Android: [TextField] with search [InputDecoration].
class AdaptiveSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String placeholder;
  final bool autofocus;
  final FocusNode? focusNode;

  const AdaptiveSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.placeholder = 'Search',
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoSearchTextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onSuffixTap: () {
          controller?.clear();
          onChanged?.call('');
          onClear?.call();
        },
        placeholder: placeholder,
        autofocus: autofocus,
        focusNode: focusNode,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        placeholderStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      );
    }

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller != null
            ? ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller!,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller!.clear();
                      onChanged?.call('');
                      onClear?.call();
                    },
                  );
                },
              )
            : null,
      ),
    );
  }
}
