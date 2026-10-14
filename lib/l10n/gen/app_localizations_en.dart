// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Clock';

  @override
  String get sectionWorld => 'World';

  @override
  String get sectionAlarms => 'Alarms';

  @override
  String get sectionStopwatch => 'Stopwatch';

  @override
  String get sectionTimers => 'Timers';

  @override
  String get decimalSeparator => '.';

  @override
  String get add => 'Add';

  @override
  String get addCity => 'Add a City';

  @override
  String get searchCities => 'Search for a city or country';

  @override
  String get noResults => 'No matching city';

  @override
  String get removeClock => 'Remove Clock';

  @override
  String cityTime(String city, String time) {
    return '$city, $time';
  }

  @override
  String get dayToday => 'Today';

  @override
  String get dayTomorrow => 'Tomorrow';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String hoursOffset(String day, String offset) {
    return '$day, $offset h';
  }

  @override
  String get worldEmpty => 'Add a city to see its time';

  @override
  String get noAlarms => 'No Alarms';

  @override
  String get newAlarm => 'New Alarm';

  @override
  String get editAlarm => 'Edit Alarm';

  @override
  String get alarmDefaultLabel => 'Alarm';

  @override
  String get repeat => 'Repeat';

  @override
  String get label => 'Label';

  @override
  String get sound => 'Sound';

  @override
  String get snooze => 'Snooze';

  @override
  String get snoozeLength => 'Snooze for';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get defaultSound => 'Default';

  @override
  String get repeatNever => 'Never';

  @override
  String get repeatEveryDay => 'Every day';

  @override
  String get repeatWeekdays => 'Weekdays';

  @override
  String get repeatWeekends => 'Weekends';

  @override
  String repeatSummary(String days) {
    return 'Repeat: $days';
  }

  @override
  String soundSummary(String sound) {
    return 'Sound: $sound';
  }

  @override
  String get weekdayLetters => 'MTWTFSS';

  @override
  String get weekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAlarm => 'Delete Alarm';

  @override
  String get toggleAlarm => 'Turn Alarm On or Off';

  @override
  String get lap => 'Lap';

  @override
  String get reset => 'Reset';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String lapNumber(int n) {
    return 'Lap $n';
  }

  @override
  String get lapsHeaderLap => 'Lap';

  @override
  String get lapsHeaderSplit => 'Lap time';

  @override
  String get lapsHeaderTotal => 'Total';

  @override
  String get unitHours => 'h';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitSeconds => 'sec';

  @override
  String get timerLabel => 'Timer';

  @override
  String get presets => 'Presets';

  @override
  String get recents => 'Recent';

  @override
  String get timerDone => 'Timer done';

  @override
  String alarmRinging(String label, String time) {
    return '$label · $time';
  }

  @override
  String get dismiss => 'Stop';

  @override
  String endsAt(String time) {
    return '$time';
  }
}
