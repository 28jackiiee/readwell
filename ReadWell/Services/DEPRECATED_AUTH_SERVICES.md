# Deprecated Authentication Services

⚠️ **NOTICE**: The following services are deprecated and should no longer be used.

## Deprecated Files

### AuthenticationService.swift
**Status**: ❌ Deprecated as of Version 2.0.0  
**Replacement**: `FirebaseAuthService.swift`

**Why deprecated**:
- Used local Core Data for authentication
- Password hashing done locally (SHA256)
- No cloud backup or sync
- No password reset functionality
- Security limitations of local-only auth

### TeacherAuthService.swift
**Status**: ❌ Deprecated as of Version 2.0.0  
**Replacement**: `FirebaseAuthService.swift` (teacher PIN methods)

**Why deprecated**:
- Functionality merged into unified FirebaseAuthService
- Simpler architecture with single auth service
- PIN storage moved from Keychain to UserDefaults for simplicity

## Migration Path

If you're still using the old services:

1. **Read the Migration Guide**: See [MIGRATION_GUIDE.md](../../../MIGRATION_GUIDE.md)
2. **Update your code**: Replace imports and service references
3. **Handle async/await**: New service uses async methods
4. **Test thoroughly**: Verify all auth flows work

## Old Service Usage (DO NOT USE)

```swift
// ❌ OLD - Don't use this anymore
import AuthenticationService
let authService = AuthenticationService()
if authService.signIn(username: "user", password: "pass") {
    // ...
}

// ❌ OLD - Don't use this anymore
import TeacherAuthService
let teacherAuth = TeacherAuthService()
if teacherAuth.authenticate(pin: "1234") {
    // ...
}
```

## New Service Usage (USE THIS)

```swift
// ✅ NEW - Use this instead
import FirebaseAuthService
let authService = FirebaseAuthService()

// Sign in (async)
Task {
    if await authService.signIn(email: "user@example.com", password: "pass") {
        // Success
    }
}

// Teacher PIN (still synchronous)
if authService.authenticateTeacherWithPIN("1234") {
    // Success
}
```

## Removal Timeline

- **v2.0.0** (Current): Services marked as deprecated
- **v2.1.0**: Deprecation warnings in code
- **v3.0.0**: Services will be removed entirely

## Questions?

- Review [MIGRATION_GUIDE.md](../../../MIGRATION_GUIDE.md) for detailed migration steps
- Check [FIREBASE_SETUP.md](../../../FIREBASE_SETUP.md) for Firebase configuration
- See [QUICKSTART.md](../../../QUICKSTART.md) for quick setup guide

## Need to Keep Old Services?

If you need to temporarily keep the old services:

1. Rename them with `Legacy` prefix:
   - `AuthenticationService.swift` → `LegacyAuthenticationService.swift`
   - `TeacherAuthService.swift` → `LegacyTeacherAuthService.swift`

2. Add a feature flag:
```swift
enum AuthMode {
    case legacy
    case firebase
}

let authMode: AuthMode = .firebase
```

3. Use conditional initialization:
```swift
let authService: Any = authMode == .firebase 
    ? FirebaseAuthService() 
    : LegacyAuthenticationService()
```

**However**, we strongly recommend migrating to Firebase as soon as possible for:
- ✅ Better security
- ✅ Cloud backup
- ✅ Password reset
- ✅ Future features
- ✅ Industry-standard practices

