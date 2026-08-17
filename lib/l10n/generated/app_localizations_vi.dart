// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailInvalid => 'Nhập email hợp lệ';

  @override
  String get loginPasswordLabel => 'Mật khẩu';

  @override
  String get loginPasswordTooShort => 'Tối thiểu 6 ký tự';

  @override
  String get loginSubmitButton => 'Đăng nhập';

  @override
  String get loginNoAccount => 'Chưa có tài khoản? Đăng ký';

  @override
  String get loginGenericError =>
      'Không thể đăng nhập. Kiểm tra kết nối internet.';

  @override
  String get registerTitle => 'Đăng ký';

  @override
  String get registerEstablishmentSectionTitle => 'Đăng ký cơ sở';

  @override
  String get registerFullNameLabel => 'Họ tên';

  @override
  String get registerFullNameRequired => 'Nhập họ tên';

  @override
  String get registerPhoneLabel => 'Số điện thoại';

  @override
  String get registerPhoneRequired => 'Nhập số điện thoại';

  @override
  String get registerYourEstablishmentTitle => 'Cơ sở của bạn';

  @override
  String get registerIcoLabel => 'IČO';

  @override
  String get registerIcoHint => '8 chữ số';

  @override
  String get registerIcoInvalid => 'Nhập IČO hợp lệ (8 chữ số)';

  @override
  String get registerEstablishmentNameLabel => 'Tên cơ sở';

  @override
  String get registerEstablishmentNameHint =>
      'Tự động điền từ ARES hoặc nhập thủ công';

  @override
  String get registerEstablishmentNameRequired => 'Nhập tên cơ sở';

  @override
  String get registerAddressLabel => 'Địa chỉ';

  @override
  String get registerAddressRequired => 'Nhập địa chỉ cơ sở';

  @override
  String get registerSubmitButton => 'Đăng ký';

  @override
  String get registerIcoNotFoundInAres =>
      'Không tìm thấy tổ chức trong ARES — vui lòng nhập tên và địa chỉ thủ công.';

  @override
  String get registerIcoFoundInAres => 'Đã lấy dữ liệu từ ARES.';

  @override
  String get registerEmailConfirmationNeeded =>
      'Đăng ký gần hoàn tất! Xác nhận email qua liên kết trong thư, sau đó đăng nhập.';

  @override
  String get registerGenericError =>
      'Không thể đăng ký. Kiểm tra thông tin đã nhập và kết nối internet.';

  @override
  String get registerIcoAlreadyRegistered =>
      'Cơ sở có IČO này đã được đăng ký trong hệ thống. Vui lòng liên hệ quản trị viên công ty dịch vụ.';

  @override
  String get registerEmailAlreadyRegistered =>
      'Người dùng với email này đã được đăng ký.';

  @override
  String get authGateProfileNotFound =>
      'Không tìm thấy hồ sơ người dùng.\nCó vẻ đăng ký chưa hoàn tất — hãy xác nhận email.';

  @override
  String get authGateSignOutRetry => 'Đăng xuất và thử lại';

  @override
  String get statusRequestNew => 'Mới';

  @override
  String get statusRequestScheduled => 'Đã hẹn thời gian';

  @override
  String get statusRequestDone => 'Đã hoàn thành';

  @override
  String get statusRequestCancelled => 'Đã hủy';

  @override
  String get statusEquipmentActive => 'Đang hoạt động';

  @override
  String get statusEquipmentInRepair => 'Đang sửa chữa';

  @override
  String get statusEquipmentDecommissioned => 'Đã ngừng sử dụng';

  @override
  String get adminHomeActiveTab => 'Yêu cầu đang xử lý';

  @override
  String get adminHomeDoneTab => 'Yêu cầu đã hoàn thành';

  @override
  String get adminHomeClientsTab => 'Khách hàng';

  @override
  String get signOutTooltip => 'Đăng xuất';

  @override
  String get navActive => 'Đang xử lý';

  @override
  String get navDone => 'Đã hoàn thành';

  @override
  String requestsLoadError(String error) {
    return 'Không thể tải yêu cầu: $error';
  }

  @override
  String get noActiveRequests => 'Chưa có yêu cầu đang xử lý';

  @override
  String get noDoneRequests => 'Chưa có yêu cầu đã hoàn thành';

  @override
  String get mapsOpenError => 'Không thể mở bản đồ';

  @override
  String get callError => 'Không thể bắt đầu cuộc gọi';

  @override
  String visitLabel(String time) {
    return 'Thăm khám: $time';
  }

  @override
  String establishmentsLoadError(String error) {
    return 'Không thể tải danh sách cơ sở: $error';
  }

  @override
  String get noEstablishments => 'Chưa có cơ sở nào';

  @override
  String get requestFallbackTitle => 'Yêu cầu';

  @override
  String requestDetailTitle(String id) {
    return 'Yêu cầu #$id';
  }

  @override
  String get chatWithClient => 'Trò chuyện với khách hàng';

  @override
  String get clientLabel => 'Khách hàng';

  @override
  String get equipmentLabel => 'Thiết bị';

  @override
  String get notSpecified => 'Chưa xác định';

  @override
  String get descriptionLabel => 'Mô tả';

  @override
  String get assignTimeButton => 'Đặt lịch hẹn';

  @override
  String changeTimeButton(String time) {
    return 'Đổi thời gian ($time)';
  }

  @override
  String get technicianCommentTitle => 'Ghi chú của kỹ thuật viên';

  @override
  String get technicianCommentHint => 'Đã làm gì, đã thay gì...';

  @override
  String get saveCommentButton => 'Lưu ghi chú';

  @override
  String get markDoneButton => 'Đánh dấu đã hoàn thành';

  @override
  String get cancelRequestButton => 'Hủy yêu cầu';

  @override
  String get cancelRequestDialogTitle => 'Hủy yêu cầu?';

  @override
  String get cancelRequestDialogContent =>
      'Hành động này chỉ có thể hoàn tác thủ công trong cơ sở dữ liệu.';

  @override
  String get cancelRequestDialogDismiss => 'Không hủy';

  @override
  String get saveChangesError => 'Không thể lưu thay đổi';

  @override
  String get chatWithTechnician => 'Trò chuyện với kỹ thuật viên';

  @override
  String get technicianName => 'Kỹ thuật viên';

  @override
  String get visitTimeLabel => 'Thời gian thăm khám';

  @override
  String get chatSendError => 'Không thể gửi tin nhắn';

  @override
  String chatTitle(String title) {
    return 'Trò chuyện · $title';
  }

  @override
  String chatLoadError(String error) {
    return 'Không thể tải cuộc trò chuyện: $error';
  }

  @override
  String get chatEmpty => 'Chưa có tin nhắn nào — hãy là người đầu tiên';

  @override
  String get chatMessageHint => 'Tin nhắn...';

  @override
  String get addEquipmentTooltip => 'Thêm thiết bị';

  @override
  String get entranceSectionTitle => 'Lối vào';

  @override
  String get photoSaveError => 'Không thể lưu ảnh';

  @override
  String get photoDeleteError => 'Không thể xóa ảnh';

  @override
  String get addEntrancePhotoLabel => 'Thêm ảnh lối vào';

  @override
  String equipmentLoadError(String error) {
    return 'Không thể tải thiết bị: $error';
  }

  @override
  String get noEquipmentYet => 'Chưa có thiết bị nào được thêm';

  @override
  String get equipmentFormEditTitle => 'Chỉnh sửa thiết bị';

  @override
  String get equipmentFormNewTitle => 'Thiết bị mới';

  @override
  String get equipmentTypeSectionTitle => 'Loại thiết bị';

  @override
  String get equipmentTypeOther => 'Khác';

  @override
  String get equipmentTypeRequired => 'Chọn loại thiết bị';

  @override
  String get equipmentTypeCustomLabel => 'Nhập loại thiết bị';

  @override
  String get equipmentTypeCustomRequired => 'Nhập loại thiết bị';

  @override
  String get modelLabel => 'Model';

  @override
  String get stickerPhotoSectionTitle => 'Ảnh tem nhãn';

  @override
  String get stickerPhotoHint =>
      'Chụp ảnh tem nhãn trên thiết bị — không cần nhập mã.';

  @override
  String get equipmentPhotosSectionTitle => 'Ảnh thiết bị';

  @override
  String get statusDropdownLabel => 'Trạng thái';

  @override
  String get installedAtNotSet => 'Chưa xác định ngày lắp đặt';

  @override
  String installedAtSet(String date) {
    return 'Đã lắp đặt: $date';
  }

  @override
  String get saveButton => 'Lưu';

  @override
  String equipmentSaveError(String error) {
    return 'Không thể lưu thiết bị: $error';
  }

  @override
  String get cameraOption => 'Máy ảnh';

  @override
  String get galleryOption => 'Thư viện ảnh';

  @override
  String get languageSwitcherTooltip => 'Ngôn ngữ';

  @override
  String get systemLanguageOption => 'Theo hệ thống';

  @override
  String get equipmentTypeFridge => 'Tủ lạnh';

  @override
  String get equipmentTypeFreezer => 'Tủ đông';

  @override
  String get equipmentTypeCombiOven => 'Lò hấp nướng đa năng';

  @override
  String get equipmentTypeStove => 'Bếp';

  @override
  String get equipmentTypeDishwasher => 'Máy rửa chén';

  @override
  String get equipmentTypeGrill => 'Vỉ nướng';

  @override
  String get equipmentTypeCoffeeMachine => 'Máy pha cà phê';

  @override
  String get equipmentTypeMixer => 'Máy trộn/máy xay';

  @override
  String get equipmentTypeCuttingTable => 'Bàn sơ chế';

  @override
  String get clientEquipmentTab => 'Thiết bị của tôi';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get profilePersonalDataTitle => 'Thông tin cá nhân';

  @override
  String get profileSaved => 'Đã lưu thông tin';

  @override
  String get profileSaveError => 'Không thể lưu thông tin';

  @override
  String get profileEmailSectionTitle => 'Email';

  @override
  String get profileEmailHint =>
      'Sau khi đổi email, có thể cần xác nhận qua liên kết trong thư.';

  @override
  String get profileChangeEmailButton => 'Đổi email';

  @override
  String get emailChangeRequested =>
      'Đã gửi yêu cầu. Kiểm tra hộp thư nếu cần xác nhận.';

  @override
  String get emailChangeError => 'Không thể đổi email';

  @override
  String get profilePasswordSectionTitle => 'Mật khẩu';

  @override
  String get profileNewPasswordLabel => 'Mật khẩu mới';

  @override
  String get profileChangePasswordButton => 'Đổi mật khẩu';

  @override
  String get passwordChanged => 'Đã đổi mật khẩu';

  @override
  String get passwordChangeError => 'Không thể đổi mật khẩu';

  @override
  String get clientCreateRequestButton => 'Tạo yêu cầu sửa chữa';

  @override
  String get createRequestTitle => 'Yêu cầu mới';

  @override
  String get createRequestTypeSectionTitle => 'Loại thiết bị';

  @override
  String get createRequestEquipmentSectionTitle => 'Thiết bị';

  @override
  String get createRequestEquipmentRequired => 'Chọn thiết bị';

  @override
  String get createRequestDescriptionSectionTitle => 'Mô tả sự cố';

  @override
  String get createRequestDescriptionHint => 'Mô tả ngắn gọn điều đã xảy ra';

  @override
  String get createRequestDescriptionRequired => 'Thêm mô tả sự cố';

  @override
  String get createRequestSubmitButton => 'Gửi yêu cầu';

  @override
  String createRequestError(String error) {
    return 'Không thể tạo yêu cầu: $error';
  }

  @override
  String get establishmentSwitcherTooltip => 'Chuyển cơ sở';

  @override
  String get establishmentSwitcherAddNew => 'Thêm cơ sở';

  @override
  String get addEstablishmentTitle => 'Cơ sở mới';

  @override
  String get addEstablishmentPhoneLabel => 'Số điện thoại liên hệ của cơ sở';

  @override
  String get addEstablishmentPhoneRequired => 'Nhập số điện thoại liên hệ';

  @override
  String get addEstablishmentSubmitButton => 'Thêm';

  @override
  String get addEstablishmentGenericError =>
      'Không thể thêm cơ sở. Kiểm tra thông tin đã nhập và kết nối internet.';

  @override
  String get markDoneDialogTitle => 'Đóng yêu cầu';

  @override
  String get markDoneRepairCostLabel => 'Chi phí sửa chữa';

  @override
  String get markDonePartsCostLabel => 'Chi phí phụ tùng';

  @override
  String get markDoneCostRequired => 'Nhập số tiền';

  @override
  String get markDoneCostInvalid => 'Nhập số tiền hợp lệ';

  @override
  String get markDoneDialogCancel => 'Hủy';

  @override
  String get markDoneDialogConfirm => 'Đóng yêu cầu';

  @override
  String get requestCostRepairLabel => 'Sửa chữa';

  @override
  String get requestCostPartsLabel => 'Phụ tùng';

  @override
  String get adminHomeStatsTab => 'Thống kê';

  @override
  String get statsPeriodWeek => 'Tuần';

  @override
  String get statsPeriodMonth => 'Tháng';

  @override
  String get statsPeriodYear => 'Năm';

  @override
  String get statsPeriodCustom => 'Khoảng thời gian tùy chỉnh';

  @override
  String get statsClosedCount => 'Yêu cầu đã đóng';

  @override
  String get statsRevenue => 'Doanh thu';

  @override
  String get statsExpenses => 'Chi phí';

  @override
  String get statsProfit => 'Lợi nhuận';

  @override
  String statsLoadError(String error) {
    return 'Không thể tải thống kê: $error';
  }
}
