//  Copyright (c) 2019 Aleksander Woźniak
//  Licensed under Apache License v2.0

part of table_calendar;

class _CellWidget extends StatelessWidget {
  final String text;
  final bool isUnavailable;
  final bool isSelected;
  final bool isToday;
  final bool isWeekend;
  final bool isOutsideMonth;
  final bool isHoliday;
  final bool isPreSelected;
  final bool isSelectedArea;
  final CalendarStyle calendarStyle;
  final bool enablePre;
  final bool isPreDay;

  const _CellWidget({
    Key key,
    @required this.text,
    this.isUnavailable = false,
    this.isSelected = false,
    this.isToday = false,
    this.isWeekend = false,
    this.isOutsideMonth = false,
    this.isHoliday = false,
    this.isPreSelected = false,
    this.isSelectedArea = false,
    this.enablePre = false,
    this.isPreDay = false,

    @required this.calendarStyle,
  })  : assert(text != null),
        assert(calendarStyle != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: isSelectedArea ? BoxDecoration(color:  calendarStyle.highlightAreaColor??Color.fromRGBO(220, 241, 254, 1)) : BoxDecoration(),
        margin: EdgeInsets.symmetric(vertical: 6.0),
        alignment: Alignment.center,
        child: Stack(
          children: <Widget>[
            enablePre && (isSelected || isPreSelected) ? Row(
              children: <Widget>[

                Expanded(
                  flex: 1,
                  child: Container(
                    color: !isPreDay ? calendarStyle.highlightAreaColor !=null ?Color(0xFF111111): Color.fromRGBO(255, 255, 255, 1) : calendarStyle.highlightAreaColor!=null?calendarStyle.highlightAreaColor:Color.fromRGBO(220, 241, 254, 1),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: isPreDay ? calendarStyle.highlightAreaColor !=null ?Color(0xFF111111): Color.fromRGBO(255, 255, 255, 1) : calendarStyle.highlightAreaColor!=null?calendarStyle.highlightAreaColor:Color.fromRGBO(220, 241, 254, 1),
                    // color: !isPreDay ? calendarStyle.highlightAreaColor!=null?Color.fromRGBO(255, 255, 255, 1) :Color(0xFF111111) : calendarStyle.highlightAreaColor !=null ?Color(0xFF111111):Color.fromRGBO(220, 241, 254, 1),
                  ),
                ),
              ],
            ) : Container(),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 6),
              decoration: _buildCellDecoration(),
              alignment: Alignment.center,
              child: Text(
                text,
                style: _buildCellTextStyle(),
              ),
            ),
          ],
        )
    );
  }

  Decoration _buildCellDecoration() {
    if ((isSelected || isPreSelected) && calendarStyle.renderSelectedFirst && calendarStyle.highlightSelected) {
      return BoxDecoration(shape: BoxShape.rectangle, color:  calendarStyle.selectedColor, borderRadius: BorderRadius.all(Radius.circular(17)));
    } else if (isToday && calendarStyle.highlightToday) {
      return BoxDecoration(shape: BoxShape.rectangle, color: calendarStyle.todayColor, borderRadius: BorderRadius.all(Radius.circular(17)));
    } else if ((isSelected || isPreSelected) && calendarStyle.highlightSelected) {
      return BoxDecoration(shape: BoxShape.rectangle, color:  calendarStyle.selectedColor, borderRadius: BorderRadius.all(Radius.circular(17)));
    } else {
      return BoxDecoration(shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(17)));
    }
  }

  TextStyle _buildCellTextStyle() {
    if (isUnavailable) {
      return calendarStyle.unavailableStyle;
    } else if ((isSelected || isPreSelected) && calendarStyle.renderSelectedFirst && calendarStyle.highlightSelected) {
      return calendarStyle.selectedStyle;
    } else if (isToday && calendarStyle.highlightToday) {
      return calendarStyle.todayStyle;
    } else if ((isSelected || isPreSelected) && calendarStyle.highlightSelected) {
      return calendarStyle.selectedStyle;
    } else if (isOutsideMonth && isHoliday) {
      return calendarStyle.outsideHolidayStyle;
    } else if (isHoliday) {
      return calendarStyle.holidayStyle;
    } else if (isOutsideMonth && isWeekend) {
      return calendarStyle.outsideWeekendStyle;
    } else if (isOutsideMonth) {
      return calendarStyle.outsideStyle;
    } else if (isWeekend) {
      return calendarStyle.weekendStyle;
    } else {
      return calendarStyle.weekdayStyle;
    }
  }
}
