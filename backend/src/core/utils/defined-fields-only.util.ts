/** Strips keys whose value is `undefined` from a DTO before merging it onto
 * an entity. class-transformer instantiates DTO classes with every declared
 * field present as an own property — which TypeScript (under
 * `useDefineForClassFields`, default from ES2022+) initializes to an explicit
 * `undefined` own-property on every instance, even fields absent from the
 * request body. Spreading/assigning such a DTO directly would overwrite
 * untouched entity fields (e.g. NOT NULL columns) with `undefined`; this
 * strips those out first so a partial update only touches the fields it
 * actually named. */
export function definedFieldsOnly<T extends object>(dto: T): Partial<T> {
  return Object.fromEntries(
    Object.entries(dto).filter(([, value]) => value !== undefined),
  ) as Partial<T>;
}
