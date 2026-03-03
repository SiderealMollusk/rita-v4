# 0310 - Effect-DDD Lego Blocks Specification

## Context
This document defines the technical implementation of the DDD primitives using `EffectTS`. These "Lego Blocks" are the core building blocks for the Hive, designed to force good practice (observability, type safety, and DI) at the type level.

---

## 1. Core Primitives

### 1.1 Entity & Value Object
Instead of separate base classes, we use `Effect.Schema` to define both.
- **Identity**: Every Entity must have an `id` field of a branded type (e.g., `UserId`).
- **Immutability**: All fields are `readonly` by default.
- **Validation**: Validation happens at the boundary using `Schema.decode`.

```typescript
// Example: Domain Entity
import { Schema } from "@effect/schema";

export const UserId = Schema.String.pipe(Schema.brand("UserId"));
export type UserId = Schema.Schema.Type<typeof UserId>;

export const User = Schema.Struct({
  id: UserId,
  name: Schema.String,
  email: Schema.String.pipe(Schema.pattern(/@/)),
});
export interface User extends Schema.Schema.Type<typeof User> {}
```

### 1.2 Use Case (The Observable Unit)
Every UseCase is a function that returns an `Effect`. To enforce observability, we define a helper that wraps the execution in a `Span`.

```typescript
// Example: UseCase Definition
import { Effect } from "effect";

export const makeUseCase = <A, E, R>(
  name: string,
  fn: (input: any) => Effect.Effect<A, E, R>
) => {
  return (input: any) =>
    fn(input).pipe(
      Effect.withSpan(name, { attributes: { input } }),
      Effect.annotateLogs({ useCase: name })
    );
};
```

---

## 2. Infrastructure Primitives

### 2.1 Ports & Adapters (Tags & Layers)
- **Ports**: Defined as `Context.Tag`. They describe the *behavior* without an implementation.
- **Adapters**: Defined as `Layer`. They provide the *actual implementation*.

```typescript
// Example: Port (Tag)
import { Context } from "effect";

export interface UserRepository {
  readonly findById: (id: UserId) => Effect.Effect<User | null, Error>;
  readonly save: (user: User) => Effect.Effect<void, Error>;
}

export const UserRepository = Context.GenericTag<UserRepository>("UserRepository");

// Example: Adapter (Layer)
export const UserRepositoryInMemory = Layer.succeed(
  UserRepository,
  UserRepository.of({
    findById: (id) => Effect.succeed(null),
    save: (user) => Effect.log(`Saving user: ${user.name}`),
  })
);
```

---

## 3. The "Forced" Practice Rules

1. **No Naked Logic**: Every domain operation that interacts with infrastructure or crosses bounded contexts MUST be defined as a `UseCase` via `makeUseCase`.
2. **Strict Identity**: Mixing IDs (e.g., passing a `CardId` where a `UserId` is expected) must result in a compiler error via branded types.
3. **Dependency Injection ONLY**: No `new` or global singletons for services. Everything must be requested from the `Context`.
4. **Result over Throw**: No `try/catch` for business errors. All expected failures must be part of the `E` (error) type in `Effect<A, E, R>`.

---

## 4. Directory Layout

```text
src/hive/
├── domain/            # Pure logic + Entities (Schema)
├── application/       # UseCases (Effect factories)
├── infrastructure/    # Adapters (Layers)
│   ├── nextcloud/     # Deck, Talk, etc.
│   └── persistence/   # Postgres, InMemory
├── shared/            # Kernel (Base types, common schemas)
└── interface/         # CLI, Webhooks
```
