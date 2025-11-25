import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Service to parse document data from QR codes and OCR text
class DocumentParserService {
  /// Parse QR code data (can be JSON or structured text)
  Map<String, dynamic>? parseQRCodeData(String qrData) {
    try {
      // Try to parse as JSON first
      final jsonData = jsonDecode(qrData) as Map<String, dynamic>?;
      if (jsonData != null) {
        return jsonData;
      }
    } catch (e) {
      debugPrint('QR code is not JSON: $e');
    }

    // Try to parse as structured text format
    // Format: KEY1:VALUE1|KEY2:VALUE2|KEY3:VALUE3
    try {
      final parts = qrData.split('|');
      final data = <String, dynamic>{};
      
      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          data[keyValue[0].trim()] = keyValue[1].trim();
        }
      }
      
      if (data.isNotEmpty) {
        return data;
      }
    } catch (e) {
      debugPrint('Failed to parse QR code as structured text: $e');
    }

    return null;
  }

  /// Parse Vietnamese ID card (CCCD/CMND) from OCR text
  Map<String, dynamic>? parseVietnameseIDCard(String ocrText) {
    final data = <String, dynamic>{};
    final lines = ocrText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // Common patterns for Vietnamese ID cards
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      
      // Extract ID number (Số CCCD/CMND)
      if (line.contains('SO') || line.contains('SỐ')) {
        // Look for number pattern
        final idMatch = RegExp(r'(\d{9,12})').firstMatch(line);
        if (idMatch != null && !data.containsKey('idNumber')) {
          data['idNumber'] = idMatch.group(1);
        }
      }
      
      // Extract full name (Họ và tên)
      if (line.contains('HO VA TEN') || line.contains('HỌ VÀ TÊN') || 
          line.contains('FULL NAME') || (line.length > 10 && !line.contains(RegExp(r'\d{9,}')))) {
        // Check if next line might be the name
        if (i + 1 < lines.length) {
          final nameLine = lines[i + 1];
          if (nameLine.length > 5 && !nameLine.contains(RegExp(r'^\d+$'))) {
            data['fullName'] = nameLine;
            i++; // Skip next line
          }
        }
      }
      
      // Extract date of birth (Ngày sinh)
      final dobMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(line);
      if (dobMatch != null) {
        final day = dobMatch.group(1)!.padLeft(2, '0');
        final month = dobMatch.group(2)!.padLeft(2, '0');
        final year = dobMatch.group(3);
        data['dateOfBirth'] = '$year-$month-$day';
      }
      
      // Extract gender (Giới tính)
      if (line.contains('NAM') || line.contains('MALE')) {
        data['gender'] = 'Nam';
      } else if (line.contains('NU') || line.contains('FEMALE')) {
        data['gender'] = 'Nữ';
      }
      
      // Extract nationality (Quốc tịch)
      if (line.contains('QUOC TICH') || line.contains('QUỐC TỊCH') || line.contains('NATIONALITY')) {
        if (i + 1 < lines.length) {
          data['nationality'] = lines[i + 1];
          i++;
        }
      }
      
      // Extract address (Địa chỉ)
      if (line.contains('DIA CHI') || line.contains('ĐỊA CHỈ') || line.contains('ADDRESS')) {
        // Address might span multiple lines
        final addressParts = <String>[];
        for (var j = i + 1; j < lines.length && j < i + 5; j++) {
          if (lines[j].length > 10) {
            addressParts.add(lines[j]);
          } else {
            break;
          }
        }
        if (addressParts.isNotEmpty) {
          data['address'] = addressParts.join(', ');
        }
      }
      
      // Extract issued date (Ngày cấp)
      if (line.contains('NGAY CAP') || line.contains('NGÀY CẤP') || line.contains('ISSUED')) {
        final issuedMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(line);
        if (issuedMatch != null) {
          final day = issuedMatch.group(1)!.padLeft(2, '0');
          final month = issuedMatch.group(2)!.padLeft(2, '0');
          final year = issuedMatch.group(3);
          data['issuedDate'] = '$year-$month-$day';
        }
      }
      
      // Extract issued place (Nơi cấp)
      if (line.contains('NOI CAP') || line.contains('NƠI CẤP') || line.contains('ISSUED BY')) {
        if (i + 1 < lines.length) {
          data['issuedPlace'] = lines[i + 1];
          i++;
        }
      }
    }

    return data.isNotEmpty ? data : null;
  }

  /// Parse passport from OCR text
  Map<String, dynamic>? parsePassport(String ocrText) {
    final data = <String, dynamic>{};
    final lines = ocrText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      
      // Extract passport number
      if (line.contains('PASSPORT') || line.contains('PASS') || line.contains('NO')) {
        final passportMatch = RegExp(r'([A-Z]{1,2}\d{6,9})').firstMatch(line);
        if (passportMatch != null) {
          data['passportNumber'] = passportMatch.group(1);
        }
      }
      
      // Extract full name
      if (line.contains('SURNAME') || line.contains('GIVEN NAMES') || 
          (line.length > 10 && !line.contains(RegExp(r'[A-Z]{1,2}\d{6,}')))) {
        if (i + 1 < lines.length) {
          final nameLine = lines[i + 1];
          if (nameLine.length > 5) {
            data['fullName'] = nameLine;
            i++;
          }
        }
      }
      
      // Extract date of birth
      final dobMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(line);
      if (dobMatch != null && !data.containsKey('dateOfBirth')) {
        final day = dobMatch.group(1)!.padLeft(2, '0');
        final month = dobMatch.group(2)!.padLeft(2, '0');
        final year = dobMatch.group(3);
        data['dateOfBirth'] = '$year-$month-$day';
      }
      
      // Extract nationality
      if (line.contains('NATIONALITY') || line.contains('VIET NAM') || line.contains('VIỆT NAM')) {
        data['nationality'] = 'Việt Nam';
      }
      
      // Extract issued date
      if (line.contains('DATE OF ISSUE') || line.contains('ISSUED')) {
        final issuedMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(line);
        if (issuedMatch != null) {
          final day = issuedMatch.group(1)!.padLeft(2, '0');
          final month = issuedMatch.group(2)!.padLeft(2, '0');
          final year = issuedMatch.group(3);
          data['issuedDate'] = '$year-$month-$day';
        }
      }
      
      // Extract expiry date
      if (line.contains('DATE OF EXPIRY') || line.contains('EXPIRY') || line.contains('EXPIRES')) {
        final expiryMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(line);
        if (expiryMatch != null) {
          final day = expiryMatch.group(1)!.padLeft(2, '0');
          final month = expiryMatch.group(2)!.padLeft(2, '0');
          final year = expiryMatch.group(3);
          data['expiryDate'] = '$year-$month-$day';
        }
      }
    }

    return data.isNotEmpty ? data : null;
  }

  /// Parse driver license from OCR text
  Map<String, dynamic>? parseDriverLicense(String ocrText) {
    final data = <String, dynamic>{};
    final lines = ocrText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      
      // Extract license number
      final licenseMatch = RegExp(r'(\d{12})').firstMatch(line);
      if (licenseMatch != null && !data.containsKey('licenseNumber')) {
        data['licenseNumber'] = licenseMatch.group(1);
      }
      
      // Extract full name
      if (line.length > 10 && !line.contains(RegExp(r'^\d+$'))) {
        if (!data.containsKey('fullName')) {
          data['fullName'] = lines[i];
        }
      }
      
      // Extract license class (Hạng bằng)
      final classMatch = RegExp(r'([A-Z]\d?)').firstMatch(line);
      if (classMatch != null && ['A1', 'A2', 'A3', 'A4', 'B1', 'B2', 'C', 'D', 'E', 'F'].contains(classMatch.group(1))) {
        data['licenseClass'] = classMatch.group(1);
      }
      
      // Extract dates
      final dateMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(line);
      if (dateMatch != null) {
        final day = dateMatch.group(1)!.padLeft(2, '0');
        final month = dateMatch.group(2)!.padLeft(2, '0');
        final year = dateMatch.group(3);
        
        if (line.contains('SINH') || line.contains('BIRTH')) {
          data['dateOfBirth'] = '$year-$month-$day';
        } else if (line.contains('CAP') || line.contains('ISSUED')) {
          data['issuedDate'] = '$year-$month-$day';
        } else if (line.contains('HET HAN') || line.contains('EXPIRY') || line.contains('EXPIRES')) {
          data['expiryDate'] = '$year-$month-$day';
        }
      }
    }

    return data.isNotEmpty ? data : null;
  }

  /// Parse structured text blocks to extract field values
  Map<String, dynamic>? parseStructuredText(String ocrText, String documentType) {
    switch (documentType.toLowerCase()) {
      case 'identity_card':
      case 'cccd':
      case 'cmnd':
        return parseVietnameseIDCard(ocrText);
      case 'passport':
        return parsePassport(ocrText);
      case 'driver_license':
      case 'driver_licence':
        return parseDriverLicense(ocrText);
      default:
        // Try to parse as generic document
        return _parseGenericDocument(ocrText);
    }
  }

  /// Parse generic document (try to extract common fields)
  Map<String, dynamic>? _parseGenericDocument(String ocrText) {
    final data = <String, dynamic>{};
    final lines = ocrText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    for (var line in lines) {
      // Extract dates
      final dateMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(line);
      if (dateMatch != null) {
        final day = dateMatch.group(1)!.padLeft(2, '0');
        final month = dateMatch.group(2)!.padLeft(2, '0');
        final year = dateMatch.group(3);
        final dateStr = '$year-$month-$day';
        
        if (!data.containsKey('dateOfBirth') && 
            (line.contains('SINH') || line.contains('BIRTH'))) {
          data['dateOfBirth'] = dateStr;
        } else if (!data.containsKey('issuedDate') && 
                   (line.contains('CAP') || line.contains('ISSUED'))) {
          data['issuedDate'] = dateStr;
        } else if (!data.containsKey('expiryDate') && 
                   (line.contains('HET HAN') || line.contains('EXPIRY'))) {
          data['expiryDate'] = dateStr;
        }
      }
      
      // Extract numbers that might be IDs
      final idMatch = RegExp(r'(\d{9,12})').firstMatch(line);
      if (idMatch != null && !data.containsKey('idNumber')) {
        data['idNumber'] = idMatch.group(1);
      }
      
      // Extract names (lines that are long and don't contain only numbers)
      if (line.length > 10 && !line.contains(RegExp(r'^\d+$')) && !data.containsKey('fullName')) {
        // Check if it looks like a name
        if (line.split(' ').length >= 2) {
          data['fullName'] = line;
        }
      }
    }

    return data.isNotEmpty ? data : null;
  }

  /// Map parsed data to credential template fields
  Map<String, dynamic> mapToCredentialFields(Map<String, dynamic> parsedData, String credentialType) {
    final mappedData = <String, dynamic>{};
    
    // Common field mappings
    if (parsedData.containsKey('fullName')) {
      mappedData['fullName'] = parsedData['fullName'];
    }
    if (parsedData.containsKey('dateOfBirth')) {
      mappedData['dateOfBirth'] = parsedData['dateOfBirth'];
    }
    if (parsedData.containsKey('gender')) {
      mappedData['gender'] = parsedData['gender'];
    }
    if (parsedData.containsKey('address')) {
      mappedData['address'] = parsedData['address'];
    }
    if (parsedData.containsKey('nationality')) {
      mappedData['nationality'] = parsedData['nationality'];
    }
    if (parsedData.containsKey('issuedDate')) {
      mappedData['issuedDate'] = parsedData['issuedDate'];
    }
    if (parsedData.containsKey('issuedPlace')) {
      mappedData['issuedPlace'] = parsedData['issuedPlace'];
    }
    if (parsedData.containsKey('expiryDate')) {
      mappedData['expiryDate'] = parsedData['expiryDate'];
    }
    
    // Type-specific mappings
    switch (credentialType) {
      case 'identity_card':
        if (parsedData.containsKey('idNumber')) {
          mappedData['idNumber'] = parsedData['idNumber'];
        }
        break;
      case 'passport':
        if (parsedData.containsKey('passportNumber')) {
          mappedData['passportNumber'] = parsedData['passportNumber'];
        }
        break;
      case 'driver_license':
        if (parsedData.containsKey('licenseNumber')) {
          mappedData['licenseNumber'] = parsedData['licenseNumber'];
        }
        if (parsedData.containsKey('licenseClass')) {
          mappedData['licenseClass'] = parsedData['licenseClass'];
        }
        break;
    }
    
    return mappedData;
  }
}

