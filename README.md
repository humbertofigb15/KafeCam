# KafeCam

## Supabase Integration (Development)

- Add package: `https://github.com/supabase-community/supabase-swift` (Xcode > Add Packages)
- Copy `KafeCam/Configuration/SupabaseConfig.sample.swift` to `KafeCam/Configuration/SupabaseConfig.swift` and fill values:
  - `url`: https://dmctlhsjdwykywrjmpax.supabase.co
  - `anonKey`: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtY3RsaHNqZHd5a3l3cmptcGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0NjU4MTUsImV4cCI6MjA3MzA0MTgxNX0.34WixD2nWiqQl4gD7Vc-jSoEzbQ_lTPmzVM6ezS5rbM
  - `devEmail`/`devPassword`: development account for testing RLS (test@test.com/test12345)
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
