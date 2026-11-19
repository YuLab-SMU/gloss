import React, { useEffect, useRef } from "react";
import { EditorState } from "@codemirror/state";
import { EditorView, lineNumbers } from "@codemirror/view";
import { json } from "@codemirror/lang-json";
import { HighlightStyle, StreamLanguage, syntaxHighlighting } from "@codemirror/language";
import { r as rMode } from "@codemirror/legacy-modes/mode/r";
import { tags } from "@lezer/highlight";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";

const lightHighlight = HighlightStyle.define([
  { tag: tags.keyword, color: "#1d4ed8", fontWeight: "600" },
  { tag: tags.string, color: "#0f766e" },
  { tag: tags.number, color: "#b45309" },
  { tag: tags.comment, color: "#76849b", fontStyle: "italic" },
  { tag: tags.propertyName, color: "#1e3a8a" },
  { tag: tags.operator, color: "#475569" },
  { tag: tags.bool, color: "#7c3aed" },
]);

const darkHighlight = HighlightStyle.define([
  { tag: tags.keyword, color: "#60a5fa", fontWeight: "600" },
  { tag: tags.string, color: "#2dd4bf" },
  { tag: tags.number, color: "#fbbf24" },
  { tag: tags.comment, color: "#64748b", fontStyle: "italic" },
  { tag: tags.propertyName, color: "#93c5fd" },
  { tag: tags.operator, color: "#94a3b8" },
  { tag: tags.bool, color: "#c4b5fd" },
]);

export const CodeViewer: React.FC<{
  value: string;
  language: "r" | "json" | "text";
}> = ({ value, language }) => {
  const theme = useWorkbenchStore((s) => s.theme);
  const hostRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;

    const langExt =
      language === "r"
        ? StreamLanguage.define(rMode)
        : language === "json"
          ? json()
          : [];

    const editorTheme = EditorView.theme(
      {
        "&": {
          height: "100%",
          color: "var(--ink-primary)",
          backgroundColor: "transparent",
        },
        ".cm-gutters": {
          backgroundColor: "transparent",
          color: "var(--ink-muted)",
          borderRight: "1px solid var(--border-subtle)",
          fontSize: "10.5px",
        },
        ".cm-content": {
          padding: "8px 0",
        },
        ".cm-line": {
          padding: "0 10px",
        },
      },
      { dark: theme === "obsidian" }
    );

    const state = EditorState.create({
      doc: value,
      extensions: [
        EditorState.readOnly.of(true),
        EditorView.editable.of(false),
        EditorView.lineWrapping,
        lineNumbers(),
        langExt,
        syntaxHighlighting(theme === "obsidian" ? darkHighlight : lightHighlight),
        editorTheme,
      ],
    });

    const view = new EditorView({ state, parent: host });
    return () => view.destroy();
  }, [value, language, theme]);

  return <div ref={hostRef} className="h-full w-full overflow-hidden" />;
};
