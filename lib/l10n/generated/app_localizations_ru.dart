// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailInvalid => 'Введите корректный email';

  @override
  String get loginPasswordLabel => 'Пароль';

  @override
  String get loginPasswordTooShort => 'Минимум 6 символов';

  @override
  String get loginSubmitButton => 'Войти';

  @override
  String get loginNoAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get loginGenericError =>
      'Не удалось войти. Проверьте подключение к интернету.';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get registerEstablishmentSectionTitle => 'Регистрация заведения';

  @override
  String get registerFullNameLabel => 'Имя';

  @override
  String get registerFullNameRequired => 'Введите имя';

  @override
  String get registerPhoneLabel => 'Телефон';

  @override
  String get registerPhoneRequired => 'Введите телефон';

  @override
  String get registerYourEstablishmentTitle => 'Ваше заведение';

  @override
  String get registerIcoLabel => 'IČO';

  @override
  String get registerIcoHint => '8 цифр';

  @override
  String get registerIcoInvalid => 'Введите корректный IČO (8 цифр)';

  @override
  String get registerEstablishmentNameLabel => 'Название заведения';

  @override
  String get registerEstablishmentNameHint =>
      'Подставится из ARES или введите вручную';

  @override
  String get registerEstablishmentNameRequired => 'Введите название заведения';

  @override
  String get registerAddressLabel => 'Адрес';

  @override
  String get registerAddressRequired => 'Введите адрес заведения';

  @override
  String get registerEstablishmentPhoneLabel => 'Контактный телефон заведения';

  @override
  String get registerEstablishmentPhoneRequired => 'Введите контактный телефон';

  @override
  String get registerSubmitButton => 'Зарегистрироваться';

  @override
  String get registerIcoNotFoundInAres =>
      'Не нашли организацию в ARES — заполните название и адрес вручную.';

  @override
  String get registerIcoFoundInAres => 'Данные подтянуты из ARES.';

  @override
  String get registerEmailConfirmationNeeded =>
      'Регистрация почти завершена! Подтвердите email по ссылке из письма, а затем войдите.';

  @override
  String get registerGenericError =>
      'Не удалось зарегистрироваться. Проверьте введённые данные и подключение к интернету.';

  @override
  String get registerIcoAlreadyRegistered =>
      'Заведение с таким IČO уже зарегистрировано в системе. Обратитесь к администратору сервисной компании.';

  @override
  String get registerEmailAlreadyRegistered =>
      'Пользователь с таким email уже зарегистрирован.';

  @override
  String get authGateProfileNotFound =>
      'Не удалось найти профиль пользователя.\nПохоже, регистрация не завершена: подтвердите email.';

  @override
  String get authGateSignOutRetry => 'Выйти и попробовать снова';

  @override
  String get statusRequestNew => 'Новая';

  @override
  String get statusRequestScheduled => 'Согласовано время';

  @override
  String get statusRequestDone => 'Выполнено';

  @override
  String get statusRequestCancelled => 'Отменено';

  @override
  String get statusEquipmentActive => 'Работает';

  @override
  String get statusEquipmentInRepair => 'В ремонте';

  @override
  String get statusEquipmentDecommissioned => 'Списано';

  @override
  String get adminHomeActiveTab => 'Активные заявки';

  @override
  String get adminHomeDoneTab => 'Выполненные заявки';

  @override
  String get adminHomeClientsTab => 'Клиенты';

  @override
  String get signOutTooltip => 'Выйти';

  @override
  String get navActive => 'Активные';

  @override
  String get navDone => 'Выполненные';

  @override
  String requestsLoadError(String error) {
    return 'Не удалось загрузить заявки: $error';
  }

  @override
  String get noActiveRequests => 'Активных заявок пока нет';

  @override
  String get noDoneRequests => 'Выполненных заявок пока нет';

  @override
  String get mapsOpenError => 'Не удалось открыть карты';

  @override
  String get callError => 'Не удалось начать звонок';

  @override
  String visitLabel(String time) {
    return 'Визит: $time';
  }

  @override
  String establishmentsLoadError(String error) {
    return 'Не удалось загрузить заведения: $error';
  }

  @override
  String get noEstablishments => 'Заведений пока нет';

  @override
  String get requestFallbackTitle => 'Заявка';

  @override
  String requestDetailTitle(String id) {
    return 'Заявка #$id';
  }

  @override
  String get chatWithClient => 'Чат с клиентом';

  @override
  String get clientLabel => 'Клиент';

  @override
  String get equipmentLabel => 'Оборудование';

  @override
  String get notSpecified => 'Не указано';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get assignTimeButton => 'Назначить время';

  @override
  String changeTimeButton(String time) {
    return 'Изменить время ($time)';
  }

  @override
  String get technicianCommentTitle => 'Комментарий мастера';

  @override
  String get technicianCommentHint => 'Что сделано, что заменено...';

  @override
  String get saveCommentButton => 'Сохранить комментарий';

  @override
  String get markDoneButton => 'Отметить выполненной';

  @override
  String get cancelRequestButton => 'Отменить заявку';

  @override
  String get cancelRequestDialogTitle => 'Отменить заявку?';

  @override
  String get cancelRequestDialogContent =>
      'Это действие можно будет отменить только вручную в базе.';

  @override
  String get cancelRequestDialogDismiss => 'Не отменять';

  @override
  String get saveChangesError => 'Не удалось сохранить изменения';

  @override
  String get chatWithTechnician => 'Чат с мастером';

  @override
  String get technicianName => 'Мастер';

  @override
  String get visitTimeLabel => 'Время визита';

  @override
  String get chatSendError => 'Не удалось отправить сообщение';

  @override
  String chatTitle(String title) {
    return 'Чат · $title';
  }

  @override
  String chatLoadError(String error) {
    return 'Не удалось загрузить чат: $error';
  }

  @override
  String get chatEmpty => 'Сообщений пока нет — напишите первым';

  @override
  String get chatMessageHint => 'Сообщение...';

  @override
  String get addEquipmentTooltip => 'Добавить оборудование';

  @override
  String get entranceSectionTitle => 'Входная группа';

  @override
  String get photoSaveError => 'Не удалось сохранить фото';

  @override
  String get photoDeleteError => 'Не удалось удалить фото';

  @override
  String get addEntrancePhotoLabel => 'Добавить фото входной группы';

  @override
  String equipmentLoadError(String error) {
    return 'Не удалось загрузить оборудование: $error';
  }

  @override
  String get noEquipmentYet => 'Оборудование пока не добавлено';

  @override
  String get equipmentFormEditTitle => 'Изменить оборудование';

  @override
  String get equipmentFormNewTitle => 'Новое оборудование';

  @override
  String get equipmentTypeSectionTitle => 'Тип оборудования';

  @override
  String get equipmentTypeOther => 'Другое';

  @override
  String get equipmentTypeRequired => 'Выберите тип оборудования';

  @override
  String get equipmentTypeCustomLabel => 'Укажите тип оборудования';

  @override
  String get equipmentTypeCustomRequired => 'Введите тип оборудования';

  @override
  String get modelLabel => 'Модель';

  @override
  String get stickerPhotoSectionTitle => 'Фото стикера';

  @override
  String get stickerPhotoHint =>
      'Сфотографируйте бирку на оборудовании — код вводить не нужно.';

  @override
  String get equipmentPhotosSectionTitle => 'Фото оборудования';

  @override
  String get statusDropdownLabel => 'Статус';

  @override
  String get installedAtNotSet => 'Дата установки не указана';

  @override
  String installedAtSet(String date) {
    return 'Установлено: $date';
  }

  @override
  String get saveButton => 'Сохранить';

  @override
  String equipmentSaveError(String error) {
    return 'Не удалось сохранить оборудование: $error';
  }

  @override
  String get cameraOption => 'Камера';

  @override
  String get galleryOption => 'Галерея';

  @override
  String get languageSwitcherTooltip => 'Язык';

  @override
  String get systemLanguageOption => 'Как в системе';

  @override
  String get equipmentTypeFridge => 'Холодильник';

  @override
  String get equipmentTypeFreezer => 'Морозильная камера';

  @override
  String get equipmentTypeCombiOven => 'Пароконвектомат';

  @override
  String get equipmentTypeStove => 'Плита';

  @override
  String get equipmentTypeDishwasher => 'Посудомоечная машина';

  @override
  String get equipmentTypeGrill => 'Гриль';

  @override
  String get equipmentTypeCoffeeMachine => 'Кофемашина';

  @override
  String get equipmentTypeMixer => 'Миксер/блендер';

  @override
  String get equipmentTypeCuttingTable => 'Разделочный стол';

  @override
  String get clientEquipmentTab => 'Моё оборудование';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profilePersonalDataTitle => 'Личные данные';

  @override
  String get profileSaved => 'Данные сохранены';

  @override
  String get profileSaveError => 'Не удалось сохранить данные';

  @override
  String get profileEmailSectionTitle => 'Email';

  @override
  String get profileEmailHint =>
      'После смены email может понадобиться подтверждение по ссылке из письма.';

  @override
  String get profileChangeEmailButton => 'Изменить email';

  @override
  String get emailChangeRequested =>
      'Запрос отправлен. Проверьте почту, если потребуется подтверждение.';

  @override
  String get emailChangeError => 'Не удалось изменить email';

  @override
  String get profilePasswordSectionTitle => 'Пароль';

  @override
  String get profileNewPasswordLabel => 'Новый пароль';

  @override
  String get profileChangePasswordButton => 'Изменить пароль';

  @override
  String get passwordChanged => 'Пароль изменён';

  @override
  String get passwordChangeError => 'Не удалось изменить пароль';

  @override
  String get clientCreateRequestButton => 'Создать заявку на ремонт';

  @override
  String get createRequestTitle => 'Новая заявка';

  @override
  String get createRequestTypeSectionTitle => 'Вид техники';

  @override
  String get createRequestEquipmentSectionTitle => 'Оборудование';

  @override
  String get createRequestEquipmentRequired => 'Выберите оборудование';

  @override
  String get createRequestDescriptionSectionTitle => 'Опишите проблему';

  @override
  String get createRequestDescriptionHint => 'Кратко расскажите, что случилось';

  @override
  String get createRequestDescriptionRequired => 'Добавьте описание проблемы';

  @override
  String get createRequestSubmitButton => 'Отправить заявку';

  @override
  String createRequestError(String error) {
    return 'Не удалось создать заявку: $error';
  }
}
