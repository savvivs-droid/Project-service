import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('cs'),
    Locale('en'),
    Locale('ru'),
    Locale('vi')
  ];

  /// Login: email field label
  ///
  /// In cs, this message translates to:
  /// **'E-mail'**
  String get loginEmailLabel;

  /// Login: invalid email validator
  ///
  /// In cs, this message translates to:
  /// **'Zadejte platný e-mail'**
  String get loginEmailInvalid;

  /// Login: password field label
  ///
  /// In cs, this message translates to:
  /// **'Heslo'**
  String get loginPasswordLabel;

  /// Login: password too short validator
  ///
  /// In cs, this message translates to:
  /// **'Minimálně 6 znaků'**
  String get loginPasswordTooShort;

  /// Login: submit button
  ///
  /// In cs, this message translates to:
  /// **'Přihlásit se'**
  String get loginSubmitButton;

  /// Login: link to register screen
  ///
  /// In cs, this message translates to:
  /// **'Nemáte účet? Zaregistrujte se'**
  String get loginNoAccount;

  /// Login: generic sign-in error
  ///
  /// In cs, this message translates to:
  /// **'Přihlášení se nezdařilo. Zkontrolujte připojení k internetu.'**
  String get loginGenericError;

  /// Register: app bar title
  ///
  /// In cs, this message translates to:
  /// **'Registrace'**
  String get registerTitle;

  /// Register: section heading
  ///
  /// In cs, this message translates to:
  /// **'Registrace podniku'**
  String get registerEstablishmentSectionTitle;

  /// Register: full name field
  ///
  /// In cs, this message translates to:
  /// **'Jméno'**
  String get registerFullNameLabel;

  /// Register: full name validator
  ///
  /// In cs, this message translates to:
  /// **'Zadejte jméno'**
  String get registerFullNameRequired;

  /// Register: phone field
  ///
  /// In cs, this message translates to:
  /// **'Telefon'**
  String get registerPhoneLabel;

  /// Register: phone validator
  ///
  /// In cs, this message translates to:
  /// **'Zadejte telefon'**
  String get registerPhoneRequired;

  /// Register: establishment section heading
  ///
  /// In cs, this message translates to:
  /// **'Váš podnik'**
  String get registerYourEstablishmentTitle;

  /// Register: IČO field label
  ///
  /// In cs, this message translates to:
  /// **'IČO'**
  String get registerIcoLabel;

  /// Register: IČO field hint
  ///
  /// In cs, this message translates to:
  /// **'8 číslic'**
  String get registerIcoHint;

  /// Register: IČO validator
  ///
  /// In cs, this message translates to:
  /// **'Zadejte platné IČO (8 číslic)'**
  String get registerIcoInvalid;

  /// Register: establishment name field
  ///
  /// In cs, this message translates to:
  /// **'Název podniku'**
  String get registerEstablishmentNameLabel;

  /// Register: establishment name hint
  ///
  /// In cs, this message translates to:
  /// **'Doplní se z ARES, nebo zadejte ručně'**
  String get registerEstablishmentNameHint;

  /// Register: establishment name validator
  ///
  /// In cs, this message translates to:
  /// **'Zadejte název podniku'**
  String get registerEstablishmentNameRequired;

  /// Register: address field
  ///
  /// In cs, this message translates to:
  /// **'Adresa'**
  String get registerAddressLabel;

  /// Register: address validator
  ///
  /// In cs, this message translates to:
  /// **'Zadejte adresu podniku'**
  String get registerAddressRequired;

  /// Register: submit button
  ///
  /// In cs, this message translates to:
  /// **'Zaregistrovat se'**
  String get registerSubmitButton;

  /// Register: ARES lookup not found
  ///
  /// In cs, this message translates to:
  /// **'Organizaci jsme v ARES nenašli — vyplňte název a adresu ručně.'**
  String get registerIcoNotFoundInAres;

  /// Register: ARES lookup success
  ///
  /// In cs, this message translates to:
  /// **'Údaje byly načteny z ARES.'**
  String get registerIcoFoundInAres;

  /// Register: email confirmation needed
  ///
  /// In cs, this message translates to:
  /// **'Registrace je téměř dokončena! Potvrďte e-mail odkazem z dopisu a poté se přihlaste.'**
  String get registerEmailConfirmationNeeded;

  /// Register: generic sign-up error
  ///
  /// In cs, this message translates to:
  /// **'Registrace se nezdařila. Zkontrolujte zadané údaje a připojení k internetu.'**
  String get registerGenericError;

  /// Register: IČO already registered error
  ///
  /// In cs, this message translates to:
  /// **'Podnik s tímto IČO je již v systému zaregistrován. Obraťte se na administrátora servisní společnosti.'**
  String get registerIcoAlreadyRegistered;

  /// Register: email already registered error
  ///
  /// In cs, this message translates to:
  /// **'Uživatel s tímto e-mailem je již zaregistrován.'**
  String get registerEmailAlreadyRegistered;

  /// Auth gate: profile not found message
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se najít profil uživatele.\nRegistrace zřejmě není dokončena — potvrďte e-mail.'**
  String get authGateProfileNotFound;

  /// Auth gate: sign out and retry button
  ///
  /// In cs, this message translates to:
  /// **'Odhlásit se a zkusit znovu'**
  String get authGateSignOutRetry;

  /// Request status: new
  ///
  /// In cs, this message translates to:
  /// **'Nová'**
  String get statusRequestNew;

  /// Request status: scheduled
  ///
  /// In cs, this message translates to:
  /// **'Domluven čas'**
  String get statusRequestScheduled;

  /// Request status: done
  ///
  /// In cs, this message translates to:
  /// **'Hotovo'**
  String get statusRequestDone;

  /// Request status: cancelled
  ///
  /// In cs, this message translates to:
  /// **'Zrušeno'**
  String get statusRequestCancelled;

  /// Equipment status: active
  ///
  /// In cs, this message translates to:
  /// **'Funguje'**
  String get statusEquipmentActive;

  /// Equipment status: in repair
  ///
  /// In cs, this message translates to:
  /// **'V opravě'**
  String get statusEquipmentInRepair;

  /// Equipment status: decommissioned
  ///
  /// In cs, this message translates to:
  /// **'Vyřazeno'**
  String get statusEquipmentDecommissioned;

  /// Admin home: active tab title
  ///
  /// In cs, this message translates to:
  /// **'Aktivní zakázky'**
  String get adminHomeActiveTab;

  /// Admin home: done tab title
  ///
  /// In cs, this message translates to:
  /// **'Dokončené zakázky'**
  String get adminHomeDoneTab;

  /// Admin home: clients tab title
  ///
  /// In cs, this message translates to:
  /// **'Klienti'**
  String get adminHomeClientsTab;

  /// Sign out icon button tooltip
  ///
  /// In cs, this message translates to:
  /// **'Odhlásit se'**
  String get signOutTooltip;

  /// Bottom nav: active label
  ///
  /// In cs, this message translates to:
  /// **'Aktivní'**
  String get navActive;

  /// Bottom nav: done label
  ///
  /// In cs, this message translates to:
  /// **'Dokončené'**
  String get navDone;

  /// Requests load error with details
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se načíst zakázky: {error}'**
  String requestsLoadError(String error);

  /// Empty state: no active requests
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádné aktivní zakázky'**
  String get noActiveRequests;

  /// Empty state: no done requests
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádné dokončené zakázky'**
  String get noDoneRequests;

  /// Error opening maps app
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se otevřít mapy'**
  String get mapsOpenError;

  /// Error starting a phone call
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se zahájit hovor'**
  String get callError;

  /// Scheduled visit time label
  ///
  /// In cs, this message translates to:
  /// **'Návštěva: {time}'**
  String visitLabel(String time);

  /// Establishments load error with details
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se načíst podniky: {error}'**
  String establishmentsLoadError(String error);

  /// Empty state: no establishments
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádné podniky'**
  String get noEstablishments;

  /// Fallback request card title when no equipment listed
  ///
  /// In cs, this message translates to:
  /// **'Zakázka'**
  String get requestFallbackTitle;

  /// Request detail: app bar title with short id
  ///
  /// In cs, this message translates to:
  /// **'Zakázka #{id}'**
  String requestDetailTitle(String id);

  /// Chat button/tooltip on admin request detail
  ///
  /// In cs, this message translates to:
  /// **'Chat s klientem'**
  String get chatWithClient;

  /// Request detail: client section label
  ///
  /// In cs, this message translates to:
  /// **'Klient'**
  String get clientLabel;

  /// Request detail: equipment section label
  ///
  /// In cs, this message translates to:
  /// **'Vybavení'**
  String get equipmentLabel;

  /// Generic 'not specified' value
  ///
  /// In cs, this message translates to:
  /// **'Neuvedeno'**
  String get notSpecified;

  /// Request detail: description section label
  ///
  /// In cs, this message translates to:
  /// **'Popis'**
  String get descriptionLabel;

  /// Button to assign a visit time
  ///
  /// In cs, this message translates to:
  /// **'Naplánovat čas'**
  String get assignTimeButton;

  /// Button to change the assigned visit time
  ///
  /// In cs, this message translates to:
  /// **'Změnit čas ({time})'**
  String changeTimeButton(String time);

  /// Technician comment section title
  ///
  /// In cs, this message translates to:
  /// **'Poznámka technika'**
  String get technicianCommentTitle;

  /// Technician comment text field hint
  ///
  /// In cs, this message translates to:
  /// **'Co bylo uděláno, co bylo vyměněno...'**
  String get technicianCommentHint;

  /// Save technician comment button
  ///
  /// In cs, this message translates to:
  /// **'Uložit poznámku'**
  String get saveCommentButton;

  /// Mark request as done button
  ///
  /// In cs, this message translates to:
  /// **'Označit jako dokončeno'**
  String get markDoneButton;

  /// Cancel request button/dialog action
  ///
  /// In cs, this message translates to:
  /// **'Zrušit zakázku'**
  String get cancelRequestButton;

  /// Cancel request confirmation dialog title
  ///
  /// In cs, this message translates to:
  /// **'Zrušit zakázku?'**
  String get cancelRequestDialogTitle;

  /// Cancel request confirmation dialog body
  ///
  /// In cs, this message translates to:
  /// **'Tuto akci bude možné vrátit zpět jen ručně v databázi.'**
  String get cancelRequestDialogContent;

  /// Cancel request confirmation dialog dismiss action
  ///
  /// In cs, this message translates to:
  /// **'Nerušit'**
  String get cancelRequestDialogDismiss;

  /// Generic save error
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se uložit změny'**
  String get saveChangesError;

  /// Chat button/tooltip on client request detail
  ///
  /// In cs, this message translates to:
  /// **'Chat s technikem'**
  String get chatWithTechnician;

  /// Display name for the technician side in chat
  ///
  /// In cs, this message translates to:
  /// **'Technik'**
  String get technicianName;

  /// Client request detail: visit time section label
  ///
  /// In cs, this message translates to:
  /// **'Čas návštěvy'**
  String get visitTimeLabel;

  /// Chat: send message error
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se odeslat zprávu'**
  String get chatSendError;

  /// Chat screen app bar title
  ///
  /// In cs, this message translates to:
  /// **'Chat · {title}'**
  String chatTitle(String title);

  /// Chat load error with details
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se načíst chat: {error}'**
  String chatLoadError(String error);

  /// Chat empty state
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádné zprávy — napište první'**
  String get chatEmpty;

  /// Chat message input hint
  ///
  /// In cs, this message translates to:
  /// **'Zpráva...'**
  String get chatMessageHint;

  /// Establishment detail: add equipment FAB tooltip
  ///
  /// In cs, this message translates to:
  /// **'Přidat vybavení'**
  String get addEquipmentTooltip;

  /// Establishment detail: entrance photo section title
  ///
  /// In cs, this message translates to:
  /// **'Vstup'**
  String get entranceSectionTitle;

  /// Photo save error
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se uložit fotku'**
  String get photoSaveError;

  /// Photo delete error
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se smazat fotku'**
  String get photoDeleteError;

  /// Add entrance photo placeholder label
  ///
  /// In cs, this message translates to:
  /// **'Přidat fotku vstupu'**
  String get addEntrancePhotoLabel;

  /// Equipment load error with details
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se načíst vybavení: {error}'**
  String equipmentLoadError(String error);

  /// Empty state: no equipment
  ///
  /// In cs, this message translates to:
  /// **'Zatím nebylo přidáno žádné vybavení'**
  String get noEquipmentYet;

  /// Equipment form: edit title
  ///
  /// In cs, this message translates to:
  /// **'Upravit vybavení'**
  String get equipmentFormEditTitle;

  /// Equipment form: new title
  ///
  /// In cs, this message translates to:
  /// **'Nové vybavení'**
  String get equipmentFormNewTitle;

  /// Equipment form: type section title
  ///
  /// In cs, this message translates to:
  /// **'Typ vybavení'**
  String get equipmentTypeSectionTitle;

  /// Equipment type picker: other option
  ///
  /// In cs, this message translates to:
  /// **'Jiné'**
  String get equipmentTypeOther;

  /// Equipment type validator
  ///
  /// In cs, this message translates to:
  /// **'Vyberte typ vybavení'**
  String get equipmentTypeRequired;

  /// Custom equipment type field label
  ///
  /// In cs, this message translates to:
  /// **'Uveďte typ vybavení'**
  String get equipmentTypeCustomLabel;

  /// Custom equipment type validator
  ///
  /// In cs, this message translates to:
  /// **'Zadejte typ vybavení'**
  String get equipmentTypeCustomRequired;

  /// Equipment model field label
  ///
  /// In cs, this message translates to:
  /// **'Model'**
  String get modelLabel;

  /// Sticker photo section title
  ///
  /// In cs, this message translates to:
  /// **'Fotka štítku'**
  String get stickerPhotoSectionTitle;

  /// Sticker photo instructions
  ///
  /// In cs, this message translates to:
  /// **'Vyfoťte štítek na vybavení — kód zadávat nemusíte.'**
  String get stickerPhotoHint;

  /// Equipment photos section title
  ///
  /// In cs, this message translates to:
  /// **'Fotky vybavení'**
  String get equipmentPhotosSectionTitle;

  /// Equipment status dropdown label
  ///
  /// In cs, this message translates to:
  /// **'Stav'**
  String get statusDropdownLabel;

  /// Installed-at button, no date set
  ///
  /// In cs, this message translates to:
  /// **'Datum instalace neuvedeno'**
  String get installedAtNotSet;

  /// Installed-at button with date
  ///
  /// In cs, this message translates to:
  /// **'Instalováno: {date}'**
  String installedAtSet(String date);

  /// Generic save button
  ///
  /// In cs, this message translates to:
  /// **'Uložit'**
  String get saveButton;

  /// Equipment save error with details
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se uložit vybavení: {error}'**
  String equipmentSaveError(String error);

  /// Photo source picker: camera option
  ///
  /// In cs, this message translates to:
  /// **'Fotoaparát'**
  String get cameraOption;

  /// Photo source picker: gallery option
  ///
  /// In cs, this message translates to:
  /// **'Galerie'**
  String get galleryOption;

  /// Language switcher icon button tooltip
  ///
  /// In cs, this message translates to:
  /// **'Jazyk'**
  String get languageSwitcherTooltip;

  /// Language switcher: follow system language option
  ///
  /// In cs, this message translates to:
  /// **'Jako v systému'**
  String get systemLanguageOption;

  /// Equipment type: fridge
  ///
  /// In cs, this message translates to:
  /// **'Lednice'**
  String get equipmentTypeFridge;

  /// Equipment type: freezer
  ///
  /// In cs, this message translates to:
  /// **'Mraznička'**
  String get equipmentTypeFreezer;

  /// Equipment type: combi oven
  ///
  /// In cs, this message translates to:
  /// **'Konvektomat'**
  String get equipmentTypeCombiOven;

  /// Equipment type: stove
  ///
  /// In cs, this message translates to:
  /// **'Sporák'**
  String get equipmentTypeStove;

  /// Equipment type: dishwasher
  ///
  /// In cs, this message translates to:
  /// **'Myčka nádobí'**
  String get equipmentTypeDishwasher;

  /// Equipment type: grill
  ///
  /// In cs, this message translates to:
  /// **'Gril'**
  String get equipmentTypeGrill;

  /// Equipment type: coffee machine
  ///
  /// In cs, this message translates to:
  /// **'Kávovar'**
  String get equipmentTypeCoffeeMachine;

  /// Equipment type: mixer/blender
  ///
  /// In cs, this message translates to:
  /// **'Mixér / tyčový mixér'**
  String get equipmentTypeMixer;

  /// Equipment type: cutting table
  ///
  /// In cs, this message translates to:
  /// **'Krájecí stůl'**
  String get equipmentTypeCuttingTable;

  /// Client bottom nav: equipment tab
  ///
  /// In cs, this message translates to:
  /// **'Moje vybavení'**
  String get clientEquipmentTab;

  /// Client bottom nav: profile tab / app bar title
  ///
  /// In cs, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// Profile: personal data section title
  ///
  /// In cs, this message translates to:
  /// **'Osobní údaje'**
  String get profilePersonalDataTitle;

  /// Profile: save success message
  ///
  /// In cs, this message translates to:
  /// **'Údaje uloženy'**
  String get profileSaved;

  /// Profile: save error
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se uložit údaje'**
  String get profileSaveError;

  /// Profile: email section title
  ///
  /// In cs, this message translates to:
  /// **'E-mail'**
  String get profileEmailSectionTitle;

  /// Profile: email change hint
  ///
  /// In cs, this message translates to:
  /// **'Po změně e-mailu může být potřeba potvrzení odkazem z dopisu.'**
  String get profileEmailHint;

  /// Profile: change email button
  ///
  /// In cs, this message translates to:
  /// **'Změnit e-mail'**
  String get profileChangeEmailButton;

  /// Profile: email change requested message
  ///
  /// In cs, this message translates to:
  /// **'Žádost odeslána. Zkontrolujte poštu, pokud je potřeba potvrzení.'**
  String get emailChangeRequested;

  /// Profile: email change error
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se změnit e-mail'**
  String get emailChangeError;

  /// Profile: password section title
  ///
  /// In cs, this message translates to:
  /// **'Heslo'**
  String get profilePasswordSectionTitle;

  /// Profile: new password field label
  ///
  /// In cs, this message translates to:
  /// **'Nové heslo'**
  String get profileNewPasswordLabel;

  /// Profile: change password button
  ///
  /// In cs, this message translates to:
  /// **'Změnit heslo'**
  String get profileChangePasswordButton;

  /// Profile: password change success
  ///
  /// In cs, this message translates to:
  /// **'Heslo bylo změněno'**
  String get passwordChanged;

  /// Profile: password change error
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se změnit heslo'**
  String get passwordChangeError;

  /// Client home: FAB label to create a repair request
  ///
  /// In cs, this message translates to:
  /// **'Vytvořit žádost o opravu'**
  String get clientCreateRequestButton;

  /// Create request screen title
  ///
  /// In cs, this message translates to:
  /// **'Nová žádost'**
  String get createRequestTitle;

  /// Create request: equipment type section title
  ///
  /// In cs, this message translates to:
  /// **'Typ vybavení'**
  String get createRequestTypeSectionTitle;

  /// Create request: specific equipment section title
  ///
  /// In cs, this message translates to:
  /// **'Vybavení'**
  String get createRequestEquipmentSectionTitle;

  /// Create request: equipment not selected error
  ///
  /// In cs, this message translates to:
  /// **'Vyberte vybavení'**
  String get createRequestEquipmentRequired;

  /// Create request: description section title
  ///
  /// In cs, this message translates to:
  /// **'Popište problém'**
  String get createRequestDescriptionSectionTitle;

  /// Create request: description field hint
  ///
  /// In cs, this message translates to:
  /// **'Stručně popište, co se stalo'**
  String get createRequestDescriptionHint;

  /// Create request: description required error
  ///
  /// In cs, this message translates to:
  /// **'Přidejte popis problému'**
  String get createRequestDescriptionRequired;

  /// Create request: submit button
  ///
  /// In cs, this message translates to:
  /// **'Odeslat žádost'**
  String get createRequestSubmitButton;

  /// Create request: submission error with details
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se vytvořit žádost: {error}'**
  String createRequestError(String error);

  /// Establishment switcher: button tooltip
  ///
  /// In cs, this message translates to:
  /// **'Přepnout podnik'**
  String get establishmentSwitcherTooltip;

  /// Establishment switcher: menu item to add another establishment
  ///
  /// In cs, this message translates to:
  /// **'Přidat podnik'**
  String get establishmentSwitcherAddNew;

  /// Add establishment: screen title
  ///
  /// In cs, this message translates to:
  /// **'Nový podnik'**
  String get addEstablishmentTitle;

  /// Add establishment: contact phone field
  ///
  /// In cs, this message translates to:
  /// **'Kontaktní telefon podniku'**
  String get addEstablishmentPhoneLabel;

  /// Add establishment: contact phone validator
  ///
  /// In cs, this message translates to:
  /// **'Zadejte kontaktní telefon'**
  String get addEstablishmentPhoneRequired;

  /// Add establishment: submit button
  ///
  /// In cs, this message translates to:
  /// **'Přidat'**
  String get addEstablishmentSubmitButton;

  /// Add establishment: generic submission error
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se přidat podnik. Zkontrolujte zadané údaje a připojení k internetu.'**
  String get addEstablishmentGenericError;

  /// Mark done dialog: title
  ///
  /// In cs, this message translates to:
  /// **'Uzavřít zakázku'**
  String get markDoneDialogTitle;

  /// Mark done dialog: repair cost field
  ///
  /// In cs, this message translates to:
  /// **'Cena opravy'**
  String get markDoneRepairCostLabel;

  /// Mark done dialog: parts cost field
  ///
  /// In cs, this message translates to:
  /// **'Cena náhradních dílů'**
  String get markDonePartsCostLabel;

  /// Mark done dialog: cost field required
  ///
  /// In cs, this message translates to:
  /// **'Zadejte částku'**
  String get markDoneCostRequired;

  /// Mark done dialog: cost field invalid
  ///
  /// In cs, this message translates to:
  /// **'Zadejte platnou částku'**
  String get markDoneCostInvalid;

  /// Mark done dialog: cancel action
  ///
  /// In cs, this message translates to:
  /// **'Zrušit'**
  String get markDoneDialogCancel;

  /// Mark done dialog: confirm action
  ///
  /// In cs, this message translates to:
  /// **'Uzavřít zakázku'**
  String get markDoneDialogConfirm;

  /// Request card: repair cost short label
  ///
  /// In cs, this message translates to:
  /// **'Oprava'**
  String get requestCostRepairLabel;

  /// Request card: parts cost short label
  ///
  /// In cs, this message translates to:
  /// **'Díly'**
  String get requestCostPartsLabel;

  /// Admin home: statistics tab title
  ///
  /// In cs, this message translates to:
  /// **'Statistika'**
  String get adminHomeStatsTab;

  /// Statistics: week period preset
  ///
  /// In cs, this message translates to:
  /// **'Týden'**
  String get statsPeriodWeek;

  /// Statistics: month period preset
  ///
  /// In cs, this message translates to:
  /// **'Měsíc'**
  String get statsPeriodMonth;

  /// Statistics: year period preset
  ///
  /// In cs, this message translates to:
  /// **'Rok'**
  String get statsPeriodYear;

  /// Statistics: custom period preset
  ///
  /// In cs, this message translates to:
  /// **'Vlastní období'**
  String get statsPeriodCustom;

  /// Statistics: closed requests count label
  ///
  /// In cs, this message translates to:
  /// **'Uzavřené zakázky'**
  String get statsClosedCount;

  /// Statistics: revenue (sum of repair cost) label
  ///
  /// In cs, this message translates to:
  /// **'Příjem'**
  String get statsRevenue;

  /// Statistics: expenses (sum of parts cost) label
  ///
  /// In cs, this message translates to:
  /// **'Výdaje'**
  String get statsExpenses;

  /// Statistics: profit label
  ///
  /// In cs, this message translates to:
  /// **'Zisk'**
  String get statsProfit;

  /// Statistics: load error with details
  ///
  /// In cs, this message translates to:
  /// **'Nepodařilo se načíst statistiku: {error}'**
  String statsLoadError(String error);
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
      <String>['cs', 'en', 'ru', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
