import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('pt')
  ];

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgot_password;

  /// No description provided for @return_to_login.
  ///
  /// In en, this message translates to:
  /// **'Return to login'**
  String get return_to_login;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get email_required;

  /// No description provided for @verification_code.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verification_code;

  /// No description provided for @success_message.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success_message;

  /// No description provided for @code_required.
  ///
  /// In en, this message translates to:
  /// **'Code required'**
  String get code_required;

  /// No description provided for @code_invalid.
  ///
  /// In en, this message translates to:
  /// **'Code invalid'**
  String get code_invalid;

  /// No description provided for @error_message.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error_message;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get tickets;

  /// No description provided for @events_source.
  ///
  /// In en, this message translates to:
  /// **'Events source'**
  String get events_source;

  /// No description provided for @vulnerabilities.
  ///
  /// In en, this message translates to:
  /// **'Vulnerabilities'**
  String get vulnerabilities;

  /// No description provided for @email_leak.
  ///
  /// In en, this message translates to:
  /// **'Emails leak'**
  String get email_leak;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @select_company.
  ///
  /// In en, this message translates to:
  /// **'Select company'**
  String get select_company;

  /// No description provided for @no_result.
  ///
  /// In en, this message translates to:
  /// **'No result'**
  String get no_result;

  /// No description provided for @incidents.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get incidents;

  /// No description provided for @total_number_of_incidents.
  ///
  /// In en, this message translates to:
  /// **'Total number of incidents'**
  String get total_number_of_incidents;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @last_24_hours.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get last_24_hours;

  /// No description provided for @last_7_days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last_7_days;

  /// No description provided for @last_30_days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last_30_days;

  /// No description provided for @source_user.
  ///
  /// In en, this message translates to:
  /// **'Source user'**
  String get source_user;

  /// No description provided for @target_user.
  ///
  /// In en, this message translates to:
  /// **'Target user'**
  String get target_user;

  /// No description provided for @most_recurrent.
  ///
  /// In en, this message translates to:
  /// **'Most recurrent'**
  String get most_recurrent;

  /// No description provided for @by_severity.
  ///
  /// In en, this message translates to:
  /// **'By severity'**
  String get by_severity;

  /// No description provided for @source_hostname.
  ///
  /// In en, this message translates to:
  /// **'Source hostname'**
  String get source_hostname;

  /// No description provided for @destination_hostname.
  ///
  /// In en, this message translates to:
  /// **'Destination hostname'**
  String get destination_hostname;

  /// No description provided for @ticket_id.
  ///
  /// In en, this message translates to:
  /// **'Ticket Id'**
  String get ticket_id;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @criticality.
  ///
  /// In en, this message translates to:
  /// **'Criticality'**
  String get criticality;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @opening_date.
  ///
  /// In en, this message translates to:
  /// **'Opening date'**
  String get opening_date;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @ip.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get ip;

  /// No description provided for @health_check.
  ///
  /// In en, this message translates to:
  /// **'HealthCheck'**
  String get health_check;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// No description provided for @offset.
  ///
  /// In en, this message translates to:
  /// **'Offset'**
  String get offset;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @log_state.
  ///
  /// In en, this message translates to:
  /// **'Log state'**
  String get log_state;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @ticket.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get ticket;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'address'**
  String get address;

  /// No description provided for @plugin_name.
  ///
  /// In en, this message translates to:
  /// **'Plugin name'**
  String get plugin_name;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @solution.
  ///
  /// In en, this message translates to:
  /// **'Solution'**
  String get solution;

  /// No description provided for @discovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get discovery;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @telephone.
  ///
  /// In en, this message translates to:
  /// **'Telephone'**
  String get telephone;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get change_password;

  /// No description provided for @current_password.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get current_password;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get new_password;

  /// No description provided for @confirm_new_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirm_new_password;

  /// No description provided for @passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwords_do_not_match;

  /// No description provided for @password_must_be_between_8_and_30_characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be between 8 and 30 characters'**
  String get password_must_be_between_8_and_30_characters;

  /// No description provided for @access_level.
  ///
  /// In en, this message translates to:
  /// **'Access level'**
  String get access_level;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @company_data.
  ///
  /// In en, this message translates to:
  /// **'Company data'**
  String get company_data;

  /// No description provided for @create_user.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get create_user;

  /// No description provided for @create_company.
  ///
  /// In en, this message translates to:
  /// **'Create company'**
  String get create_company;

  /// No description provided for @permission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permission;

  /// No description provided for @active_user.
  ///
  /// In en, this message translates to:
  /// **'Active user'**
  String get active_user;

  /// No description provided for @active_company.
  ///
  /// In en, this message translates to:
  /// **'Active company'**
  String get active_company;

  /// No description provided for @reset_password.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get reset_password;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @companies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get companies;

  /// No description provided for @ips_direct.
  ///
  /// In en, this message translates to:
  /// **'Directly related IPs'**
  String get ips_direct;

  /// No description provided for @plugin_family_indirect.
  ///
  /// In en, this message translates to:
  /// **'Indirectly related plugin family'**
  String get plugin_family_indirect;

  /// No description provided for @ips_indirect.
  ///
  /// In en, this message translates to:
  /// **'Indirectly related IPs'**
  String get ips_indirect;

  /// No description provided for @plugin_family_direct.
  ///
  /// In en, this message translates to:
  /// **'Directly related plugin family'**
  String get plugin_family_direct;

  /// No description provided for @vulnerabilities_summary.
  ///
  /// In en, this message translates to:
  /// **'Vulnerabilities summary'**
  String get vulnerabilities_summary;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @open_ports.
  ///
  /// In en, this message translates to:
  /// **'Open ports'**
  String get open_ports;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @open_in.
  ///
  /// In en, this message translates to:
  /// **'Open in'**
  String get open_in;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
