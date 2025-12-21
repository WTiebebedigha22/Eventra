Eventra: Effortless Event Planning & Booking 🚀

Eventra is a modern mobile application built with Flutter, designed to seamlessly connect event planners (vendors) with customers looking to organize or book services for their events. We take the complexity out of event management and service procurement, making planning smooth, fast, and transparent.

✨ Features

🔍 Discover Planners: Easily browse and search for professional event planners and vendors based on location, ratings, and service categories.

💬 Direct Messaging: Instant, in-app chat functionality to communicate directly with planners, backed by a real-time database.

📅 Booking & Scheduling: Streamlined process for booking services and managing the event schedule with secure transaction handling.

⭐️ Ratings & Reviews: Customers can provide feedback and ratings, helping the community choose reliable planners.

🗺️ Geo-Location Services: Integrate external APIs for map visualization, planner location tracking, and distance calculations.

🛠️ Technology Stack & Architecture

Eventra leverages a powerful, scalable, and entirely serverless mobile architecture.

📱 Frontend (Client)

Flutter: The UI toolkit for building natively compiled applications for mobile.

Dart: The fast, object-oriented language that powers Flutter.

☁️ Backend & Services

Firebase Authentication: Handles secure user sign-up and login for both customers and planners.

Firestore: A flexible, scalable, and real-time NoSQL cloud database used for storing event details, user profiles, planner portfolios, and chat messages.

Firebase Storage: Used for storing media assets like planner portfolio images and user profile pictures.

External API Integrations: Utilized for critical functions, including:

Google Maps Platform: For location-based searching and routing.

Payment Gateways (e.g., Stripe/Razorpay SDKs): For secure booking transactions and deposits.

Other Web Services: For specialized features like AI-driven event suggestions or complex data analysis.

💻 Getting Started

This project is a starting point for the Eventra mobile application.

Prerequisites

Flutter SDK: Make sure you have the Flutter SDK installed on your machine.

IDE: An IDE like VS Code or Android Studio with the Flutter and Dart plugins installed.

Firebase Project: You must have an active Firebase project with Firestore, Authentication, and Storage enabled.

Installation and Setup

Clone the repository:

git clone [https://github.com/wtiebebedigha22/eventra.git](https://github.com/wtiebebedigha22/eventra.git)


Navigate to the project directory:

cd eventra


Add Firebase Configuration:

Follow the instructions to add Firebase to your Flutter project (using the flutterfire configure command is recommended).

Ensure your google-services.json (Android) and GoogleService-Info.plist (iOS) files are correctly placed.

Install dependencies:

flutter pub get


Run the app:

flutter run


Note: Ensure you have an active emulator or a physical device connected.

📚 Resources

For help getting started with Flutter development, view the official resources:

Lab: Write your first Flutter app

Cookbook: Useful Flutter samples

Flutter Online Documentation

Happy Event Planning with Eventra!