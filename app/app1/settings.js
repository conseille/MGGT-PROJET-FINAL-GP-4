module.exports = {
  flowFile: "flows.json",
  uiPort: process.env.PORT || 1880,
  diagnostics: { enabled: true, ui: false },
  runtimeState: { enabled: false, ui: false },
  editorTheme: {
    projects: { enabled: false },
    page: { title: "Smart City - Groupe 4" },
    header: { title: "Smart City - Groupe 4" }
  },
  functionGlobalContext: {}
};
