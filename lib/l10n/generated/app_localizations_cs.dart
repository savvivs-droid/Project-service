// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginEmailInvalid => 'Zadejte platný e-mail';

  @override
  String get loginPasswordLabel => 'Heslo';

  @override
  String get loginPasswordTooShort => 'Minimálně 6 znaků';

  @override
  String get loginSubmitButton => 'Přihlásit se';

  @override
  String get loginNoAccount => 'Nemáte účet? Zaregistrujte se';

  @override
  String get loginGenericError =>
      'Přihlášení se nezdařilo. Zkontrolujte připojení k internetu.';

  @override
  String get registerTitle => 'Registrace';

  @override
  String get registerEstablishmentSectionTitle => 'Registrace podniku';

  @override
  String get registerFullNameLabel => 'Jméno';

  @override
  String get registerFullNameRequired => 'Zadejte jméno';

  @override
  String get registerPhoneLabel => 'Telefon';

  @override
  String get registerPhoneRequired => 'Zadejte telefon';

  @override
  String get registerYourEstablishmentTitle => 'Váš podnik';

  @override
  String get registerIcoLabel => 'IČO';

  @override
  String get registerIcoHint => '8 číslic';

  @override
  String get registerIcoInvalid => 'Zadejte platné IČO (8 číslic)';

  @override
  String get registerEstablishmentNameLabel => 'Název podniku';

  @override
  String get registerEstablishmentNameHint =>
      'Doplní se z ARES, nebo zadejte ručně';

  @override
  String get registerEstablishmentNameRequired => 'Zadejte název podniku';

  @override
  String get registerAddressLabel => 'Adresa';

  @override
  String get registerAddressRequired => 'Zadejte adresu podniku';

  @override
  String get registerEstablishmentPhoneLabel => 'Kontaktní telefon podniku';

  @override
  String get registerEstablishmentPhoneRequired => 'Zadejte kontaktní telefon';

  @override
  String get registerSubmitButton => 'Zaregistrovat se';

  @override
  String get registerIcoNotFoundInAres =>
      'Organizaci jsme v ARES nenašli — vyplňte název a adresu ručně.';

  @override
  String get registerIcoFoundInAres => 'Údaje byly načteny z ARES.';

  @override
  String get registerEmailConfirmationNeeded =>
      'Registrace je téměř dokončena! Potvrďte e-mail odkazem z dopisu a poté se přihlaste.';

  @override
  String get registerGenericError =>
      'Registrace se nezdařila. Zkontrolujte zadané údaje a připojení k internetu.';

  @override
  String get registerIcoAlreadyRegistered =>
      'Podnik s tímto IČO je již v systému zaregistrován. Obraťte se na administrátora servisní společnosti.';

  @override
  String get registerEmailAlreadyRegistered =>
      'Uživatel s tímto e-mailem je již zaregistrován.';

  @override
  String get authGateProfileNotFound =>
      'Nepodařilo se najít profil uživatele.\nRegistrace zřejmě není dokončena — potvrďte e-mail.';

  @override
  String get authGateSignOutRetry => 'Odhlásit se a zkusit znovu';

  @override
  String get statusRequestNew => 'Nová';

  @override
  String get statusRequestScheduled => 'Domluven čas';

  @override
  String get statusRequestDone => 'Hotovo';

  @override
  String get statusRequestCancelled => 'Zrušeno';

  @override
  String get statusEquipmentActive => 'Funguje';

  @override
  String get statusEquipmentInRepair => 'V opravě';

  @override
  String get statusEquipmentDecommissioned => 'Vyřazeno';

  @override
  String get adminHomeActiveTab => 'Aktivní zakázky';

  @override
  String get adminHomeDoneTab => 'Dokončené zakázky';

  @override
  String get adminHomeClientsTab => 'Klienti';

  @override
  String get signOutTooltip => 'Odhlásit se';

  @override
  String get navActive => 'Aktivní';

  @override
  String get navDone => 'Dokončené';

  @override
  String requestsLoadError(String error) {
    return 'Nepodařilo se načíst zakázky: $error';
  }

  @override
  String get noActiveRequests => 'Zatím žádné aktivní zakázky';

  @override
  String get noDoneRequests => 'Zatím žádné dokončené zakázky';

  @override
  String get mapsOpenError => 'Nepodařilo se otevřít mapy';

  @override
  String get callError => 'Nepodařilo se zahájit hovor';

  @override
  String visitLabel(String time) {
    return 'Návštěva: $time';
  }

  @override
  String establishmentsLoadError(String error) {
    return 'Nepodařilo se načíst podniky: $error';
  }

  @override
  String get noEstablishments => 'Zatím žádné podniky';

  @override
  String get requestFallbackTitle => 'Zakázka';

  @override
  String requestDetailTitle(String id) {
    return 'Zakázka #$id';
  }

  @override
  String get chatWithClient => 'Chat s klientem';

  @override
  String get clientLabel => 'Klient';

  @override
  String get equipmentLabel => 'Vybavení';

  @override
  String get notSpecified => 'Neuvedeno';

  @override
  String get descriptionLabel => 'Popis';

  @override
  String get assignTimeButton => 'Naplánovat čas';

  @override
  String changeTimeButton(String time) {
    return 'Změnit čas ($time)';
  }

  @override
  String get technicianCommentTitle => 'Poznámka technika';

  @override
  String get technicianCommentHint => 'Co bylo uděláno, co bylo vyměněno...';

  @override
  String get saveCommentButton => 'Uložit poznámku';

  @override
  String get markDoneButton => 'Označit jako dokončeno';

  @override
  String get cancelRequestButton => 'Zrušit zakázku';

  @override
  String get cancelRequestDialogTitle => 'Zrušit zakázku?';

  @override
  String get cancelRequestDialogContent =>
      'Tuto akci bude možné vrátit zpět jen ručně v databázi.';

  @override
  String get cancelRequestDialogDismiss => 'Nerušit';

  @override
  String get saveChangesError => 'Nepodařilo se uložit změny';

  @override
  String get chatWithTechnician => 'Chat s technikem';

  @override
  String get technicianName => 'Technik';

  @override
  String get visitTimeLabel => 'Čas návštěvy';

  @override
  String get chatSendError => 'Nepodařilo se odeslat zprávu';

  @override
  String chatTitle(String title) {
    return 'Chat · $title';
  }

  @override
  String chatLoadError(String error) {
    return 'Nepodařilo se načíst chat: $error';
  }

  @override
  String get chatEmpty => 'Zatím žádné zprávy — napište první';

  @override
  String get chatMessageHint => 'Zpráva...';

  @override
  String get addEquipmentTooltip => 'Přidat vybavení';

  @override
  String get entranceSectionTitle => 'Vstup';

  @override
  String get photoSaveError => 'Nepodařilo se uložit fotku';

  @override
  String get photoDeleteError => 'Nepodařilo se smazat fotku';

  @override
  String get addEntrancePhotoLabel => 'Přidat fotku vstupu';

  @override
  String equipmentLoadError(String error) {
    return 'Nepodařilo se načíst vybavení: $error';
  }

  @override
  String get noEquipmentYet => 'Zatím nebylo přidáno žádné vybavení';

  @override
  String get equipmentFormEditTitle => 'Upravit vybavení';

  @override
  String get equipmentFormNewTitle => 'Nové vybavení';

  @override
  String get equipmentTypeSectionTitle => 'Typ vybavení';

  @override
  String get equipmentTypeOther => 'Jiné';

  @override
  String get equipmentTypeRequired => 'Vyberte typ vybavení';

  @override
  String get equipmentTypeCustomLabel => 'Uveďte typ vybavení';

  @override
  String get equipmentTypeCustomRequired => 'Zadejte typ vybavení';

  @override
  String get modelLabel => 'Model';

  @override
  String get stickerPhotoSectionTitle => 'Fotka štítku';

  @override
  String get stickerPhotoHint =>
      'Vyfoťte štítek na vybavení — kód zadávat nemusíte.';

  @override
  String get equipmentPhotosSectionTitle => 'Fotky vybavení';

  @override
  String get statusDropdownLabel => 'Stav';

  @override
  String get installedAtNotSet => 'Datum instalace neuvedeno';

  @override
  String installedAtSet(String date) {
    return 'Instalováno: $date';
  }

  @override
  String get saveButton => 'Uložit';

  @override
  String equipmentSaveError(String error) {
    return 'Nepodařilo se uložit vybavení: $error';
  }

  @override
  String get cameraOption => 'Fotoaparát';

  @override
  String get galleryOption => 'Galerie';

  @override
  String get languageSwitcherTooltip => 'Jazyk';

  @override
  String get systemLanguageOption => 'Jako v systému';

  @override
  String get equipmentTypeFridge => 'Lednice';

  @override
  String get equipmentTypeFreezer => 'Mraznička';

  @override
  String get equipmentTypeCombiOven => 'Konvektomat';

  @override
  String get equipmentTypeStove => 'Sporák';

  @override
  String get equipmentTypeDishwasher => 'Myčka nádobí';

  @override
  String get equipmentTypeGrill => 'Gril';

  @override
  String get equipmentTypeCoffeeMachine => 'Kávovar';

  @override
  String get equipmentTypeMixer => 'Mixér / tyčový mixér';

  @override
  String get equipmentTypeCuttingTable => 'Krájecí stůl';

  @override
  String get clientEquipmentTab => 'Moje vybavení';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profilePersonalDataTitle => 'Osobní údaje';

  @override
  String get profileSaved => 'Údaje uloženy';

  @override
  String get profileSaveError => 'Nepodařilo se uložit údaje';

  @override
  String get profileEmailSectionTitle => 'E-mail';

  @override
  String get profileEmailHint =>
      'Po změně e-mailu může být potřeba potvrzení odkazem z dopisu.';

  @override
  String get profileChangeEmailButton => 'Změnit e-mail';

  @override
  String get emailChangeRequested =>
      'Žádost odeslána. Zkontrolujte poštu, pokud je potřeba potvrzení.';

  @override
  String get emailChangeError => 'Nepodařilo se změnit e-mail';

  @override
  String get profilePasswordSectionTitle => 'Heslo';

  @override
  String get profileNewPasswordLabel => 'Nové heslo';

  @override
  String get profileChangePasswordButton => 'Změnit heslo';

  @override
  String get passwordChanged => 'Heslo bylo změněno';

  @override
  String get passwordChangeError => 'Nepodařilo se změnit heslo';

  @override
  String get clientCreateRequestButton => 'Vytvořit žádost o opravu';

  @override
  String get createRequestTitle => 'Nová žádost';

  @override
  String get createRequestTypeSectionTitle => 'Typ vybavení';

  @override
  String get createRequestEquipmentSectionTitle => 'Vybavení';

  @override
  String get createRequestEquipmentRequired => 'Vyberte vybavení';

  @override
  String get createRequestDescriptionSectionTitle => 'Popište problém';

  @override
  String get createRequestDescriptionHint => 'Stručně popište, co se stalo';

  @override
  String get createRequestDescriptionRequired => 'Přidejte popis problému';

  @override
  String get createRequestSubmitButton => 'Odeslat žádost';

  @override
  String createRequestError(String error) {
    return 'Nepodařilo se vytvořit žádost: $error';
  }
}
