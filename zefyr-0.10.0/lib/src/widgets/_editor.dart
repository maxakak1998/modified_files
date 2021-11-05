import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import '../rendering/editor.dart';

class RawEditor extends MultiChildRenderObjectWidget {
  @override
  RenderEditor createRenderObject(BuildContext context) {
    return RenderEditor();
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditor renderObject) {
    // TODO
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // TODO
//    properties.add(EnumProperty<Axis>('direction', direction));
  }
}

class ZefyrText extends StatelessWidget {
  ZefyrText({
    Key key,
    ContainerNode node,
    TextStyle textStyle,
    EdgeInsets padding,
    BoxDecoration decoration,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}
