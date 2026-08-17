// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailInvalid => 'Enter a valid email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordTooShort => 'At least 6 characters';

  @override
  String get loginSubmitButton => 'Sign in';

  @override
  String get loginNoAccount => 'Don\'t have an account? Sign up';

  @override
  String get loginGenericError =>
      'Couldn\'t sign in. Check your internet connection.';

  @override
  String get registerTitle => 'Registration';

  @override
  String get registerEstablishmentSectionTitle =>
      'Registering your establishment';

  @override
  String get registerFullNameLabel => 'Name';

  @override
  String get registerFullNameRequired => 'Enter your name';

  @override
  String get registerPhoneLabel => 'Phone';

  @override
  String get registerPhoneRequired => 'Enter your phone number';

  @override
  String get registerYourEstablishmentTitle => 'Your establishment';

  @override
  String get registerIcoLabel => 'IČO';

  @override
  String get registerIcoHint => '8 digits';

  @override
  String get registerIcoInvalid => 'Enter a valid IČO (8 digits)';

  @override
  String get registerEstablishmentNameLabel => 'Establishment name';

  @override
  String get registerEstablishmentNameHint =>
      'Auto-filled from ARES, or enter manually';

  @override
  String get registerEstablishmentNameRequired =>
      'Enter the establishment name';

  @override
  String get registerAddressLabel => 'Address';

  @override
  String get registerAddressRequired => 'Enter the establishment\'s address';

  @override
  String get registerSubmitButton => 'Sign up';

  @override
  String get registerIcoNotFoundInAres =>
      'We couldn\'t find this organization in ARES — fill in the name and address manually.';

  @override
  String get registerIcoFoundInAres => 'Details pulled in from ARES.';

  @override
  String get registerEmailConfirmationNeeded =>
      'Registration almost done! Confirm your email via the link we sent you, then sign in.';

  @override
  String get registerGenericError =>
      'Couldn\'t sign up. Check the details you entered and your internet connection.';

  @override
  String get registerIcoAlreadyRegistered =>
      'An establishment with this IČO is already registered. Contact the service company\'s administrator.';

  @override
  String get registerEmailAlreadyRegistered =>
      'A user with this email is already registered.';

  @override
  String get authGateProfileNotFound =>
      'Couldn\'t find a user profile.\nRegistration may not be finished yet — confirm your email.';

  @override
  String get authGateSignOutRetry => 'Sign out and try again';

  @override
  String get statusRequestNew => 'New';

  @override
  String get statusRequestScheduled => 'Time scheduled';

  @override
  String get statusRequestDone => 'Done';

  @override
  String get statusRequestCancelled => 'Cancelled';

  @override
  String get statusEquipmentActive => 'Working';

  @override
  String get statusEquipmentInRepair => 'Being repaired';

  @override
  String get statusEquipmentDecommissioned => 'Decommissioned';

  @override
  String get adminHomeActiveTab => 'Active requests';

  @override
  String get adminHomeDoneTab => 'Completed requests';

  @override
  String get adminHomeClientsTab => 'Clients';

  @override
  String get signOutTooltip => 'Sign out';

  @override
  String get navActive => 'Active';

  @override
  String get navDone => 'Done';

  @override
  String requestsLoadError(String error) {
    return 'Couldn\'t load requests: $error';
  }

  @override
  String get noActiveRequests => 'No active requests yet';

  @override
  String get noDoneRequests => 'No completed requests yet';

  @override
  String get mapsOpenError => 'Couldn\'t open maps';

  @override
  String get callError => 'Couldn\'t start the call';

  @override
  String visitLabel(String time) {
    return 'Visit: $time';
  }

  @override
  String establishmentsLoadError(String error) {
    return 'Couldn\'t load establishments: $error';
  }

  @override
  String get noEstablishments => 'No establishments yet';

  @override
  String get requestFallbackTitle => 'Request';

  @override
  String requestDetailTitle(String id) {
    return 'Request #$id';
  }

  @override
  String get chatWithClient => 'Chat with client';

  @override
  String get clientLabel => 'Client';

  @override
  String get equipmentLabel => 'Equipment';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get assignTimeButton => 'Schedule a time';

  @override
  String changeTimeButton(String time) {
    return 'Change time ($time)';
  }

  @override
  String get technicianCommentTitle => 'Technician\'s note';

  @override
  String get technicianCommentHint => 'What was done, what was replaced...';

  @override
  String get saveCommentButton => 'Save comment';

  @override
  String get markDoneButton => 'Mark as done';

  @override
  String get cancelRequestButton => 'Cancel request';

  @override
  String get cancelRequestDialogTitle => 'Cancel request?';

  @override
  String get cancelRequestDialogContent =>
      'This action can only be undone manually in the database.';

  @override
  String get cancelRequestDialogDismiss => 'Don\'t cancel';

  @override
  String get saveChangesError => 'Couldn\'t save changes';

  @override
  String get chatWithTechnician => 'Chat with technician';

  @override
  String get technicianName => 'Technician';

  @override
  String get visitTimeLabel => 'Visit time';

  @override
  String get chatSendError => 'Couldn\'t send the message';

  @override
  String chatTitle(String title) {
    return 'Chat · $title';
  }

  @override
  String chatLoadError(String error) {
    return 'Couldn\'t load the chat: $error';
  }

  @override
  String get chatEmpty => 'No messages yet — be the first to write';

  @override
  String get chatMessageHint => 'Message...';

  @override
  String get addEquipmentTooltip => 'Add equipment';

  @override
  String get entranceSectionTitle => 'Entrance';

  @override
  String get photoSaveError => 'Couldn\'t save the photo';

  @override
  String get photoDeleteError => 'Couldn\'t delete the photo';

  @override
  String get addEntrancePhotoLabel => 'Add an entrance photo';

  @override
  String equipmentLoadError(String error) {
    return 'Couldn\'t load equipment: $error';
  }

  @override
  String get noEquipmentYet => 'No equipment added yet';

  @override
  String get equipmentFormEditTitle => 'Edit equipment';

  @override
  String get equipmentFormNewTitle => 'New equipment';

  @override
  String get equipmentTypeSectionTitle => 'Equipment type';

  @override
  String get equipmentTypeOther => 'Other';

  @override
  String get equipmentTypeRequired => 'Choose an equipment type';

  @override
  String get equipmentTypeCustomLabel => 'Specify the equipment type';

  @override
  String get equipmentTypeCustomRequired => 'Enter the equipment type';

  @override
  String get modelLabel => 'Model';

  @override
  String get stickerPhotoSectionTitle => 'Sticker photo';

  @override
  String get stickerPhotoHint =>
      'Photograph the sticker on the equipment — no need to type in the code.';

  @override
  String get equipmentPhotosSectionTitle => 'Equipment photos';

  @override
  String get statusDropdownLabel => 'Status';

  @override
  String get installedAtNotSet => 'Installation date not set';

  @override
  String installedAtSet(String date) {
    return 'Installed: $date';
  }

  @override
  String get saveButton => 'Save';

  @override
  String equipmentSaveError(String error) {
    return 'Couldn\'t save the equipment: $error';
  }

  @override
  String get cameraOption => 'Camera';

  @override
  String get galleryOption => 'Gallery';

  @override
  String get languageSwitcherTooltip => 'Language';

  @override
  String get systemLanguageOption => 'System language';

  @override
  String get equipmentTypeFridge => 'Fridge';

  @override
  String get equipmentTypeFreezer => 'Freezer';

  @override
  String get equipmentTypeCombiOven => 'Combi oven';

  @override
  String get equipmentTypeStove => 'Stove';

  @override
  String get equipmentTypeDishwasher => 'Dishwasher';

  @override
  String get equipmentTypeGrill => 'Grill';

  @override
  String get equipmentTypeCoffeeMachine => 'Coffee machine';

  @override
  String get equipmentTypeMixer => 'Mixer/blender';

  @override
  String get equipmentTypeCuttingTable => 'Cutting table';

  @override
  String get clientEquipmentTab => 'My equipment';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profilePersonalDataTitle => 'Personal details';

  @override
  String get profileSaved => 'Details saved';

  @override
  String get profileSaveError => 'Couldn\'t save the details';

  @override
  String get profileEmailSectionTitle => 'Email';

  @override
  String get profileEmailHint =>
      'After changing your email, you may need to confirm it via the link we send.';

  @override
  String get profileChangeEmailButton => 'Change email';

  @override
  String get emailChangeRequested =>
      'Request sent. Check your inbox if confirmation is needed.';

  @override
  String get emailChangeError => 'Couldn\'t change the email';

  @override
  String get profilePasswordSectionTitle => 'Password';

  @override
  String get profileNewPasswordLabel => 'New password';

  @override
  String get profileChangePasswordButton => 'Change password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get passwordChangeError => 'Couldn\'t change the password';

  @override
  String get clientCreateRequestButton => 'Create repair request';

  @override
  String get createRequestTitle => 'New request';

  @override
  String get createRequestTypeSectionTitle => 'Equipment type';

  @override
  String get createRequestEquipmentSectionTitle => 'Equipment';

  @override
  String get createRequestEquipmentRequired => 'Select equipment';

  @override
  String get createRequestDescriptionSectionTitle => 'Describe the problem';

  @override
  String get createRequestDescriptionHint => 'Briefly describe what happened';

  @override
  String get createRequestDescriptionRequired => 'Add a problem description';

  @override
  String get createRequestSubmitButton => 'Submit request';

  @override
  String createRequestError(String error) {
    return 'Failed to create request: $error';
  }

  @override
  String get establishmentSwitcherTooltip => 'Switch establishment';

  @override
  String get establishmentSwitcherAddNew => 'Add establishment';

  @override
  String get addEstablishmentTitle => 'New establishment';

  @override
  String get addEstablishmentPhoneLabel => 'Establishment contact phone';

  @override
  String get addEstablishmentPhoneRequired => 'Enter a contact phone number';

  @override
  String get addEstablishmentSubmitButton => 'Add';

  @override
  String get addEstablishmentGenericError =>
      'Failed to add the establishment. Check the details and your internet connection.';

  @override
  String get markDoneDialogTitle => 'Close request';

  @override
  String get markDoneRepairCostLabel => 'Repair cost';

  @override
  String get markDonePartsCostLabel => 'Parts cost';

  @override
  String get markDoneCostRequired => 'Enter an amount';

  @override
  String get markDoneCostInvalid => 'Enter a valid amount';

  @override
  String get markDoneDialogCancel => 'Cancel';

  @override
  String get markDoneDialogConfirm => 'Close request';

  @override
  String get requestCostRepairLabel => 'Repair';

  @override
  String get requestCostPartsLabel => 'Parts';

  @override
  String get adminHomeStatsTab => 'Statistics';

  @override
  String get statsPeriodWeek => 'Week';

  @override
  String get statsPeriodMonth => 'Month';

  @override
  String get statsPeriodYear => 'Year';

  @override
  String get statsPeriodCustom => 'Custom period';

  @override
  String get statsClosedCount => 'Closed requests';

  @override
  String get statsRevenue => 'Revenue';

  @override
  String get statsExpenses => 'Expenses';

  @override
  String get statsProfit => 'Profit';

  @override
  String statsLoadError(String error) {
    return 'Failed to load statistics: $error';
  }
}
