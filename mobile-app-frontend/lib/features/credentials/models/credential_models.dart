import 'package:flutter/material.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class CredentialTypeMetadata {
  final String title;
  final IconData icon;

  const CredentialTypeMetadata({required this.title, required this.icon});
  
  /// Get localized title based on vcType
  static String? getLocalizedTitle(String? vcType, AppLocalizations l10n) {
    if (vcType == null) return null;
    switch (vcType) {
      case 'IdentityCredential':
        return l10n.governmentId;
      case 'PassportCredential':
        return l10n.passport;
      case 'DriverLicenseCredential':
        return l10n.driverLicense;
      case 'EducationalCredential':
        return l10n.universityDegree;
      case 'ProfessionalCredential':
        return l10n.professionalCertificate;
      case 'TrainingCredential':
        return l10n.trainingCertificate;
      case 'EmploymentCredential':
        return l10n.employmentCredential;
      case 'WorkPermitCredential':
        return l10n.workPermit;
      case 'HealthInsuranceCredential':
        return l10n.healthInsurance;
      case 'VaccinationCredential':
        return l10n.vaccinationCertificate;
      case 'MembershipCredential':
        return l10n.membershipCard;
      case 'Credential':
        return l10n.credential;
      default:
        return credentialTypeMetadata[vcType]?.title;
    }
  }
}

class CredentialAttachment {
  final String rawKey;
  final String label;
  final String uri;
  final String? fileName;

  const CredentialAttachment({
    required this.rawKey,
    required this.label,
    required this.uri,
    this.fileName,
  });
}

class GatewayLink {
  final String label;
  final String url;

  const GatewayLink({required this.label, required this.url});
}

const Map<String, CredentialTypeMetadata> credentialTypeMetadata = {
  'IdentityCredential': CredentialTypeMetadata(
    title: 'Government ID',
    icon: Icons.credit_card,
  ),
  'PassportCredential': CredentialTypeMetadata(
    title: 'Passport',
    icon: Icons.article,
  ),
  'DriverLicenseCredential': CredentialTypeMetadata(
    title: 'Driver License',
    icon: Icons.drive_eta,
  ),
  'EducationalCredential': CredentialTypeMetadata(
    title: 'University Degree',
    icon: Icons.school,
  ),
  'ProfessionalCredential': CredentialTypeMetadata(
    title: 'Professional Certificate',
    icon: Icons.workspace_premium,
  ),
  'TrainingCredential': CredentialTypeMetadata(
    title: 'Training Certificate',
    icon: Icons.book,
  ),
  'EmploymentCredential': CredentialTypeMetadata(
    title: 'Employment Credential',
    icon: Icons.business_center,
  ),
  'WorkPermitCredential': CredentialTypeMetadata(
    title: 'Work Permit',
    icon: Icons.work,
  ),
  'HealthInsuranceCredential': CredentialTypeMetadata(
    title: 'Health Insurance',
    icon: Icons.medical_services,
  ),
  'VaccinationCredential': CredentialTypeMetadata(
    title: 'Vaccination Certificate',
    icon: Icons.vaccines,
  ),
  'MembershipCredential': CredentialTypeMetadata(
    title: 'Membership Card',
    icon: Icons.card_membership,
  ),
  'Credential': CredentialTypeMetadata(
    title: 'Credential',
    icon: Icons.verified,
  ),
};

