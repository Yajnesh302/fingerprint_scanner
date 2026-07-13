# Requirement Specification: Hierarchical Category & Multi-Admin Access Control

## 1. Background / Why This Change

Today the system has a flat `Category` field with three fixed values: **Skilled**, **Semi-Skilled**, **Unskilled**. All contracts and employees sit directly under one of these three values, and there is a single flat `Admin` role above regular users.

This is no longer sufficient. In practice, "Skilled" or "Unskilled" means something different depending on the department — e.g. HR's Skilled role is a Data Entry Operator, while Cook's Skilled role is a Cook. We need a two-level category structure, and multiple admins scoped to different slices of it.

---

## 2. New Data Model: Main Category → Sub Category

### 2.1 Main Category
- A configurable top-level grouping, e.g. `HR`, `Driver`, `Cook`, `Security` (names not fixed — Super Admin defines these).
- Created only by **Super Admin**.
- Can exist in a "half-configured" state with zero Sub Categories defined yet — this is allowed (not blocked).

### 2.2 Sub Category
- Each Main Category can have up to 3 Sub Categories, one per Skill Level: **Skilled**, **Semi-Skilled**, **Unskilled**.
- A Main Category is **not required** to define all three — Super Admin can skip any skill level for any Main Category (fully configurable, no hardcoded assumption of 3).
- Each defined Skill Level has exactly **one** configurable Role Label under it (not multiple labels per skill level). Example:
  - `HR › Skilled › Data Entry Operator`
  - `HR › Semi-Skilled › Office Staff`
  - `HR › Unskilled › Attender`
  - `Cook › Skilled › Cook`
  - `Cook › Semi-Skilled › Chopper`
  - `Cook › Unskilled › Cleaner`
- Role Label text is **editable anytime** by Super Admin without affecting historical data — everything hangs off a stable internal Sub Category ID, never the display text. Renaming is safe and non-destructive to past contracts/employees.
- **Display format everywhere** (grids, ledgers, documents, attendance sheets, reports): breadcrumb style —
  `Main Category › Skill Level › Role Label` (e.g. `Cook › Skilled › Cook`, `HR › Unskilled › Attender`).

### 2.3 Contracts, Ledgers, Documents — scoped to Sub Category
- Every contract runs independently **per Sub Category** — its own contract period, vendor bid, sealing/closing lifecycle — exactly like today's flat Category behaves, just one level deeper.
- Contract numbering, ledger sequences, and document numbering run **independently per Sub Category** (not shared across the whole Main Category). E.g. `HR-Skilled-001`, `HR-Unskilled-001` are separate sequences, not a shared `HR-001...`.

---

## 3. Roles

### 3.1 Super Admin
- Can create/edit Main Categories and their Sub Categories (skill level + role label) at any time.
- Can create new Super Admins.
- Can create Admins and assign each Admin one or more **(Main Category, Sub Category)** scopes — an Admin can be scoped across **multiple different Main Categories** (e.g. one Admin handling both `Cook › Unskilled` and `Driver › Unskilled` simultaneously).
- The same Sub Category can be assigned to **multiple different Admins** at once (many-to-many relationship between Admins and Sub Categories) — e.g. two separate Admins can both be scoped to `HR › Skilled`.
- Does **not** perform operational work — no creating contracts, no marking attendance, no data entry. Super Admin's role is administrative/oversight only:
  - Create/manage Main Categories & Sub Categories.
  - Create/manage Admins and Super Admins, and assign category scopes.
  - View **all** data across every Main Category / Sub Category, with the ability to filter/categorize the view (not just a flat dump — can drill into a specific category or see a consolidated cross-category view).
- When a Super Admin creates an Admin, the UI must prompt: **which Main Category + which Sub Category (skill level)** to grant that Admin access to (multi-select, since one Admin can span multiple categories).

### 3.2 Admin (category-scoped)
- Scoped to one or more specific `(Main Category › Sub Category)` combinations, as assigned by Super Admin.
- Can create/manage contracts **only within their assigned Sub Category(ies)** — contracts under other Sub Categories (even within the same Main Category) are **not visible** to them.
- **Vendor visibility exception:** the same vendor can hold separate contracts under different Main Categories/Sub Categories. An Admin can see that a vendor exists and its profile/contact details even if that vendor also has a contract under another Admin's category — but the **commercial terms of a contract outside their scope stay hidden**. Only vendor identity/master info is shared globally; contract-specific data stays sub-category-scoped.
- **Cannot see other Main Categories or other Admins' scopes at all** — this must be completely invisible (not shown grayed out, not present in dropdowns/menus, no trace of their existence).
- Creates and manages **regular users (POC)** under their own scope, and when doing so must specify which of their assigned Sub Categories **and** which Division that regular user can access (both filters apply together — see §3.3).
- Employee lifecycle actions (upgrade, downgrade, transfer) are performed by **whichever Admin currently has access** to that employee's Sub Category. If an employee transfers from one category to another (e.g. Cook → HR), the transfer is recorded by the Admin who has access to that employee at the time — no separate approval workflow, just a normal edit/action by the scoped Admin.

### 3.3 Regular User (POC)
- Scoped by **both** Division (as today) **and** the specific Sub Category(ies) granted by their creating Admin.
- Since an Admin can span multiple Main Categories, a regular user is still pinned to exactly the combination(s) the Admin explicitly grants — Admin decides which category + which division a given regular user can see (not automatically all of the Admin's categories).

---

## 4. Employee Master — New Tab

- Current tabs: **Active**, **Resigned**.
- Add new tab: **Other Employees**.
- Scoping behavior per Admin:
  - **Active** and **Resigned** tabs now show only employees within *that Admin's* assigned Sub Category(ies).
  - **Other Employees** tab shows all employees **outside** that Admin's scope (other Sub Categories, other Main Categories entirely) — **read-only**.
- **Super Admin** sees everything across all three tabs, unscoped, with filter/drill-down capability by Main Category / Sub Category.

---

## 5. Explicitly Out of Scope / Confirmed Non-Requirements

- No data migration needed right now — existing flat Skilled/Semi-Skilled/Unskilled test data can be discarded and re-entered fresh once the new structure is live.
- No manual "first Super Admin" onboarding flow needed in the app — this will be handled directly via a database update/seed after deployment; the app does not need a special first-run wizard for this.
- No approval workflow needed for employee upgrade/downgrade/transfer — a normal edit by the scoped Admin is sufficient.

---

## 6. Summary Example

```
Main Category: HR
  ├─ Skilled       → Role Label: "Data Entry Operator"
  ├─ Semi-Skilled  → Role Label: "Office Staff"
  └─ Unskilled     → Role Label: "Attender"

Main Category: Cook
  ├─ Skilled       → Role Label: "Cook"
  ├─ Semi-Skilled  → Role Label: "Chopper"
  └─ Unskilled     → Role Label: "Cleaner"

Main Category: Driver
  ├─ Skilled       → Role Label: "Driver"
  └─ Unskilled     → Role Label: "Helper"
  (No Semi-Skilled defined — allowed)

Admin A → scoped to: HR › Unskilled
Admin B → scoped to: HR › Skilled + HR › Semi-Skilled
Admin C → scoped to: Cook › Unskilled + Driver › Unskilled

Super Admin → sees/manages everything, creates Main/Sub Categories,
              creates Admins & Super Admins, assigns scopes,
              does not create contracts or mark attendance directly.
```

---

## 7. Build Instructions for Antigravity

Please implement this as a schema and permission-layer change:

1. Introduce `MainCategory` and `SubCategory` entities (Sub Category has: parent Main Category ID, Skill Level enum, editable Role Label text, stable internal ID).
2. Replace the flat `Category` field on Contract/Employee with a foreign key to `SubCategory`.
3. Introduce `AdminCategoryScope` as a many-to-many join table between Admin users and SubCategory (supports multi-category admins and multi-admin-per-category).
4. Add `SuperAdmin` as a distinct role above Admin, with its own permission set as described in §3.1.
5. Update all visibility/query filters (contracts, vendors, employees, ledgers, documents, attendance) to respect Sub Category scoping per §3.2, with the vendor-identity exception in §3.2.
6. Add the "Other Employees" tab to Employee Master, with scoping logic per §4.
7. Update every UI location currently displaying flat `Category` to instead show the breadcrumb `Main Category › Skill Level › Role Label`.
8. Update contract numbering/ledger/document numbering to run independently per Sub Category.
9. Build the Super Admin screens: Main Category management, Sub Category management (with skip-a-level support), Admin/Super Admin creation with multi-select category-scope assignment, and a cross-category oversight view with filtering.
10. No data migration script required — build against a clean/empty category structure.
