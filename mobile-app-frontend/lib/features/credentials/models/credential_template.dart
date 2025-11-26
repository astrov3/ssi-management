import 'package:flutter/material.dart';

/// Credential field types
enum CredentialFieldType {
  text,
  number,
  date,
  email,
  phone,
  address,
  file,
  dropdown,
  textarea,
}

/// Credential field definition
class CredentialField {
  final String key;
  final String label;
  final CredentialFieldType type;
  final bool required;
  final String? hint;
  final String? placeholder;
  final List<String>? options; // For dropdown type
  final String? validationRegex;
  final String? validationMessage;

  const CredentialField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.hint,
    this.placeholder,
    this.options,
    this.validationRegex,
    this.validationMessage,
  });
}

/// Credential type definition
class CredentialTemplate {
  final String id;
  final String name;
  final String description;
  final String vcType;
  final IconData icon;
  final List<CredentialField> fields;

  const CredentialTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.vcType,
    required this.icon,
    required this.fields,
  });
}

/// Predefined credential templates
class CredentialTemplates {
  static const List<CredentialTemplate> templates = [
    // Identity Credentials
    identityCard,
    passport,
    driverLicense,
    
    // Educational Credentials
    universityDegree,
    highSchoolDiploma,
    professionalCertificate,
    trainingCertificate,
    
    // Employment Credentials
    employmentCertificate,
    workPermit,
    
    // Health Credentials
    healthInsurance,
    vaccinationCertificate,
    
    // Other
    membershipCard,
    genericCredential,
  ];

  // Identity Credentials
  static const identityCard = CredentialTemplate(
    id: 'identity_card',
    name: 'Căn Cước Công Dân (CCCD)',
    description: 'Chứng minh nhân dân/Căn cước công dân',
    vcType: 'IdentityCredential',
    icon: Icons.credit_card,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'idNumber',
        label: 'Số CCCD/CMND',
        type: CredentialFieldType.text,
        required: true,
        placeholder: '001234567890',
        validationRegex: r'^\d{9,12}$',
        validationMessage: 'Số CCCD/CMND phải từ 9-12 chữ số',
      ),
      CredentialField(
        key: 'dateOfBirth',
        label: 'Ngày sinh',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'gender',
        label: 'Giới tính',
        type: CredentialFieldType.dropdown,
        required: true,
        options: ['Nam', 'Nữ', 'Khác'],
      ),
      CredentialField(
        key: 'nationality',
        label: 'Quốc tịch',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Việt Nam',
      ),
      CredentialField(
        key: 'address',
        label: 'Địa chỉ thường trú',
        type: CredentialFieldType.textarea,
        required: true,
        placeholder: 'Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành phố',
      ),
      CredentialField(
        key: 'issuedDate',
        label: 'Ngày cấp',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'issuedPlace',
        label: 'Nơi cấp',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Công an tỉnh/thành phố...',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên ảnh CCCD/CMND',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file CCCD/CMND',
      ),
    ],
  );

  static const passport = CredentialTemplate(
    id: 'passport',
    name: 'Hộ Chiếu',
    description: 'Hộ chiếu quốc tế',
    vcType: 'PassportCredential',
    icon: Icons.article,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'passportNumber',
        label: 'Số hộ chiếu',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'A12345678',
      ),
      CredentialField(
        key: 'dateOfBirth',
        label: 'Ngày sinh',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'gender',
        label: 'Giới tính',
        type: CredentialFieldType.dropdown,
        required: true,
        options: ['Nam', 'Nữ', 'Khác'],
      ),
      CredentialField(
        key: 'nationality',
        label: 'Quốc tịch',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Việt Nam',
      ),
      CredentialField(
        key: 'issuedDate',
        label: 'Ngày cấp',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'expiryDate',
        label: 'Ngày hết hạn',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'issuedPlace',
        label: 'Nơi cấp',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Cục Quản lý xuất nhập cảnh...',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên ảnh hộ chiếu',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file hộ chiếu',
      ),
    ],
  );

  static const driverLicense = CredentialTemplate(
    id: 'driver_license',
    name: 'Bằng Lái Xe',
    description: 'Giấy phép lái xe',
    vcType: 'DriverLicenseCredential',
    icon: Icons.drive_eta,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'licenseNumber',
        label: 'Số bằng lái',
        type: CredentialFieldType.text,
        required: true,
        placeholder: '123456789012',
      ),
      CredentialField(
        key: 'licenseClass',
        label: 'Hạng bằng',
        type: CredentialFieldType.dropdown,
        required: true,
        options: ['A1', 'A2', 'A3', 'A4', 'B1', 'B2', 'C', 'D', 'E', 'F'],
      ),
      CredentialField(
        key: 'dateOfBirth',
        label: 'Ngày sinh',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'address',
        label: 'Địa chỉ',
        type: CredentialFieldType.textarea,
        required: true,
      ),
      CredentialField(
        key: 'issuedDate',
        label: 'Ngày cấp',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'expiryDate',
        label: 'Ngày hết hạn',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'issuedPlace',
        label: 'Nơi cấp',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Sở Giao thông Vận tải...',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên ảnh bằng lái',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file bằng lái xe',
      ),
    ],
  );

  // Educational Credentials
  static const universityDegree = CredentialTemplate(
    id: 'university_degree',
    name: 'Bằng Đại Học',
    description: 'Bằng cử nhân, thạc sĩ, tiến sĩ',
    vcType: 'EducationalCredential',
    icon: Icons.school,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'degreeType',
        label: 'Loại bằng',
        type: CredentialFieldType.dropdown,
        required: true,
        options: ['Cử nhân', 'Thạc sĩ', 'Tiến sĩ', 'Kỹ sư'],
      ),
      CredentialField(
        key: 'major',
        label: 'Chuyên ngành',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Công nghệ thông tin',
      ),
      CredentialField(
        key: 'university',
        label: 'Trường đại học',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Đại học Bách Khoa',
      ),
      CredentialField(
        key: 'graduationDate',
        label: 'Ngày tốt nghiệp',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'gpa',
        label: 'Điểm trung bình',
        type: CredentialFieldType.number,
        placeholder: '3.5',
      ),
      CredentialField(
        key: 'degreeNumber',
        label: 'Số hiệu bằng',
        type: CredentialFieldType.text,
        placeholder: 'BS-2024-001234',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên bằng cấp',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file bằng cấp',
      ),
    ],
  );

  static const highSchoolDiploma = CredentialTemplate(
    id: 'high_school_diploma',
    name: 'Bằng Tốt Nghiệp THPT',
    description: 'Bằng tốt nghiệp trung học phổ thông',
    vcType: 'EducationalCredential',
    icon: Icons.menu_book,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'school',
        label: 'Trường THPT',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'THPT Nguyễn Du',
      ),
      CredentialField(
        key: 'graduationDate',
        label: 'Ngày tốt nghiệp',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'diplomaNumber',
        label: 'Số hiệu bằng',
        type: CredentialFieldType.text,
        placeholder: 'THPT-2024-001234',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên bằng tốt nghiệp',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file bằng tốt nghiệp',
      ),
    ],
  );

  static const professionalCertificate = CredentialTemplate(
    id: 'professional_certificate',
    name: 'Chứng Chỉ Nghề Nghiệp',
    description: 'Chứng chỉ chuyên nghiệp, chứng nhận kỹ năng',
    vcType: 'ProfessionalCredential',
    icon: Icons.workspace_premium,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'certificateName',
        label: 'Tên chứng chỉ',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Chứng chỉ AWS Solutions Architect',
      ),
      CredentialField(
        key: 'issuingOrganization',
        label: 'Tổ chức cấp',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Amazon Web Services',
      ),
      CredentialField(
        key: 'issuedDate',
        label: 'Ngày cấp',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'expiryDate',
        label: 'Ngày hết hạn',
        type: CredentialFieldType.date,
      ),
      CredentialField(
        key: 'certificateNumber',
        label: 'Số chứng chỉ',
        type: CredentialFieldType.text,
        placeholder: 'AWS-2024-001234',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên chứng chỉ',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file chứng chỉ',
      ),
    ],
  );

  static const trainingCertificate = CredentialTemplate(
    id: 'training_certificate',
    name: 'Chứng Chỉ Đào Tạo',
    description: 'Chứng chỉ khóa học, đào tạo',
    vcType: 'TrainingCredential',
    icon: Icons.book,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'courseName',
        label: 'Tên khóa học',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Khóa học Flutter Development',
      ),
      CredentialField(
        key: 'trainingOrganization',
        label: 'Tổ chức đào tạo',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Tech Academy',
      ),
      CredentialField(
        key: 'completionDate',
        label: 'Ngày hoàn thành',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'duration',
        label: 'Thời lượng (giờ)',
        type: CredentialFieldType.number,
        placeholder: '40',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên chứng chỉ',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file chứng chỉ',
      ),
    ],
  );

  // Employment Credentials
  static const employmentCertificate = CredentialTemplate(
    id: 'employment_certificate',
    name: 'Giấy Chứng Nhận Công Tác',
    description: 'Giấy xác nhận làm việc, hợp đồng lao động',
    vcType: 'EmploymentCredential',
    icon: Icons.business_center,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'company',
        label: 'Tên công ty',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Công ty ABC',
      ),
      CredentialField(
        key: 'position',
        label: 'Chức vụ',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Software Engineer',
      ),
      CredentialField(
        key: 'startDate',
        label: 'Ngày bắt đầu',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'endDate',
        label: 'Ngày kết thúc',
        type: CredentialFieldType.date,
      ),
      CredentialField(
        key: 'employeeId',
        label: 'Mã nhân viên',
        type: CredentialFieldType.text,
        placeholder: 'EMP-001234',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên giấy chứng nhận',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file chứng nhận công tác',
      ),
    ],
  );

  static const workPermit = CredentialTemplate(
    id: 'work_permit',
    name: 'Giấy Phép Lao Động',
    description: 'Giấy phép làm việc cho người nước ngoài',
    vcType: 'WorkPermitCredential',
    icon: Icons.work,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'permitNumber',
        label: 'Số giấy phép',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'WP-2024-001234',
      ),
      CredentialField(
        key: 'issuedDate',
        label: 'Ngày cấp',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'expiryDate',
        label: 'Ngày hết hạn',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'issuedPlace',
        label: 'Nơi cấp',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Sở Lao động Thương binh và Xã hội...',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên giấy phép',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file giấy phép lao động',
      ),
    ],
  );

  // Health Credentials
  static const healthInsurance = CredentialTemplate(
    id: 'health_insurance',
    name: 'Bảo Hiểm Y Tế',
    description: 'Thẻ bảo hiểm y tế',
    vcType: 'HealthInsuranceCredential',
    icon: Icons.medical_services,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'insuranceNumber',
        label: 'Số thẻ BHYT',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'BH1234567890123',
      ),
      CredentialField(
        key: 'dateOfBirth',
        label: 'Ngày sinh',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'validFrom',
        label: 'Có hiệu lực từ',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'validTo',
        label: 'Có hiệu lực đến',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên thẻ BHYT',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file thẻ bảo hiểm y tế',
      ),
    ],
  );

  static const vaccinationCertificate = CredentialTemplate(
    id: 'vaccination_certificate',
    name: 'Giấy Chứng Nhận Tiêm Chủng',
    description: 'Chứng nhận tiêm vaccine',
    vcType: 'VaccinationCredential',
    icon: Icons.vaccines,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'dateOfBirth',
        label: 'Ngày sinh',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'vaccineName',
        label: 'Tên vaccine',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'COVID-19 Vaccine',
      ),
      CredentialField(
        key: 'vaccinationDate',
        label: 'Ngày tiêm',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'doseNumber',
        label: 'Mũi tiêm',
        type: CredentialFieldType.dropdown,
        required: true,
        options: ['Mũi 1', 'Mũi 2', 'Mũi 3', 'Mũi 4'],
      ),
      CredentialField(
        key: 'vaccinationPlace',
        label: 'Nơi tiêm',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Trung tâm y tế...',
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên giấy chứng nhận',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file chứng nhận tiêm chủng',
      ),
    ],
  );

  // Other
  static const membershipCard = CredentialTemplate(
    id: 'membership_card',
    name: 'Thẻ Thành Viên',
    description: 'Thẻ thành viên, hội viên',
    vcType: 'MembershipCredential',
    icon: Icons.card_membership,
    fields: [
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'membershipNumber',
        label: 'Số thẻ thành viên',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'MEM-001234',
      ),
      CredentialField(
        key: 'organization',
        label: 'Tổ chức',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Câu lạc bộ...',
      ),
      CredentialField(
        key: 'issuedDate',
        label: 'Ngày cấp',
        type: CredentialFieldType.date,
        required: true,
      ),
      CredentialField(
        key: 'expiryDate',
        label: 'Ngày hết hạn',
        type: CredentialFieldType.date,
      ),
      CredentialField(
        key: 'documentFile',
        label: 'Tải lên thẻ thành viên',
        type: CredentialFieldType.file,
        hint: 'Chụp ảnh hoặc upload file thẻ thành viên',
      ),
    ],
  );

  static const genericCredential = CredentialTemplate(
    id: 'generic',
    name: 'Chứng Nhận Chung',
    description: 'Chứng nhận tùy chỉnh',
    vcType: 'Credential',
    icon: Icons.verified,
    fields: [
      CredentialField(
        key: 'name',
        label: 'Tên chứng nhận',
        type: CredentialFieldType.text,
        required: true,
        placeholder: 'Tên chứng nhận',
      ),
      CredentialField(
        key: 'description',
        label: 'Mô tả',
        type: CredentialFieldType.textarea,
        placeholder: 'Mô tả chi tiết',
      ),
      CredentialField(
        key: 'fullName',
        label: 'Họ và tên (tùy chọn)',
        type: CredentialFieldType.text,
        placeholder: 'Nguyễn Văn A',
      ),
      CredentialField(
        key: 'issuedDate',
        label: 'Ngày cấp',
        type: CredentialFieldType.date,
      ),
      CredentialField(
        key: 'expiryDate',
        label: 'Ngày hết hạn',
        type: CredentialFieldType.date,
      ),
    ],
  );

  /// Get template by ID
  static CredentialTemplate? getTemplateById(String id) {
    try {
      return templates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }
}

