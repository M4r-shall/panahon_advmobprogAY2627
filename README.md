# Marius Clarence Panahon
## INF231
## CTAMOBL Advance Mobile Programming

A new Flutter project that focuses on advanced topics. Covering the mobile to web transaction.

Lab Activity Instance

Lab Activity 2: discussion

In this activity, we implemented a structured architecture where the Model, Services, and Screens interact seamlessly to render data from the API endpoint. Model defines the expected JSON structure and maps the API response to Dart objects.
Service acts as the networking layer, encapsulating the HTTP fetch logic and converting JSON directly into a list of model instances.
Screen triggers the service logic and uses a FutureBuilder to handle the asynchronous states and finally binds the fetched model data into the UI components.
This separation of concerns closely follows the Provider and Model-View-Controller / Model-View-ViewModel inspired design patterns. It makes the codebase much easier to maintain, test, and read by strictly decoupling network and business logic from the user interface.
