/** One matched record — enough for a result row and for the frontend to
 * navigate straight to that record's own detail page. */
export interface SearchResultItem {
  id: string;
  title: string;
  subtitle: string | null;
}

/** Grouped by category so the frontend can render one labeled section per
 * type and route a tap to the right detail page. A category is always
 * present (possibly empty) when the caller holds whatever permission that
 * category needs — the categories gated by a permission the caller lacks
 * are simply never populated, not merely hidden, since `SearchService`
 * never queries them in the first place. */
export interface SearchResponseDto {
  employees: SearchResultItem[];
  tasks: SearchResultItem[];
  projects: SearchResultItem[];
  clients: SearchResultItem[];
  articles: SearchResultItem[];
  leads: SearchResultItem[];
}
