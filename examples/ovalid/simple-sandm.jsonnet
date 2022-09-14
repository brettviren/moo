local h = import "simple-schema-hier.jsonnet";
{
    schema: h,
    targets: ["real", h.count, "Name", "Counts", "Counts", "Counts", "Count", "Count"],
    models: [6.9, 42, "Arthur", [1,2,3], [1.1, 2.2, 3.3], ["one", "two", "three"], 1.1, "one"]
}
