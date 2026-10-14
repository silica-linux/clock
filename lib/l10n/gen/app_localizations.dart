import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// The app name
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get appTitle;

  /// Section with the clocks of other cities
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get sectionWorld;

  /// Section with the alarms
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get sectionAlarms;

  /// Section with the stopwatch
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get sectionStopwatch;

  /// Section with the countdown timers
  ///
  /// In en, this message translates to:
  /// **'Timers'**
  String get sectionTimers;

  /// Decimal separator of the stopwatch hundredths
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get decimalSeparator;

  /// Tooltip of the + button in the toolbar
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Title of the sheet that adds a world clock
  ///
  /// In en, this message translates to:
  /// **'Add a City'**
  String get addCity;

  /// Placeholder of the city search field
  ///
  /// In en, this message translates to:
  /// **'Search for a city or country'**
  String get searchCities;

  /// City search without results
  ///
  /// In en, this message translates to:
  /// **'No matching city'**
  String get noResults;

  /// Context menu of a world clock card
  ///
  /// In en, this message translates to:
  /// **'Remove Clock'**
  String get removeClock;

  /// City name and its time on a card
  ///
  /// In en, this message translates to:
  /// **'{city}, {time}'**
  String cityTime(String city, String time);

  /// The city's date compared with ours
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dayTomorrow;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayYesterday;

  /// Day and offset from local time, e.g. Today, +1 h
  ///
  /// In en, this message translates to:
  /// **'{day}, {offset} h'**
  String hoursOffset(String day, String offset);

  /// World section without cards
  ///
  /// In en, this message translates to:
  /// **'Add a city to see its time'**
  String get worldEmpty;

  /// Empty state of the alarms
  ///
  /// In en, this message translates to:
  /// **'No Alarms'**
  String get noAlarms;

  /// Title of the alarm editor
  ///
  /// In en, this message translates to:
  /// **'New Alarm'**
  String get newAlarm;

  /// No description provided for @editAlarm.
  ///
  /// In en, this message translates to:
  /// **'Edit Alarm'**
  String get editAlarm;

  /// Label of an alarm without one
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarmDefaultLabel;

  /// Rows of the alarm editor
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @snoozeLength.
  ///
  /// In en, this message translates to:
  /// **'Snooze for'**
  String get snoozeLength;

  /// A duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// A duration in hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hours(int count);

  /// The alarm and timer sound
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultSound;

  /// Repeat summaries
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNever;

  /// No description provided for @repeatEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatEveryDay;

  /// No description provided for @repeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get repeatWeekends;

  /// No description provided for @repeatSummary.
  ///
  /// In en, this message translates to:
  /// **'Repeat: {days}'**
  String repeatSummary(String days);

  /// No description provided for @soundSummary.
  ///
  /// In en, this message translates to:
  /// **'Sound: {sound}'**
  String soundSummary(String sound);

  /// One letter per day, Monday first
  ///
  /// In en, this message translates to:
  /// **'MTWTFSS'**
  String get weekdayLetters;

  /// Short day names, Monday first, comma separated
  ///
  /// In en, this message translates to:
  /// **'Mon,Tue,Wed,Thu,Fri,Sat,Sun'**
  String get weekdaysShort;

  /// Buttons
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAlarm.
  ///
  /// In en, this message translates to:
  /// **'Delete Alarm'**
  String get deleteAlarm;

  /// No description provided for @toggleAlarm.
  ///
  /// In en, this message translates to:
  /// **'Turn Alarm On or Off'**
  String get toggleAlarm;

  /// Stopwatch and timer buttons
  ///
  /// In en, this message translates to:
  /// **'Lap'**
  String get lap;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @lapNumber.
  ///
  /// In en, this message translates to:
  /// **'Lap {n}'**
  String lapNumber(int n);

  /// Headers of the laps table
  ///
  /// In en, this message translates to:
  /// **'Lap'**
  String get lapsHeaderLap;

  /// No description provided for @lapsHeaderSplit.
  ///
  /// In en, this message translates to:
  /// **'Lap time'**
  String get lapsHeaderSplit;

  /// No description provided for @lapsHeaderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get lapsHeaderTotal;

  /// Labels above the timer picker
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get unitHours;

  /// No description provided for @unitMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unitMinutes;

  /// No description provided for @unitSeconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get unitSeconds;

  /// Placeholder of the timer label and default name
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerLabel;

  /// Submenu with ready-made timers
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// Header of the recent timers
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recents;

  /// Notification when a timer ends
  ///
  /// In en, this message translates to:
  /// **'Timer done'**
  String get timerDone;

  /// Notification body of a ringing alarm
  ///
  /// In en, this message translates to:
  /// **'{label} · {time}'**
  String alarmRinging(String label, String time);

  /// Action that stops a ringing alarm or timer
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get dismiss;

  /// End time of a running timer, next to a bell
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String endsAt(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
