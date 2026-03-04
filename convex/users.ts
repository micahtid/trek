import { mutation } from "./_generated/server";
import { v } from "convex/values";

// Called after successful Google sign-in to store or update the user record.
//
// On first sign-in: creates a new user document in the users table.
// On subsequent sign-ins: updates email, name, avatarUrl, and lastSignIn.
//
// The caller (Flutter AuthNotifier) passes the Google user data obtained
// from the google_sign_in v7 event. Convex verifies the request is
// authenticated (via ctx.auth.getUserIdentity) before writing.
//
// Returns: the Convex document _id for the user (string).
export const upsertUser = mutation({
  args: {
    googleId: v.string(),
    email: v.string(),
    name: v.string(),
    avatarUrl: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Verify the caller is authenticated via Convex's OIDC bridge
    // If the Google ID token is not valid, this throws and the mutation aborts
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");

    // Look up existing user by Google ID (primary identity field)
    const existing = await ctx.db
      .query("users")
      .withIndex("by_googleId", (q) => q.eq("googleId", args.googleId))
      .unique();

    if (existing) {
      // Update mutable fields on every sign-in
      // (name/email/avatar can change if user updates their Google profile)
      await ctx.db.patch(existing._id, {
        email: args.email,
        name: args.name,
        avatarUrl: args.avatarUrl,
        lastSignIn: Date.now(),
      });
      return existing._id;
    }

    // First sign-in: create the user record
    return await ctx.db.insert("users", {
      googleId: args.googleId,
      email: args.email,
      name: args.name,
      avatarUrl: args.avatarUrl,
      lastSignIn: Date.now(),
    });
  },
});
