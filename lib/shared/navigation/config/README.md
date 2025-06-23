# Navigation Configuration

This directory contains the modular routing configuration for the Aina Flutter app.

## File Structure

- **`routes.dart`** - Main router configuration that imports all route modules
- **`auth_routes.dart`** - Authentication routes (login, code verification)
- **`home_routes.dart`** - Home feature routes with shell route and tab bar
- **`mall_routes.dart`** - Mall feature routes with shell route and tab bar
- **`coworking_routes.dart`** - Coworking feature routes with shell route and tab bar
- **`misc_routes.dart`** - Miscellaneous standalone routes

## Architecture

Each route module is organized as a class with static properties:

```dart
class FeatureRoutes {
  static List<RouteBase> routes = [...]; // For simple routes
  static ShellRoute shellRoute = ...; // For routes with shell/tab bar
}
```

### Shell Routes

Features that have tab bars use `ShellRoute` to wrap their child routes:

- **Home**: Uses `HomeTabBarScreen` 
- **Mall**: Uses `MainTabBarScreen`
- **Coworking**: Uses `CoworkingTabBarScreen`

### Route Organization

- **Authentication routes** are at the top level (no shell)
- **Feature routes** are grouped by functionality
- **Miscellaneous routes** include standalone pages like splash, notifications, etc.

## Benefits

1. **Modularity**: Each feature's routes are in their own file
2. **Maintainability**: Easier to find and modify specific routes
3. **Scalability**: Easy to add new features without touching other route definitions
4. **Clarity**: Clear separation of concerns

## Usage

To add a new route:

1. Identify which module it belongs to
2. Add the route to the appropriate file
3. No changes needed in the main `routes.dart` file

To add a new feature module:

1. Create new `feature_routes.dart` file
2. Follow the existing pattern
3. Import and add to main `routes.dart` 