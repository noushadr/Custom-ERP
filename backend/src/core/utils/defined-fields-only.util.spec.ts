import { definedFieldsOnly } from './defined-fields-only.util';

describe('definedFieldsOnly', () => {
  it('drops keys whose value is undefined', () => {
    const result = definedFieldsOnly({
      name: 'Engineering',
      description: undefined,
      isArchived: true,
    });

    expect(result).toEqual({ name: 'Engineering', isArchived: true });
    expect(Object.keys(result)).not.toContain('description');
  });

  it('keeps explicit null values, distinguishing "clear this field" from "leave it alone"', () => {
    const result = definedFieldsOnly({
      headEmployeeId: null,
      name: undefined,
    });

    expect(result).toEqual({ headEmployeeId: null });
  });

  it('returns an empty object when every field is undefined', () => {
    expect(definedFieldsOnly({ a: undefined, b: undefined })).toEqual({});
  });
});
