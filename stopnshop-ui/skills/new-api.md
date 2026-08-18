Add a new API integration file to `stopnshop-ui/src/api/`.

File name: `<feature>Api.ts` (e.g., `pincodeApi.ts`)

Rules:
- Import and use `axiosInstance` from `src/api/axiosInstance.ts` — never import axios directly
- Export one async function per API endpoint
- Define TypeScript request parameter types and response types in `src/types/` before writing the API functions
- Return the `data` field from the axios response, not the full response object
- Do not put error handling here — let errors propagate to the calling component/hook

Read `src/api/axiosInstance.ts` and one existing API file before generating.
