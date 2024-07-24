import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class CustomizeThemeForEditor extends StatefulWidget {
  const CustomizeThemeForEditor({super.key});

  @override
  State<CustomizeThemeForEditor> createState() => _CustomizeThemeForEditorState();
}

class _CustomizeThemeForEditorState extends State<CustomizeThemeForEditor> {
  late final Future<EditorState> editorState;

  @override
  void initState() {
    super.initState();

    final jsonString = PlatformExtension.isDesktopOrWeb ? rootBundle.loadString('assets/example.json') : rootBundle.loadString('assets/mobile_example.json');
    editorState = jsonString.then((value) {
      return EditorState(
        document: Document.fromJson(
          Map<String, Object>.from(
            json.decode(value),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Custom Theme For Editor'),
        titleTextStyle: const TextStyle(color: Colors.white),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: FutureBuilder(
        future: editorState,
        builder: (context, snapshot) {
          return !snapshot.hasData ? const Center(child: CircularProgressIndicator()) : buildEditor(snapshot.data!);
        },
      ),
    );
  }

  Widget buildEditor(EditorState editorState) {
    return Container(
      color: Colors.grey[900],
      child: FloatingToolbar(
        items: [
          paragraphItem,
          ...headingItems,
          ...markdownFormatItems,
          quoteItem,
          bulletedListItem,
          numberedListItem,
          linkItem,
          buildTextColorItem(),
          buildHighlightColorItem(),
          ...textDirectionItems,
          ...alignmentItems,
          ToolbarItem(
            id: "id",
            group: 1,
            isActive: (state) => true,
            builder: (context, editorState, c1, _) {
              return IconButton(
                onPressed: () {
                  editorState.toggleAttribute(
                    "formula",
                    selection: editorState.selection!,
                  );
                },
                icon: const Icon(Icons.abc),
              );
            },
          ),
        ],
        editorState: editorState,
        textDirection: TextDirection.ltr,
        editorScrollController: EditorScrollController(
          editorState: editorState,
          shrinkWrap: false,
        ),
        child: AppFlowyEditor(
          editorState: editorState,
          editorStyle: customizeEditorStyle(),
          blockComponentBuilders: customBuilder(editorState),
          header: Image.asset(
            'assets/images/header.png',
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// custom the block style
  Map<String, BlockComponentBuilder> customBuilder(
    EditorState editorState,
  ) {
    final configuration = BlockComponentConfiguration(
      padding: (node) {
        if (HeadingBlockKeys.type == node.type) {
          return const EdgeInsets.symmetric(vertical: 30);
        }
        return const EdgeInsets.symmetric(vertical: 5);
      },
      textStyle: (node) {
        if (HeadingBlockKeys.type == node.type) {
          return const TextStyle(color: Colors.yellow);
        }
        return const TextStyle();
      },
    );

    // customize heading block style
    return {
      ...standardBlockComponentBuilderMap,
      // heading block
      HeadingBlockKeys.type: HeadingBlockComponentBuilder(
        configuration: configuration,
      ),
      // todo-list block
      TodoListBlockKeys.type: TodoListBlockComponentBuilder(
        configuration: configuration,
        iconBuilder: (context, node, ___) {
          final checked = node.attributes[TodoListBlockKeys.checked] as bool;
          return GestureDetector(
            onTap: () => editorState.apply(
              editorState.transaction..updateNode(node, {TodoListBlockKeys.checked: !checked}),
            ),
            child: Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: Colors.white,
            ),
          );
        },
      ),
      // bulleted list block
      BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
        configuration: configuration,
        iconBuilder: (context, node) {
          return Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            child: const Icon(
              Icons.circle,
              size: 10,
              color: Colors.red,
            ),
          );
        },
      ),
      // quote block
      QuoteBlockKeys.type: QuoteBlockComponentBuilder(
        configuration: configuration,
        iconBuilder: (context, node) {
          return const EditorSvg(
            width: 20,
            height: 20,
            padding: EdgeInsets.only(right: 5.0),
            name: 'quote',
            color: Colors.pink,
          );
        },
      ),
    };
  }

  /// custom the text style
  EditorStyle customizeEditorStyle() {
    return EditorStyle(
      padding: PlatformExtension.isDesktopOrWeb ? const EdgeInsets.only(left: 200, right: 200) : const EdgeInsets.symmetric(horizontal: 20),
      cursorColor: Colors.green,
      dragHandleColor: Colors.green,
      selectionColor: Colors.green.withOpacity(0.5),
      textStyleConfiguration: TextStyleConfiguration(
        text: GoogleFonts.poppins(
          fontSize: 14.0,
          color: Colors.white,
        ),
        bold: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
        href: TextStyle(
          color: Colors.amber,
          decoration: TextDecoration.combine(
            [
              TextDecoration.overline,
              TextDecoration.underline,
            ],
          ),
        ),
        code: const TextStyle(
          fontSize: 14.0,
          fontStyle: FontStyle.italic,
          color: Colors.blue,
          backgroundColor: Colors.black12,
        ),
      ),
      textSpanDecorator: (context, node, index, text, before, _) {
        final attributes = text.attributes;
        final href = attributes?[AppFlowyRichTextKeys.href];
        if (href != null) {
          return TextSpan(
            text: text.text,
            style: before.style,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                debugPrint('onTap: $href');
              },
          );
        }
        return before;
      },
    );
  }

  InlineSpan customizeAttributeDecorator(
    BuildContext context,
    Node node,
    int index,
    TextInsert text,
    TextSpan before,
    TextSpan after,
  ) {
    final attributes = text.attributes;
    if (attributes == null) {
      return before;
    }

    // Inline Mentions (Page Reference, Date, Reminder, etc.)
    // final mention =
    //     attributes[MentionBlockKeys.mention] as Map<String, dynamic>?;
    // if (mention != null) {
    //   final type = mention[MentionBlockKeys.type];
    //   return WidgetSpan(
    //     alignment: PlaceholderAlignment.middle,
    //     style: after.style,
    //     child: MentionBlock(
    //       key: ValueKey(
    //         switch (type) {
    //           MentionType.page => mention[MentionBlockKeys.pageId],
    //           MentionType.date => mention[MentionBlockKeys.date],
    //           _ => MentionBlockKeys.mention,
    //         },
    //       ),
    //       node: node,
    //       index: index,
    //       mention: mention,
    //       textStyle: after.style,
    //     ),
    //   );
    // }

    // customize the inline math equation block
    // final formula = attributes[InlineMathEquationKeys.formula];
    // if (formula is String) {
    //   return WidgetSpan(
    //     alignment: PlaceholderAlignment.middle,
    //     child: InlineMathEquation(
    //       node: node,
    //       index: index,
    //       formula: formula,
    //       // textStyle: style().textStyleConfiguration.text,
    //     ),
    //   );
    // }

    // if (attributes["formula"] ?? false) {
    print("value is ${attributes["formula"]}");
    var widgetSpan = WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      child: Math.tex(
        attributes["formula"],
        mathStyle: MathStyle.text,
        textStyle: TextStyleConfiguration(
          text: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
          ),
          code: GoogleFonts.architectsDaughter(),
          bold: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ).text,
      ),
    );
    return TextSpan(
      children: [
        const WidgetSpan(child: SizedBox(width: 10)),
        widgetSpan,
        const WidgetSpan(child: SizedBox(width: 10)),
      ],
    );
    // }

    // customize the link on mobile
    // final href = attributes[AppFlowyRichTextKeys.href] as String?;
    // if (PlatformExtension.isMobile && href != null) {
    //   return TextSpan(
    //     style: before.style,
    //     text: text.text,
    //     recognizer: TapGestureRecognizer()
    //       ..onTap = () {
    //         final editorState = context.read<EditorState>();
    //         if (editorState.selection == null) {
    //           afLaunchUrlString(href, addingHttpSchemeWhenFailed: true);
    //           return;
    //         }

    //         editorState.updateSelectionWithReason(
    //           editorState.selection,
    //           extraInfo: {selectionExtraInfoDisableMobileToolbarKey: true},
    //         );

    //         showEditLinkBottomSheet(
    //           context,
    //           text.text,
    //           href,
    //           (linkContext, newText, newHref) {
    //             final selection = Selection.single(
    //               path: node.path,
    //               startOffset: index,
    //               endOffset: index + text.text.length,
    //             );
    //             editorState.updateTextAndHref(
    //               text.text,
    //               href,
    //               newText,
    //               newHref,
    //               selection: selection,
    //             );
    //             linkContext.pop();
    //           },
    //         );
    //       },
    //   );
    // }

    return defaultTextSpanDecoratorForAttribute(
      context,
      node,
      index,
      text,
      before,
      after,
    );
  }
}
