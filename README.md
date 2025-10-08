# 🌐 Pantheon Learn

**Pantheon Learn** is an interactive web platform built with **Flutter Web** that helps students master English vocabulary and multiple-choice questions through intelligent assistance and gamified learning systems.

Deployed on **GitHub Pages**, powered by **OpenRouter AI** (for intelligent responses) and **Vercel** (for secure API key management).

---

## 🚀 Features

### 🧠 Intelligent AI Assistant
- Provides contextual explanations and personalized feedback powered by **OpenRouter AI**.
- Supports both **question generation** and **answer evaluation**.
- Smooth interaction experience optimized for education scenarios.

### 📚 Vocabulary System
- Includes categorized word lists for **PSLE** and **O-Level** levels.
- Each entry includes:
  - English meaning(s)
  - Chinese meaning(s)
  - Built-in **Text-to-Speech (TTS)** pronunciation.
- Lazy-loaded dictionary ensures faster app startup and smoother navigation.

### 🎛️ Settings & Customization
- **Volume Control** with smooth slider interaction.
- **Light / Dark Mode** switch (saved via `SharedPreferences`).
- Persistent **user history** and preferences saved locally.

### ⚔️ Combo Learning System
- Earn **combo points** for consecutive correct answers.
- Encourages consistency and engagement in practice sessions.
- Motivates learners through progress-based reinforcement.

---

## 🧩 Technology Stack

| Layer | Technology |
|-------|-------------|
| Frontend | Flutter Web |
| Backend / API | OpenRouter AI via Vercel proxy |
| Storage | SharedPreferences (local), IndexedDB (web) |
| Deployment | GitHub Pages |
| Build Tools | Flutter SDK |

---

## 🔑 API & Security

Pantheon Learn uses **Vercel Serverless Functions** as a secure middleware to handle AI API requests.  
API keys are never exposed to the client side — ensuring **data security and privacy**.

---

## 🖥️ Run Locally

To run the project on your local environment:

```bash
git clone https://github.com/<your-username>/pantheon-learn.git
cd pantheon-learn
flutter pub get
flutter run -d chrome
