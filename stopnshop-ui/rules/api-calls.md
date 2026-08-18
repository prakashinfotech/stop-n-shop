## API Call Rules

- All HTTP calls must use `axiosInstance` from `src/api/axiosInstance.ts`
- API functions live in `src/api/<feature>Api.ts` — never write fetch/axios calls inside components or hooks directly
- The `axiosInstance` handles the base URL, auth token injection, and 401 redirects automatically
- Do not duplicate API functions — check `src/api/` before creating a new one
