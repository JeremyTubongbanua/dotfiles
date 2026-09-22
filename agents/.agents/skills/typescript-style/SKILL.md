---
name: typescript-style
description: Apply the user's preferred TypeScript and TSX coding style. Use whenever writing or editing TypeScript or TSX code.
---

# TypeScript Style

Prefer function expressions over declarations, explicit type annotations even when inferred, exports at the bottom of the file, and semicolons after expressions, variables, and return statements.

```tsx
const Button = (): React.JSX.Element => {
    return <div>abc</div>;
};

export default Button;
```
