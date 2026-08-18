Generate a `.http` test file for a given controller.

Read the controller file first, then create a `tests/` file named after the controller (e.g., `tests/products.http`).

Include:
- A variable block at the top: `@baseUrl = http://localhost:5000` and `@token = YOUR_JWT_HERE`
- One request per endpoint, separated by `###`
- Realistic sample request bodies using Indian names, INR prices, Indian cities
- Both authenticated and unauthenticated variants for protected endpoints

Format each request as:
```
### GET all products
GET {{baseUrl}}/api/products
Authorization: Bearer {{token}}
```
