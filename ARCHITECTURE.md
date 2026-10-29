# 🏛️ CookMate — Architectural Specification & Engineering Blueprint

> **CookMate** is an offline-first, luxury editorial culinary discovery and companion mobile application engineered with Flutter, Dart, Riverpod, and Material Design 3.

---

## 📑 Table of Contents
1. [Architectural Overview & Core Principles](#1-architectural-overview--core-principles)
2. [System Architecture Diagram](#2-system-architecture-diagram)
3. [Navigation Hierarchy & PopScope Routing](#3-navigation-hierarchy--popscope-routing)
4. [State Management & Data Flow (Riverpod)](#4-state-management--data-flow-riverpod)
5. [Authentication & Cryptographic Vault](#5-authentication--cryptographic-vault)
6. [Photo Processing & Beauty Engine](#6-photo-processing--beauty-engine)
7. [Chef AI Recipe Synthesis & Autofill Pipeline](#7-chef-ai-recipe-synthesis--autofill-pipeline)
8. [Synchronized Cooking Timer State Machine](#8-synchronized-cooking-timer-state-machine)
9. [Responsive Layout & Cross-Device Strategy](#9-responsive-layout--cross-device-strategy)
10. [Folder & Package Structure](#10-folder--package-structure)

---

## 1. Architectural Overview & Core Principles

CookMate follows **Feature-First Clean Architecture** with strict layer separation, deterministic dependency injection, and unidirectional reactive state flow.

```
┌──────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  (Widgets, Screens, Slivers, Animations, Glass Surfaces)     │
└──────────────────────────────┬───────────────────────────────┘
                               │ Watches / Listens
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
│      (Riverpod Notifiers, StateProviders, Selectors)         │
└──────────────────────────────┬───────────────────────────────┘
                               │ Invokes / Orchestrates
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                       Domain Layer                           │
│ (Entities, Models, Pure Business Logic, Scalers, Validators) │
└──────────────────────────────┬───────────────────────────────┘
                               │ Implements Interfaces
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│  (Repositories, SharedPreferences, JSON Assets, Vault, GCS)  │
└──────────────────────────────────────────────────────────────┘
```

### Core Engineering Invariants:
1. **Offline-First Resilience**: All core capabilities—recipe exploration, multi-criteria search, ingredients scaling, cooking timers, chef registration, and local community submissions—function seamlessly without an active internet connection.
2. **Unidirectional Data Flow**: State flows downward from Riverpod providers to presentation widgets; user events trigger methods on Notifiers, which mutate state immutably.
3. **Defensive Layout Constraints**: Every viewport orientation (portrait, compact landscape, tablet, desktop) enforces bounded constraints (`LayoutBuilder`, `SingleChildScrollView`, `ConstrainedBox`), guaranteeing **0 pixel overflow** under all form factors.
4. **Guaranteed Back Navigation**: Every route and nested shell utilizes Flutter 3.22+ `PopScope` handlers with intelligent fallbacks (`context.canPop() ? context.pop() : context.go('/')`) and an accidental-exit prevention toast on Home.

---

## 2. System Architecture Diagram

```mermaid
graph TD
    subgraph UI ["Presentation Layer (Flutter 3.22+)"]
        Home["HomeScreen (Discovery & Hero Deck)"]
        Explore["ExploreScreen (Categorized Grid)"]
        Search["SearchScreen (Prefix & Accent Match)"]
        Saved["FavoritesScreen (Saved Recipes)"]
        Detail["RecipeDetailScreen (Scaling & Steps)"]
        TimerSheet["CookingTimerSheet (Synchronized Timer)"]
        Profile["ProfileScreen (Chef Identity & Vault)"]
        Auth["SignInScreen / SignUpScreen"]
        Submit["SubmitRecipeScreen (AI Auto-Fill)"]
    end

    subgraph State ["Application & State Layer (Riverpod)"]
        AllRecProv["allRecipesProvider"]
        SearchProv["searchFilterProvider & searchResultsProvider"]
        FavNotifier["favoritesNotifierProvider"]
        AuthNotifier["authNotifierProvider"]
        ThemeProv["themeModeProvider"]
        DetailProv["recipeDetailProvider(id)"]
    end

    subgraph Domain ["Domain Layer (Business Logic)"]
        RecipeModel["Recipe Model & Scaler"]
        SearchEngine["RecipeSearchEngine (Levenshtein + Prefix)"]
        AutofillService["SmartRecipeAutofillService"]
        AvatarService["AvatarImageService (Cropper & Filters)"]
        AuthValidator["PasswordValidator & EmailValidator"]
    end

    subgraph Data ["Data Layer & Local Vault"]
        JsonSeed["LocalJsonRecipeDataSource (recipes.json)"]
        RecipeRepo["DefaultRecipeRepository"]
        FavRepo["LocalFavoritesRepository (Prefs)"]
        AuthRepo["LocalAuthRepository (SHA-256 Vault)"]
        DiskStore["App Document Storage (Avatars & Drafts)"]
    end

    Home --> AllRecProv
    Home --> ThemeProv
    Explore --> AllRecProv
    Search --> SearchProv
    Saved --> FavNotifier
    Detail --> DetailProv
    Detail --> TimerSheet
    Profile --> AuthNotifier
    Auth --> AuthNotifier
    Submit --> AutofillService

    AllRecProv --> RecipeRepo
    SearchProv --> SearchEngine
    FavNotifier --> FavRepo
    AuthNotifier --> AuthRepo
    DetailProv --> RecipeRepo

    RecipeRepo --> JsonSeed
    RecipeRepo --> DiskStore
    FavRepo --> DiskStore
    AuthRepo --> DiskStore
    AvatarService --> DiskStore
```

---

## 3. Navigation Hierarchy & PopScope Routing

CookMate utilizes **GoRouter** with a persistent `StatefulShellRoute` for seamless branch transitions and standalone root navigator routes for detailed flows.

```mermaid
flowchart TD
    Splash["/splash (SplashScreen)"] -->|Countdown Complete| Shell["/ (ResponsiveScaffold Shell)"]

    subgraph ShellNav ["Stateful Shell Tabs (Swipe & Nav Bar)"]
        Tab0["Branch 0: / (Home)"]
        Tab1["Branch 1: /recipes (Explore)"]
        Tab2["Branch 2: /search (Search)"]
        Tab3["Branch 3: /favorites (Saved)"]
    end

    Shell --> ShellNav

    subgraph RootRoutes ["Root Navigator Routes (Pushed Over Shell)"]
        DetailRoute["/recipes/:recipeId (RecipeDetailScreen)"]
        SubmitRoute["/submit (SubmitRecipeScreen)"]
        ProfileRoute["/profile (ProfileScreen)"]
        SignInRoute["/sign-in (SignInScreen)"]
        SignUpRoute["/sign-up (SignUpScreen)"]
    end

    Tab0 -.->|Tap Recipe Card| DetailRoute
    Tab0 -.->|Tap Search Bar| Tab2
    Tab0 -.->|Tap Chef Avatar| ProfileRoute
    Tab0 -.->|Tap Center FAB| SubmitRoute

    ProfileRoute -.->|Guest Taps Sign In| SignInRoute
    SignInRoute -.->|New Chef Taps Register| SignUpRoute
    SignUpRoute -.->|Account Created| ProfileRoute

    subgraph PopLogic ["Intelligent Back Navigation Fallback"]
        HardwareBack{"Phone Back Pressed"}
        HardwareBack -->|On Detail / Profile / Submit| CanPop1{"context.canPop()?"}
        CanPop1 -->|Yes| PopStack["context.pop() (Previous Screen)"]
        CanPop1 -->|No| GoHome["context.go('/') (Safe Home Return)"]

        HardwareBack -->|On Tabs 1, 2, or 3| SwitchTab0["_onDestinationSelected(0) -> Jump to Home"]

        HardwareBack -->|On Home Tab 0| CheckTimer{"Time since last press < 2s?"}
        CheckTimer -->|No| ShowToast["Show Floating Toast: Press back again to exit"]
        CheckTimer -->|Yes| ExitApp["SystemNavigator.pop() -> Clean Exit"]
    end
```

---

## 4. State Management & Data Flow (Riverpod)

State management in CookMate is strictly reactive, asynchronous, and memory-safe.

```mermaid
graph LR
    subgraph UI_Events ["User Actions"]
        T1["Toggle Favorite Heart"]
        T2["Type Search Keyword"]
        T3["Adjust Recipe Servings"]
        T4["Sign In / Register"]
    end

    subgraph Riverpod_Notifiers ["Riverpod Application Layer"]
        FNot["favoritesNotifierProvider<br/>(AsyncNotifier&lt;Set&lt;String&gt;&gt;)"]
        SNot["searchFilterProvider<br/>(StateProvider&lt;SearchFilterState&gt;)"]
        ANot["authNotifierProvider<br/>(AsyncNotifier&lt;UserProfile?&gt;)"]
    end

    subgraph Selectors ["Computed & Filtered Selectors"]
        FRec["favoriteRecipesProvider"]
        SRec["searchResultsProvider"]
    end

    subgraph Persistence ["Local Disk & Preferences"]
        SP["SharedPreferences ('favorite_recipe_ids')"]
        Vault["SharedPreferences ('cookmate_user_vault_v1')"]
    end

    T1 -->|optimistic toggle| FNot
    FNot -->|writes JSON| SP
    FNot -->|triggers| FRec

    T2 -->|updates query| SNot
    SNot -->|re-runs ranker| SRec

    T4 -->|authenticates| ANot
    ANot -->|stores hashed token| Vault
```

---

## 5. Authentication & Cryptographic Vault

CookMate incorporates a local hashed security vault simulating bank-grade authentication with zero network dependencies.

```mermaid
sequenceDiagram
    autonumber
    actor User as Chef User
    participant Screen as SignUp / SignIn Screen
    participant Validator as PasswordValidator
    participant Notifier as AuthNotifier
    participant Repo as LocalAuthRepository
    participant Storage as SharedPreferences (Vault)

    User->>Screen: Enters Email & Password
    Screen->>Validator: Validate format & calculate strength score
    Validator-->>Screen: Strength: 0-4 (Weak / Fair / Strong / Formidable)

    User->>Screen: Taps 'Create Chef Account'
    Screen->>Notifier: register(name, email, password)
    Notifier->>Repo: createUser(...)
    Repo->>Repo: Check if email exists (Unique constraint)
    Repo->>Repo: Salt & Hash password via SHA-256
    Repo->>Storage: Persist serialized UserProfile JSON in secure vault
    Storage-->>Repo: Saved OK
    Repo->>Storage: Update 'cookmate_active_user_session_v1'
    Repo-->>Notifier: Returns UserProfile instance
    Notifier-->>Screen: State updated to Authenticated
    Screen-->>User: Welcomes Chef to kitchen with toast
```

---

## 6. Photo Processing & Beauty Engine

When updating their Chef Portrait, users can capture a fresh selfie via the front camera or choose an existing portrait from their phone gallery. The image is processed through an automated background image manipulation pipeline.

```mermaid
flowchart LR
    Source["Camera / Gallery Source"] --> RawBytes["Raw Image Bytes (Uint8List)"]
    RawBytes --> Recover{"Android recreate loss?"}
    Recover -->|Yes| LostService["pickerService.retrieveLostData()"]
    Recover -->|No| Worker["Background Compute Worker"]
    LostService --> Worker

    subgraph Processor ["AvatarImageService & Beautification Engine"]
        Decode["Decode raw JPEG/PNG"]
        Crop["Calculate min(w, h) and center-crop to 1:1 Square"]
        Scale["Downscale to 720x720 (Memory Protection)"]
        Filter{"Beauty Filter Selection"}
        
        Filter -->|Radiant Glow| F1["+12% Brightness, +18% Contrast, +15% Warm Tint"]
        Filter -->|Fresh & Crisp| F2["+8% Contrast, +25% Saturation, Cool White Balance"]
        Filter -->|Warm Sunset| F3["+20% Red Tone, +10% Green Tone, Golden Highlights"]
        Filter -->|Studio Clean| F4["Histogram Normalized Balance & Smooth Specular"]

        F1 --> Encode["Encode to High-Quality JPEG (88% Quality)"]
        F2 --> Encode
        F3 --> Encode
        F4 --> Encode
    end

    Worker --> Processor
    Encode --> Disk["Save to App Docs Dir (chef_avatar_<timestamp>.jpg)"]
    Disk --> Profile["Update UserProfile.avatarUrl & Notify UI"]
```

---

## 7. Chef AI Recipe Synthesis & Autofill Pipeline

When sharing a new kitchen creation, CookMate's **Chef AI Auto-Fill Engine** automatically analyzes the dish title and category, generating complete culinary specifications and fetching verified authentic photography from Unsplash.

```mermaid
flowchart TD
    InputTitle["User enters Recipe Title<br/>(e.g., 'Red Velvet Cake')"] --> Analyze["SmartRecipeAutofillService.generateSuggestion()"]
    InputCategory["Optional Category Hint<br/>(e.g., 'Desserts')"] --> Analyze

    Analyze --> MatchCategory["Rule-based & keyword culinary classifier"]
    MatchCategory --> KnownCheck{"Is Signature Dish?<br/>(Red Velvet, Lasagna, Carbonara, Biryani, Tacos)"}

    KnownCheck -->|Yes| SignatureProfile["Load Authentic Gourmet Profile<br/>• Authentic prep/cook durations<br/>• Exact Chef ingredient measurements<br/>• Step-by-step culinary instructions<br/>• High-Res Unsplash CDN Photo URL"]
    KnownCheck -->|No| SynthesisEngine["Dynamic Recipe Synthesizer<br/>• Harmonize spices & base aromatics<br/>• Compute balanced cooking time<br/>• Curate matching Unsplash food collection URL"]

    SignatureProfile --> AutoFillUI["Populate Form Controllers<br/>(Title, Description, Times, Ingredients, Steps, Photo)"]
    SynthesisEngine --> AutoFillUI

    AutoFillUI --> Preview["Live Interactive Photo Preview & Edit"]
    Preview --> Save["User taps 'Publish Recipe'"]
    Save --> LocalDB["Prepend to RecipeRepository in-memory & local storage"]
    LocalDB --> FeedSync["Instant reactive appearance on Home, Explore & Search"]
```

---

## 8. Synchronized Cooking Timer State Machine

Cooking Mode provides an interactive step-by-step workflow with real-time timers synchronized to each cooking instruction.

```mermaid
stateDiagram-v2
    [*] --> Idle: Screen opened with initial duration

    Idle --> Running: Tap 'Start Timer'
    Running --> Paused: Tap 'Pause'
    Paused --> Running: Tap 'Resume'

    Running --> Running: Tap '+30 sec' or '+1 min' (Extends duration)
    Paused --> Paused: Tap '+30 sec' or '+1 min' (Extends duration)

    Running --> Idle: Tap 'Reset'
    Paused --> Idle: Tap 'Reset'

    Running --> Completed: Countdown reaches 00:00
    Completed --> Idle: Tap 'Restart' or navigate to Next Step

    state Completed {
        [*] --> AlarmTriggered: HapticFeedback.heavyImpact()
        AlarmTriggered --> VisualPulse: Glowing Coral Badge & Completion Sound
    }
```

---

## 9. Responsive Layout & Cross-Device Strategy

CookMate guarantees zero pixel overflows across all screen sizes and rotation angles:

| Form Factor | Screen Width / Height | Adaptive Component |
|---|---|---|
| **Mobile Portrait** | `width < 480px` | Translucent Liquid-Glass bottom navigation bar, single-column sliver lists, stacked metric rows. |
| **Compact Landscape** | `width >= 480px` & `height < 500px` | Side `NavigationRail` wrapped in scrollable `LayoutBuilder` with compact icons, preventing vertical overflow. |
| **Tablet / Desktop** | `width >= 840px` | Expanded `NavigationRail` with persistent labels, multi-column grid (`SliverGridDelegateWithMaxCrossAxisExtent: 280`), and centered content bounded by `maxContentWidth: 1200px`. |

---

## 10. Folder & Package Structure

```
c:\Users\khero\StudioProjects\CookMate\
├── assets/
│   ├── data/
│   │   └── recipes.json                     # Seed catalogue of 15 gourmet recipes
│   └── images/
│       ├── app_logo.png                     # Transparent 3D chef logo badge
│       └── splash_preview.png               # High-res splash illustration
├── lib/
│   ├── main.dart                            # Application entry point with ProviderScope
│   ├── app/
│   │   ├── app.dart                         # MaterialApp.router with Theme configuration
│   │   └── router.dart                      # GoRouter StatefulShellRoute & route transitions
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart           # Categories, breakpoints, shared pref keys
│   │   └── theme/
│   │       ├── app_colors.dart              # Gourmet color palette (Forest Green, Citrus Lime, etc.)
│   │       └── app_theme.dart               # Material 3 light/dark ThemeData & typography
│   ├── features/
│   │   ├── auth/                            # Authentication & Chef Profile feature
│   │   │   ├── data/repositories/           # LocalAuthRepository (SHA-256 hashed vault)
│   │   │   ├── domain/
│   │   │   │   ├── models/user_profile.dart # UserProfile entity
│   │   │   │   └── services/                # AvatarImageService & PasswordValidator
│   │   │   └── presentation/                # ProfileScreen, SignInScreen, SignUpScreen
│   │   ├── favorites/                       # Saved recipes bookmarking feature
│   │   ├── home/                            # Discovery screen & hero carousel
│   │   ├── recipes/                         # Catalog, details, scaling & search features
│   │   │   ├── domain/services/             # RecipeScaler & RecipeSearchEngine
│   │   │   └── presentation/screens/        # ExploreScreen & RecipeDetailScreen
│   │   ├── search/                          # Real-time search with query params
│   │   ├── splash/                          # 3D logo physics splash screen
│   │   └── submission/                      # Recipe submission & Smart Autofill feature
│   └── shared/
│       └── widgets/                         # Reusable UI components: GlassCard, BounceTap,
│                                            # ChefPickDeck, AppLogoBadge, CookingTimerSheet
└── test/
    ├── unit/                                # Unit tests: scaling, search, auth, autofill, filters
    ├── widget_test.dart                     # UI & responsiveness widget tests
    └── widget_timer_test.dart               # Cooking timer sheet widget tests
```
