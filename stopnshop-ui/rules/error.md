## Error Handling Rules

- Every component that makes an API call must render an error state — never silently fail
- Use the shared `<ErrorMessage />` component from `src/components/ui/` for inline errors
- Use the shared `<Toast />` component for transient success/error notifications
- Wrap page-level components with `<ErrorBoundary />` to catch unexpected render errors
- Never show raw error messages or stack traces to the user — show a friendly message
- Log errors to the console in development; in production errors should be sent to a monitoring service
