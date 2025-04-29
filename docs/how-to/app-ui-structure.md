# 📘 App Structure Documentation

## 🗂️ Folder Structure
```
src/
├── routes/                     # Routing structure
│   ├── index.tsx              # Root router using createBrowserRouter
│   ├── MainRoutes.tsx         # Consolidated module routes
│   ├── LoginRoutes.tsx        # Auth routes (login/callback)
│   ├── LandingRoutes.tsx      # Public landing pages (about, terms, etc.)
│   └── modules/               # Modular routes split per domain
│       ├── community-routes.tsx
│       ├── sales-routes.tsx
│       └── ...
├── contexts/                  # Global contexts
│   ├── Auth0Context.tsx       # Auth0 provider with SafeAuth0Provider wrapper
│   ├── ErrorContext.tsx       # App-level error handling
│   ├── ConfigContext.tsx      # Org/Company/FinYear tracking
├── components/                # Shared components
│   ├── ErrorBoundary          # Global + auth error boundaries
│   ├── Loader.tsx, ScrollTop, Notistack, Snackbar
│   └── logo/ etc.
├── pages/                     # Page screens per feature
│   └── landing.tsx            # Public landing page
├── themes/                    # MUI theme setup
├── hooks/                     # Custom hooks (useAuth, useConfig, useMenuItems)
└── shared/                    # Shared utils & storage helpers
```

---

## 🔐 Authentication & Permissions

### 1. **Login Flow**
- Wrapped with `SafeAuth0Provider` → `Auth0Provider` internally.
- On login:
  - Auth0 session is validated.
  - User info + token fetched.
  - Service token stored in `localStorage`.
  - Org/Company/FinYear are restored from `localStorage` via `applyLastSelectedPreferences()`.

### 2. **Permission Management**
- Permissions fetched using: `fetchUserPermissionsApi(orgId, userId)`.
- Stored in Redux/context + localStorage.
- Permission refreshes automatically on org change.

```ts
useEffect(() => {
  if (organization?.organizationId && state.isLoggedIn) {
    refreshPermissions();
  }
}, [organization?.organizationId]);
```

### 3. **Accessing Permissions**
- `useAuth()` hook gives access to `userPermissions`.
- Used for conditional rendering of menus, routes, or UI elements.
- Permissions follow RBAC model with dynamic policies.

---

## 🧭 Menu Generation

### `useMenuItems()`
- Generates dynamic menus based on user permissions + current company/org.
- Reads from centralized permissions list.
- Organized in a modular structure, e.g.:
```ts
const getMenuItemsImpl = ({ permissions, company, user }) => {
  if (!Array.isArray(permissions)) return [];
  return permissions.map(p => generateMenuItemFromPermission(p));
};
```
- Resilient to null/undefined using fallback checks.

---

## 🧩 Routing
- Each domain (community, sales, inventory, payroll, etc.) has its own file under `routes/modules/`
- Combined in `MainRoutes.tsx`.
- Public routes (about, terms) in `LandingRoutes.tsx`
- Error boundary per route via:
```tsx
{
  path: '/app',
  element: <MinimalLayout />,
  errorElement: <RouteErrorPage />, // dynamically catches per route
  children: [...]
}
```

---

## 🚨 Error Boundaries

### 1. **GlobalErrorBoundary**
Wraps `App.tsx` — catches unexpected React errors.

### 2. **AuthErrorBoundary**
Handles failures inside the auth layer.

### 3. **RouteErrorPage**
Used in routing `errorElement`. Displays fallback UI for route crashes (e.g. failed loaders, permissions map errors).

---

## 🔄 Full Login & Preference Restoration Flow
```plaintext
[Login Success]
  → Get user via Auth0
  → Save token to localStorage
  → Fetch org/company/finYear from localStorage or defaults
  → Call `applyLastSelectedPreferences`
      ↳ Triggers ConfigContext update
  → Fetch permissions
      ↳ Save to context + localStorage
  → Render components conditionally based on permissions
```

---

## 🧠 Key Learnings / Best Practices

- Modular route files scale better.
- SafeAuth0Provider with AuthErrorBoundary gives graceful auth fallback.
- Global error handling ensures better UX under failure.
- useConfig + localStorage drives organization/company/fin year persistence.
- Centralized permission fetch avoids redundancy and ensures proper UI visibility.
- Menu is dynamically derived and not hardcoded.

---

✅ Refactoring completed successfully.
📦 Future Enhancements:
- Add lazy loading + suspense fallback per route chunk
- Implement role-based menu grouping
- Add loader guards while permission fetch is pending

---

## 📊 Suggested Diagram

```plaintext
┌────────────┐
│ Login Page │
└─────┬──────┘
      ↓
┌──────────────────┐     ┌────────────────┐
│ Auth0 Login Flow │────▶ Save Token     │
└──────────────────┘     └──────┬─────────┘
                               ↓
                     ┌────────────────────────────┐
                     │ Restore Preferences        │
                     │ - Org                      │
                     │ - Company                  │
                     │ - Fin Year                 │
                     └──────────┬─────────────────┘
                                ↓
                      ┌──────────────────────┐
                      │ Fetch Permissions    │
                      └──────────┬───────────┘
                                 ↓
                      ┌────────────────────────┐
                      │ Update Auth Context    │
                      │ + localStorage         │
                      └──────────┬─────────────┘
                                 ↓
                      ┌───────────────────────────┐
                      │ useMenuItems builds Menu  │
                      └───────────────────────────┘
```



