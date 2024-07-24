import 'package:appflowy_editor/appflowy_editor.dart';

void insertHeadingAfterSelection(EditorState editorState, int level) {
  insertNodeAfterSelection(
    editorState,
    headingNode(level: level),
  );
}

void insertQuoteAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    quoteNode(),
  );
}

void insertCheckboxAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    todoListNode(checked: false),
  );
}

void insertBulletedListAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    bulletedListNode(),
  );
}

void insertNumberedListAfterSelection(EditorState editorState) {
  insertNodeAfterSelection(
    editorState,
    numberedListNode(),
  );
}

bool insertNodeAfterSelection(
  EditorState editorState,
  Node node,
) {
  final selection = editorState.selection;
  print("# selection is $selection");
  if (selection == null || !selection.isCollapsed) {
    return false;
  }

  final currentNode = editorState.getNodeAtPath(selection.end.path);
  print("# currentNode is $currentNode");
  if (currentNode == null) {
    return false;
  }
  node.updateAttributes({
    blockComponentTextDirection: currentNode.attributes[blockComponentTextDirection],
  });

  final transaction = editorState.transaction;
  final delta = currentNode.delta;
  print("# delta is $delta");
  if (delta != null && delta.isEmpty) {
    transaction
      ..insertNode(selection.end.path, node)
      ..deleteNode(currentNode)
      ..afterSelection = Selection.collapsed(Position(path: selection.end.path));
  } else {
    final next = selection.end.path.next;

    print("# inserting node ${node.type}");

    transaction
      ..insertNode(next, node)
      ..afterSelection = Selection.collapsed(Position(path: next));
  }

  editorState.apply(transaction);
  return true;
}
