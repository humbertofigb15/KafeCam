# KafeCam

## Supabase Integration (Development)

- Add package: `https://github.com/supabase-community/supabase-swift` (Xcode > Add Packages)
- Copy `KafeCam/Configuration/SupabaseConfig.sample.swift` to `KafeCam/Configuration/SupabaseConfig.swift` and fill values:
  - `url`: your Supabase project URL
  - `anonKey`: anon public key
  - `devEmail`/`devPassword`: development account for testing RLS
- Build and run. Open `PlotsView` to sign in (dev) and list/create plots.

### Endpoints used
- PostgREST
  - `plots`: select with `.eq("owner_user_id", userId)` and insert with `owner_user_id` set
  - `captures`: insert only (after upload)
- Storage
  - Private bucket `captures`. Signed upload URL is obtained via team API (TODO placeholder in app).

### Security
- No secrets are committed. `SupabaseConfig.swift` is in `.gitignore`.
- Only anon key used in-app. Service role is never used on-device.
