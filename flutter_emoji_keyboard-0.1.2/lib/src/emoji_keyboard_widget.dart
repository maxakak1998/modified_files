import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'base_emoji.dart';
import 'compatible_emojis.dart';

// typedef void _SetCategoryKey(int index, GlobalKey key);
typedef _CategoryButtonPressed = void Function(int index);

/// Callback function when emoji is pressed will be called.
/// by [Emoji] argument.
typedef OnEmojiSelected = void Function(Emoji emoji);

const _categoryHeaderHeight = 30.0;
const _categoryTitleHeight = _categoryHeaderHeight; // todo: fix scroll issue

/// The Emoji Keyboard Widget
///
/// Contains all emojis in a vertically scrollable grid
class EmojiKeyboard extends StatefulWidget {
  final bool floatingHeader;
  final int column;
  final double height;
  final OnEmojiSelected onEmojiSelected;
  final CategoryIcons categoryIcons;
  final CategoryTitles categoryTitles;
  final Color color;

  /// Creates a emoji keyboard widget.
  ///
  /// [column] is number of columns in keyboard grid.
  ///
  /// [height] of keyboard.
  ///
  /// [color] color of keyboard, by default is [Colors.white].
  ///
  /// [onEmojiSelected] The callback function when emoji is pressed,
  /// Must not be null.
  ///
  /// Emojis in keyboard are soreted by categories with header of [categoryTitles]
  ///
  /// Keyboard has a header that contain all [categoryIcons] is a row and take postion by pressing the icon,
  ///
  /// If [floatingHeader] is true then keyboard scrolls offscreen header as the user scrolls down the list.
  EmojiKeyboard({
    Key key,
    this.column = 8,
    this.height = 290.0,
    @required this.onEmojiSelected,
    this.floatingHeader = false,
    this.color = Colors.white,
    this.categoryIcons = const CategoryIcons(),
    this.categoryTitles = const CategoryTitles(),
  }) : super(key: key);

  @override
  _EmojiKeyboardState createState() => _EmojiKeyboardState();
}

class _EmojiKeyboardState extends State<EmojiKeyboard> {
  final contentKey = UniqueKey();

  List<GlobalKey> categoyKeys;
  ValueNotifier<int> activeIndex;
  ScrollController _scrollController;
  Debouncer<int> debouncer;

  /// Calback function when user press one of categorie in keyboard header
  /// and scroll emojis grid to the postion of that category by it's [index].
  void onCategoryClick(int index) {
    // activeIndex.value=index+1;
    Scrollable.ensureVisible(categoyKeys[index].currentContext);
  }

  /// set the [key] of emoji category header by it's [index] in grid.
  void setCategoryKey(int index, GlobalKey key) {
    categoyKeys[index] = key;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    debouncer.cancel();
    activeIndex.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = new ScrollController();
    debouncer = new Debouncer<int>(Duration(milliseconds: 200));

    _scrollController.addListener(() {
      debouncer.value = _scrollController.offset.floor();
    });
    debouncer.values.listen((value) {
      int i = 0;
      for (GlobalKey key in categoyKeys) {
        final RenderSliverToBoxAdapter renderBox =
            key.currentContext.findRenderObject();
        final int offset = _scrollController.offset.floor();
        final sum =
            renderBox.constraints.precedingScrollExtent.floor() - offset;
        if (sum <= 50) {
          if (activeIndex.value != i) {
            activeIndex.value = i;
          }
        }
        i++;
      }
    });
    categoyKeys = List.generate(8, (i) => GlobalKey());
    activeIndex = new ValueNotifier<int>(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.color,
      height: widget.height ??
          (MediaQuery.of(context).size.width / widget.column) * 5 +
              (_categoryHeaderHeight + _categoryTitleHeight),
      child: Scrollbar(
        child: NestedScrollView(
          key: PageStorageKey<Type>(NestedScrollView),
          //floatHeaderSlivers: true,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            // These are the slivers that show up in the "outer" scroll view.
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverPersistentHeader(
                  delegate: _EmojiKeyboardHeader(
                    activeIndex: activeIndex,
                    minExtent: _categoryHeaderHeight,
                    maxExtent: _categoryHeaderHeight,
                    categoryIcons: widget.categoryIcons,
                    onClick: onCategoryClick,
                    color: widget.color,
                  ),
                  pinned: !widget.floatingHeader,
                  floating: widget.floatingHeader,
                ),
              ),
            ];
          },
          body: FutureBuilder<List<List<Emoji>>>(
            future: getEmojis(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                final List<Widget> list = List<Widget>.generate(
                  16,
                  (index) {
                    if (index.isEven) {
                      index = (index / 2).round();
                      final key = categoyKeys[index];
                      return SliverToBoxAdapter(
                        key: key,
                        child: Container(
                          height: 20,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            widget.categoryTitles[index],
                          ),
                        ),
                      );
                    } else {
                      return SliverGrid(
                        key: ValueKey(index),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                        ),
                        delegate: SliverChildListDelegate.fixed(
                          snapshot.data[index ~/ 2].map((Emoji emoji) {
                            return CupertinoButton(
                              key: ValueKey('${emoji.text}'),
                              pressedOpacity: 0.4,
                              padding: EdgeInsets.all(0),
                              child: Center(
                                child: Text(
                                  '${emoji.text}',
                                  style: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              onPressed: () => widget.onEmojiSelected(emoji),
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                );
                return CustomScrollView(
                    controller: _scrollController,
                    shrinkWrap: true,
                    slivers: [
                      // todo : avoid generate
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                      ),
                      ...list
                      // ignore: prefer_spread_collections
                    ]);
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _EmojiKeyboardHeader implements SliverPersistentHeaderDelegate {
  _EmojiKeyboardHeader(
      {key,
      this.minExtent,
      @required this.maxExtent,
      @required this.categoryIcons,
      @required this.onClick,
      this.color = Colors.white,
      this.activeIndex});

  final _CategoryButtonPressed onClick;
  final CategoryIcons categoryIcons;
  @override
  final double minExtent;
  @override
  final double maxExtent;
  final Color color;
  final ValueNotifier<int> activeIndex;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return CategoryHeader(
      categoryIcons: categoryIcons,
      color: color,
      onClick: onClick,
      activeIndex: activeIndex,
      maxExtent: maxExtent,
      minExtent: minExtent,
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;

  @override
  FloatingHeaderSnapConfiguration get snapConfiguration => null;

  @override
  OverScrollHeaderStretchConfiguration get stretchConfiguration => null;

  @override
  // TODO: implement showOnScreenConfiguration
  PersistentHeaderShowOnScreenConfiguration get showOnScreenConfiguration =>
      throw UnimplementedError();

  @override
  // TODO: implement vsync
  TickerProvider get vsync => throw UnimplementedError();
}

class CategoryHeader extends StatefulWidget {
  final _CategoryButtonPressed onClick;
  final CategoryIcons categoryIcons;
  @override
  final double minExtent;
  @override
  final double maxExtent;
  final Color color;
  final ValueNotifier<int> activeIndex;

  CategoryHeader(
      {key,
      this.minExtent,
      @required this.maxExtent,
      @required this.categoryIcons,
      @required this.onClick,
      this.color = Colors.white,
      this.activeIndex});

  @override
  _CategoryHeaderState createState() => _CategoryHeaderState();
}

class _CategoryHeaderState extends State<CategoryHeader> {
  int _activeIndex = 0;
  @override
  void initState() {
    widget.activeIndex.addListener(() {
      _activeIndex = widget.activeIndex.value;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        color: widget.categoryIcons.color,
        height: widget.maxExtent,
        child: Center(
          child: ValueListenableBuilder(
            valueListenable: widget.activeIndex,
            builder: (context, value, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  8,
                  (index) => CupertinoButton(
                    color: widget.color,
                    pressedOpacity: 0.4,
                    padding: EdgeInsets.all(0),
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                    child: Center(
                      child: Icon(
                        widget.categoryIcons[index],
                        size: (widget.minExtent < widget.maxExtent - 10)
                            ? widget.minExtent
                            : widget.maxExtent - 10,
                        color:
                            _activeIndex == index ? Colors.blue : Colors.grey,
                      ),
                    ),
                    onPressed: () {
                      widget.onClick(index);
                      // setState(() {
                      //   _activeIndex = index;
                      //
                      // });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// CategoryTitles class that used to define all category titles.
class CategoryTitles {
  final String people;
  final String nature;
  final String food;
  final String activity;
  final String travel;
  final String objects;
  final String symbols;
  final String flags;

  /// This class contains all category titles.
  ///
  /// [people] for [EmojiCategory.people]
  ///
  /// [nature] for [EmojiCategory.nature]
  ///
  /// [food] for [EmojiCategory.food]
  ///
  /// [activity] for [EmojiCategory.activity]
  ///
  /// [travel] for [EmojiCategory.travel]
  ///
  /// [objects] for [EmojiCategory.objects]
  ///
  /// [symbols] for [EmojiCategory.symbols]
  ///
  /// [flags] for [EmojiCategory.flags]
  const CategoryTitles({
    this.people = 'Smileys & People',
    this.nature = 'Animals & Nature',
    this.food = 'Food & Drink',
    this.activity = 'Activity',
    this.travel = 'Travel & Places',
    this.objects = 'Objects',
    this.symbols = 'Symbols',
    this.flags = 'Flags',
  });

  /// Get category title by it's [index]
  String operator [](int index) => <String>[
        people,
        nature,
        food,
        activity,
        travel,
        objects,
        symbols,
        flags,
      ][index];
}

/// CategoryIcons class that used to define all category icons.
class CategoryIcons {
  final Color color;
  final IconData people;
  final IconData nature;
  final IconData food;
  final IconData activity;
  final IconData travel;
  final IconData objects;
  final IconData symbols;
  final IconData flags;

  /// This class contains all category icons.
  ///
  /// Keyboard Header [color] is [Colors.with] by default.
  ///
  /// [people] for [EmojiCategory.people]
  ///
  /// [nature] for [EmojiCategory.nature]
  ///
  /// [food] for [EmojiCategory.food]
  ///
  /// [activity] for [EmojiCategory.activity]
  ///
  /// [travel] for [EmojiCategory.travel]
  ///
  /// [objects] for [EmojiCategory.objects]
  ///
  /// [symbols] for [EmojiCategory.symbols]
  ///
  /// [flags] for [EmojiCategory.flags]
  const CategoryIcons({
    this.people = Icons.sentiment_satisfied,
    this.nature = Icons.pets,
    this.food = Icons.fastfood,
    this.activity = Icons.directions_run,
    this.travel = Icons.location_city,
    this.objects = Icons.lightbulb_outline,
    this.symbols = Icons.euro_symbol,
    this.flags = Icons.flag,
    this.color = Colors.white,
  });

  /// Get category icon by it's [index]
  IconData operator [](int index) => <IconData>[
        people,
        nature,
        food,
        activity,
        travel,
        objects,
        symbols,
        flags,
      ][index];
}
