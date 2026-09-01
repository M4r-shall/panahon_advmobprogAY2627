# Marius Clarence Panahon
## INF231
## CTAMOBL Advance Mobile Programming

A new Flutter project that focuses on advanced topics. Covering the mobile to web transaction.

Lab Activity Instance
Lab Activity 2: discussion

In this activity, we implemented a structured architecture where the Model (product.dart), Services (product_service.dart), and Screens (product_screen.dart, product_details_screen.dart) interact seamlessly to render data from the API endpoint.

Model defines the expected JSON structure and maps the API response to Dart objects.
Service acts as the networking layer, encapsulating the HTTP fetch logic and converting JSON directly into a list of model instances.
Screen triggers the service logic and uses a FutureBuilder to handle the asynchronous states (loading, error, success) and finally binds the fetched model data into the UI components.
This separation of concerns closely follows the Provider and Model-View-Controller (MVC) / Model-View-ViewModel (MVVM) inspired design patterns. It makes the codebase much easier to maintain, test, and read by strictly decoupling network and business logic from the user interface.

Lab Activity 3: discussion

In this activity, the Cart and CartProduct models structure the raw API data, while the CartService handles network requests, allowing the CartScreen to display the retrieved data. Because cart items only hold basic details, tapping an item triggers an API call to fetch the complete product information, which is then seamlessly passed to the existing detail_screen.dart to prevent code duplication and reuse the widget. This reinforces a modular design pattern that strictly separates the data models, service logic, and UI screens, making the application easier to maintain and expand when adding features like the new cart screen. Finally, to implement a "get by ID" feature as instructed by the API documentation, the CartService simply appends the target user ID to the endpoint URL, such as fetching from dummyjson, and parses the successful JSON response directly into the Dart model.