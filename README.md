# ShopEase - E-Commerce Product Listing App

A scalable Flutter e-commerce application built with clean architecture principles, featuring product browsing, search, wishlists, and offline support.

## Architecture

This project follows a **Feature-Based Architecture** with **Repository Pattern** for clean separation of concerns:

```
lib/
├── core/                   # Shared utilities & components
│   ├── constants/          # API endpoints, storage keys
│   ├── network/            # Dio API client, connectivity service
│   ├── storage/            # GetStorage wrapper for local persistence
│   ├── theme/              # App themes (light/dark), theme controller
│   └── widgets/            # Reusable widgets (error, loading, shimmer, product card)
├── data/                   # Data layer
│   ├── models/             # Data models (ProductModel, ProductResponse)
│   ├── providers/          # API data providers (raw HTTP calls)
│   └── repositories/       # Repository pattern (data source abstraction)
├── modules/                # Feature modules
│   ├── auth/               # Login (controller, binding, screen)
│   ├── home/               # Product listing (controller, binding, screen)
│   ├── product_detail/     # Product details (controller, binding, screen)
│   └── wishlist/           # Wishlist (controller, binding, screen)
├── routes/                 # App routing configuration
└── main.dart               # App entry point & dependency injection
```

### Key Architecture Decisions:

- **Repository Pattern**: `ProductRepository` abstracts data sources - fetches from API when online, falls back to cached data when offline
- **Provider Layer**: `ProductProvider` handles raw API communication via Dio
- **GetX Bindings**: Each route has its own binding for lazy dependency injection, preventing unnecessary memory usage
- **Separation of Concerns**: UI → Controller → Repository → Provider → API

## State Management

**GetX** is used for state management across the app:

- **Reactive State (.obs)**: Used for UI-bound reactive variables (product list, loading states, errors)
- **GetxController**: Business logic lives in controllers, one per feature module
- **GetView**: Screens extend `GetView<Controller>` for clean controller access
- **Obx Widget**: Granular reactive rebuilds — only the widget wrapped in `Obx` rebuilds when its observed variable changes, avoiding unnecessary rebuilds
- **Global Controllers**: `ThemeController` and `WishlistController` are initialized globally since they're needed across multiple screens

## Offline Storage

**GetStorage** is used for local data persistence:

- **Product Caching**: First page of products is cached locally. When the device is offline, cached products are displayed
- **Wishlist Persistence**: Wishlist product IDs are stored locally and persist across sessions
- **Theme Preference**: Dark/light mode preference is saved and restored on app launch
- **Auth State**: Login state persists across app restarts

### Offline Flow:
1. On first load, products are fetched from API and cached locally
2. On subsequent loads without internet, cached products are shown
3. Wishlist works fully offline as IDs are stored locally
4. A clear "No internet" error with retry button is shown when cache is unavailable

## Features

- **Dummy Authentication** - Login with any email/password (min 6 chars)
- **Product Listing** - Grid view with product cards showing image, title, price, rating, discount
- **Pagination** - Infinite scroll loading (20 products per page)
- **Pull-to-Refresh** - Swipe down to refresh product list
- **Search** - Search products by name with API-backed search
- **Product Details** - Full product info with image gallery, specs, reviews
- **Wishlist** - Add/remove favorites with swipe-to-dismiss, persisted offline
- **Dark Mode** - Toggle dark/light theme, preference saved locally
- **Shimmer Loading** - Skeleton loading placeholders while data loads
- **Error Handling** - No internet, timeout, empty state with retry mechanism
- **Responsive UI** - Adapts grid columns based on screen width

## Error Handling

| Scenario | Handling |
|----------|----------|
| No Internet | Shows offline icon with message + retry button; falls back to cache if available |
| API Timeout | Shows timeout message with retry button (15s timeout configured) |
| Empty State | Shows appropriate message with refresh option |
| Load More Failure | Shows snackbar, keeps existing data intact |

## How to Run

### Prerequisites
- Flutter SDK (3.13+)
- Dart SDK
- Android Studio / VS Code
- Android Emulator or physical device

### Steps

```bash
# 1. Navigate to project directory
cd ecommerce_app

# 2. Get dependencies
flutter pub get

# 3. Run the app
flutter run

# 4. Build APK
flutter build apk --release
```

### Test Credentials
- Email: any valid email format (e.g., test@example.com)
- Password: any string with 6+ characters

## Dependencies

| Package | Purpose |
|---------|---------|
| get | State management, routing, DI |
| dio | HTTP client with timeout & interceptors |
| get_storage | Local key-value storage |
| connectivity_plus | Network connectivity detection |
| cached_network_image | Image caching & placeholders |
| shimmer | Loading skeleton animations |

## API

Base URL: `https://dummyjson.com`

| Endpoint | Description |
|----------|-------------|
| GET /products?limit=20&skip=0 | Paginated product list |
| GET /products/search?q=query | Search products |
| GET /products/{id} | Single product details |
