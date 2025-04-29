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

## 🏗️ App Wrapping (App.tsx Structure)

```tsx
<GlobalErrorBoundary>
  <ConfigProvider>
    <ThemeCustomization>
      <Locales>
        <ScrollTop>
          <ErrorProvider>
            <SafeAuth0Provider>
              <Notistack>
                <BackdropProvider>
                  <RouterProvider router={router} />
                  <Snackbar />
                </BackdropProvider>
              </Notistack>
            </SafeAuth0Provider>
          </ErrorProvider>
        </ScrollTop>
      </Locales>
    </ThemeCustomization>
  </ConfigProvider>
</GlobalErrorBoundary>
```

Each provider layer:
- **GlobalErrorBoundary**: Catch any crash globally.
- **ConfigProvider**: Manage Organization, Company, Financial Year context.
- **ThemeCustomization**: Material UI theme setup.
- **Locales**: Language and RTL support.
- **ScrollTop**: Scrolls page to top on route changes.
- **ErrorProvider**: Manage app-wide caught errors.
- **SafeAuth0Provider**: Wraps Auth0Provider inside AuthErrorBoundary.
- **Notistack**: Snackbar system for notifications.
- **BackdropProvider**: Loader/spinner control.
- **RouterProvider**: React Router DOM routes.

---

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



## 🗂️ Routes Structure

### src/routes/index.tsx
```tsx
createBrowserRouter([
  LandingRoutes, // Public landing pages
  LoginRoutes,   // Login / Callback
  MainRoutes     // Protected /App Routes
]);
```

### src/routes/MainRoutes.tsx
Splits into module-specific routes:
```tsx
{
  path: '/community',
  element: <MinimalLayout />,
  errorElement: <RouteErrorPage />, // Per module fallback
  children: [...]
}
{
  path: '/sales', children: [...]
}
{
  path: '/purchase', children: [...]
}
...
```

✅ **Each domain (`community`, `sales`, etc.) has its own file.**
✅ **Every route tree uses an `errorElement` for route errors.**

---

## 🔐 Auth & Permission Lifecycle

### Login Flow
```plaintext
- User clicks Login
- Auth0 popup appears
- On success:
    1. Token stored → localStorage
    2. User profile fetched
    3. Restore Last Selected Org/Company/FinYear
    4. Update ConfigContext
    5. Fetch Permissions based on organization
    6. Save Permissions into context + localStorage
```

### Core Files
- `contexts/Auth0Context.tsx` → Handles login, token, user, permissions.
- `hooks/useAuth.ts` → Custom hook to access auth.
- `hooks/useConfig.ts` → Custom hook to access org/company/fin year.


---

## 🧩 Menu Generation and Permissions

### Menu is Generated Dynamically via `useMenuItems`

```tsx
const menuItems = useMenuItems();
```

Internal working:
```ts
const getMenuItemsImpl = ({ permissions, company, user }) => {
  if (!Array.isArray(permissions)) return [];
  return permissions.map(p => generateMenuItemFromPermission(p));
};
```
- Menu options are based on permissions.
- No hardcoded menu.
- Hides features if permission missing.

✅ **Safe fallbacks if permissions are missing.**

### Example:
If user has `Sales.Invoice.View`, they see `Invoices` menu.
If not, it won't even render that menu item.

---

## 🚨 Error Handling in the App

- **GlobalErrorBoundary**: Any React error at the App level.
- **AuthErrorBoundary**: If Auth0 provider crashes.
- **RouteErrorPage**: Per route crash fallback.

Sample Route Usage:
```tsx
{
  path: '/sales',
  element: <MinimalLayout />,
  errorElement: <RouteErrorPage />,
  children: [...]
}
```

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
---

## 🔄 Full App Lifecycle Diagram

```plaintext
[User Lands]
  ↓
[Auth0 Check Session]
  ↓
Is Logged In? 
 |        
No        Yes
 |           ↓
Show Login   Fetch Token
               ↓
           Fetch User Profile
               ↓
           Restore Org/Company/FinYear
               ↓
           Fetch Permissions
               ↓
           Update Auth Context
               ↓
           Render Menu Items Dynamically
```

---

## 📦 Summary

- **App wrapping is deeply layered but clean.**
- **Dynamic routing with modular approach.**
- **Permission-driven UI visibility (RBAC).**
- **Error boundaries at App, Auth, and Route levels.**
- **Use of centralized hooks (`useAuth`, `useConfig`, `useMenuItems`).**
- **Minimal hardcoding → Everything reactive.**
