<h1 align="center">
  <img src="https://img.shields.io/badge/Aura-Social%20Media%20App-6C63FF?style=for-the-badge&logo=flutter&logoColor=white" alt="Aura" />
</h1>

<p align="center">
  A modern, feature-rich social media application built with Flutter & Supabase — inspired by the best of Instagram.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=flat-square&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Cloudinary-Media%20Storage-3448C5?style=flat-square&logo=cloudinary&logoColor=white" />
  <img src="https://img.shields.io/badge/Hive-Local%20Storage-FFCA28?style=flat-square&logo=hive&logoColor=black" />
  <img src="https://img.shields.io/badge/BLoC-State%20Management-13B9FD?style=flat-square" />
</p>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔐 **Authentication** | Sign up, login, forgot password & email-based password reset |
| 🏠 **Home Feed** | Scrollable post feed with likes, comments & saves |
| 📸 **Create Posts** | Upload photos/videos from camera or gallery via Cloudinary |
| 🎬 **Reels** | Short-form video feed with smooth playback |
| 🔍 **Explore / Search** | Search users and posts, tap to view post details |
| 💬 **Messaging** | Real-time 1-to-1 chat with push notification alerts |
| 🔔 **Notifications** | Push notifications for likes, comments, follows & messages |
| 👤 **Profile** | View followers / following, saved posts, edit profile |
| ⚙️ **Settings** | Dark mode toggle, private account, pause notifications, switch accounts, logout |
| 🤝 **Followers & Following** | Lists with "Friends" badge when mutual follow detected |
| 💾 **Offline Support** | Hive-powered local caching for recent chats & preferences |
| 🤖 **AI Chat Support** | Prototype AI-powered customer service chatbot |

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend & Auth**: [Supabase](https://supabase.com/) (PostgreSQL + Realtime)
- **Media Storage**: [Cloudinary](https://cloudinary.com/)
- **Local Storage**: [Hive](https://pub.dev/packages/hive)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (BLoC / Cubit)
- **Push Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Fonts**: [Google Fonts](https://pub.dev/packages/google_fonts)

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>= 3.x`
- A [Supabase](https://supabase.com/) project
- A [Cloudinary](https://cloudinary.com/) account

### 1. Clone the repository

```bash
git clone https://github.com/shar2awyz/Aura.git
cd Aura
```

### 2. Configure environment variables

Create a `.env` file in the project root (this file is git-ignored for security):

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_cloudinary_upload_preset
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the app

```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── components/      # Shared UI widgets
│   ├── services/        # Global services (notifications, etc.)
│   ├── theme/           # App theme & colors
│   └── utils/           # Helper utilities
├── features/
│   ├── auth/            # Login, Register, Password Reset
│   ├── camera/          # Camera capture
│   ├── comments/        # Post comments
│   ├── home/            # Home feed
│   ├── messages/        # Real-time chat
│   ├── notifications/   # Push notifications
│   ├── post/            # Create & view posts
│   ├── profile/         # User profile & settings
│   ├── reels/           # Short videos
│   ├── search/          # Explore & search
│   ├── shell/           # App shell / navigation
│   └── splash/          # Splash / onboarding screen
└── main.dart
```

---

## 🔒 Security

- All sensitive credentials are stored in a local `.env` file which is **excluded from version control** via `.gitignore`.
- Never commit your `.env` file or share your Supabase/Cloudinary keys publicly.

---

## 🤝 Contributing

Contributions, issues and feature requests are welcome! Feel free to open a pull request or file an issue.

---

## 📄 License

This project is licensed under the **MIT License**.

---

<p align="center">Made with ❤️ using Flutter</p>
