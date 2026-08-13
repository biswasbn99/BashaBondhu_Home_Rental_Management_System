# Implementation Plan - Unify Dropdown Design

Refactor the dropdown components in the "Find Home" feature to match the `DropdownButtonFormField` style used in the Authentication screens. This ensures a consistent look and feel throughout the application.

## User Review Required

> [!IMPORTANT]
> **Styling Change**: The custom 72px mint-green boxes will be replaced by standard-height `DropdownButtonFormField` widgets with Teal borders.
> [!NOTE]
> **Loading Indicators**: I will implement the loading state using the `suffixIcon` of the `InputDecoration` to maintain the clean look of the form fields while still providing feedback during API calls.

## Proposed Changes

### Feature: Shared Widgets

#### [MODIFY] [filter_dropdown.dart](file:///F:/Ostad/Flutter/bashabondhu_home_rental_management_system/lib/features/shared/presentation/widgets/filter_dropdown.dart)
- Replace `Container` + `DropdownButton` with `DropdownButtonFormField`.
- Remove `_mintBg`, `_disabledBg`, and `_textDark` constants.
- Implement `isLoading` by adding a small `CircularProgressIndicator` to the `suffixIcon` of the `InputDecoration`.
- Ensure `enabled` correctly disables the field and greys out the text.

### Feature: Find Home

#### [MODIFY] [find_home_screen.dart](file:///F:/Ostad/Flutter/bashabondhu_home_rental_management_system/lib/features/find_home/presentation/screens/find_home_screen.dart)
- Verify the layout remains balanced with the new dropdown heights.
- Ensure all dropdowns (Month, House Type, Division, District, Upazila, and Room Count) inherit the new design automatically via the refactored `FilterDropdown`.

## Verification Plan

### Automated Tests
- `fvm flutter analyze`: Verify no compilation errors or type mismatches.

### Manual Verification
1.  Navigate to the **Find Home** screen.
2.  Check that all dropdowns have Teal borders and matching heights.
3.  Observe the loading spinner when divisions or districts are being fetched.
4.  Confirm that dependent dropdowns (like District) remain disabled until a parent value (like Division) is selected.
