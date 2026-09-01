# Marius Clarence Panahon
## INF231
## CTAMOBL Advance Mobile Programming

A new Flutter project that focuses on advanced topics. Covering the mobile to web transaction.

**Lab Activity 4: discussion**

In this activity, the User model structures the authentication data, while the UserService handles the login API request and persists the resulting user data locally using the shared_preferences package. The profile_screen then interacts with this service to retrieve the saved User object, allowing it to instantly render the user's avatar, name, and details without making redundant network calls. This introduces an updated design pattern focused on state persistence and authentication flow, where a splash_screen actively checks the saved token state via _userService.isLoggedIn() to seamlessly route the user to either the signin_screen or the main application. Finally, this persisted data is essential for rendering the cart_screen; by fetching the securely saved user ID from shared_preferences, the application can pass this specific ID directly to the CartService to query the backend and retrieve only the cart items belonging to the currently authenticated user.