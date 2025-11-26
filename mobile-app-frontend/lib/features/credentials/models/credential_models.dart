import 'package:flutter/material.dart';

class CredentialTypeMetadata {
  final String title;
  final IconData icon;

  const CredentialTypeMetadata({required this.title, required this.icon});
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

