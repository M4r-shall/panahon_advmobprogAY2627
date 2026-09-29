# Marius Clarence Panahon
## INF231
## CTAMOBL Advance Mobile Programming

A new Flutter project that focuses on advanced topics. Covering the mobile to web transaction.

Lab Activity Instance

Lab Activity 1: discussion

setState is best for local state inside a widget it rebuilds the whole widget, and provider is best for multiple screens or widgets it keeps business logic separate from the UI and only rebuilds the exact widgets that need updating.

Lab Activity 2: discussion

In this activity, we implemented a structured architecture where the Model, Services, and Screens interact seamlessly to render data from the API endpoint. Model defines the expected JSON structure and maps the API response to Dart objects. Service acts as the networking layer, encapsulating the HTTP fetch logic and converting JSON directly into a list of model instances. Screen triggers the service logic and uses a FutureBuilder to handle the asynchronous states (loading, error, success) and finally binds the fetched model data into the UI components. This separation of concerns closely follows the Provider and Model-View-Controller (MVC) / Model-View-ViewModel (MVVM) inspired design patterns. It makes the codebase much easier to maintain, test, and read by strictly decoupling network and business logic from the user interface.

Lab Activity 3: discussion

In this activity, the Cart and CartProduct models structure the raw API data, while the CartService handles network requests, allowing the CartScreen to display the retrieved data. Because cart items only hold basic details, tapping an item triggers an API call to fetch the complete product information, which is then seamlessly passed to the existing detail_screen.dart to prevent code duplication and reuse the widget. This reinforces a modular design pattern that strictly separates the data models, service logic, and UI screens, making the application easier to maintain and expand when adding features like the new cart screen. Finally, to implement a "get by ID" feature as instructed by the API documentation, the CartService simply appends the target user ID to the endpoint URL, such as fetching from dummyjson, and parses the successful JSON response directly into the Dart model.

Lab Activity 4: discussion

In this activity, the User model structures the authentication data, while the UserService handles the login API request and persists the resulting user data locally using the shared_preferences package. The profile_screen then interacts with this service to retrieve the saved User object, allowing it to instantly render the user's avatar, name, and details without making redundant network calls. This introduces an updated design pattern focused on state persistence and authentication flow, where a splash_screen actively checks the saved token state via _userService.isLoggedIn() to seamlessly route the user to either the signin_screen or the main application. Finally, this persisted data is essential for rendering the cart_screen; by fetching the securely saved user ID from shared_preferences, the application can pass this specific ID directly to the CartService to query the backend and retrieve only the cart items belonging to the currently authenticated user.


Lab Activity 5: discussion

This lab contrasts a mock authentication workflow against a production-ready one using an abstracted UserService that lets the UI switch between DummyJSON and Firebase without rewriting screen logic. DummyJSON handles login as a basic HTTP call where the app manually manages tokens, but its mock nature means user creation, updates, and deletions are merely simulated and never persist. In contrast, Firebase automatically manages persistent sessions, token refreshes, and server-side security rules, enabling genuine account creation and safe credential management. While the Firebase integration code is fully built to eliminate backend overhead, it currently falls back to DummyJSON (demo credentials: emilys / emilyspass) until project configuration files like google-services.json are provisioned.


Lab Activity 6: discussion

In this activity the chat feature is spread across three Cloud Firestore collections, each holding a different slice of the user structure. The Users collection is the directory of registered accounts, where every document id is the Firebase Auth uid and the same uid is repeated as a field so the authentication identity and the Firestore record can never drift apart; because the app previously stored profile data only in shared_preferences, the write is placed inside UserService.saveFirebaseUserData(), the one method that runs on both signup and every sign-in, which means accounts registered before the collection existed are backfilled the next time they log in rather than needing a migration. The chat_rooms collection is the conversation container, and its document id is derived rather than random: the two participant uids are sorted alphabetically and joined with an underscore, so whichever of the two people opens the conversation first, both resolve to the exact same room and neither ends up writing into a duplicate thread. Each room then owns a messages subcollection whose auto-id documents carry senderId, senderEmail, receiverId, message, timestamp and seen, which is enough for the detail screen to decide alignment, colour and delivery state without ever reading the Users collection back; note that the chat_rooms document itself is created implicitly by that subcollection write and stays empty, which is why the Firestore console renders it in italics. Regarding initiating a chat with yourself, nothing actually breaks, because sorting a pair of identical uids simply collapses the room id to uid_uid: a perfectly valid room is created where senderId equals receiverId, every bubble therefore evaluates isMe as true and renders on the right, and the seen-receipt batch immediately matches the user's own messages and marks them read the instant the screen opens, so the thread degenerates into a notes-to-self scratchpad rather than an error. Enhancement 1 nevertheless filters the logged-in uid out of the chat list so the UI never offers that path, which is the important distinction here: the data model permits a self-chat, while the interface deliberately prevents one. The enhancements build on this structure by adding a client-side search that filters the streamed user list across firstName, lastName, username and email from a single listener, and by redesigning the detail screen with fade-and-slide bubble animations keyed to each document id, a shared Hero avatar between the list and the conversation, and genuine delivery states driven by Firestore's own latency compensation, where metadata.hasPendingWrites shows a clock while the write is unacknowledged, a single check once the server commits it, and a blue double check once the recipient opens the room and the seen flag is batched to true in real time.


