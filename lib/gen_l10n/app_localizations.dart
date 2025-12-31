import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dodgeball Battle'**
  String get appTitle;

  /// No description provided for @missionMode.
  ///
  /// In en, this message translates to:
  /// **'Mission Mode'**
  String get missionMode;

  /// No description provided for @missionModeSelectLevel.
  ///
  /// In en, this message translates to:
  /// **'Mission Mode - Select Level'**
  String get missionModeSelectLevel;

  /// No description provided for @playerCount.
  ///
  /// In en, this message translates to:
  /// **'Player Count:'**
  String get playerCount;

  /// No description provided for @onePlayer.
  ///
  /// In en, this message translates to:
  /// **'1 Player'**
  String get onePlayer;

  /// No description provided for @twoPlayers.
  ///
  /// In en, this message translates to:
  /// **'2 Players'**
  String get twoPlayers;

  /// No description provided for @mapEditor.
  ///
  /// In en, this message translates to:
  /// **'Map Editor'**
  String get mapEditor;

  /// No description provided for @noMaps.
  ///
  /// In en, this message translates to:
  /// **'No Maps Available'**
  String get noMaps;

  /// No description provided for @createMap.
  ///
  /// In en, this message translates to:
  /// **'Create Map'**
  String get createMap;

  /// No description provided for @enemyCount.
  ///
  /// In en, this message translates to:
  /// **'Enemies: {count}'**
  String enemyCount(int count);

  /// No description provided for @obstacles.
  ///
  /// In en, this message translates to:
  /// **'Obstacles: {count}'**
  String obstacles(int count);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @missionOnlyFromFirst.
  ///
  /// In en, this message translates to:
  /// **'Mission mode can only start from level 1'**
  String get missionOnlyFromFirst;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMap.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete map \"{name}\"?'**
  String confirmDeleteMap(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @mapDeleted.
  ///
  /// In en, this message translates to:
  /// **'Map deleted'**
  String get mapDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @builtinMapCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'Built-in maps cannot be deleted'**
  String get builtinMapCannotDelete;

  /// No description provided for @killCount.
  ///
  /// In en, this message translates to:
  /// **'Kills: {current} / {total}'**
  String killCount(int current, int total);

  /// No description provided for @cooldownTime.
  ///
  /// In en, this message translates to:
  /// **'Cooldown: {seconds}s'**
  String cooldownTime(String seconds);

  /// No description provided for @player1.
  ///
  /// In en, this message translates to:
  /// **'Player 1'**
  String get player1;

  /// No description provided for @player2.
  ///
  /// In en, this message translates to:
  /// **'Player 2'**
  String get player2;

  /// No description provided for @gamePaused.
  ///
  /// In en, this message translates to:
  /// **'Game Paused'**
  String get gamePaused;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map: {name}'**
  String map(String name);

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target: Eliminate {count} enemies'**
  String target(int count);

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @exitGame.
  ///
  /// In en, this message translates to:
  /// **'Exit Game'**
  String get exitGame;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat!'**
  String get defeat;

  /// No description provided for @levelComplete.
  ///
  /// In en, this message translates to:
  /// **'🎉 Level Complete!'**
  String get levelComplete;

  /// No description provided for @levelCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations on completing {name}!'**
  String levelCompleteMessage(String name);

  /// No description provided for @preparingNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Preparing for {name}'**
  String preparingNextLevel(String name);

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status:'**
  String get currentStatus;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'💚 Health: {health}'**
  String health(int health);

  /// No description provided for @speedBoost.
  ///
  /// In en, this message translates to:
  /// **'⚡ Speed Boost: {time}s'**
  String speedBoost(String time);

  /// No description provided for @attackSpeedBoost.
  ///
  /// In en, this message translates to:
  /// **'🎯 Attack Speed Boost: {time}s'**
  String attackSpeedBoost(String time);

  /// No description provided for @statusCarryOver.
  ///
  /// In en, this message translates to:
  /// **'💡 Your health and power-up effects will carry over to the next level!'**
  String get statusCarryOver;

  /// No description provided for @backToSelection.
  ///
  /// In en, this message translates to:
  /// **'Back to Selection'**
  String get backToSelection;

  /// No description provided for @continueNow.
  ///
  /// In en, this message translates to:
  /// **'Continue Now'**
  String get continueNow;

  /// No description provided for @allLevelsComplete.
  ///
  /// In en, this message translates to:
  /// **'🏆 All Levels Complete!'**
  String get allLevelsComplete;

  /// No description provided for @allLevelsCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You\'ve completed all levels!'**
  String get allLevelsCompleteMessage;

  /// No description provided for @lastLevel.
  ///
  /// In en, this message translates to:
  /// **'Last Level: {name}'**
  String lastLevel(String name);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @missionDescription.
  ///
  /// In en, this message translates to:
  /// **'• Eliminate all enemies to complete the level\n• Automatically proceed to the next level after completion\n• Set health and AI difficulty before starting the challenge'**
  String get missionDescription;

  /// No description provided for @maxHealth.
  ///
  /// In en, this message translates to:
  /// **'Max Health: {health}'**
  String maxHealth(int health);

  /// No description provided for @aiDifficulty.
  ///
  /// In en, this message translates to:
  /// **'AI Difficulty'**
  String get aiDifficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @gameHelp.
  ///
  /// In en, this message translates to:
  /// **'Game Help'**
  String get gameHelp;

  /// No description provided for @gameObjective.
  ///
  /// In en, this message translates to:
  /// **'Game Objective'**
  String get gameObjective;

  /// No description provided for @gameObjectiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Eliminate all enemies on the field to complete the level! Hit enemies with the ball to knock them out, but be careful not to get hit. After completing a level, you\'ll automatically proceed to the next one, and your health and power-up effects will carry over.'**
  String get gameObjectiveDesc;

  /// No description provided for @basicControls.
  ///
  /// In en, this message translates to:
  /// **'Basic Controls'**
  String get basicControls;

  /// No description provided for @basicControlsDesc.
  ///
  /// In en, this message translates to:
  /// **'• Movement: Use arrow keys, WASD, virtual joystick, or gamepad to move\n• Throw: Auto-aims at nearest enemy, press Space, J key, or gamepad button to throw\n• Cooldown: Wait 10 seconds after throwing before you can throw again\n• Two Players: Player 2 uses arrow keys to move and L key to throw'**
  String get basicControlsDesc;

  /// No description provided for @powerUps.
  ///
  /// In en, this message translates to:
  /// **'Power-Ups'**
  String get powerUps;

  /// No description provided for @healthPotion.
  ///
  /// In en, this message translates to:
  /// **'Health Potion'**
  String get healthPotion;

  /// No description provided for @healthPotionDesc.
  ///
  /// In en, this message translates to:
  /// **'Restores 1 health point. When you get hit, you lose health. Use health potions to stay in the fight.'**
  String get healthPotionDesc;

  /// No description provided for @speedBoostItem.
  ///
  /// In en, this message translates to:
  /// **'Speed Boost'**
  String get speedBoostItem;

  /// No description provided for @speedBoostItemDesc.
  ///
  /// In en, this message translates to:
  /// **'Increases movement speed for 30 seconds. Pick up to dodge enemy attacks more easily and chase down enemies faster.'**
  String get speedBoostItemDesc;

  /// No description provided for @attackSpeedItem.
  ///
  /// In en, this message translates to:
  /// **'Attack Speed Boost'**
  String get attackSpeedItem;

  /// No description provided for @attackSpeedItemDesc.
  ///
  /// In en, this message translates to:
  /// **'Reduces throw cooldown for 30 seconds. Pick up to throw balls more frequently and increase your combat efficiency.'**
  String get attackSpeedItemDesc;

  /// No description provided for @gameTips.
  ///
  /// In en, this message translates to:
  /// **'Game Tips'**
  String get gameTips;

  /// No description provided for @gameTipsDesc.
  ///
  /// In en, this message translates to:
  /// **'• Use obstacles to dodge enemy attacks\n• Power-up effects stack and carry over to next level\n• Keep moving when you can\'t throw\n• Prioritize the most threatening enemies\n• Two-player cooperation makes difficult levels easier'**
  String get gameTipsDesc;

  /// No description provided for @obstaclesTitle.
  ///
  /// In en, this message translates to:
  /// **'Obstacles'**
  String get obstaclesTitle;

  /// No description provided for @obstaclesDesc.
  ///
  /// In en, this message translates to:
  /// **'Stones and walls on the field block ball trajectories. Use obstacles wisely to dodge enemy attacks, but remember they also block your own throws.'**
  String get obstaclesDesc;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get gotIt;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
