import fs from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";
import {
  buildOutlineTree,
  decodeArtifactText,
  humanizeOutlineLabel,
  humanizeToken,
  resolveNaturalFocus,
} from "./index";

const REPO_ROOT = path.resolve(__dirname, "../../..");

describe("design-tool outline tree & natural-language focus", () => {
  it("builds semantic, data-group, and grob outline hierarchies on real mtcars-workbench.html", async () => {
    const htmlPath = path.join(REPO_ROOT, "dev_docs/demo/mtcars-workbench.html");
    const bundle = await decodeArtifactText(fs.readFileSync(htmlPath, "utf8"), "mtcars-workbench.html");

    const sem = buildOutlineTree(bundle, "semantic");
    expect(sem.length).toBe(1);
    expect(sem[0].label).toContain("vehicle weight vs fuel economy");
    expect(sem[0].recordCount).toBe(10);

    const branchLabels = sem[0].children.map((c) => c.label);
    expect(branchLabels).toContain("Data Layer");
    expect(branchLabels).toContain("Natural-Language Semantics");
    expect(branchLabels).toContain("Typography & Guides");

    // Verify cross-panel data grouping infers `cyl = 4`, `cyl = 6`, `cyl = 8` automatically
    const dataTree = buildOutlineTree(bundle, "data");
    const byGroup = dataTree[0].children.find((c) => c.id === "data:by-group");
    expect(byGroup).toBeDefined();
    const groupLabels = byGroup!.children.map((g) => g.label);
    expect(groupLabels).toEqual(["cyl = 4", "cyl = 6", "cyl = 8"]);
    const cyl6 = byGroup!.children.find((g) => g.label === "cyl = 6")!;
    expect(cyl6.elementIds.length).toBe(7); // 7 six-cylinder cars in mtcars!

    // Verify natural-language focus resolves data groups, exceptions, entities, and guides
    const fCyl6 = resolveNaturalFocus(bundle, "cyl 6");
    expect(fCyl6?.label).toBe("cyl = 6");
    expect(fCyl6?.elementIds.length).toBe(7);

    const fExc = resolveNaturalFocus(bundle, "exception");
    expect(fExc?.isException).toBe(true);
    expect(fExc?.label).toContain("am = 0");
    expect(fExc?.label).toContain("cyl = 4");
    expect(fExc?.elementIds.length).toBe(3);

    const fLegend = resolveNaturalFocus(bundle, "legend");
    expect(fLegend?.label).toBe("Legend · Cylinders");
    expect(fLegend!.elementIds.length).toBeGreaterThan(0);

    const chrome = sem[0].children.find((c) => c.id === "root:chrome")!;
    expect(chrome.children[0].label).toBe("Title");
    expect(chrome.children[1].label).toBe("Subtitle");

    const fMazda = resolveNaturalFocus(bundle, "Mazda RX4");
    expect(fMazda?.elementIds.length).toBeGreaterThanOrEqual(1);

    expect(humanizeToken("cross_panel_comparison")).toBe("Cross panel comparison");
    expect(humanizeOutlineLabel("root:data", "Data Layer", "32 bound marks", bundle)).toEqual({
      label: "Plotted Data",
      subtitle: "32 observations",
    });
    expect(humanizeOutlineLabel("root:semantics", "Natural-Language Semantics", "10 records", bundle)).toEqual({
      label: "Notes & Findings",
      subtitle: "10 notes",
    });
  });
});
