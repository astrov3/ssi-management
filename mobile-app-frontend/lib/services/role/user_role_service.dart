import 'package:shared_preferences/shared_preferences.dart';

enum UserRoleType {
  owner,
  issuer,
}

class UserRoleService {
  static const String _roleKey = 'user_role';
  static const String _roleOwner = 'owner';
  static const String _roleIssuer = 'issuer';
  static const String _roleBoth = 'both';

  /// Save user role preference (can be owner, issuer, or both)
  Future<void> saveUserRole(UserRoleType role) async {
    final prefs = await SharedPreferences.getInstance();
    final currentRoles = await getUserRoles();
    
    // If user already has roles, add the new one
    if (currentRoles.contains(role)) {
      return; // Already has this role
    }
    
    // Add the new role
    final updatedRoles = {...currentRoles, role};
    
    // Save as 'both' if user has both roles, otherwise save the single role
    if (updatedRoles.length == 2) {
      await prefs.setString(_roleKey, _roleBoth);
    } else if (updatedRoles.contains(UserRoleType.owner)) {
      await prefs.setString(_roleKey, _roleOwner);
    } else if (updatedRoles.contains(UserRoleType.issuer)) {
      await prefs.setString(_roleKey, _roleIssuer);
    }
  }

  /// Remove a specific role
  Future<void> removeUserRole(UserRoleType role) async {
    final prefs = await SharedPreferences.getInstance();
    final currentRoles = await getUserRoles();
    
    if (!currentRoles.contains(role)) {
      return; // Doesn't have this role
    }
    
    final updatedRoles = currentRoles.where((r) => r != role).toSet();
    
    if (updatedRoles.isEmpty) {
      await prefs.remove(_roleKey);
    } else if (updatedRoles.contains(UserRoleType.owner)) {
      await prefs.setString(_roleKey, _roleOwner);
    } else if (updatedRoles.contains(UserRoleType.issuer)) {
      await prefs.setString(_roleKey, _roleIssuer);
    }
  }

  /// Get user role preference (single role for backward compatibility)
  Future<UserRoleType?> getUserRole() async {
    final roles = await getUserRoles();
    if (roles.isEmpty) return null;
    // Return owner if available, otherwise issuer
    return roles.contains(UserRoleType.owner) ? UserRoleType.owner : UserRoleType.issuer;
  }

  /// Get all user roles (can be both owner and issuer)
  Future<Set<UserRoleType>> getUserRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(_roleKey);
    
    if (roleString == null) return <UserRoleType>{};
    
    if (roleString == _roleOwner) {
      return {UserRoleType.owner};
    } else if (roleString == _roleIssuer) {
      return {UserRoleType.issuer};
    } else if (roleString == _roleBoth) {
      return {UserRoleType.owner, UserRoleType.issuer};
    }
    
    return <UserRoleType>{};
  }

  /// Set user roles explicitly
  Future<void> setUserRoles(Set<UserRoleType> roles) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (roles.isEmpty) {
      await prefs.remove(_roleKey);
    } else if (roles.length == 2) {
      await prefs.setString(_roleKey, _roleBoth);
    } else if (roles.contains(UserRoleType.owner)) {
      await prefs.setString(_roleKey, _roleOwner);
    } else if (roles.contains(UserRoleType.issuer)) {
      await prefs.setString(_roleKey, _roleIssuer);
    }
  }

  /// Check if user has selected a role
  Future<bool> hasSelectedRole() async {
    final roles = await getUserRoles();
    return roles.isNotEmpty;
  }

  /// Check if user has a specific role
  Future<bool> hasRole(UserRoleType role) async {
    final roles = await getUserRoles();
    return roles.contains(role);
  }

  /// Clear user role (for logout or reset)
  Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }

  /// Get role display name
  String getRoleDisplayName(UserRoleType role) {
    switch (role) {
      case UserRoleType.owner:
        return 'Owner';
      case UserRoleType.issuer:
        return 'Issuer';
    }
  }

  /// Get role description
  String getRoleDescription(UserRoleType role) {
    switch (role) {
      case UserRoleType.owner:
        return 'Register and manage your own DID. You can issue credentials and authorize issuers.';
      case UserRoleType.issuer:
        return 'Issue credentials for organizations. You need to be authorized by an owner first.';
    }
  }

  /// Get roles display text
  String getRolesDisplayText(Set<UserRoleType> roles) {
    if (roles.isEmpty) return 'No role selected';
    if (roles.length == 2) return 'Owner & Issuer';
    return roles.map((r) => getRoleDisplayName(r)).join(' & ');
  }
}

