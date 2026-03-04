import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

// Database schema for the Intern Growth Vault backend.
//
// The users table stores identity and integration state for authenticated users.
// Records are created/updated by the auth mutation in Plan 03 when users sign in
// via Google OAuth. The googleId and email indexes support fast lookups.

export default defineSchema({
  users: defineTable({
    // Identity fields from Google ID token (populated by auth mutation in Plan 03)
    googleId: v.string(),             // Google's unique user ID (sub claim from JWT)
    email: v.string(),                // User's email address (email claim from JWT)
    name: v.string(),                 // Display name (name claim from JWT)
    avatarUrl: v.optional(v.string()), // Profile picture URL (picture claim from JWT)

    // Integration state (populated when user connects services in Settings)
    githubConnected: v.optional(v.boolean()), // True after GitHub OAuth completes (Phase 1 Plan 04)

    // Timestamps (Unix milliseconds)
    lastSignIn: v.number(),           // Updated on every successful sign-in
  })
    .index("by_googleId", ["googleId"]) // Primary lookup: find user by Google ID on sign-in
    .index("by_email", ["email"]),      // Secondary lookup: find user by email address
});
