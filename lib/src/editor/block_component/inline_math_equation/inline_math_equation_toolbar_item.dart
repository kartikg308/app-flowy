
import 'package:appflowy_editor/appflowy_editor.dart';

import 'inline_math_equation.dart';

final ToolbarItem inlineMathEquationItem = ToolbarItem(
  id: 'editor.inline_math_equation',
  group: 2,
  isActive: onlyShowInSingleSelectionAndTextType,
  builder: (context, editorState, highlightColor, _) {
    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);
    final isHighlight = nodes.allSatisfyInSelection(selection, (delta) {
      return delta.everyAttributes(
        (attributes) => attributes[InlineMathEquationKeys.type] != null,
      );
    });
    return SVGIconItemWidget(
      isHighlight: isHighlight,
      highlightColor: highlightColor,
      onPressed: () async {
        final selection = editorState.selection;
        if (selection == null || selection.isCollapsed) {
          return;
        }
        final node = editorState.getNodeAtPath(selection.start.path);
        final delta = node?.delta;
        if (node == null || delta == null) {
          return;
        }

        final transaction = editorState.transaction;
        if (isHighlight) {
          final formula = delta
              .slice(selection.startIndex, selection.endIndex)
              .whereType<TextInsert>()
              .firstOrNull
              ?.attributes?[InlineMathEquationKeys.type];
          assert(formula != null);
          if (formula == null) {
            return;
          }
          // clear the format
          transaction.replaceText(
            node,
            selection.startIndex,
            selection.length,
            formula,
            attributes: {},
          );
        } else {
          final text = editorState.getTextInSelection(selection).join();
          transaction.replaceText(
            node,
            selection.startIndex,
            selection.length,
            '\$',
            attributes: {
              InlineMathEquationKeys.type: text,
            },
          );
        }
        await editorState.apply(transaction);
      },
    );
  },
);
