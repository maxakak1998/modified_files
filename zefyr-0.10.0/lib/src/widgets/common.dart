// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'controller.dart';
import 'editable_box.dart';
import 'horizontal_rule.dart';
import 'image.dart';
import 'rich_text.dart';
import 'scope.dart';
import 'theme.dart';

/// Represents single line of rich text document in Zefyr editor.
class ZefyrLine extends StatefulWidget {
  const ZefyrLine(
      {Key key,
        @required this.node,
        this.style,
        this.padding,
        this.zefyrController})
      : assert(node != null),
        super(key: key);

  /// Line in the document represented by this widget.
  final LineNode node;

  /// Style to apply to this line. Required for lines with text contents,
  /// ignored for lines containing embeds.
  final TextStyle style;

  /// Padding to add around this paragraph.
  final EdgeInsets padding;
  final ZefyrController zefyrController;

  @override
  _ZefyrLineState createState() => _ZefyrLineState();
}

class _ZefyrLineState extends State<ZefyrLine> {
  final LayerLink _link = LayerLink();
  /* RegExp REGEX_EMOJI_STRING, REGEX_EMOJI;
  Map<RegExp, TextStyle> defaultPattern = {};*/
  @override
  void initState() {
    /* REGEX_EMOJI_STRING = RegExp(r":([\w-+]+):");
    REGEX_EMOJI = RegExp(
        r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
    defaultPattern = {
      REGEX_EMOJI_STRING: TextStyle(),
      REGEX_EMOJI: TextStyle()
    };*/

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ZefyrScope.of(context);
    if (scope.isEditable) {
      ensureVisible(context, scope);
    }
    final theme = Theme.of(context);

    Widget content;
    if (widget.node.hasEmbed) {
      content = buildEmbed(context, scope);
    } else {
      assert(widget.style != null);
      content = ZefyrRichText(
        node: widget.node,
        text: buildText(context),
      );
    }

    if (scope.isEditable) {
      Color cursorColor;
      switch (theme.platform) {
        case TargetPlatform.iOS:
          cursorColor ??= CupertinoTheme.of(context).primaryColor;
          break;

        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          cursorColor = theme.cursorColor;
          break;
      }

      content = EditableBox(
        child: content,
        node: widget.node,
        layerLink: _link,
        renderContext: scope.renderContext,
        showCursor: scope.showCursor,
        selection: scope.selection,
        selectionColor: theme.textSelectionColor,
        cursorColor: cursorColor,
      );
      content = CompositedTransformTarget(link: _link, child: content);
    }

    if (widget.padding != null) {
      return Padding(padding: widget.padding, child: content);
    }
    return content;
  }

  void ensureVisible(BuildContext context, ZefyrScope scope) {
    if (scope.selection.isCollapsed &&
        widget.node.containsOffset(scope.selection.extentOffset)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bringIntoView(context);
      });
    }
  }

  void bringIntoView(BuildContext context) {
    ScrollableState scrollable = Scrollable.of(context);
    final object = context.findRenderObject();
    assert(object.attached);
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object);
    assert(viewport != null);

    final double offset = scrollable.position.pixels;
    double target = viewport.getOffsetToReveal(object, 0.0).offset;
    if (target - offset < 0.0) {
      scrollable.position.jumpTo(target);
      return;
    }
    target = viewport.getOffsetToReveal(object, 1.0).offset;
    if (target - offset > 0.0) {
      scrollable.position.jumpTo(target);
    }
  }

  TextSpan buildText(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final List<TextSpan> children = widget.node.children
        .map((node) => _segmentToTextSpan(node, theme))
        .toList(growable: false);
    return TextSpan(style: widget.style, children: children);
  }

  TextSpan _segmentToTextSpan(Node node, ZefyrThemeData theme) {
    final TextNode segment = node;
    final attrs = segment.style;
    List<TextSpan> children = [];
    TextStyle allRegexTextStyle;
    RegExp allRegex;
    if (widget.zefyrController?.userName != null) {
      widget.zefyrController
          .updateDefaultPattern(widget.zefyrController.userName);
      /*final key = RegExp(r"(@" + widget.zefyrController.userName + ")");
      final value = TextStyle(color: Colors.blue);
      defaultPattern.update(key, (value) => value, ifAbsent: () => value);*/
    }
    allRegex = RegExp(widget.zefyrController.defaultPattern.keys
        .map((e) => e.pattern)
        .join('|'));
    /* segment.value.splitMapJoin(
      allRegex,
      onMatch: (Match m) {
        if (widget.zefyrController.defaultPattern.entries.isNotEmpty) {
          RegExp k = widget.zefyrController.defaultPattern.entries
              .singleWhere((element) {
            return element.key.allMatches(m[0]).isNotEmpty;
          }).key;
          if (k.pattern == ZefyrController.REGEX_EMOJI.pattern) {
            return m[0];
          } else {
            allRegexTextStyle = widget.zefyrController.defaultPattern[k];
          }

          return m[0];
        } else {
          return m[0];
        }
      },

      ///[1,3,e
      onNonMatch: (String span) {
        return span.toString();
      },
    );*/
    segment.value.splitMapJoin(
      allRegex,
      onMatch: (Match m) {
        if (widget.zefyrController.defaultPattern.entries.isNotEmpty) {
          RegExp k = widget.zefyrController.defaultPattern.entries
              .singleWhere((element) {
            return element.key.allMatches(m[0]).isNotEmpty;
          }).key;
          if (k.pattern == ZefyrController.REGEX_EMOJI.pattern) {
            children.add(
              TextSpan(
                text: m[0],
              ),
            );
            return m[0];
          } else {
            children.add(
              TextSpan(
                text: m[0],
                style: widget.zefyrController.defaultPattern[k],
              ),
            );
          }

          return m[0];
        } else {
          children.add(
            TextSpan(text: m[0]),
          );
          return m[0];
        }
      },

      ///[1,3,e
      onNonMatch: (String span) {
        children.add(TextSpan(text: span, style: _getTextStyle(attrs, theme)));
        return span.toString();
      },
    );
    /*return TextSpan(
      text: segment.value,
      style: allRegexTextStyle != null
          ? allRegexTextStyle
          : _getTextStyle(attrs, theme),
    );*/
    if (children == null || children.isEmpty) {
      return TextSpan(style: _getTextStyle(attrs, theme), text: segment.value);
    } else {
      return TextSpan(style: _getTextStyle(attrs, theme), children: children);
    }
  }

  TextStyle _getTextStyle(NotusStyle style, ZefyrThemeData theme) {
    TextStyle result = TextStyle();
    if (style.containsSame(NotusAttribute.bold)) {
      result = result.merge(theme.attributeTheme.bold);
    }
    if (style.containsSame(NotusAttribute.italic)) {
      result = result.merge(theme.attributeTheme.italic);
    }
    if (style.containsSame(NotusAttribute.underline)) {
      result = result.merge(theme.attributeTheme.underline);
    }
    if (style.contains(NotusAttribute.link)) {
      result = result.merge(theme.attributeTheme.link);
    }
    return result;
  }

  Widget buildEmbed(BuildContext context, ZefyrScope scope) {
    EmbedNode node = widget.node.children.single;
    EmbedAttribute embed = node.style.get(NotusAttribute.embed);

    if (embed.type == EmbedType.horizontalRule) {
      return ZefyrHorizontalRule(node: node);
    } else if (embed.type == EmbedType.image) {
      return ZefyrImage(node: node, delegate: scope.imageDelegate);
    } else {
      throw UnimplementedError('Unimplemented embed type ${embed.type}');
    }
  }
}
