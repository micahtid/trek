import { AuthConfig } from "convex/server";

// Custom OIDC configuration for Google ID token authentication.
//
// This trusts Google ID tokens issued by Google's OAuth 2.0 infrastructure.
// The Convex backend validates these tokens against Google's JWKS endpoint
// at https://accounts.google.com/.well-known/jwks.json.
//
// IMPORTANT: The applicationID MUST match the `aud` claim in Google ID tokens,
// which is the Web OAuth 2.0 Client ID from Google Cloud Console.
//
// SETUP REQUIRED before production:
// 1. Go to Google Cloud Console > APIs & Services > Credentials
// 2. Create a Web application OAuth 2.0 Client ID (if not already created)
// 3. Replace the placeholder below with the actual Web Client ID
//    (format: NUMBERS-HASH.apps.googleusercontent.com)
// 4. Use this same Web Client ID as `serverClientId` in Flutter's
//    GoogleSignIn.instance.initialize() call
//
// See: https://docs.convex.dev/auth/advanced/custom-auth
// See: .planning/phases/01-foundation-and-auth/01-RESEARCH.md (Pattern 1)

export default {
  providers: [
    {
      domain: "https://accounts.google.com",
      // TODO: Replace with actual Web OAuth 2.0 Client ID from Google Cloud Console.
      // The "verified" placeholder causes Convex to accept any Google-signed token.
      // This is acceptable for local development but MUST be replaced before
      // production deployment to prevent accepting tokens issued for other apps.
      applicationID: "559229937063-sp4cfdk9dn3uano0g84f6ei502j7tvh7.apps.googleusercontent.com",
    },
  ],
} satisfies AuthConfig;
