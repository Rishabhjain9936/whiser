# 📱 Whisper App  

Whisper is a voice-first communication app built using Flutter and Firebase, designed to provide seamless and secure voice interactions. The app focuses on real-time audio recording, playback, and storage, while also enabling community-driven discovery of voice notes.  

---

## 🚀 Features  

- 🎙️ **Voice Recording** – Record, pause, resume, and save audio with ease  
- 📂 **Cloud Storage** – Upload audio files to Firebase Storage with metadata saved in Firestore  
- 🗺️ **Location Tagging** – Save the location where recordings are made using Google Maps & Geocoding  
- 🔊 **Playback Support** – Listen to your saved recordings anytime  
- 🔐 **Secure Authentication** – Firebase Auth for user login/signup  
- ⚡ **Smooth UI/UX** – Built with Riverpod for state management  

### 🌟 Advanced Features  
- 😀 **Upload with Emoji** – Add an emoji to express the mood of your voice note  
- 🔑 **Password-Protected Notes** – Lock sensitive recordings with a password  
- 👤 **Anonymous Uploads** – Share thoughts without revealing identity  
- 💬 **Comments & Likes** – Interact with others’ voice notes through reactions  
- 📡 **Nearby Discovery** – Use a radius slider to find voice notes recorded near your location  
- 🔍 **Search & Filter** – Quickly find notes by tags, emoji, or location  

---

## 🛠️ Tech Stack  

- **Frontend**: Flutter (Dart)  
- **State Management**: Riverpod  
- **Backend & Auth**: Firebase Auth  
- **Database**: Firestore  
- **Storage**: Firebase Storage  
- **Location Services**: Google Maps + Geocoding  
- **Audio**: just_audio, record  

---

## 📸 Screenshots  

### 🚀 Splash Screen  
<p align="center">
   <img src="https://github.com/user-attachments/assets/63bf7f7a-c41e-450e-8d3c-19e56cf81a26" width="250" />
 
</p>

### 🏠 Home Screen  
<p align="center">


  <img src="https://github.com/user-attachments/assets/e6a744d2-6943-4483-a7d6-b9674ca10fe0" width="250" />


   <img src="https://github.com/user-attachments/assets/f90bdaed-958a-40d5-ba7c-0e3f15463553" width="250" />
     <img src="https://github.com/user-attachments/assets/19afdde5-0739-4d41-8794-87b0a57c5882" width="250" />
    <img src="https://github.com/user-attachments/assets/35718e09-4aa1-4d2b-9e3b-15333d2d3a50" width="250" />
     </p>
 
 


### 🌍 Explore & Location  
<p align="center">

 <img src="https://github.com/user-attachments/assets/b357143f-bf42-4531-9302-4ff22d64c473" width="250" />
  <img src="https://github.com/user-attachments/assets/3677c5e8-4571-495e-aed2-58a689770fcd" width="250" />

  <p align="center">
  <img src="https://github.com/user-attachments/assets/2b574b2e-3ea1-4f95-b0b3-0548d8dad9ed" width="250" />

</p>
  
</p>


### 👤 Profile & History

<p align="center">
  <img src="https://github.com/user-attachments/assets/3d6872a6-07a7-40ee-936d-3dd48a03d643" width="250" />
  <img src="https://github.com/user-attachments/assets/cfda9a57-7a04-4bdb-8965-5f14bae8f40e" width="250" />
</p>

---

## ⚡ Installation & Setup  

### Prerequisites  
- Install [Flutter](https://docs.flutter.dev/get-started/install)  
- Firebase project setup (Auth, Firestore, Storage)  
- Google Maps API key  

### Steps  
```bash
# Clone the repository
git clone https://github.com/Rohanxx10/Whisper.git

# Navigate into the project
cd whisper-app

# Install dependencies
flutter pub get

# Run the app
flutter run
