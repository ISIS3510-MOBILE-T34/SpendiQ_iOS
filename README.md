# SpendiQ_iOS
This repository hold the development process of the iOS mobile app version of SpendiQ

# Branch Information
These are the initial Folders and Files in the Swift Programming Language that make up our SpendiQ Project's initial Structure.
The project is organized in folders for our Architecture Pattern (MVVM) plus folders for Helpers, Resources and Services. There are also folders for Logic and UI tests.

To-Do: 
- Add the other Files corresponding to your views (UI) implementation according to Figma
- Install the Firebase library in the project to visualize the previews of the views built.
- Integrate this commit to the main branch.

# 📁 Project Structure

## Folders Tree View inside SpendiQ Main Folder

│ SpendiQ
 
. . . . . . ├ - -Models

. . . . . . ├ - -ViewModels

. . . . . . ├ - -Views

. . . . . . ├ - -Services

. . . . . . ├ - -Helpers

. . . . . . └ - -Resources

The SpendiQ project is organized using the Model-View-ViewModel (MVVM) architecture to ensure a clean separation of concerns and facilitate teamwork. Below is an overview of each folder and its purpose:

## 1. Models
### Purpose:
Define the data structures used throughout the app.

### Key Files:

#### OfferModel.swift
Represents an offer with properties like placeName, offerDescription, recommendationReason, logoName, latitude, longitude, and distance.

#### UserModel.swift 
Represents user data such as firstName, lastName, email, and favoriteShops.

#### ShopModel.swift
Represents shop details including name, logoUrl, location, and category.

## 2. ViewModels
### Purpose:
Handle business logic, data fetching, and prepare data for the Views. They act as intermediaries between Models and Views.

### Key Files:

#### SpecialOffersViewModel.swift
Manages fetching offers, calculating distances based on user location, and updating the UI accordingly.

#### OfferDetailViewModel.swift
Manages the details of a selected offer, including map region setup.

## 3. Views
### Purpose:
Contain all SwiftUI view components that define the app's user interface.

### Key Files:

#### ContentView.swift
Entry point of the app, typically launching the MainMenuView.

#### MainMenuView.swift
Displays the main menu and includes the SpecialOffersAlertView.

#### SpecialOffersAlertView.swift
Shows an alert with nearby special offers and shop logos.

#### SpecialOffersListView.swift
Displays a scrollable list of special offers using OfferBubbleView.

#### OfferBubbleView.swift
Represents each offer in the list with details like name, distance, description, and logo.

#### OfferDetailView.swift
Shows detailed information about a selected offer, including a map and sales details.

## 4. ViewModels
### Purpose:
Handle the business logic and data manipulation, acting as a bridge between Models and Views.

### Key Files:

#### SpecialOffersViewModel.swift
Manages fetching and processing offer data, including distance calculations based on user location.

#### OfferDetailViewModel.swift
Manages the state and data for the OfferDetailView, such as map region configuration.

## 5. Services
### Purpose:
Handle external services and functionalities like data fetching and location management.

### Key Files:

#### DataService.swift
Manages interactions with Firebase Firestore, including fetching offers.

#### LocationManager.swift
Handles location updates and permissions using CoreLocation.

## 6. Helpers
### Purpose:
Contain utility functions, extensions, and any reusable code snippets that assist other parts of the app.

### Key Files:
(Todo: Add the documentation of the files when included)

## 7. Resources
### Purpose:
Store all app assets such as images, icons, and fonts.

### Key Files:

#### Assets.xcassets
Contains all image assets like shop logos (e.g., mcdonalds, puma) and other UI-related images.

#### Fonts
Custom fonts used throughout the app.

## 8. Additional Files
### Purpose:
Support project configuration and setup.

### Key Files:

#### Info.plist
Contains app configurations, including location permission descriptions.

#### GoogleService-Info.plist
Firebase configuration file for initializing Firebase services.
