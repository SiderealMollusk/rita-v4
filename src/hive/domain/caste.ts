import { Schema } from "@effect/schema";

/**
 * Branded ID for a Caste.
 */
export const CasteId = Schema.String.pipe(Schema.brand("CasteId"));
export type CasteId = Schema.Schema.Type<typeof CasteId>;

/**
 * A Caste defines the template for an agent's capabilities.
 */
export const Caste = Schema.Struct({
  id: CasteId,
  name: Schema.String,
  description: Schema.String,

  /**
   * Doctrine is the core "persona" or system prompt snippet.
   */
  doctrine: Schema.String,

  /**
   * Skills define the available tools for this caste.
   */
  skills: Schema.Array(Schema.String),

  /**
   * Constraints define what the agent is NOT allowed to do.
   */
  constraints: Schema.Array(Schema.String),

  /**
   * Model preference (e.g., "qwen-7b", "claude-3-sonnet").
   */
  preferredModel: Schema.String,
});

export interface Caste extends Schema.Schema.Type<typeof Caste> {}
