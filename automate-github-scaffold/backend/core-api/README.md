# Core REST API

Node.js REST API for platform workflows such as user/profile operations, vehicle listings, rental bookings, workshops, service packages and appointments.

Suggested structure inside `src/modules/<module>/`:
- controller / route
- service
- repository
- DTO / validation schema
- module tests

Add the chosen Node framework, package manager and persistence approach after the team confirms whether business data is accessed directly through Firebase or through this API.
