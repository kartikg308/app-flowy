import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../appflowy_editor.dart';
import '../base_component/block_icon_builder.dart';

class InlineMathEquationKeys {
  const InlineMathEquationKeys._();

  static const String type = 'equation';
  static const String delta = blockComponentDelta;
  static const String backgroundColor = blockComponentBackgroundColor;
  static const String textDirection = blockComponentTextDirection;
}

Node mathEquationNode({
  String? text,
  Delta? delta,
  String? textDirection,
  Attributes? attributes,
  Iterable<Node>? children,
}) {
  attributes ??= {
    'delta': (delta ?? Delta()
          ..insert(text ?? ''))
        .toJson(),
  };
  return Node(
    type: InlineMathEquationKeys.type,
    attributes: {
      ...attributes,
      if (textDirection != null) InlineMathEquationKeys.textDirection: textDirection,
    },
    children: children ?? [],
  );
}

class InlineMathEquationComponentBuilder extends BlockComponentBuilder {
  InlineMathEquationComponentBuilder({
    this.configuration = const BlockComponentConfiguration(),
    this.iconBuilder,
  });

  @override
  final BlockComponentConfiguration configuration;

  final BlockIconBuilder? iconBuilder;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return InlineMathEquationComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      iconBuilder: iconBuilder,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  bool validate(Node node) => node.delta != null;
}

class InlineMathEquationComponentWidget extends BlockComponentStatefulWidget {
  const InlineMathEquationComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.iconBuilder,
  });

  final BlockIconBuilder? iconBuilder;

  @override
  State<InlineMathEquationComponentWidget> createState() => _InlineMathEquationComponentWidgetState();
}

class _InlineMathEquationComponentWidgetState extends State<InlineMathEquationComponentWidget> with SelectableMixin, DefaultSelectableMixin, BlockComponentConfigurable, BlockComponentBackgroundColorMixin, BlockComponentTextDirectionMixin, BlockComponentAlignMixin {
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(
    debugLabel: InlineMathEquationKeys.type,
  );

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  late final editorState = Provider.of<EditorState>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    Widget child = Container(
      width: double.infinity,
      alignment: alignment,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          textDirection: textDirection,
          children: [
            widget.iconBuilder != null ? widget.iconBuilder!(context, node) : const _InlineMathEquationIcon(),
            Flexible(
              child: AppFlowyRichText(
                key: forwardKey,
                delegate: this,
                node: widget.node,
                editorState: editorState,
                textAlign: alignment?.toTextAlign,
                placeholderText: placeholderText,
                textSpanDecorator: (textSpan) => textSpan.updateTextStyle(
                  textStyle,
                ),
                placeholderTextSpanDecorator: (textSpan) => textSpan.updateTextStyle(
                  placeholderTextStyle,
                ),
                textDirection: textDirection,
                cursorColor: editorState.editorStyle.cursorColor,
                selectionColor: editorState.editorStyle.selectionColor,
                cursorWidth: editorState.editorStyle.cursorWidth,
              ),
            ),
          ],
        ),
      ),
    );

    child = Container(
      color: backgroundColor,
      child: Padding(
        key: blockComponentKey,
        padding: padding,
        child: child,
      ),
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [
        BlockSelectionType.block,
      ],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }
}

class _InlineMathEquationIcon extends StatelessWidget {
  const _InlineMathEquationIcon();

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = context.read<EditorState>().editorStyle.textScaleFactor;
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 22) * textScaleFactor,
      padding: const EdgeInsets.only(right: 4.0),
      child: Container(
        width: 4 * textScaleFactor,
        color: '#00BCF0'.tryToColor(),
      ),
    );
  }
}
