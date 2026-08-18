## TypeScript Rules

- Never use `any` — define proper types in `src/types/` or inline interfaces
- All API response shapes must have a matching TypeScript interface
- Use `unknown` instead of `any` when the type is genuinely unknown, then narrow it
- Prefer `interface` for object shapes, `type` for unions and primitives
- All component props must have an explicit interface defined above the component
- Do not use non-null assertion (`!`) unless you can prove the value is never null at that point
