// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Orologio';

  @override
  String get sectionWorld => 'Mondo';

  @override
  String get sectionAlarms => 'Sveglie';

  @override
  String get sectionStopwatch => 'Cronometro';

  @override
  String get sectionTimers => 'Timer';

  @override
  String get decimalSeparator => ',';

  @override
  String get add => 'Aggiungi';

  @override
  String get addCity => 'Aggiungi una città';

  @override
  String get searchCities => 'Cerca una città o un paese';

  @override
  String get noResults => 'Nessuna città trovata';

  @override
  String get removeClock => 'Togli l\'orologio';

  @override
  String cityTime(String city, String time) {
    return '$city, $time';
  }

  @override
  String get dayToday => 'Oggi';

  @override
  String get dayTomorrow => 'Domani';

  @override
  String get dayYesterday => 'Ieri';

  @override
  String hoursOffset(String day, String offset) {
    return '$day, $offset h';
  }

  @override
  String get worldEmpty => 'Aggiungi una città per vederne l\'ora';

  @override
  String get noAlarms => 'Nessuna sveglia';

  @override
  String get newAlarm => 'Nuova sveglia';

  @override
  String get editAlarm => 'Modifica sveglia';

  @override
  String get alarmDefaultLabel => 'Sveglia';

  @override
  String get repeat => 'Ripeti';

  @override
  String get label => 'Nome';

  @override
  String get sound => 'Suono';

  @override
  String get snooze => 'Rimanda';

  @override
  String get snoozeLength => 'Rimanda di';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore',
      one: '1 ora',
    );
    return '$_temp0';
  }

  @override
  String get defaultSound => 'Predefinito';

  @override
  String get repeatNever => 'Mai';

  @override
  String get repeatEveryDay => 'Ogni giorno';

  @override
  String get repeatWeekdays => 'Giorni feriali';

  @override
  String get repeatWeekends => 'Fine settimana';

  @override
  String repeatSummary(String days) {
    return 'Ripeti: $days';
  }

  @override
  String soundSummary(String sound) {
    return 'Suono: $sound';
  }

  @override
  String get weekdayLetters => 'LMMGVSD';

  @override
  String get weekdaysShort => 'lun,mar,mer,gio,ven,sab,dom';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteAlarm => 'Elimina la sveglia';

  @override
  String get toggleAlarm => 'Accendi o spegni la sveglia';

  @override
  String get lap => 'Giro';

  @override
  String get reset => 'Azzera';

  @override
  String get start => 'Avvia';

  @override
  String get stop => 'Ferma';

  @override
  String get pause => 'Pausa';

  @override
  String get resume => 'Riprendi';

  @override
  String lapNumber(int n) {
    return 'Giro $n';
  }

  @override
  String get lapsHeaderLap => 'Giro';

  @override
  String get lapsHeaderSplit => 'Tempo del giro';

  @override
  String get lapsHeaderTotal => 'Totale';

  @override
  String get unitHours => 'h';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitSeconds => 's';

  @override
  String get timerLabel => 'Timer';

  @override
  String get presets => 'Pronti';

  @override
  String get recents => 'Recenti';

  @override
  String get timerDone => 'Timer finito';

  @override
  String alarmRinging(String label, String time) {
    return '$label · $time';
  }

  @override
  String get restart => 'Riavvia';

  @override
  String get dismiss => 'Ferma';

  @override
  String endsAt(String time) {
    return '$time';
  }
}
