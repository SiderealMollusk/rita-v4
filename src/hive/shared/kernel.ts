import { Effect, Context } from "effect";

/**
 * A UseCase is the primary entry point for a domain operation.
 * It enforces observability (tracing and logging) by default.
 */
export const makeUseCase = <In, Out, E, R>(
  name: string,
  fn: (input: In) => Effect.Effect<Out, E, R>
) => {
  return (input: In) =>
    fn(input).pipe(
      Effect.withSpan(`UseCase:${name}`, { attributes: { input: JSON.stringify(input) } }),
      Effect.annotateLogs({ useCase: name })
    );
};

/**
 * Base Port interface for Repositories.
 */
export interface Repository<T, Id> {
  readonly findById: (id: Id) => Effect.Effect<T | null, Error>;
  readonly save: (entity: T) => Effect.Effect<void, Error>;
  readonly delete: (id: Id) => Effect.Effect<void, Error>;
}
