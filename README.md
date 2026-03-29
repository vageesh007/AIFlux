<h1 align="center">🚀 PuzzleFlux AI</h1>
<h3 align="center">🧠 AI-Powered Vocabulary Puzzle App (iOS | SwiftUI)</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-blue?style=for-the-badge&logo=apple" />
  <img src="https://img.shields.io/badge/Language-Swift-orange?style=for-the-badge&logo=swift" />
  <img src="https://img.shields.io/badge/Framework-SwiftUI-0A84FF?style=for-the-badge" />
  <img src="https://img.shields.io/badge/AI-On--Device-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Architecture-MVVM-purple?style=for-the-badge" />
</p>

---

## ✨ Overview  
**LexiFlux AI** is an intelligent vocabulary puzzle application that generates **one-word substitution challenges dynamically using on-device AI**.  
Unlike traditional quiz apps with static datasets, LexiFlux AI delivers **infinite, real-time puzzles**, making learning engaging, adaptive, and fun.

---

https://github.com/user-attachments/assets/8767e2d1-1eb3-45c1-922b-b271aedd1828

## 🎯 Key Features  

- 🧠 **AI-Generated Puzzles**  
  Uses Apple’s on-device Foundation Models to generate vocabulary challenges dynamically  

- 🎮 **Interactive Gameplay**  
  Letter-based puzzle solving with real-time validation  

- ⚡ **Scoring & Combo System**  
  Tracks performance with score boosts for consecutive correct answers  

- 💡 **Hint System**  
  Helps users when stuck without breaking the learning flow  

- 🎨 **Smooth Animations & Feedback**  
  Includes haptic feedback, audio cues, ripple effects, and transitions  

- 🔁 **Retry & Validation Logic**  
  Ensures AI-generated content is clean, valid, and non-repetitive  

---

## 🏗️ Tech Stack  

- **Language:** Swift  
- **Framework:** SwiftUI  
- **Architecture:** MVVM (Model-View-ViewModel)  
- **Concurrency:** Async/Await  
- **AI Integration:** Apple Foundation Models (on-device)  
- **UI/UX:** Animations, Haptics, Audio Feedback  

---

## 🧠 How It Works  

### 1. AI Puzzle Generation  
- App sends a structured prompt to the AI model  
- AI returns:
  - Category  
  - Clue  
  - One-word answer  

### 2. Validation Layer  
- Ensures:
  - Single-word output  
  - No invalid characters  
  - No duplicates  
- Retries if validation fails  

### 3. Puzzle Setup  
- Extracts answer letters  
- Adds random characters  
- Shuffles letters for gameplay  

### 4. User Interaction  
- User selects letters  
- Input is matched **character-by-character (prefix matching)**  

### 5. Matching Logic  

- If input matches expected sequence → continue  
- If mismatch → reset input  
- If complete match → success 🎉  

### 6. Game Progression  
- Score increases  
- Combo multiplier applied  
- Next puzzle generated automatically  

---

## 🧩 Architecture  

- **PuzzleManager** → Controls game flow and state  
- **AIService** → Handles AI communication  
- **GameModel** → Stores puzzle data  
- **FeedbackManager** → Haptics & audio  
- **SwiftUI Views** → UI rendering  

---

## ⚙️ Core Concepts  

- Separation of UI and business logic  
- Reactive state updates using SwiftUI  
- Async AI calls for smooth UX  
- Error handling and retry mechanisms  
- Data validation for AI outputs  

---

## 🚧 Challenges Solved  

- Handling **unpredictable AI responses**  
- Avoiding **duplicate or invalid puzzles**  
- Maintaining **smooth UI during async operations**  
- Designing **engaging and responsive gameplay logic**  

---

## 🚀 Future Enhancements  

- 📊 Leaderboard system  
- 🎚️ Difficulty levels  
- 💾 Offline puzzle caching  
- 📈 Analytics tracking  
- 🧪 Unit testing for logic modules  

---

## 📌 Why This Project?  

LexiFlux AI demonstrates:  
- Real-world **AI integration in mobile apps**  
- Strong **problem-solving and validation logic**  
- Clean **architecture and state management**  
- Focus on **user experience and interactivity**  

---

## 👨‍💻 Author  

**Vageesh Singh**  
MCA Student | Software Developer | AI Enthusiast  

---

## ⭐ If you like this project  
Give it a star ⭐ and feel free to contribute!
