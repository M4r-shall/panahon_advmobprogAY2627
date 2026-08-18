# Marius Clarence Panahon
## INF231
## CTAMOBL Advance Mobile Programming

A new Flutter project that focuses on advanced topics. Covering the mobile to web transaction.

**Lab Activity 3: discussion**

In this activity, the Cart and CartProduct models structure the raw API data, while the CartService handles network requests, allowing the CartScreen to display the retrieved data. Because cart items only hold basic details, tapping an item triggers an API call to fetch the complete product information, which is then seamlessly passed to the existing detail_screen.dart to prevent code duplication and reuse the widget. This reinforces a modular design pattern that strictly separates the data models, service logic, and UI screens, making the application easier to maintain and expand when adding features like the new cart screen. Finally, to implement a "get by ID" feature as instructed by the API documentation, the CartService simply appends the target user ID to the endpoint URL, such as fetching from dummyjson, and parses the successful JSON response directly into the Dart model.