/*
 * Modified work: Copyright 2020 Ali Ahamed Thowfeek
 * Original work: Copyright 2019 Ashraff Hathibelagal
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml_events.dart' as xmle;

import './utils.dart';

class _Tag {
  String name;
  String styles;
  TextStyle overrideStyle;

  _Tag(this.name, this.styles, this.overrideStyle);
}

/// This class is at the core of the simple_html_css package . It has most of
/// the methods required to convert HTML content into Flutter widgets
class Parser {
  List<_Tag> _stack = [];
  var _events;
  BuildContext _context;
  Function _linksCallback;
  final Map<String, TextStyle> overrideStyleMap;
  final TextStyle defaultTextStyle;
  int indexList;
  bool isListNumber;

  Parser(BuildContext context, String data,
      {this.defaultTextStyle,Function linksCallback, this.overrideStyleMap}) {
    _events = xmle.parseEvents(data);
    _context = context;
    if (linksCallback != null) _linksCallback = linksCallback;
    indexList = 1;
    isListNumber = false;
  }

  TextSpan _getTextSpan(String text, String style, TextStyle overrideStyle) {
    var rules = style.split(";").where((item) => item.trim().isNotEmpty);
    TextStyle textStyle = DefaultTextStyle.of(_context).style;
    textStyle = textStyle.apply(color: Color(0xff000000));
    textStyle = textStyle.merge(defaultTextStyle);
    var isLink = false;
    var link = "";
    rules.forEach((String rule) {
      if (rule.indexOf(":") == -1) return;
      final parts = rule.split(":");
      String name = parts[0].trim();
      String value = parts[1].trim();
      switch (name.toLowerCase()) {
        case "color":
          textStyle = StyleGenUtils.addFontColor(textStyle, value);
          break;

        case "background-color":
          textStyle = StyleGenUtils.addBgColor(textStyle, value);
          break;

        case "font-weight":
          textStyle = StyleGenUtils.addFontWeight(textStyle, value);
          break;

        case "font-style":
          textStyle = StyleGenUtils.addFontStyle(textStyle, value);
          break;

        case "font-size":
          textStyle = StyleGenUtils.addFontSize(textStyle, value);
          break;

        case "text-decoration":
          textStyle = StyleGenUtils.addTextDecoration(textStyle, value);
          break;

        case "font-family":
          textStyle = StyleGenUtils.addFontFamily(textStyle, value);
          break;

        case "line-height":
          textStyle = StyleGenUtils.addLineHeight(textStyle, value);
          break;

        //dropping partial support for li bullets
       case "list_item":
          if(isListNumber){
          text = "${indexList++}. $text";
          }
          else
          text = "• " + text;
         break;
        case "visit_link":
          isLink = true;
          link = TextGenUtils.getLink(value);
          break;
      }
    });

    if (overrideStyle != null) {
      textStyle = textStyle.merge(overrideStyle);
    }

    if (isLink) {
      return TextSpan(
          style: textStyle,
          text: text,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (_linksCallback != null)
                _linksCallback(link);
              else
                print("Add a link callback to visit $link");
            });
    }
    return TextSpan(style: textStyle, text: text);
  }

  TextSpan _handleText(String text) {
    text = TextGenUtils.strip(text);
    if (text.isEmpty) return TextSpan(text: "");
    var style = "";
    TextStyle textStyle = TextStyle();
    _stack.forEach((tag) {
      style += tag.styles + ";";
      textStyle = textStyle.merge(tag.overrideStyle);
    });
    return _getTextSpan(text, style, textStyle);
  }

  /// Converts HTML content to a list of [TextSpan] objects
  List<TextSpan> parse() {
    List spans = <TextSpan>[];
    _events.forEach((event) {
      if (event is xmle.XmlStartElementEvent) {
        if (!event.isSelfClosing) {
          var styles = "";
          var tagName = event.name.toLowerCase();
          var overrideStyles;
          double defaultFontSize = defaultTextStyle?.fontSize;
          if (overrideStyleMap.containsKey(tagName))
            overrideStyles = overrideStyleMap[tagName];

          switch (tagName) {
            case "h1":
              double h1;
              if (defaultFontSize == null) {
                h1 = Theme.of(_context).textTheme.headline.fontSize;
              } else {
                h1 = defaultFontSize * 2;
              }
              styles = "font-size: ${h1}px;";
              break;

            case "h2":
              double h2;
              if (defaultFontSize == null) {
                h2 = Theme.of(_context).textTheme.title.fontSize;
              } else {
                h2 = defaultFontSize * 1.5;
              }
              styles = "font-size: ${h2}px; font-weight: medium;";
              break;

            case "h3":
              double h3;
              if (defaultFontSize == null) {
                h3 = Theme.of(_context).textTheme.subhead.fontSize;
              } else {
                h3 = defaultFontSize * 1.17;
              }
              styles = "font-size: ${h3}px;";
              break;

            case "h4":
              double h4;
              if (defaultFontSize == null) {
                h4 = Theme.of(_context).textTheme.body1.fontSize;
              } else {
                h4 = defaultFontSize;
              }
              styles = "font-size: ${h4}px; font-weight: medium;";
              break;

            case "h5":
              double h5;
              if (defaultFontSize == null) {
                h5 = Theme.of(_context).textTheme.body1.fontSize;
              } else {
                h5 = defaultFontSize * .83;
              }
              styles = "font-weight: bold;";
              break;

            case "h6":
              double h6;
              if (defaultFontSize == null) {
                h6 = Theme.of(_context).textTheme.body2.fontSize;
              } else {
                h6 = defaultFontSize * .67;
              }
              styles = "font-size: ${h6}px; font-weight: bold;";
              break;

            case "b":
              styles = "font-weight: bold;";
              break;

            case "strong":
              styles = "font-weight: bold;";
              break;

            case "i":
              styles = "font-style: italic;";
              break;

            case "em":
              styles = "font-style: italic;";
              break;

            case "u":
              styles = "text-decoration: underline;";
              break;

            case "strike":
              styles = "text-decoration: line-through;";
              break;

            case "del":
              styles = "text-decoration: line-through;";
              break;

            case "s":
              styles = "text-decoration: line-through;";
              break;

            case "a":
              styles = "visit_link:__#TO_GET#__;" +
                  "text-decoration: underline;" +
                  " color: #4287f5;";
              break;

            //dropping partial support for ul-li bullets
           case "li":
             styles = "list_item:ul;";
             break;
            case "ul":
              isListNumber = false;
              break;
            case "ol":
            isListNumber = true;
            break;
          }

          event.attributes.forEach((attribute) {
            if (attribute.name == "style")
              styles = styles + ";" + attribute.value;
            else if (attribute.name == "href") {
              styles = styles.replaceFirst(r"__#TO_GET#__",
                  attribute.value.replaceAll(r":", "__#COLON#__"));
            }
          });

          if (tagName == "br") {
            spans.add(TextSpan(text: "\n"));
          } else {
            _stack.add(_Tag(event.name, styles, overrideStyles));
          }
        } else {
          if (event.name == "br") {
            spans.add(TextSpan(text: "\n"));
          }
        }
      }

      //TODO: see if there is a better way to add space after these tags
      if (event is xmle.XmlEndElementEvent) {
        if (event.name == 'p' ||
            event.name == 'h1' ||
            event.name == 'h2' ||
            event.name == 'h3' ||
            event.name == 'h4' ||
            event.name == 'h5' ||
            event.name == 'h6' ||
            event.name == 'div') {
          spans.add(TextSpan(
            text: "\n\n",
          ));
        } else if (event.name == 'li') {
          spans.add(TextSpan(
            text: "\n",
            style: TextStyle(color: Colors.black)
          ));
        } else if (event.name == 'ul' || event.name == 'ol') {
          spans.add(TextSpan(
            text: "\n",
            style: TextStyle(color: Colors.black)
          ));
        } 
        var top = _stack.removeLast();
        if (top.name != event.name) {
          print("Malformed HTML");
          return;
        }
      }

      if (event is xmle.XmlTextEvent) {
        final currentSpan = _handleText(event.text);
        if (currentSpan.text.isNotEmpty) {
          spans.add(currentSpan);
        }
      }
    });

    //removing last textSpan to avoid extra space at the bottom
    spans.removeLast();
    return spans;
  }
}
